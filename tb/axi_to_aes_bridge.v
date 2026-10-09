// =============================================================================
// axi_to_aes_bridge.v
//
// AXI4-Lite slave wrapper around aes_cipher_top (encrypt) and
// aes_inv_cipher_top (decrypt).
//
// ── Key insight: port interfaces ─────────────────────────────────────────────
//
//   aes_cipher_top(clk, rst, ld, done, key, text_in, text_out)
//     rst  : active-low
//     ld   : 1-cycle pulse → loads key + plaintext, starts encryption
//     done : high when text_out is valid (~11 clocks later)
//
//   aes_inv_cipher_top(clk, rst, kld, ld, done, key, text_in, text_out)
//     rst  : active-low
//     kld  : key load (same cycle as cipher ld) → expands key schedule
//     ld   : data load → triggered by enc_done, feeds ciphertext in
//     done : high when text_out (plaintext) is valid
//
// ── Operating modes ──────────────────────────────────────────────────────────
//
//   ENCRYPT (CTRL[0] = 1):
//     • Pulse enc_ld one cycle.
//     • inv_cipher.kld fires simultaneously (pre-loads its key schedule).
//     • ~11 cycles later enc_done fires → inv_cipher.ld fires automatically,
//       feeding the ciphertext into the inverse cipher.
//     • ~11 more cycles later dec_done fires — STATUS[1] sets.
//     • TXOUT holds the ciphertext (enc_text_out captured on enc_done).
//     • STATUS[0] (enc_done_sticky) sets after enc_done.
//
//   DECRYPT-ONLY  (not directly supported — the HW always does enc→dec chain)
//     If you need pure decryption, write KEY + TXIN (ciphertext-to-decrypt),
//     assert CTRL[1] = 1.  A dec_ld pulse is generated; HOWEVER because
//     inv_cipher.ld is a data load (not a key load), pure decryption without
//     a preceding key schedule is not supported by this RTL.  Instead, use
//     the round-trip: CTRL[0] will encrypt and then auto-decrypt.
//     For the SoC use case CTRL[0] always triggers the full chain.
//
// ── Register map (AXI byte address = slave_base + offset) ───────────────────
//
//  Offset  Name        R/W  Description
//  0x00    CTRL         W   [0] = start encrypt + arm auto-decrypt chain
//                           [1] = reserved (write ignored)
//                           Always reads 0.
//  0x04    STATUS        R  [1] = dec_done sticky (plaintext in TXOUT)
//                           [0] = enc_done sticky (ciphertext in TXOUT)
//                           Cleared automatically on next CTRL write.
//  0x08    KEY0         RW  key[127:96]
//  0x0C    KEY1         RW  key[ 95:64]
//  0x10    KEY2         RW  key[ 63:32]
//  0x14    KEY3         RW  key[ 31: 0]
//  0x18    TXIN0        RW  text_in[127:96]   (plaintext for encrypt)
//  0x1C    TXIN1        RW  text_in[ 95:64]
//  0x20    TXIN2        RW  text_in[ 63:32]
//  0x24    TXIN3        RW  text_in[ 31: 0]
//  0x28    TXOUT0        R  text_out[127:96]  (last captured result)
//  0x2C    TXOUT1        R  text_out[ 95:64]
//  0x30    TXOUT2        R  text_out[ 63:32]
//  0x34    TXOUT3        R  text_out[ 31: 0]
//
// ── Typical software flow ─────────────────────────────────────────────────────
//   1. Write KEY0–KEY3  (128-bit key, MSB first)
//   2. Write TXIN0–TXIN3 (128-bit plaintext, MSB first)
//   3. Write CTRL = 1   → starts encryption
//   4. Poll STATUS[0] until set → ciphertext is in TXOUT0–TXOUT3
//   5. (Optional) Poll STATUS[1] until set → inv_cipher result also ready
//      (should equal original plaintext if enc→dec chain worked correctly)
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module axi_to_aes_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                    clk,
    input  wire                    rst,       // active-high synchronous reset

    // ── AXI4 Slave ───────────────────────────────────────────────────────
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

    // ── Register indices (addr[7:2]) ─────────────────────────────────────
    localparam REG_CTRL   = 4'd0;
    localparam REG_STATUS = 4'd1;
    localparam REG_KEY0   = 4'd2;
    localparam REG_KEY1   = 4'd3;
    localparam REG_KEY2   = 4'd4;
    localparam REG_KEY3   = 4'd5;
    localparam REG_TXIN0  = 4'd6;
    localparam REG_TXIN1  = 4'd7;
    localparam REG_TXIN2  = 4'd8;
    localparam REG_TXIN3  = 4'd9;
    localparam REG_TXOUT0 = 4'd10;
    localparam REG_TXOUT1 = 4'd11;
    localparam REG_TXOUT2 = 4'd12;
    localparam REG_TXOUT3 = 4'd13;

    // ── Register storage ─────────────────────────────────────────────────
    reg [127:0] r_key;
    reg [127:0] r_text_in;
    reg [127:0] r_text_out;   // latched on enc_done or dec_done

    // ── AES core signals ─────────────────────────────────────────────────
    wire [127:0] enc_text_out;
    wire [127:0] dec_text_out;
    wire         enc_done;
    wire         dec_done;

    reg          enc_ld;      // drives cipher.ld AND inv_cipher.kld

    // AES cores use active-LOW reset
    wire aes_rst_n = ~rst;

    // ── aes_cipher_top ───────────────────────────────────────────────────
    aes_cipher_top u_cipher (
        .clk      (clk),
        .rst      (aes_rst_n),
        .ld       (enc_ld),
        .done     (enc_done),
        .key      (r_key),
        .text_in  (r_text_in),
        .text_out (enc_text_out)
    );

    // ── aes_inv_cipher_top ───────────────────────────────────────────────
    // kld  = enc_ld    (loads key schedule the same cycle cipher starts)
    // ld   = enc_done  (auto-triggered when cipher finishes)
    // text_in = enc_text_out (decrypt whatever the cipher just produced)
    aes_inv_cipher_top u_inv_cipher (
        .clk      (clk),
        .rst      (aes_rst_n),
        .kld      (enc_ld),        // key load: same pulse as cipher
        .ld       (enc_done),      // data load: driven by cipher done
        .done     (dec_done),
        .key      (r_key),
        .text_in  (enc_text_out),  // always decrypts cipher's own output
        .text_out (dec_text_out)
    );

    // ── Status sticky bits ───────────────────────────────────────────────
    reg r_enc_done_sticky;
    reg r_dec_done_sticky;

    always @(posedge clk) begin
        if (rst) begin
            r_enc_done_sticky <= 1'b0;
            r_dec_done_sticky <= 1'b0;
            r_text_out        <= 128'b0;
        end else begin
            if (enc_ld) begin
                // Clear on new operation start
                r_enc_done_sticky <= 1'b0;
                r_dec_done_sticky <= 1'b0;
            end
            if (enc_done) begin
                r_enc_done_sticky <= 1'b1;
                r_text_out        <= enc_text_out;  // capture ciphertext
            end
            if (dec_done) begin
                r_dec_done_sticky <= 1'b1;
                r_text_out        <= dec_text_out;  // overwrite with plaintext
            end
        end
    end

    // ── AXI Write FSM ────────────────────────────────────────────────────
    localparam W_IDLE = 2'd0,
               W_DATA = 2'd1,
               W_RESP = 2'd2;

    reg [1:0]            wstate;
    reg [ID_WIDTH-1:0]   w_cap_id;
    reg [5:0]            w_cap_reg;
    reg [DATA_WIDTH-1:0] w_cap_data;
    reg                  enc_ld_next;

    always @(posedge clk) begin
        if (rst) begin
            wstate        <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            enc_ld        <= 1'b0;
            enc_ld_next   <= 1'b0;
            r_key         <= 128'b0;
            r_text_in     <= 128'b0;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            enc_ld        <= 1'b0;

            // Fire the one-cycle pulse requested in the previous cycle
            if (enc_ld_next) begin
                enc_ld      <= 1'b1;
                enc_ld_next <= 1'b0;
            end

            case (wstate)
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        w_cap_id      <= s_axi_awid;
                        w_cap_reg     <= s_axi_awaddr[7:2];
                        if (s_axi_wvalid) begin
                            s_axi_wready <= 1'b1;
                            w_cap_data   <= s_axi_wdata;
                            wstate       <= W_RESP;
                        end else begin
                            wstate <= W_DATA;
                        end
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        w_cap_data   <= s_axi_wdata;
                        wstate       <= W_RESP;
                    end
                end

                W_RESP: begin
                    // Commit register write
                    case (w_cap_reg[3:0])
                        REG_CTRL: begin
                            if (w_cap_data[0]) enc_ld_next <= 1'b1;
                            // bit[1] ignored — inv cipher is auto-chained
                        end
                        REG_KEY0:  r_key[127:96]     <= w_cap_data;
                        REG_KEY1:  r_key[ 95:64]     <= w_cap_data;
                        REG_KEY2:  r_key[ 63:32]     <= w_cap_data;
                        REG_KEY3:  r_key[ 31: 0]     <= w_cap_data;
                        REG_TXIN0: r_text_in[127:96] <= w_cap_data;
                        REG_TXIN1: r_text_in[ 95:64] <= w_cap_data;
                        REG_TXIN2: r_text_in[ 63:32] <= w_cap_data;
                        REG_TXIN3: r_text_in[ 31: 0] <= w_cap_data;
                        default: ;  // status/txout are read-only
                    endcase

                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00;
                    s_axi_bid    <= w_cap_id;
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        wstate       <= W_IDLE;
                    end
                end

                default: wstate <= W_IDLE;
            endcase
        end
    end

    // ── AXI Read FSM ─────────────────────────────────────────────────────
    localparam R_IDLE = 2'd0,
               R_RESP = 2'd1;

    reg [1:0]          rstate;
    reg [ID_WIDTH-1:0] r_cap_id;
    reg [5:0]          r_cap_reg;

    reg [DATA_WIDTH-1:0] rdata_mux;
    always @(*) begin
        case (r_cap_reg[3:0])
            REG_CTRL:   rdata_mux = 32'h0;
            REG_STATUS: rdata_mux = {30'b0, r_dec_done_sticky, r_enc_done_sticky};
            REG_KEY0:   rdata_mux = r_key[127:96];
            REG_KEY1:   rdata_mux = r_key[ 95:64];
            REG_KEY2:   rdata_mux = r_key[ 63:32];
            REG_KEY3:   rdata_mux = r_key[ 31: 0];
            REG_TXIN0:  rdata_mux = r_text_in[127:96];
            REG_TXIN1:  rdata_mux = r_text_in[ 95:64];
            REG_TXIN2:  rdata_mux = r_text_in[ 63:32];
            REG_TXIN3:  rdata_mux = r_text_in[ 31: 0];
            REG_TXOUT0: rdata_mux = r_text_out[127:96];
            REG_TXOUT1: rdata_mux = r_text_out[ 95:64];
            REG_TXOUT2: rdata_mux = r_text_out[ 63:32];
            REG_TXOUT3: rdata_mux = r_text_out[ 31: 0];
            default:    rdata_mux = 32'hDEAD_BEEF;
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
                    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        r_cap_id      <= s_axi_arid;
                        r_cap_reg     <= s_axi_araddr[7:2];
                        rstate        <= R_RESP;
                    end
                end
                R_RESP: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    s_axi_rdata   <= rdata_mux;
                    s_axi_rresp   <= 2'b00;
                    s_axi_rid     <= r_cap_id;
                    s_axi_rlast   <= 1'b1;
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        rstate       <= R_IDLE;
                    end
                end
                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
