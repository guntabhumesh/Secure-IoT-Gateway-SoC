/*
 * dummy_axi_slave.v
 *
 * Simple AXI4 slave that:
 *  - Accepts any write transaction and returns OKAY response
 *  - Accepts any read transaction and returns a fixed read data (0xDEAD_xxxx)
 *    where xxxx encodes the slave index passed as a parameter
 *  - Single-beat only (awlen/arlen expected to be 0 for these tests)
 *
 * Used as placeholder for m01 – m10 ports of the interconnect.
 */

`timescale 1ns/1ps
`default_nettype none

module dummy_axi_slave #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,
    parameter ID_WIDTH    = 8,
    parameter SLAVE_INDEX = 0        // appears in lower 16 bits of read data
)(
    input  wire                    clk,
    input  wire                    rst,

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

    // Internal storage (word-addressed, 16 words deep)
    reg [DATA_WIDTH-1:0] mem [0:15];

    // ── Write FSM ───────────────────────────────────────────────────────
    localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
    reg [1:0]         wstate;
    reg [ID_WIDTH-1:0] wid;
    reg [3:0]          waddr_idx;

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = {16'hDEAD, SLAVE_INDEX[15:0]};
    end

    always @(posedge clk) begin
        if (rst) begin
            wstate        <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            case (wstate)
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        wid           <= s_axi_awid;
                        waddr_idx     <= s_axi_awaddr[5:2];
                        if (s_axi_wvalid) begin
                            s_axi_wready <= 1'b1;
                            mem[s_axi_awaddr[5:2]] <= s_axi_wdata;
                            wstate <= W_RESP;
                        end else begin
                            wstate <= W_DATA;
                        end
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready           <= 1'b1;
                        mem[waddr_idx]         <= s_axi_wdata;
                        wstate                 <= W_RESP;
                    end
                end

                W_RESP: begin
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b1;
                    s_axi_bresp   <= 2'b00;   // OKAY
                    s_axi_bid     <= wid;
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        wstate       <= W_IDLE;
                    end
                end

                default: wstate <= W_IDLE;
            endcase
        end
    end

    // ── Read FSM ────────────────────────────────────────────────────────
    localparam R_IDLE = 2'd0, R_RESP = 2'd1;
    reg [1:0]          rstate;
    reg [ID_WIDTH-1:0] rid_r;
    reg [3:0]          raddr_idx;
<<<<<<< HEAD
    reg                r_valid_sent;  // rvalid has been held for at least 1 cycle
=======
>>>>>>> 64c88e06a437d5756a98d02e50ac7b47001c0389

    always @(posedge clk) begin
        if (rst) begin
            rstate        <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rlast   <= 1'b0;
<<<<<<< HEAD
            r_valid_sent  <= 1'b0;
=======
>>>>>>> 64c88e06a437d5756a98d02e50ac7b47001c0389
        end else begin
            s_axi_arready <= 1'b0;

            case (rstate)
                R_IDLE: begin
<<<<<<< HEAD
                    s_axi_rvalid  <= 1'b0;
                    r_valid_sent  <= 1'b0;
=======
                    s_axi_rvalid <= 1'b0;
>>>>>>> 64c88e06a437d5756a98d02e50ac7b47001c0389
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        rid_r         <= s_axi_arid;
                        raddr_idx     <= s_axi_araddr[5:2];
                        rstate        <= R_RESP;
                    end
                end

                R_RESP: begin
<<<<<<< HEAD
                    // Assert rvalid + data (holds until rready seen after rvalid)
=======
                    s_axi_arready <= 1'b0;
>>>>>>> 64c88e06a437d5756a98d02e50ac7b47001c0389
                    s_axi_rvalid  <= 1'b1;
                    s_axi_rdata   <= mem[raddr_idx];
                    s_axi_rresp   <= 2'b00;
                    s_axi_rid     <= rid_r;
                    s_axi_rlast   <= 1'b1;
<<<<<<< HEAD
                    r_valid_sent  <= 1'b1;
                    // Only complete handshake after rvalid has been seen for >= 1 cycle
                    if (r_valid_sent && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        r_valid_sent <= 1'b0;
=======
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
>>>>>>> 64c88e06a437d5756a98d02e50ac7b47001c0389
                        rstate       <= R_IDLE;
                    end
                end

                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
