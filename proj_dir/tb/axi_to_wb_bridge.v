/*
 * axi_to_wb_bridge.v
 *
 * AXI4-Lite Slave  →  Wishbone (B2) Master bridge
 * ─────────────────────────────────────────────────
 * Translates single-beat AXI4-Lite write/read transactions into
 * Wishbone cycles for the i2c_master_top (8-bit data, 3-bit address).
 *
 * AXI data bus  : 32-bit (only byte-0, bits [7:0], is forwarded to WB)
 * AXI address   : 32-bit (bits [4:2] are forwarded as wb_adr_i[2:0])
 * WB data bus   : 8-bit
 * WB address    : 3-bit
 *
 * The bridge handles one transaction at a time (no pipelining).
 */

`timescale 1ns/1ps
`default_nettype none

module axi_to_wb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                  clk,
    input  wire                  rst,        // active-high synchronous reset

    // ── AXI4-Lite Slave (from interconnect m00 port) ──────────────────
    // Write address channel
    input  wire [ID_WIDTH-1:0]   s_axi_awid,
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [7:0]            s_axi_awlen,
    input  wire [2:0]            s_axi_awsize,
    input  wire [1:0]            s_axi_awburst,
    input  wire                  s_axi_awlock,
    input  wire [3:0]            s_axi_awcache,
    input  wire [2:0]            s_axi_awprot,
    input  wire [3:0]            s_axi_awqos,
    input  wire [3:0]            s_axi_awregion,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,
    // Write data channel
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                  s_axi_wlast,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,
    // Write response channel
    output reg  [ID_WIDTH-1:0]   s_axi_bid,
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,
    // Read address channel
    input  wire [ID_WIDTH-1:0]   s_axi_arid,
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [7:0]            s_axi_arlen,
    input  wire [2:0]            s_axi_arsize,
    input  wire [1:0]            s_axi_arburst,
    input  wire                  s_axi_arlock,
    input  wire [3:0]            s_axi_arcache,
    input  wire [2:0]            s_axi_arprot,
    input  wire [3:0]            s_axi_arqos,
    input  wire [3:0]            s_axi_arregion,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,
    // Read data channel
    output reg  [ID_WIDTH-1:0]   s_axi_rid,
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rlast,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // ── Wishbone Master (to i2c_master_top) ───────────────────────────
    output reg  [2:0]            wb_adr_o,
    output reg  [7:0]            wb_dat_o,
    input  wire [7:0]            wb_dat_i,
    output reg                   wb_we_o,
    output reg                   wb_stb_o,
    output reg                   wb_cyc_o,
    input  wire                  wb_ack_i
);

    // ── FSM states ────────────────────────────────────────────────────
    localparam IDLE      = 3'd0,
               WR_DATA   = 3'd1,   // wait for wvalid if not yet arrived
               WR_WB     = 3'd2,   // drive WB write cycle
               WR_RESP   = 3'd3,   // send AXI B-channel response
               RD_WB     = 3'd4,   // drive WB read cycle
               RD_RESP   = 3'd5;   // send AXI R-channel response

    reg [2:0] state;

    // Captured transaction fields
    reg [ID_WIDTH-1:0]   cap_id;
    reg [2:0]            cap_wb_addr;   // bits [4:2] of AXI address
    reg [7:0]            cap_wb_wdata;  // byte 0 of AXI wdata
    reg [7:0]            cap_wb_rdata;

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
            // Default de-assertions
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_arready <= 1'b0;

            case (state)

                // ── Wait for either a write or read address ────────────
                IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_rvalid <= 1'b0;
                    wb_stb_o     <= 1'b0;
                    wb_cyc_o     <= 1'b0;

                    if (s_axi_awvalid) begin
                        // Accept write address
                        s_axi_awready <= 1'b1;
                        cap_id        <= s_axi_awid;
                        cap_wb_addr   <= s_axi_awaddr[4:2];
                        // If write data already here, capture it too
                        if (s_axi_wvalid) begin
                            s_axi_wready  <= 1'b1;
                            cap_wb_wdata  <= s_axi_wdata[7:0];
                            state         <= WR_WB;
                        end else begin
                            state         <= WR_DATA;
                        end
                    end else if (s_axi_arvalid) begin
                        // Accept read address
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

                // ── Drive Wishbone write cycle ─────────────────────────
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
                        s_axi_bresp  <= 2'b00;   // OKAY
                        s_axi_bid    <= cap_id;
                        state        <= WR_RESP;
                    end
                end

                // ── Wait for AXI master to accept B-channel ───────────
                WR_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= IDLE;
                    end
                end

                // ── Drive Wishbone read cycle ──────────────────────────
                RD_WB: begin
                    s_axi_arready <= 1'b0;
                    wb_cyc_o      <= 1'b1;
                    wb_stb_o      <= 1'b1;
                    wb_we_o       <= 1'b0;
                    wb_adr_o      <= cap_wb_addr;
                    if (wb_ack_i) begin
                        cap_wb_rdata <= wb_dat_i;
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

                // ── Wait for AXI master to accept R-channel ───────────
                RD_RESP: begin
                    if (s_axi_rready) begin
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
