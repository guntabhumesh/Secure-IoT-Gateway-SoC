// =============================================================================
// axi_aes_slave.v
//
// AXI4 slave implementing the register map from doc/regmapping.
// Wraps aes_cipher_top (encrypt) and aes_inv_cipher_top (decrypt).
//
// Register map  (byte offset from slave base address):
//   0x00  CTRL_STATUS  [17]=KDONE [16]=DONE  [2]=RST [1]=KLD [0]=LD
//   0x04  KEY0  key[127:96]
//   0x08  KEY1  key[ 95:64]
//   0x0C  KEY2  key[ 63:32]
//   0x10  KEY3  key[ 31: 0]
//   0x14  TEXT0 plain[127:96]
//   0x18  TEXT1 plain[ 95:64]
//   0x1C  TEXT2 plain[ 63:32]
//   0x20  TEXT3 plain[ 31: 0]
//   0x24  OUT0  out[127:96]  (RO)
//   0x28  OUT1  out[ 95:64]  (RO)
//   0x2C  OUT2  out[ 63:32]  (RO)
//   0x30  OUT3  out[ 31: 0]  (RO)
//
// AES core interfaces:
//   aes_cipher_top     (clk, rst_n, ld, done, key, text_in, text_out)
//   aes_inv_cipher_top (clk, rst_n, kld, ld, done, key, text_in, text_out)
//
// inv_cipher is chained after cipher:
//   kld=aes_ld, ld=enc_done, text_in=enc_text_out
//
// AXI handshake correctness:
//   bvalid / rvalid are held asserted until the cycle where
//   bready / rready is also asserted (standard AXI spec).
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module axi_aes_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,   // active-low

    // Write address channel
    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awlock,
    input  wire [3:0]              s_axi_awcache,
    input  wire [2:0]              s_axi_awprot,
    input  wire [3:0]              s_axi_awqos,
    input  wire [3:0]              s_axi_awregion,
    input  wire                    s_axi_awvalid,
    output reg                     s_axi_awready,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    // Write response channel
    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // Read address channel
    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arlock,
    input  wire [3:0]              s_axi_arcache,
    input  wire [2:0]              s_axi_arprot,
    input  wire [3:0]              s_axi_arqos,
    input  wire [3:0]              s_axi_arregion,
    input  wire                    s_axi_arvalid,
    output reg                     s_axi_arready,

    // Read data channel
    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready
);

    wire clk   = s_axi_aclk;
    wire rst   = ~s_axi_aresetn;   // active-high for logic
    wire rst_n =  s_axi_aresetn;   // active-low  for AES cores

    // ── Register address decode: word index = addr[5:2] ─────────────
    localparam [3:0]
        A_CTRL  = 4'h0,   // 0x00
        A_KEY0  = 4'h1,   // 0x04
        A_KEY1  = 4'h2,   // 0x08
        A_KEY2  = 4'h3,   // 0x0C
        A_KEY3  = 4'h4,   // 0x10
        A_TEXT0 = 4'h5,   // 0x14
        A_TEXT1 = 4'h6,   // 0x18
        A_TEXT2 = 4'h7,   // 0x1C
        A_TEXT3 = 4'h8,   // 0x20
        A_OUT0  = 4'h9,   // 0x24 — ciphertext [127:96]
        A_OUT1  = 4'hA,   // 0x28 — ciphertext [ 95:64]
        A_OUT2  = 4'hB,   // 0x2C — ciphertext [ 63:32]
        A_OUT3  = 4'hC,   // 0x30 — ciphertext [ 31: 0]
        A_DOUT0 = 4'hD,   // 0x34 — dec plaintext [127:96]
        A_DOUT1 = 4'hE,   // 0x38 — dec plaintext [ 95:64]
        A_DOUT2 = 4'hF;   // 0x3C — dec plaintext [ 63:32]
    // 0x40 = dec plaintext [31:0] uses addr[5:2]=0x10 — handled in default

    // ── Register storage ─────────────────────────────────────────────
    reg [127:0] r_key;
    reg [127:0] r_text;

    // ── AES control ───────────────────────────────────────────────────
    reg aes_ld,  aes_kld, aes_srst;
    reg aes_ld_p, aes_kld_p;   // pending pulses (fire next cycle)

    // ── AES cores ─────────────────────────────────────────────────────
    wire        enc_done;
    wire [127:0] enc_text_out;
    wire        dec_done;
    wire [127:0] dec_text_out;

    reg  aes_srst_r;
    wire aes_rst_n_eff = rst_n & ~aes_srst_r;

    aes_cipher_top u_enc (
        .clk      (clk),
        .rst      (aes_rst_n_eff),
        .ld       (aes_ld),
        .done     (enc_done),
        .key      (r_key),
        .text_in  (r_text),
        .text_out (enc_text_out)
    );

    aes_inv_cipher_top u_dec (
        .clk      (clk),
        .rst      (aes_rst_n_eff),
        .kld      (aes_ld),        // key load: same pulse as cipher
        .ld       (enc_done),      // data load: triggered by enc_done
        .done     (dec_done),
        .key      (r_key),
        .text_in  (enc_text_out),
        .text_out (dec_text_out)
    );

    // ── Status sticky bits ────────────────────────────────────────────
    reg r_done_sticky, r_kdone_sticky, r_dec_done_sticky;
    reg [127:0] r_enc_out;   // ciphertext — readable via OUT0..OUT3
    reg [127:0] r_dec_out;   // round-trip dec plaintext — readable via DEC_OUT

    always @(posedge clk) begin
        if (rst || aes_srst_r) begin
            r_done_sticky     <= 1'b0;
            r_kdone_sticky    <= 1'b0;
            r_dec_done_sticky <= 1'b0;
            r_enc_out         <= 128'b0;
            r_dec_out         <= 128'b0;
        end else begin
            // New encrypt/key-load clears all status flags
            if (aes_ld) begin
                r_done_sticky     <= 1'b0;
                r_kdone_sticky    <= 1'b0;
                r_dec_done_sticky <= 1'b0;
            end
            if (aes_kld) begin
                r_kdone_sticky    <= 1'b0;
            end
            // Set KDONE immediately when KLD or LD fires
            if (aes_kld || aes_ld) r_kdone_sticky <= 1'b1;
            // Capture enc output and set DONE
            if (enc_done) begin
                r_done_sticky <= 1'b1;
                r_enc_out     <= enc_text_out;
            end
            // Capture dec output and set DEC_DONE (round-trip complete)
            if (dec_done) begin
                r_dec_done_sticky <= 1'b1;
                r_dec_out         <= dec_text_out;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) aes_srst_r <= 1'b0;
        else     aes_srst_r <= aes_srst;
    end

    // ── AXI Write FSM ─────────────────────────────────────────────────
    localparam [1:0] W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;

    reg [1:0]            wstate;
    reg [ID_WIDTH-1:0]   w_id;
    reg [5:0]            w_reg;
    reg [DATA_WIDTH-1:0] w_data;
    reg                  w_committed; // flag: have we committed this write yet

    always @(posedge clk) begin
        if (rst) begin
            wstate        <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            aes_ld        <= 1'b0;
            aes_kld       <= 1'b0;
            aes_ld_p      <= 1'b0;
            aes_kld_p     <= 1'b0;
            aes_srst      <= 1'b0;
            r_key         <= 128'b0;
            r_text        <= 128'b0;
            w_committed   <= 1'b0;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aes_ld        <= 1'b0;
            aes_kld       <= 1'b0;
            aes_srst      <= 1'b0;

            // Fire pending AES pulses
            if (aes_ld_p)  begin aes_ld  <= 1'b1; aes_ld_p  <= 1'b0; end
            if (aes_kld_p) begin aes_kld <= 1'b1; aes_kld_p <= 1'b0; end

            case (wstate)
                W_IDLE: begin
                    w_committed <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        w_id  <= s_axi_awid;
                        w_reg <= s_axi_awaddr[7:2];
                        if (s_axi_wvalid) begin
                            s_axi_wready <= 1'b1;
                            w_data <= s_axi_wdata;
                            wstate <= W_RESP;
                        end else
                            wstate <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        w_data <= s_axi_wdata;
                        wstate <= W_RESP;
                    end
                end

                W_RESP: begin
                    if (!w_committed) begin
                        // Commit write — inline (non-blocking assigns are fine here,
                        // they all go to different registers from the FSM control regs)
                        w_committed <= 1'b1;
                        case (w_reg[3:0])
                            A_CTRL: begin
                                if (w_data[0]) aes_ld_p  <= 1'b1;
                                if (w_data[1]) aes_kld_p <= 1'b1;
                                if (w_data[2]) aes_srst  <= 1'b1;
                            end
                            A_KEY0:  r_key[127:96]  <= w_data;
                            A_KEY1:  r_key[ 95:64]  <= w_data;
                            A_KEY2:  r_key[ 63:32]  <= w_data;
                            A_KEY3:  r_key[ 31:  0] <= w_data;
                            A_TEXT0: r_text[127:96]  <= w_data;
                            A_TEXT1: r_text[ 95:64]  <= w_data;
                            A_TEXT2: r_text[ 63:32]  <= w_data;
                            A_TEXT3: r_text[ 31:  0] <= w_data;
                            default: ;
                        endcase
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                        s_axi_bid    <= w_id;
                    end else if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        w_committed  <= 1'b0;
                        wstate       <= W_IDLE;
                    end
                    // else: hold bvalid high until bready
                end

                default: wstate <= W_IDLE;
            endcase
        end
    end

    // ── AXI Read FSM ──────────────────────────────────────────────────
    localparam [1:0] R_IDLE = 2'd0, R_LATCH = 2'd1, R_RESP = 2'd2;

    reg [1:0]          rstate;
    reg [ID_WIDTH-1:0] r_id;
    reg [5:0]          r_reg;
    reg [DATA_WIDTH-1:0] r_latch;   // combinatorial read captured on AR

    // Read data mux (combinatorial off r_reg)
    reg [DATA_WIDTH-1:0] rd_mux;
    always @(*) begin
        case (r_reg[3:0])
            A_CTRL:  rd_mux = {13'b0, r_dec_done_sticky, r_kdone_sticky, r_done_sticky, 16'b0};
            A_KEY0:  rd_mux = r_key[127:96];
            A_KEY1:  rd_mux = r_key[ 95:64];
            A_KEY2:  rd_mux = r_key[ 63:32];
            A_KEY3:  rd_mux = r_key[ 31:  0];
            A_TEXT0: rd_mux = r_text[127:96];
            A_TEXT1: rd_mux = r_text[ 95:64];
            A_TEXT2: rd_mux = r_text[ 63:32];
            A_TEXT3: rd_mux = r_text[ 31:  0];
            A_OUT0:  rd_mux = r_enc_out[127:96];   // ciphertext
            A_OUT1:  rd_mux = r_enc_out[ 95:64];
            A_OUT2:  rd_mux = r_enc_out[ 63:32];
            A_OUT3:  rd_mux = r_enc_out[ 31:  0];
            A_DOUT0: rd_mux = r_dec_out[127:96];   // round-trip dec plaintext
            A_DOUT1: rd_mux = r_dec_out[ 95:64];
            A_DOUT2: rd_mux = r_dec_out[ 63:32];
            default: rd_mux = r_dec_out[ 31:  0];  // 0x40 = A_DOUT3
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            rstate        <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rlast   <= 1'b0;
        end else begin
            s_axi_arready <= 1'b0;

            case (rstate)
                R_IDLE: begin
                    if (s_axi_arvalid) begin
                        // Accept AR, capture address
                        s_axi_arready <= 1'b1;
                        r_id  <= s_axi_arid;
                        r_reg <= s_axi_araddr[7:2];
                        rstate <= R_LATCH;
                    end
                end

                // One cycle to let rd_mux settle after r_reg is written
                R_LATCH: begin
                    r_latch <= rd_mux;
                    rstate  <= R_RESP;
                end

                R_RESP: begin
                    if (!s_axi_rvalid) begin
                        // First cycle: assert rvalid
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= r_latch;
                        s_axi_rresp  <= 2'b00;
                        s_axi_rid    <= r_id;
                        s_axi_rlast  <= 1'b1;
                    end else if (s_axi_rready) begin
                        // Handshake complete
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        rstate       <= R_IDLE;
                    end
                    // else: hold rvalid=1 until rready
                end

                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
