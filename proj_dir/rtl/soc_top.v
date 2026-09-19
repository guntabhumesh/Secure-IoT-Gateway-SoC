// =============================================================================
// soc_top.v
//
// Secure IoT Gateway SoC Top-Level
//
// Address map (each window = 2^24 = 16 MB):
//   m00  0x0000_0000  axi_to_wb_bridge → i2c_master_top
//   m01  0x0100_0000  axi_aes_slave    → aes_cipher_top + aes_inv_cipher_top
//   m02  0x0200_0000  axi_uart_slave   → axi_uart_top (AXI4-Lite UART)
//   m03  0x0300_0000  dummy_axi_slave
//   m04  0x0400_0000  dummy_axi_slave
//   m05  0x0500_0000  dummy_axi_slave
//   m06  0x0600_0000  dummy_axi_slave
//   m07  0x0700_0000  dummy_axi_slave
//   m08  0x0800_0000  dummy_axi_slave
//   m09  0x0900_0000  dummy_axi_slave
//   m10  0x0A00_0000  dummy_axi_slave
//
// Two AXI master ports (s00, s01) — s01 exposed to top-level for a second CPU.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module soc_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire        clk,
    input  wire        rst_n,   // active-low system reset

    // ── AXI master port 0 (primary CPU) ──────────────────────────────
    input  wire [ID_WIDTH-1:0]    s00_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s00_axi_awaddr,
    input  wire [7:0]             s00_axi_awlen,
    input  wire [2:0]             s00_axi_awsize,
    input  wire [1:0]             s00_axi_awburst,
    input  wire                   s00_axi_awlock,
    input  wire [3:0]             s00_axi_awcache,
    input  wire [2:0]             s00_axi_awprot,
    input  wire [3:0]             s00_axi_awqos,
    input  wire                   s00_axi_awvalid,
    output wire                   s00_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s00_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s00_axi_wstrb,
    input  wire                   s00_axi_wlast,
    input  wire                   s00_axi_wvalid,
    output wire                   s00_axi_wready,
    output wire [ID_WIDTH-1:0]    s00_axi_bid,
    output wire [1:0]             s00_axi_bresp,
    output wire                   s00_axi_bvalid,
    input  wire                   s00_axi_bready,
    input  wire [ID_WIDTH-1:0]    s00_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s00_axi_araddr,
    input  wire [7:0]             s00_axi_arlen,
    input  wire [2:0]             s00_axi_arsize,
    input  wire [1:0]             s00_axi_arburst,
    input  wire                   s00_axi_arlock,
    input  wire [3:0]             s00_axi_arcache,
    input  wire [2:0]             s00_axi_arprot,
    input  wire [3:0]             s00_axi_arqos,
    input  wire                   s00_axi_arvalid,
    output wire                   s00_axi_arready,
    output wire [ID_WIDTH-1:0]    s00_axi_rid,
    output wire [DATA_WIDTH-1:0]  s00_axi_rdata,
    output wire [1:0]             s00_axi_rresp,
    output wire                   s00_axi_rlast,
    output wire                   s00_axi_rvalid,
    input  wire                   s00_axi_rready,

    // ── AXI master port 1 (secondary CPU / DMA) ───────────────────────
    input  wire [ID_WIDTH-1:0]    s01_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s01_axi_awaddr,
    input  wire [7:0]             s01_axi_awlen,
    input  wire [2:0]             s01_axi_awsize,
    input  wire [1:0]             s01_axi_awburst,
    input  wire                   s01_axi_awlock,
    input  wire [3:0]             s01_axi_awcache,
    input  wire [2:0]             s01_axi_awprot,
    input  wire [3:0]             s01_axi_awqos,
    input  wire                   s01_axi_awvalid,
    output wire                   s01_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s01_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s01_axi_wstrb,
    input  wire                   s01_axi_wlast,
    input  wire                   s01_axi_wvalid,
    output wire                   s01_axi_wready,
    output wire [ID_WIDTH-1:0]    s01_axi_bid,
    output wire [1:0]             s01_axi_bresp,
    output wire                   s01_axi_bvalid,
    input  wire                   s01_axi_bready,
    input  wire [ID_WIDTH-1:0]    s01_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s01_axi_araddr,
    input  wire [7:0]             s01_axi_arlen,
    input  wire [2:0]             s01_axi_arsize,
    input  wire [1:0]             s01_axi_arburst,
    input  wire                   s01_axi_arlock,
    input  wire [3:0]             s01_axi_arcache,
    input  wire [2:0]             s01_axi_arprot,
    input  wire [3:0]             s01_axi_arqos,
    input  wire                   s01_axi_arvalid,
    output wire                   s01_axi_arready,
    output wire [ID_WIDTH-1:0]    s01_axi_rid,
    output wire [DATA_WIDTH-1:0]  s01_axi_rdata,
    output wire [1:0]             s01_axi_rresp,
    output wire                   s01_axi_rlast,
    output wire                   s01_axi_rvalid,
    input  wire                   s01_axi_rready,

    // ── I2C pads ──────────────────────────────────────────────────────
    input  wire        scl_pad_i,
    output wire        scl_pad_o,
    output wire        scl_padoen_o,
    input  wire        sda_pad_i,
    output wire        sda_pad_o,
    output wire        sda_padoen_o,

    // ── Interrupt (from I2C) ──────────────────────────────────────────
    output wire        i2c_irq,

    // ── UART external signals ─────────────────────────────────────────
    output wire        uart_tx_o,
    input  wire        uart_rx_i,
    output wire        uart_irq
);

    // Active-high reset for logic that needs it
    wire rst = ~rst_n;

    // ══════════════════════════════════════════════════════════════════
    // Internal AXI buses (interconnect master ports → slave modules)
    // ══════════════════════════════════════════════════════════════════
    localparam STRB_WIDTH = DATA_WIDTH/8;

    // ── m00 (I2C bridge) ──────────────────────────────────────────────
    wire [ID_WIDTH-1:0]   m00_awid;   wire [ADDR_WIDTH-1:0] m00_awaddr;
    wire [7:0] m00_awlen;             wire [2:0] m00_awsize;
    wire [1:0] m00_awburst;           wire m00_awlock;
    wire [3:0] m00_awcache;           wire [2:0] m00_awprot;
    wire [3:0] m00_awqos;             wire [3:0] m00_awregion;
    wire [0:0] m00_awuser;            wire m00_awvalid; wire m00_awready;
    wire [DATA_WIDTH-1:0] m00_wdata;  wire [STRB_WIDTH-1:0] m00_wstrb;
    wire m00_wlast; wire [0:0] m00_wuser; wire m00_wvalid; wire m00_wready;
    wire [ID_WIDTH-1:0] m00_bid;      wire [1:0] m00_bresp;
    wire [0:0] m00_buser;             wire m00_bvalid; wire m00_bready;
    wire [ID_WIDTH-1:0] m00_arid;     wire [ADDR_WIDTH-1:0] m00_araddr;
    wire [7:0] m00_arlen;             wire [2:0] m00_arsize;
    wire [1:0] m00_arburst;           wire m00_arlock;
    wire [3:0] m00_arcache;           wire [2:0] m00_arprot;
    wire [3:0] m00_arqos;             wire [3:0] m00_arregion;
    wire [0:0] m00_aruser;            wire m00_arvalid; wire m00_arready;
    wire [ID_WIDTH-1:0] m00_rid;      wire [DATA_WIDTH-1:0] m00_rdata;
    wire [1:0] m00_rresp;             wire m00_rlast;
    wire [0:0] m00_ruser;             wire m00_rvalid; wire m00_rready;

    // ── m01 (AES slave) ───────────────────────────────────────────────
    wire [ID_WIDTH-1:0]   m01_awid;   wire [ADDR_WIDTH-1:0] m01_awaddr;
    wire [7:0] m01_awlen;             wire [2:0] m01_awsize;
    wire [1:0] m01_awburst;           wire m01_awlock;
    wire [3:0] m01_awcache;           wire [2:0] m01_awprot;
    wire [3:0] m01_awqos;             wire [3:0] m01_awregion;
    wire [0:0] m01_awuser;            wire m01_awvalid; wire m01_awready;
    wire [DATA_WIDTH-1:0] m01_wdata;  wire [STRB_WIDTH-1:0] m01_wstrb;
    wire m01_wlast; wire [0:0] m01_wuser; wire m01_wvalid; wire m01_wready;
    wire [ID_WIDTH-1:0] m01_bid;      wire [1:0] m01_bresp;
    wire [0:0] m01_buser;             wire m01_bvalid; wire m01_bready;
    wire [ID_WIDTH-1:0] m01_arid;     wire [ADDR_WIDTH-1:0] m01_araddr;
    wire [7:0] m01_arlen;             wire [2:0] m01_arsize;
    wire [1:0] m01_arburst;           wire m01_arlock;
    wire [3:0] m01_arcache;           wire [2:0] m01_arprot;
    wire [3:0] m01_arqos;             wire [3:0] m01_arregion;
    wire [0:0] m01_aruser;            wire m01_arvalid; wire m01_arready;
    wire [ID_WIDTH-1:0] m01_rid;      wire [DATA_WIDTH-1:0] m01_rdata;
    wire [1:0] m01_rresp;             wire m01_rlast;
    wire [0:0] m01_ruser;             wire m01_rvalid; wire m01_rready;

    // ── m02 (UART slave) ──────────────────────────────────────────────
    wire [ID_WIDTH-1:0]   m02_awid;   wire [ADDR_WIDTH-1:0] m02_awaddr;
    wire [7:0] m02_awlen;             wire [2:0] m02_awsize;
    wire [1:0] m02_awburst;           wire m02_awlock;
    wire [3:0] m02_awcache;           wire [2:0] m02_awprot;
    wire [3:0] m02_awqos;             wire [3:0] m02_awregion;
    wire [0:0] m02_awuser;            wire m02_awvalid; wire m02_awready;
    wire [DATA_WIDTH-1:0] m02_wdata;  wire [STRB_WIDTH-1:0] m02_wstrb;
    wire m02_wlast; wire [0:0] m02_wuser; wire m02_wvalid; wire m02_wready;
    wire [ID_WIDTH-1:0] m02_bid;      wire [1:0] m02_bresp;
    wire [0:0] m02_buser;             wire m02_bvalid; wire m02_bready;
    wire [ID_WIDTH-1:0] m02_arid;     wire [ADDR_WIDTH-1:0] m02_araddr;
    wire [7:0] m02_arlen;             wire [2:0] m02_arsize;
    wire [1:0] m02_arburst;           wire m02_arlock;
    wire [3:0] m02_arcache;           wire [2:0] m02_arprot;
    wire [3:0] m02_arqos;             wire [3:0] m02_arregion;
    wire [0:0] m02_aruser;            wire m02_arvalid; wire m02_arready;
    wire [ID_WIDTH-1:0] m02_rid;      wire [DATA_WIDTH-1:0] m02_rdata;
    wire [1:0] m02_rresp;             wire m02_rlast;
    wire [0:0] m02_ruser;             wire m02_rvalid; wire m02_rready;

    // ── m03-m10 dummy slaves (macro to declare wires) ─────────────────
`define MXX_WIRES(N) \
    wire [ID_WIDTH-1:0]   m``N``_awid;   wire [ADDR_WIDTH-1:0] m``N``_awaddr;  \
    wire [7:0] m``N``_awlen;             wire [2:0] m``N``_awsize;              \
    wire [1:0] m``N``_awburst;           wire m``N``_awlock;                    \
    wire [3:0] m``N``_awcache;           wire [2:0] m``N``_awprot;             \
    wire [3:0] m``N``_awqos;             wire [3:0] m``N``_awregion;           \
    wire [0:0] m``N``_awuser;            wire m``N``_awvalid; wire m``N``_awready; \
    wire [DATA_WIDTH-1:0] m``N``_wdata;  wire [STRB_WIDTH-1:0] m``N``_wstrb;   \
    wire m``N``_wlast; wire [0:0] m``N``_wuser; wire m``N``_wvalid; wire m``N``_wready; \
    wire [ID_WIDTH-1:0] m``N``_bid;      wire [1:0] m``N``_bresp;              \
    wire [0:0] m``N``_buser;             wire m``N``_bvalid;  wire m``N``_bready; \
    wire [ID_WIDTH-1:0] m``N``_arid;     wire [ADDR_WIDTH-1:0] m``N``_araddr;  \
    wire [7:0] m``N``_arlen;             wire [2:0] m``N``_arsize;              \
    wire [1:0] m``N``_arburst;           wire m``N``_arlock;                    \
    wire [3:0] m``N``_arcache;           wire [2:0] m``N``_arprot;             \
    wire [3:0] m``N``_arqos;             wire [3:0] m``N``_arregion;           \
    wire [0:0] m``N``_aruser;            wire m``N``_arvalid; wire m``N``_arready; \
    wire [ID_WIDTH-1:0] m``N``_rid;      wire [DATA_WIDTH-1:0] m``N``_rdata;   \
    wire [1:0] m``N``_rresp;             wire m``N``_rlast;                     \
    wire [0:0] m``N``_ruser;             wire m``N``_rvalid;  wire m``N``_rready;

`MXX_WIRES(03) `MXX_WIRES(04) `MXX_WIRES(05)
`MXX_WIRES(06) `MXX_WIRES(07) `MXX_WIRES(08) `MXX_WIRES(09)
`MXX_WIRES(10)

    // ── Wishbone bus (bridge ↔ I2C master) ───────────────────────────
    wire [2:0] wb_adr;
    wire [7:0] wb_dat_m2s;  // master→slave (bridge writes)
    wire [7:0] wb_dat_s2m;  // slave→master (i2c reads)
    wire       wb_we, wb_stb, wb_cyc, wb_ack;

    // ══════════════════════════════════════════════════════════════════
    // AXI Interconnect
    // ══════════════════════════════════════════════════════════════════
    axi_interconnect_wrap_2x11 #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .ID_WIDTH    (ID_WIDTH),
        .M00_BASE_ADDR (32'h0000_0000), .M00_ADDR_WIDTH ({1{32'd24}}),
        .M01_BASE_ADDR (32'h0100_0000), .M01_ADDR_WIDTH ({1{32'd24}}),
        .M02_BASE_ADDR (32'h0200_0000), .M02_ADDR_WIDTH ({1{32'd24}}),
        .M03_BASE_ADDR (32'h0300_0000), .M03_ADDR_WIDTH ({1{32'd24}}),
        .M04_BASE_ADDR (32'h0400_0000), .M04_ADDR_WIDTH ({1{32'd24}}),
        .M05_BASE_ADDR (32'h0500_0000), .M05_ADDR_WIDTH ({1{32'd24}}),
        .M06_BASE_ADDR (32'h0600_0000), .M06_ADDR_WIDTH ({1{32'd24}}),
        .M07_BASE_ADDR (32'h0700_0000), .M07_ADDR_WIDTH ({1{32'd24}}),
        .M08_BASE_ADDR (32'h0800_0000), .M08_ADDR_WIDTH ({1{32'd24}}),
        .M09_BASE_ADDR (32'h0900_0000), .M09_ADDR_WIDTH ({1{32'd24}}),
        .M10_BASE_ADDR (32'h0A00_0000), .M10_ADDR_WIDTH ({1{32'd24}})
    ) u_ic (
        .clk  (clk), .rst (rst),
        // s00
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos), .s00_axi_awuser(1'b0),
        .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wlast(s00_axi_wlast), .s00_axi_wuser(1'b0),
        .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos), .s00_axi_aruser(1'b0),
        .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid), .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp), .s00_axi_rlast(s00_axi_rlast),
        .s00_axi_rvalid(s00_axi_rvalid), .s00_axi_rready(s00_axi_rready),
        // s01
        .s01_axi_awid(s01_axi_awid), .s01_axi_awaddr(s01_axi_awaddr),
        .s01_axi_awlen(s01_axi_awlen), .s01_axi_awsize(s01_axi_awsize),
        .s01_axi_awburst(s01_axi_awburst), .s01_axi_awlock(s01_axi_awlock),
        .s01_axi_awcache(s01_axi_awcache), .s01_axi_awprot(s01_axi_awprot),
        .s01_axi_awqos(s01_axi_awqos), .s01_axi_awuser(1'b0),
        .s01_axi_awvalid(s01_axi_awvalid), .s01_axi_awready(s01_axi_awready),
        .s01_axi_wdata(s01_axi_wdata), .s01_axi_wstrb(s01_axi_wstrb),
        .s01_axi_wlast(s01_axi_wlast), .s01_axi_wuser(1'b0),
        .s01_axi_wvalid(s01_axi_wvalid), .s01_axi_wready(s01_axi_wready),
        .s01_axi_bid(s01_axi_bid), .s01_axi_bresp(s01_axi_bresp),
        .s01_axi_bvalid(s01_axi_bvalid), .s01_axi_bready(s01_axi_bready),
        .s01_axi_arid(s01_axi_arid), .s01_axi_araddr(s01_axi_araddr),
        .s01_axi_arlen(s01_axi_arlen), .s01_axi_arsize(s01_axi_arsize),
        .s01_axi_arburst(s01_axi_arburst), .s01_axi_arlock(s01_axi_arlock),
        .s01_axi_arcache(s01_axi_arcache), .s01_axi_arprot(s01_axi_arprot),
        .s01_axi_arqos(s01_axi_arqos), .s01_axi_aruser(1'b0),
        .s01_axi_arvalid(s01_axi_arvalid), .s01_axi_arready(s01_axi_arready),
        .s01_axi_rid(s01_axi_rid), .s01_axi_rdata(s01_axi_rdata),
        .s01_axi_rresp(s01_axi_rresp), .s01_axi_rlast(s01_axi_rlast),
        .s01_axi_rvalid(s01_axi_rvalid), .s01_axi_rready(s01_axi_rready),
        // m00
        .m00_axi_awid(m00_awid), .m00_axi_awaddr(m00_awaddr),
        .m00_axi_awlen(m00_awlen), .m00_axi_awsize(m00_awsize),
        .m00_axi_awburst(m00_awburst), .m00_axi_awlock(m00_awlock),
        .m00_axi_awcache(m00_awcache), .m00_axi_awprot(m00_awprot),
        .m00_axi_awqos(m00_awqos), .m00_axi_awregion(m00_awregion),
        .m00_axi_awuser(m00_awuser), .m00_axi_awvalid(m00_awvalid), .m00_axi_awready(m00_awready),
        .m00_axi_wdata(m00_wdata), .m00_axi_wstrb(m00_wstrb),
        .m00_axi_wlast(m00_wlast), .m00_axi_wuser(m00_wuser),
        .m00_axi_wvalid(m00_wvalid), .m00_axi_wready(m00_wready),
        .m00_axi_bid(m00_bid), .m00_axi_bresp(m00_bresp), .m00_axi_buser(m00_buser),
        .m00_axi_bvalid(m00_bvalid), .m00_axi_bready(m00_bready),
        .m00_axi_arid(m00_arid), .m00_axi_araddr(m00_araddr),
        .m00_axi_arlen(m00_arlen), .m00_axi_arsize(m00_arsize),
        .m00_axi_arburst(m00_arburst), .m00_axi_arlock(m00_arlock),
        .m00_axi_arcache(m00_arcache), .m00_axi_arprot(m00_arprot),
        .m00_axi_arqos(m00_arqos), .m00_axi_arregion(m00_arregion),
        .m00_axi_aruser(m00_aruser), .m00_axi_arvalid(m00_arvalid), .m00_axi_arready(m00_arready),
        .m00_axi_rid(m00_rid), .m00_axi_rdata(m00_rdata), .m00_axi_rresp(m00_rresp),
        .m00_axi_rlast(m00_rlast), .m00_axi_ruser(m00_ruser),
        .m00_axi_rvalid(m00_rvalid), .m00_axi_rready(m00_rready),
        // m01
        .m01_axi_awid(m01_awid), .m01_axi_awaddr(m01_awaddr),
        .m01_axi_awlen(m01_awlen), .m01_axi_awsize(m01_awsize),
        .m01_axi_awburst(m01_awburst), .m01_axi_awlock(m01_awlock),
        .m01_axi_awcache(m01_awcache), .m01_axi_awprot(m01_awprot),
        .m01_axi_awqos(m01_awqos), .m01_axi_awregion(m01_awregion),
        .m01_axi_awuser(m01_awuser), .m01_axi_awvalid(m01_awvalid), .m01_axi_awready(m01_awready),
        .m01_axi_wdata(m01_wdata), .m01_axi_wstrb(m01_wstrb),
        .m01_axi_wlast(m01_wlast), .m01_axi_wuser(m01_wuser),
        .m01_axi_wvalid(m01_wvalid), .m01_axi_wready(m01_wready),
        .m01_axi_bid(m01_bid), .m01_axi_bresp(m01_bresp), .m01_axi_buser(m01_buser),
        .m01_axi_bvalid(m01_bvalid), .m01_axi_bready(m01_bready),
        .m01_axi_arid(m01_arid), .m01_axi_araddr(m01_araddr),
        .m01_axi_arlen(m01_arlen), .m01_axi_arsize(m01_arsize),
        .m01_axi_arburst(m01_arburst), .m01_axi_arlock(m01_arlock),
        .m01_axi_arcache(m01_arcache), .m01_axi_arprot(m01_arprot),
        .m01_axi_arqos(m01_arqos), .m01_axi_arregion(m01_arregion),
        .m01_axi_aruser(m01_aruser), .m01_axi_arvalid(m01_arvalid), .m01_axi_arready(m01_arready),
        .m01_axi_rid(m01_rid), .m01_axi_rdata(m01_rdata), .m01_axi_rresp(m01_rresp),
        .m01_axi_rlast(m01_rlast), .m01_axi_ruser(m01_ruser),
        .m01_axi_rvalid(m01_rvalid), .m01_axi_rready(m01_rready),
        // m02 (UART)
        .m02_axi_awid(m02_awid),.m02_axi_awaddr(m02_awaddr),.m02_axi_awlen(m02_awlen),
        .m02_axi_awsize(m02_awsize),.m02_axi_awburst(m02_awburst),.m02_axi_awlock(m02_awlock),
        .m02_axi_awcache(m02_awcache),.m02_axi_awprot(m02_awprot),.m02_axi_awqos(m02_awqos),
        .m02_axi_awregion(m02_awregion),.m02_axi_awuser(m02_awuser),
        .m02_axi_awvalid(m02_awvalid),.m02_axi_awready(m02_awready),
        .m02_axi_wdata(m02_wdata),.m02_axi_wstrb(m02_wstrb),.m02_axi_wlast(m02_wlast),
        .m02_axi_wuser(m02_wuser),.m02_axi_wvalid(m02_wvalid),.m02_axi_wready(m02_wready),
        .m02_axi_bid(m02_bid),.m02_axi_bresp(m02_bresp),.m02_axi_buser(m02_buser),
        .m02_axi_bvalid(m02_bvalid),.m02_axi_bready(m02_bready),
        .m02_axi_arid(m02_arid),.m02_axi_araddr(m02_araddr),.m02_axi_arlen(m02_arlen),
        .m02_axi_arsize(m02_arsize),.m02_axi_arburst(m02_arburst),.m02_axi_arlock(m02_arlock),
        .m02_axi_arcache(m02_arcache),.m02_axi_arprot(m02_arprot),.m02_axi_arqos(m02_arqos),
        .m02_axi_arregion(m02_arregion),.m02_axi_aruser(m02_aruser),
        .m02_axi_arvalid(m02_arvalid),.m02_axi_arready(m02_arready),
        .m02_axi_rid(m02_rid),.m02_axi_rdata(m02_rdata),.m02_axi_rresp(m02_rresp),
        .m02_axi_rlast(m02_rlast),.m02_axi_ruser(m02_ruser),
        .m02_axi_rvalid(m02_rvalid),.m02_axi_rready(m02_rready),
        // m03-m10 (dummy slaves)
        .m03_axi_awid(m03_awid),.m03_axi_awaddr(m03_awaddr),.m03_axi_awlen(m03_awlen),
        .m03_axi_awsize(m03_awsize),.m03_axi_awburst(m03_awburst),.m03_axi_awlock(m03_awlock),
        .m03_axi_awcache(m03_awcache),.m03_axi_awprot(m03_awprot),.m03_axi_awqos(m03_awqos),
        .m03_axi_awregion(m03_awregion),.m03_axi_awuser(m03_awuser),
        .m03_axi_awvalid(m03_awvalid),.m03_axi_awready(m03_awready),
        .m03_axi_wdata(m03_wdata),.m03_axi_wstrb(m03_wstrb),.m03_axi_wlast(m03_wlast),
        .m03_axi_wuser(m03_wuser),.m03_axi_wvalid(m03_wvalid),.m03_axi_wready(m03_wready),
        .m03_axi_bid(m03_bid),.m03_axi_bresp(m03_bresp),.m03_axi_buser(m03_buser),
        .m03_axi_bvalid(m03_bvalid),.m03_axi_bready(m03_bready),
        .m03_axi_arid(m03_arid),.m03_axi_araddr(m03_araddr),.m03_axi_arlen(m03_arlen),
        .m03_axi_arsize(m03_arsize),.m03_axi_arburst(m03_arburst),.m03_axi_arlock(m03_arlock),
        .m03_axi_arcache(m03_arcache),.m03_axi_arprot(m03_arprot),.m03_axi_arqos(m03_arqos),
        .m03_axi_arregion(m03_arregion),.m03_axi_aruser(m03_aruser),
        .m03_axi_arvalid(m03_arvalid),.m03_axi_arready(m03_arready),
        .m03_axi_rid(m03_rid),.m03_axi_rdata(m03_rdata),.m03_axi_rresp(m03_rresp),
        .m03_axi_rlast(m03_rlast),.m03_axi_ruser(m03_ruser),
        .m03_axi_rvalid(m03_rvalid),.m03_axi_rready(m03_rready),
        .m04_axi_awid(m04_awid),.m04_axi_awaddr(m04_awaddr),.m04_axi_awlen(m04_awlen),
        .m04_axi_awsize(m04_awsize),.m04_axi_awburst(m04_awburst),.m04_axi_awlock(m04_awlock),
        .m04_axi_awcache(m04_awcache),.m04_axi_awprot(m04_awprot),.m04_axi_awqos(m04_awqos),
        .m04_axi_awregion(m04_awregion),.m04_axi_awuser(m04_awuser),
        .m04_axi_awvalid(m04_awvalid),.m04_axi_awready(m04_awready),
        .m04_axi_wdata(m04_wdata),.m04_axi_wstrb(m04_wstrb),.m04_axi_wlast(m04_wlast),
        .m04_axi_wuser(m04_wuser),.m04_axi_wvalid(m04_wvalid),.m04_axi_wready(m04_wready),
        .m04_axi_bid(m04_bid),.m04_axi_bresp(m04_bresp),.m04_axi_buser(m04_buser),
        .m04_axi_bvalid(m04_bvalid),.m04_axi_bready(m04_bready),
        .m04_axi_arid(m04_arid),.m04_axi_araddr(m04_araddr),.m04_axi_arlen(m04_arlen),
        .m04_axi_arsize(m04_arsize),.m04_axi_arburst(m04_arburst),.m04_axi_arlock(m04_arlock),
        .m04_axi_arcache(m04_arcache),.m04_axi_arprot(m04_arprot),.m04_axi_arqos(m04_arqos),
        .m04_axi_arregion(m04_arregion),.m04_axi_aruser(m04_aruser),
        .m04_axi_arvalid(m04_arvalid),.m04_axi_arready(m04_arready),
        .m04_axi_rid(m04_rid),.m04_axi_rdata(m04_rdata),.m04_axi_rresp(m04_rresp),
        .m04_axi_rlast(m04_rlast),.m04_axi_ruser(m04_ruser),
        .m04_axi_rvalid(m04_rvalid),.m04_axi_rready(m04_rready),
        .m05_axi_awid(m05_awid),.m05_axi_awaddr(m05_awaddr),.m05_axi_awlen(m05_awlen),
        .m05_axi_awsize(m05_awsize),.m05_axi_awburst(m05_awburst),.m05_axi_awlock(m05_awlock),
        .m05_axi_awcache(m05_awcache),.m05_axi_awprot(m05_awprot),.m05_axi_awqos(m05_awqos),
        .m05_axi_awregion(m05_awregion),.m05_axi_awuser(m05_awuser),
        .m05_axi_awvalid(m05_awvalid),.m05_axi_awready(m05_awready),
        .m05_axi_wdata(m05_wdata),.m05_axi_wstrb(m05_wstrb),.m05_axi_wlast(m05_wlast),
        .m05_axi_wuser(m05_wuser),.m05_axi_wvalid(m05_wvalid),.m05_axi_wready(m05_wready),
        .m05_axi_bid(m05_bid),.m05_axi_bresp(m05_bresp),.m05_axi_buser(m05_buser),
        .m05_axi_bvalid(m05_bvalid),.m05_axi_bready(m05_bready),
        .m05_axi_arid(m05_arid),.m05_axi_araddr(m05_araddr),.m05_axi_arlen(m05_arlen),
        .m05_axi_arsize(m05_arsize),.m05_axi_arburst(m05_arburst),.m05_axi_arlock(m05_arlock),
        .m05_axi_arcache(m05_arcache),.m05_axi_arprot(m05_arprot),.m05_axi_arqos(m05_arqos),
        .m05_axi_arregion(m05_arregion),.m05_axi_aruser(m05_aruser),
        .m05_axi_arvalid(m05_arvalid),.m05_axi_arready(m05_arready),
        .m05_axi_rid(m05_rid),.m05_axi_rdata(m05_rdata),.m05_axi_rresp(m05_rresp),
        .m05_axi_rlast(m05_rlast),.m05_axi_ruser(m05_ruser),
        .m05_axi_rvalid(m05_rvalid),.m05_axi_rready(m05_rready),
        .m06_axi_awid(m06_awid),.m06_axi_awaddr(m06_awaddr),.m06_axi_awlen(m06_awlen),
        .m06_axi_awsize(m06_awsize),.m06_axi_awburst(m06_awburst),.m06_axi_awlock(m06_awlock),
        .m06_axi_awcache(m06_awcache),.m06_axi_awprot(m06_awprot),.m06_axi_awqos(m06_awqos),
        .m06_axi_awregion(m06_awregion),.m06_axi_awuser(m06_awuser),
        .m06_axi_awvalid(m06_awvalid),.m06_axi_awready(m06_awready),
        .m06_axi_wdata(m06_wdata),.m06_axi_wstrb(m06_wstrb),.m06_axi_wlast(m06_wlast),
        .m06_axi_wuser(m06_wuser),.m06_axi_wvalid(m06_wvalid),.m06_axi_wready(m06_wready),
        .m06_axi_bid(m06_bid),.m06_axi_bresp(m06_bresp),.m06_axi_buser(m06_buser),
        .m06_axi_bvalid(m06_bvalid),.m06_axi_bready(m06_bready),
        .m06_axi_arid(m06_arid),.m06_axi_araddr(m06_araddr),.m06_axi_arlen(m06_arlen),
        .m06_axi_arsize(m06_arsize),.m06_axi_arburst(m06_arburst),.m06_axi_arlock(m06_arlock),
        .m06_axi_arcache(m06_arcache),.m06_axi_arprot(m06_arprot),.m06_axi_arqos(m06_arqos),
        .m06_axi_arregion(m06_arregion),.m06_axi_aruser(m06_aruser),
        .m06_axi_arvalid(m06_arvalid),.m06_axi_arready(m06_arready),
        .m06_axi_rid(m06_rid),.m06_axi_rdata(m06_rdata),.m06_axi_rresp(m06_rresp),
        .m06_axi_rlast(m06_rlast),.m06_axi_ruser(m06_ruser),
        .m06_axi_rvalid(m06_rvalid),.m06_axi_rready(m06_rready),
        .m07_axi_awid(m07_awid),.m07_axi_awaddr(m07_awaddr),.m07_axi_awlen(m07_awlen),
        .m07_axi_awsize(m07_awsize),.m07_axi_awburst(m07_awburst),.m07_axi_awlock(m07_awlock),
        .m07_axi_awcache(m07_awcache),.m07_axi_awprot(m07_awprot),.m07_axi_awqos(m07_awqos),
        .m07_axi_awregion(m07_awregion),.m07_axi_awuser(m07_awuser),
        .m07_axi_awvalid(m07_awvalid),.m07_axi_awready(m07_awready),
        .m07_axi_wdata(m07_wdata),.m07_axi_wstrb(m07_wstrb),.m07_axi_wlast(m07_wlast),
        .m07_axi_wuser(m07_wuser),.m07_axi_wvalid(m07_wvalid),.m07_axi_wready(m07_wready),
        .m07_axi_bid(m07_bid),.m07_axi_bresp(m07_bresp),.m07_axi_buser(m07_buser),
        .m07_axi_bvalid(m07_bvalid),.m07_axi_bready(m07_bready),
        .m07_axi_arid(m07_arid),.m07_axi_araddr(m07_araddr),.m07_axi_arlen(m07_arlen),
        .m07_axi_arsize(m07_arsize),.m07_axi_arburst(m07_arburst),.m07_axi_arlock(m07_arlock),
        .m07_axi_arcache(m07_arcache),.m07_axi_arprot(m07_arprot),.m07_axi_arqos(m07_arqos),
        .m07_axi_arregion(m07_arregion),.m07_axi_aruser(m07_aruser),
        .m07_axi_arvalid(m07_arvalid),.m07_axi_arready(m07_arready),
        .m07_axi_rid(m07_rid),.m07_axi_rdata(m07_rdata),.m07_axi_rresp(m07_rresp),
        .m07_axi_rlast(m07_rlast),.m07_axi_ruser(m07_ruser),
        .m07_axi_rvalid(m07_rvalid),.m07_axi_rready(m07_rready),
        .m08_axi_awid(m08_awid),.m08_axi_awaddr(m08_awaddr),.m08_axi_awlen(m08_awlen),
        .m08_axi_awsize(m08_awsize),.m08_axi_awburst(m08_awburst),.m08_axi_awlock(m08_awlock),
        .m08_axi_awcache(m08_awcache),.m08_axi_awprot(m08_awprot),.m08_axi_awqos(m08_awqos),
        .m08_axi_awregion(m08_awregion),.m08_axi_awuser(m08_awuser),
        .m08_axi_awvalid(m08_awvalid),.m08_axi_awready(m08_awready),
        .m08_axi_wdata(m08_wdata),.m08_axi_wstrb(m08_wstrb),.m08_axi_wlast(m08_wlast),
        .m08_axi_wuser(m08_wuser),.m08_axi_wvalid(m08_wvalid),.m08_axi_wready(m08_wready),
        .m08_axi_bid(m08_bid),.m08_axi_bresp(m08_bresp),.m08_axi_buser(m08_buser),
        .m08_axi_bvalid(m08_bvalid),.m08_axi_bready(m08_bready),
        .m08_axi_arid(m08_arid),.m08_axi_araddr(m08_araddr),.m08_axi_arlen(m08_arlen),
        .m08_axi_arsize(m08_arsize),.m08_axi_arburst(m08_arburst),.m08_axi_arlock(m08_arlock),
        .m08_axi_arcache(m08_arcache),.m08_axi_arprot(m08_arprot),.m08_axi_arqos(m08_arqos),
        .m08_axi_arregion(m08_arregion),.m08_axi_aruser(m08_aruser),
        .m08_axi_arvalid(m08_arvalid),.m08_axi_arready(m08_arready),
        .m08_axi_rid(m08_rid),.m08_axi_rdata(m08_rdata),.m08_axi_rresp(m08_rresp),
        .m08_axi_rlast(m08_rlast),.m08_axi_ruser(m08_ruser),
        .m08_axi_rvalid(m08_rvalid),.m08_axi_rready(m08_rready),
        .m09_axi_awid(m09_awid),.m09_axi_awaddr(m09_awaddr),.m09_axi_awlen(m09_awlen),
        .m09_axi_awsize(m09_awsize),.m09_axi_awburst(m09_awburst),.m09_axi_awlock(m09_awlock),
        .m09_axi_awcache(m09_awcache),.m09_axi_awprot(m09_awprot),.m09_axi_awqos(m09_awqos),
        .m09_axi_awregion(m09_awregion),.m09_axi_awuser(m09_awuser),
        .m09_axi_awvalid(m09_awvalid),.m09_axi_awready(m09_awready),
        .m09_axi_wdata(m09_wdata),.m09_axi_wstrb(m09_wstrb),.m09_axi_wlast(m09_wlast),
        .m09_axi_wuser(m09_wuser),.m09_axi_wvalid(m09_wvalid),.m09_axi_wready(m09_wready),
        .m09_axi_bid(m09_bid),.m09_axi_bresp(m09_bresp),.m09_axi_buser(m09_buser),
        .m09_axi_bvalid(m09_bvalid),.m09_axi_bready(m09_bready),
        .m09_axi_arid(m09_arid),.m09_axi_araddr(m09_araddr),.m09_axi_arlen(m09_arlen),
        .m09_axi_arsize(m09_arsize),.m09_axi_arburst(m09_arburst),.m09_axi_arlock(m09_arlock),
        .m09_axi_arcache(m09_arcache),.m09_axi_arprot(m09_arprot),.m09_axi_arqos(m09_arqos),
        .m09_axi_arregion(m09_arregion),.m09_axi_aruser(m09_aruser),
        .m09_axi_arvalid(m09_arvalid),.m09_axi_arready(m09_arready),
        .m09_axi_rid(m09_rid),.m09_axi_rdata(m09_rdata),.m09_axi_rresp(m09_rresp),
        .m09_axi_rlast(m09_rlast),.m09_axi_ruser(m09_ruser),
        .m09_axi_rvalid(m09_rvalid),.m09_axi_rready(m09_rready),
        .m10_axi_awid(m10_awid),.m10_axi_awaddr(m10_awaddr),.m10_axi_awlen(m10_awlen),
        .m10_axi_awsize(m10_awsize),.m10_axi_awburst(m10_awburst),.m10_axi_awlock(m10_awlock),
        .m10_axi_awcache(m10_awcache),.m10_axi_awprot(m10_awprot),.m10_axi_awqos(m10_awqos),
        .m10_axi_awregion(m10_awregion),.m10_axi_awuser(m10_awuser),
        .m10_axi_awvalid(m10_awvalid),.m10_axi_awready(m10_awready),
        .m10_axi_wdata(m10_wdata),.m10_axi_wstrb(m10_wstrb),.m10_axi_wlast(m10_wlast),
        .m10_axi_wuser(m10_wuser),.m10_axi_wvalid(m10_wvalid),.m10_axi_wready(m10_wready),
        .m10_axi_bid(m10_bid),.m10_axi_bresp(m10_bresp),.m10_axi_buser(m10_buser),
        .m10_axi_bvalid(m10_bvalid),.m10_axi_bready(m10_bready),
        .m10_axi_arid(m10_arid),.m10_axi_araddr(m10_araddr),.m10_axi_arlen(m10_arlen),
        .m10_axi_arsize(m10_arsize),.m10_axi_arburst(m10_arburst),.m10_axi_arlock(m10_arlock),
        .m10_axi_arcache(m10_arcache),.m10_axi_arprot(m10_arprot),.m10_axi_arqos(m10_arqos),
        .m10_axi_arregion(m10_arregion),.m10_axi_aruser(m10_aruser),
        .m10_axi_arvalid(m10_arvalid),.m10_axi_arready(m10_arready),
        .m10_axi_rid(m10_rid),.m10_axi_rdata(m10_rdata),.m10_axi_rresp(m10_rresp),
        .m10_axi_rlast(m10_rlast),.m10_axi_ruser(m10_ruser),
        .m10_axi_rvalid(m10_rvalid),.m10_axi_rready(m10_rready)
    );

    // ══════════════════════════════════════════════════════════════════
    // m00: AXI-to-Wishbone bridge
    // ══════════════════════════════════════════════════════════════════
    axi_to_wb_bridge #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_wb_bridge (
        .clk             (clk), .rst (rst),
        .s_axi_awid      (m00_awid),    .s_axi_awaddr  (m00_awaddr),
        .s_axi_awlen     (m00_awlen),   .s_axi_awsize  (m00_awsize),
        .s_axi_awburst   (m00_awburst), .s_axi_awlock  (m00_awlock),
        .s_axi_awcache   (m00_awcache), .s_axi_awprot  (m00_awprot),
        .s_axi_awqos     (m00_awqos),   .s_axi_awregion(m00_awregion),
        .s_axi_awvalid   (m00_awvalid), .s_axi_awready (m00_awready),
        .s_axi_wdata     (m00_wdata),   .s_axi_wstrb   (m00_wstrb),
        .s_axi_wlast     (m00_wlast),   .s_axi_wvalid  (m00_wvalid),
        .s_axi_wready    (m00_wready),
        .s_axi_bid       (m00_bid),     .s_axi_bresp   (m00_bresp),
        .s_axi_bvalid    (m00_bvalid),  .s_axi_bready  (m00_bready),
        .s_axi_arid      (m00_arid),    .s_axi_araddr  (m00_araddr),
        .s_axi_arlen     (m00_arlen),   .s_axi_arsize  (m00_arsize),
        .s_axi_arburst   (m00_arburst), .s_axi_arlock  (m00_arlock),
        .s_axi_arcache   (m00_arcache), .s_axi_arprot  (m00_arprot),
        .s_axi_arqos     (m00_arqos),   .s_axi_arregion(m00_arregion),
        .s_axi_arvalid   (m00_arvalid), .s_axi_arready (m00_arready),
        .s_axi_rid       (m00_rid),     .s_axi_rdata   (m00_rdata),
        .s_axi_rresp     (m00_rresp),   .s_axi_rlast   (m00_rlast),
        .s_axi_rvalid    (m00_rvalid),  .s_axi_rready  (m00_rready),
        .wb_adr_o        (wb_adr),
        .wb_dat_o        (wb_dat_m2s),
        .wb_dat_i        (wb_dat_s2m),
        .wb_we_o         (wb_we),
        .wb_stb_o        (wb_stb),
        .wb_cyc_o        (wb_cyc),
        .wb_ack_i        (wb_ack)
    );

    // ── I2C master (Wishbone slave) ───────────────────────────────────
    i2c_master_top u_i2c (
        .wb_clk_i     (clk),
        .wb_rst_i     (rst),
        .arst_i       (rst),
        .wb_adr_i     (wb_adr),
        .wb_dat_i     (wb_dat_m2s),
        .wb_dat_o     (wb_dat_s2m),
        .wb_we_i      (wb_we),
        .wb_stb_i     (wb_stb),
        .wb_cyc_i     (wb_cyc),
        .wb_ack_o     (wb_ack),
        .wb_inta_o    (i2c_irq),
        .scl_pad_i    (scl_pad_i),
        .scl_pad_o    (scl_pad_o),
        .scl_padoen_o (scl_padoen_o),
        .sda_pad_i    (sda_pad_i),
        .sda_pad_o    (sda_pad_o),
        .sda_padoen_o (sda_padoen_o)
    );

    // ══════════════════════════════════════════════════════════════════
    // m01: AXI AES slave
    // ══════════════════════════════════════════════════════════════════
    axi_aes_slave #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_aes (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awid    (m01_awid),    .s_axi_awaddr  (m01_awaddr),
        .s_axi_awlen   (m01_awlen),   .s_axi_awsize  (m01_awsize),
        .s_axi_awburst (m01_awburst), .s_axi_awlock  (m01_awlock),
        .s_axi_awcache (m01_awcache), .s_axi_awprot  (m01_awprot),
        .s_axi_awqos   (m01_awqos),   .s_axi_awregion(m01_awregion),
        .s_axi_awvalid (m01_awvalid), .s_axi_awready (m01_awready),
        .s_axi_wdata   (m01_wdata),   .s_axi_wstrb   (m01_wstrb),
        .s_axi_wlast   (m01_wlast),   .s_axi_wvalid  (m01_wvalid),
        .s_axi_wready  (m01_wready),
        .s_axi_bid     (m01_bid),     .s_axi_bresp   (m01_bresp),
        .s_axi_bvalid  (m01_bvalid),  .s_axi_bready  (m01_bready),
        .s_axi_arid    (m01_arid),    .s_axi_araddr  (m01_araddr),
        .s_axi_arlen   (m01_arlen),   .s_axi_arsize  (m01_arsize),
        .s_axi_arburst (m01_arburst), .s_axi_arlock  (m01_arlock),
        .s_axi_arcache (m01_arcache), .s_axi_arprot  (m01_arprot),
        .s_axi_arqos   (m01_arqos),   .s_axi_arregion(m01_arregion),
        .s_axi_arvalid (m01_arvalid), .s_axi_arready (m01_arready),
        .s_axi_rid     (m01_rid),     .s_axi_rdata   (m01_rdata),
        .s_axi_rresp   (m01_rresp),   .s_axi_rlast   (m01_rlast),
        .s_axi_rvalid  (m01_rvalid),  .s_axi_rready  (m01_rready)
    );

    // ══════════════════════════════════════════════════════════════════
    // m02: AXI UART slave
    // ══════════════════════════════════════════════════════════════════
    axi_uart_slave #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_uart (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awid    (m02_awid),    .s_axi_awaddr  (m02_awaddr),
        .s_axi_awlen   (m02_awlen),   .s_axi_awsize  (m02_awsize),
        .s_axi_awburst (m02_awburst), .s_axi_awlock  (m02_awlock),
        .s_axi_awcache (m02_awcache), .s_axi_awprot  (m02_awprot),
        .s_axi_awqos   (m02_awqos),   .s_axi_awregion(m02_awregion),
        .s_axi_awvalid (m02_awvalid), .s_axi_awready (m02_awready),
        .s_axi_wdata   (m02_wdata),   .s_axi_wstrb   (m02_wstrb),
        .s_axi_wlast   (m02_wlast),   .s_axi_wvalid  (m02_wvalid),
        .s_axi_wready  (m02_wready),
        .s_axi_bid     (m02_bid),     .s_axi_bresp   (m02_bresp),
        .s_axi_bvalid  (m02_bvalid),  .s_axi_bready  (m02_bready),
        .s_axi_arid    (m02_arid),    .s_axi_araddr  (m02_araddr),
        .s_axi_arlen   (m02_arlen),   .s_axi_arsize  (m02_arsize),
        .s_axi_arburst (m02_arburst), .s_axi_arlock  (m02_arlock),
        .s_axi_arcache (m02_arcache), .s_axi_arprot  (m02_arprot),
        .s_axi_arqos   (m02_arqos),   .s_axi_arregion(m02_arregion),
        .s_axi_arvalid (m02_arvalid), .s_axi_arready (m02_arready),
        .s_axi_rid     (m02_rid),     .s_axi_rdata   (m02_rdata),
        .s_axi_rresp   (m02_rresp),   .s_axi_rlast   (m02_rlast),
        .s_axi_rvalid  (m02_rvalid),  .s_axi_rready  (m02_rready),
        .uart_tx_o     (uart_tx_o),
        .uart_rx_i     (uart_rx_i),
        .uart_irq_o    (uart_irq)
    );

    // ══════════════════════════════════════════════════════════════════
    // m03-m10: Dummy AXI slaves
    // ══════════════════════════════════════════════════════════════════
`define DUMMY_INST(N,IDX) \
    dummy_axi_slave #(.SLAVE_INDEX(IDX)) u_dummy_``N ( \
        .clk(clk), .rst(rst), \
        .s_axi_awid(m``N``_awid),.s_axi_awaddr(m``N``_awaddr), \
        .s_axi_awlen(m``N``_awlen),.s_axi_awsize(m``N``_awsize), \
        .s_axi_awburst(m``N``_awburst),.s_axi_awlock(m``N``_awlock), \
        .s_axi_awcache(m``N``_awcache),.s_axi_awprot(m``N``_awprot), \
        .s_axi_awqos(m``N``_awqos),.s_axi_awregion(m``N``_awregion), \
        .s_axi_awvalid(m``N``_awvalid),.s_axi_awready(m``N``_awready), \
        .s_axi_wdata(m``N``_wdata),.s_axi_wstrb(m``N``_wstrb), \
        .s_axi_wlast(m``N``_wlast),.s_axi_wvalid(m``N``_wvalid), \
        .s_axi_wready(m``N``_wready), \
        .s_axi_bid(m``N``_bid),.s_axi_bresp(m``N``_bresp), \
        .s_axi_bvalid(m``N``_bvalid),.s_axi_bready(m``N``_bready), \
        .s_axi_arid(m``N``_arid),.s_axi_araddr(m``N``_araddr), \
        .s_axi_arlen(m``N``_arlen),.s_axi_arsize(m``N``_arsize), \
        .s_axi_arburst(m``N``_arburst),.s_axi_arlock(m``N``_arlock), \
        .s_axi_arcache(m``N``_arcache),.s_axi_arprot(m``N``_arprot), \
        .s_axi_arqos(m``N``_arqos),.s_axi_arregion(m``N``_arregion), \
        .s_axi_arvalid(m``N``_arvalid),.s_axi_arready(m``N``_arready), \
        .s_axi_rid(m``N``_rid),.s_axi_rdata(m``N``_rdata), \
        .s_axi_rresp(m``N``_rresp),.s_axi_rlast(m``N``_rlast), \
        .s_axi_rvalid(m``N``_rvalid),.s_axi_rready(m``N``_rready) \
    );

    `DUMMY_INST(03, 3)  `DUMMY_INST(04, 4)  `DUMMY_INST(05, 5)
    `DUMMY_INST(06, 6)  `DUMMY_INST(07, 7)  `DUMMY_INST(08, 8)
    `DUMMY_INST(09, 9)  `DUMMY_INST(10,10)

endmodule

`default_nettype wire
