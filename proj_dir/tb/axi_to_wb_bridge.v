/*
 * axi_to_wb_bridge.v
 *
 * AXI4 Slave → Wishbone (B2) Master bridge
 * Translates single-beat AXI write/read into Wishbone cycles for
 * i2c_master_top (8-bit data, 3-bit address).
 *
 * AXI data  : 32-bit  (bits [7:0] forwarded to WB)
 * AXI addr  : 32-bit  (bits [4:2] forwarded as wb_adr_i[2:0])
 * WB data   : 8-bit
 * WB addr   : 3-bit
 *
 * Handshake rules (AXI spec):
 *   - ready may be asserted before or at the same time as valid
 *   - a transfer occurs on the clock edge where BOTH valid AND ready are high
 *   - once valid is asserted it must not be de-asserted until the handshake
 *
 * This implementation accepts AW+W in the same cycle (simultaneous) or
 * separately (AW first, then W).  bvalid and rvalid are held asserted
 * until bready / rready is seen (they are NOT cleared the same cycle
 * they are first asserted — this avoids missing a ready=1 that is
 * sampled before valid propagates).
 */

`timescale 1ns/1ps
`default_nettype none

module axi_to_wb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                    clk,
    input  wire                    rst,          // active-high synchronous

    // ── AXI4 Slave ────────────────────────────────────────────────────
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

    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

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

    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready,

    // ── Wishbone Master ───────────────────────────────────────────────
    output reg  [2:0]              wb_adr_o,
    output reg  [7:0]              wb_dat_o,
    input  wire [7:0]              wb_dat_i,
    output reg                     wb_we_o,
    output reg                     wb_stb_o,
    output reg                     wb_cyc_o,
    input  wire                    wb_ack_i
);

    // ── FSM ───────────────────────────────────────────────────────────
    localparam [2:0]
        IDLE    = 3'd0,
        WR_DATA = 3'd1,   // waiting for wvalid after awvalid accepted
        WR_WB   = 3'd2,   // WB write cycle in progress
        WR_RESP = 3'd3,   // holding bvalid until bready
        RD_WB   = 3'd4,   // WB read cycle in progress
        RD_RESP = 3'd5;   // holding rvalid until rready

    reg [2:0] state;

    reg [ID_WIDTH-1:0] cap_id;
    reg [2:0]          cap_wb_addr;
    reg [7:0]          cap_wb_wdata;

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rlast   <= 1'b0;
            wb_adr_o      <= 3'd0;
            wb_dat_o      <= 8'd0;
            wb_we_o       <= 1'b0;
            wb_stb_o      <= 1'b0;
            wb_cyc_o      <= 1'b0;
        end else begin
            // Default: de-assert one-cycle pulses
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_arready <= 1'b0;

            case (state)

                // ── Idle: wait for AW or AR ────────────────────────────
                IDLE: begin
                    wb_stb_o <= 1'b0;
                    wb_cyc_o <= 1'b0;

                    if (s_axi_awvalid) begin
                        // Accept write address
                        s_axi_awready <= 1'b1;
                        cap_id        <= s_axi_awid;
                        cap_wb_addr   <= s_axi_awaddr[4:2];

                        if (s_axi_wvalid) begin
                            // Data arrived simultaneously – accept both
                            s_axi_wready <= 1'b1;
                            cap_wb_wdata <= s_axi_wdata[7:0];
                            state        <= WR_WB;
                        end else begin
                            state <= WR_DATA;
                        end

                    end else if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        cap_id        <= s_axi_arid;
                        cap_wb_addr   <= s_axi_araddr[4:2];
                        state         <= RD_WB;
                    end
                end

                // ── Wait for write data ────────────────────────────────
                WR_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        cap_wb_wdata <= s_axi_wdata[7:0];
                        state        <= WR_WB;
                    end
                end

                // ── Wishbone write cycle ───────────────────────────────
                WR_WB: begin
                    s_axi_wready <= 1'b0;
                    wb_cyc_o     <= 1'b1;
                    wb_stb_o     <= 1'b1;
                    wb_we_o      <= 1'b1;
                    wb_adr_o     <= cap_wb_addr;
                    wb_dat_o     <= cap_wb_wdata;
                    if (wb_ack_i) begin
                        wb_stb_o     <= 1'b0;
                        wb_cyc_o     <= 1'b0;
                        wb_we_o      <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                        s_axi_bid    <= cap_id;
                        state        <= WR_RESP;
                    end
                end

                // ── Hold bvalid until bready ───────────────────────────
                // bvalid was asserted the previous cycle; we stay here
                // until the master acknowledges (bready=1 while bvalid=1).
                WR_RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= IDLE;
                    end
                end

                // ── Wishbone read cycle ────────────────────────────────
                RD_WB: begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o  <= 1'b0;
                    wb_adr_o <= cap_wb_addr;
                    if (wb_ack_i) begin
                        wb_stb_o     <= 1'b0;
                        wb_cyc_o     <= 1'b0;
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= {{(DATA_WIDTH-8){1'b0}}, wb_dat_i};
                        s_axi_rresp  <= 2'b00;
                        s_axi_rid    <= cap_id;
                        s_axi_rlast  <= 1'b1;
                        state        <= RD_RESP;
                    end
                end

                // ── Hold rvalid until rready ───────────────────────────
                RD_RESP: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        state        <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
