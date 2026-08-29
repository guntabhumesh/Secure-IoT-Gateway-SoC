/*
 * tb_axi_interconnect_2x11.v
 *
 * Testbench for axi_interconnect_wrap_2x11
 *
 * Topology
 * --------
 *  AXI Masters  :  s00 (stimulus), s01 (tied off / idle)
 *  AXI Slaves   :  m00 → axi_to_wb_bridge → i2c_master_top (Wishbone)
 *                  m01–m10 → dummy_axi_slave
 *
 * Address map – base addresses MUST be naturally aligned to the window size.
 * With ADDR_WIDTH=24 (2^24 = 0x0100_0000 = 16 MB window), each base must be
 * a multiple of 0x0100_0000.
 * ---------------------------------------------------------------
 *  M00_BASE_ADDR = 32'h0000_0000  → i2c_master_top
 *  M01_BASE_ADDR = 32'h0100_0000  → dummy slave 01
 *  M02_BASE_ADDR = 32'h0200_0000  → dummy slave 02
 *  ...
 *  M10_BASE_ADDR = 32'h0A00_0000  → dummy slave 10
 *
 * Test transactions (all issued from s00)
 * ----------------------------------------
 * AXI addr = BASE(m00=0x0000_0000) + (wb_reg_idx << 2)
 *  Write 1 : addr = 0x0000_0000  → i2c PRER_LO  = 0x63
 *  Write 2 : addr = 0x0000_0004  → i2c PRER_HI  = 0x00
 *  Write 3 : addr = 0x0000_0008  → i2c CTR      = 0x80 (enable core)
 *  Read  1 : addr = 0x0000_0000  → i2c PRER_LO  (expect 0x63)
 *  Read  2 : addr = 0x0000_0008  → i2c CTR      (expect 0x80)
 */

`timescale 1ns/1ps
`default_nettype none

module tb_axi_interconnect_2x11;

// ──────────────────────────────────────────────────────────────────────────────
// Parameters
// ──────────────────────────────────────────────────────────────────────────────
localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam STRB_WIDTH = DATA_WIDTH/8;
localparam ID_WIDTH   = 8;

localparam CLK_PERIOD = 10; // 100 MHz

// i2c base address – m00 base = 0x0000_0000 (aligned to 16MB boundary)
localparam [ADDR_WIDTH-1:0] I2C_BASE = 32'h0000_0000;

// i2c register byte offsets encoded as AXI word addresses
// AXI addr = BASE + (wb_reg << 2)
localparam [ADDR_WIDTH-1:0] ADDR_PRER_LO = I2C_BASE + 32'h00;  // wb addr 0
localparam [ADDR_WIDTH-1:0] ADDR_PRER_HI = I2C_BASE + 32'h04;  // wb addr 1
localparam [ADDR_WIDTH-1:0] ADDR_CTR     = I2C_BASE + 32'h08;  // wb addr 2
localparam [ADDR_WIDTH-1:0] ADDR_TXR     = I2C_BASE + 32'h0C;  // wb addr 3
localparam [ADDR_WIDTH-1:0] ADDR_SR      = I2C_BASE + 32'h10;  // wb addr 4

// ──────────────────────────────────────────────────────────────────────────────
// Clock / reset
// ──────────────────────────────────────────────────────────────────────────────
reg clk = 1'b0;
reg rst = 1'b1;

always #(CLK_PERIOD/2) clk = ~clk;

// ──────────────────────────────────────────────────────────────────────────────
// s00 AXI master stimulus signals
// ──────────────────────────────────────────────────────────────────────────────
// Write address channel
reg  [ID_WIDTH-1:0]   s00_axi_awid    = 0;
reg  [ADDR_WIDTH-1:0] s00_axi_awaddr  = 0;
reg  [7:0]            s00_axi_awlen   = 0;
reg  [2:0]            s00_axi_awsize  = 3'b010; // 4 bytes
reg  [1:0]            s00_axi_awburst = 2'b01;  // INCR
reg                   s00_axi_awlock  = 0;
reg  [3:0]            s00_axi_awcache = 0;
reg  [2:0]            s00_axi_awprot  = 0;
reg  [3:0]            s00_axi_awqos   = 0;
reg                   s00_axi_awvalid = 0;
wire                  s00_axi_awready;
// Write data channel
reg  [DATA_WIDTH-1:0] s00_axi_wdata  = 0;
reg  [STRB_WIDTH-1:0] s00_axi_wstrb  = 4'hF;
reg                   s00_axi_wlast  = 1;
reg                   s00_axi_wvalid = 0;
wire                  s00_axi_wready;
// Write response channel
wire [ID_WIDTH-1:0]   s00_axi_bid;
wire [1:0]            s00_axi_bresp;
reg                   s00_axi_bready = 1;
wire                  s00_axi_bvalid;
// Read address channel
reg  [ID_WIDTH-1:0]   s00_axi_arid    = 0;
reg  [ADDR_WIDTH-1:0] s00_axi_araddr  = 0;
reg  [7:0]            s00_axi_arlen   = 0;
reg  [2:0]            s00_axi_arsize  = 3'b010;
reg  [1:0]            s00_axi_arburst = 2'b01;
reg                   s00_axi_arlock  = 0;
reg  [3:0]            s00_axi_arcache = 0;
reg  [2:0]            s00_axi_arprot  = 0;
reg  [3:0]            s00_axi_arqos   = 0;
reg                   s00_axi_arvalid = 0;
wire                  s00_axi_arready;
// Read data channel
wire [ID_WIDTH-1:0]   s00_axi_rid;
wire [DATA_WIDTH-1:0] s00_axi_rdata;
wire [1:0]            s00_axi_rresp;
wire                  s00_axi_rlast;
wire                  s00_axi_rvalid;
reg                   s00_axi_rready = 1;

// ──────────────────────────────────────────────────────────────────────────────
// s01 AXI master – tied off (idle)
// ──────────────────────────────────────────────────────────────────────────────
wire [ID_WIDTH-1:0]   s01_axi_awid    = 0;
wire [ADDR_WIDTH-1:0] s01_axi_awaddr  = 0;
wire [7:0]            s01_axi_awlen   = 0;
wire [2:0]            s01_axi_awsize  = 3'b010;
wire [1:0]            s01_axi_awburst = 2'b01;
wire                  s01_axi_awlock  = 0;
wire [3:0]            s01_axi_awcache = 0;
wire [2:0]            s01_axi_awprot  = 0;
wire [3:0]            s01_axi_awqos   = 0;
wire                  s01_axi_awvalid = 0;
wire                  s01_axi_awready;
wire [DATA_WIDTH-1:0] s01_axi_wdata   = 0;
wire [STRB_WIDTH-1:0] s01_axi_wstrb   = 0;
wire                  s01_axi_wlast   = 0;
wire                  s01_axi_wvalid  = 0;
wire                  s01_axi_wready;
wire [ID_WIDTH-1:0]   s01_axi_bid;
wire [1:0]            s01_axi_bresp;
wire                  s01_axi_bvalid;
wire                  s01_axi_bready  = 1;
wire [ID_WIDTH-1:0]   s01_axi_arid    = 0;
wire [ADDR_WIDTH-1:0] s01_axi_araddr  = 0;
wire [7:0]            s01_axi_arlen   = 0;
wire [2:0]            s01_axi_arsize  = 3'b010;
wire [1:0]            s01_axi_arburst = 2'b01;
wire                  s01_axi_arlock  = 0;
wire [3:0]            s01_axi_arcache = 0;
wire [2:0]            s01_axi_arprot  = 0;
wire [3:0]            s01_axi_arqos   = 0;
wire                  s01_axi_arvalid = 0;
wire                  s01_axi_arready;
wire [ID_WIDTH-1:0]   s01_axi_rid;
wire [DATA_WIDTH-1:0] s01_axi_rdata;
wire [1:0]            s01_axi_rresp;
wire                  s01_axi_rlast;
wire                  s01_axi_rvalid;
wire                  s01_axi_rready  = 1;


// ──────────────────────────────────────────────────────────────────────────────
// m00 AXI wires (interconnect → axi_to_wb_bridge)
// ──────────────────────────────────────────────────────────────────────────────
wire [ID_WIDTH-1:0]   m00_axi_awid;
wire [ADDR_WIDTH-1:0] m00_axi_awaddr;
wire [7:0]            m00_axi_awlen;
wire [2:0]            m00_axi_awsize;
wire [1:0]            m00_axi_awburst;
wire                  m00_axi_awlock;
wire [3:0]            m00_axi_awcache;
wire [2:0]            m00_axi_awprot;
wire [3:0]            m00_axi_awqos;
wire [3:0]            m00_axi_awregion;
wire                  m00_axi_awvalid;
wire                  m00_axi_awready;
wire [DATA_WIDTH-1:0] m00_axi_wdata;
wire [STRB_WIDTH-1:0] m00_axi_wstrb;
wire                  m00_axi_wlast;
wire                  m00_axi_wvalid;
wire                  m00_axi_wready;
wire [ID_WIDTH-1:0]   m00_axi_bid;
wire [1:0]            m00_axi_bresp;
wire                  m00_axi_bvalid;
wire                  m00_axi_bready;
wire [ID_WIDTH-1:0]   m00_axi_arid;
wire [ADDR_WIDTH-1:0] m00_axi_araddr;
wire [7:0]            m00_axi_arlen;
wire [2:0]            m00_axi_arsize;
wire [1:0]            m00_axi_arburst;
wire                  m00_axi_arlock;
wire [3:0]            m00_axi_arcache;
wire [2:0]            m00_axi_arprot;
wire [3:0]            m00_axi_arqos;
wire [3:0]            m00_axi_arregion;
wire                  m00_axi_arvalid;
wire                  m00_axi_arready;
wire [ID_WIDTH-1:0]   m00_axi_rid;
wire [DATA_WIDTH-1:0] m00_axi_rdata;
wire [1:0]            m00_axi_rresp;
wire                  m00_axi_rlast;
wire                  m00_axi_rvalid;
wire                  m00_axi_rready;

// ──────────────────────────────────────────────────────────────────────────────
// Wishbone wires (axi_to_wb_bridge → i2c_master_top)
// ──────────────────────────────────────────────────────────────────────────────
wire [2:0] wb_adr;
wire [7:0] wb_dat_mosi;   // bridge → i2c
wire [7:0] wb_dat_miso;   // i2c   → bridge
wire       wb_we;
wire       wb_stb;
wire       wb_cyc;
wire       wb_ack;

// i2c pad wires (looped back for simulation)
wire scl_pad_o, scl_padoen_o;
wire sda_pad_o, sda_padoen_o;
wire scl_pad_i = scl_pad_o | scl_padoen_o; // open-drain model
wire sda_pad_i = sda_pad_o | sda_padoen_o;

// ──────────────────────────────────────────────────────────────────────────────
// Dummy slave AXI wires  (macro-style: one set per slave m01..m10)
// ──────────────────────────────────────────────────────────────────────────────
// m01
wire [ID_WIDTH-1:0]   m01_axi_awid;   wire [ADDR_WIDTH-1:0] m01_axi_awaddr;
wire [7:0]            m01_axi_awlen;  wire [2:0]  m01_axi_awsize;
wire [1:0]            m01_axi_awburst;wire        m01_axi_awlock;
wire [3:0]            m01_axi_awcache;wire [2:0]  m01_axi_awprot;
wire [3:0]            m01_axi_awqos;  wire [3:0]  m01_axi_awregion;
wire                  m01_axi_awvalid;wire        m01_axi_awready;
wire [DATA_WIDTH-1:0] m01_axi_wdata;  wire [STRB_WIDTH-1:0] m01_axi_wstrb;
wire                  m01_axi_wlast;  wire        m01_axi_wvalid; wire m01_axi_wready;
wire [ID_WIDTH-1:0]   m01_axi_bid;    wire [1:0]  m01_axi_bresp;
wire                  m01_axi_bvalid; wire        m01_axi_bready;
wire [ID_WIDTH-1:0]   m01_axi_arid;   wire [ADDR_WIDTH-1:0] m01_axi_araddr;
wire [7:0]            m01_axi_arlen;  wire [2:0]  m01_axi_arsize;
wire [1:0]            m01_axi_arburst;wire        m01_axi_arlock;
wire [3:0]            m01_axi_arcache;wire [2:0]  m01_axi_arprot;
wire [3:0]            m01_axi_arqos;  wire [3:0]  m01_axi_arregion;
wire                  m01_axi_arvalid;wire        m01_axi_arready;
wire [ID_WIDTH-1:0]   m01_axi_rid;    wire [DATA_WIDTH-1:0] m01_axi_rdata;
wire [1:0]            m01_axi_rresp;  wire        m01_axi_rlast;
wire                  m01_axi_rvalid; wire        m01_axi_rready;

// m02
wire [ID_WIDTH-1:0]   m02_axi_awid;   wire [ADDR_WIDTH-1:0] m02_axi_awaddr;
wire [7:0]            m02_axi_awlen;  wire [2:0]  m02_axi_awsize;
wire [1:0]            m02_axi_awburst;wire        m02_axi_awlock;
wire [3:0]            m02_axi_awcache;wire [2:0]  m02_axi_awprot;
wire [3:0]            m02_axi_awqos;  wire [3:0]  m02_axi_awregion;
wire                  m02_axi_awvalid;wire        m02_axi_awready;
wire [DATA_WIDTH-1:0] m02_axi_wdata;  wire [STRB_WIDTH-1:0] m02_axi_wstrb;
wire                  m02_axi_wlast;  wire        m02_axi_wvalid; wire m02_axi_wready;
wire [ID_WIDTH-1:0]   m02_axi_bid;    wire [1:0]  m02_axi_bresp;
wire                  m02_axi_bvalid; wire        m02_axi_bready;
wire [ID_WIDTH-1:0]   m02_axi_arid;   wire [ADDR_WIDTH-1:0] m02_axi_araddr;
wire [7:0]            m02_axi_arlen;  wire [2:0]  m02_axi_arsize;
wire [1:0]            m02_axi_arburst;wire        m02_axi_arlock;
wire [3:0]            m02_axi_arcache;wire [2:0]  m02_axi_arprot;
wire [3:0]            m02_axi_arqos;  wire [3:0]  m02_axi_arregion;
wire                  m02_axi_arvalid;wire        m02_axi_arready;
wire [ID_WIDTH-1:0]   m02_axi_rid;    wire [DATA_WIDTH-1:0] m02_axi_rdata;
wire [1:0]            m02_axi_rresp;  wire        m02_axi_rlast;
wire                  m02_axi_rvalid; wire        m02_axi_rready;

// m03
wire [ID_WIDTH-1:0]   m03_axi_awid;   wire [ADDR_WIDTH-1:0] m03_axi_awaddr;
wire [7:0]            m03_axi_awlen;  wire [2:0]  m03_axi_awsize;
wire [1:0]            m03_axi_awburst;wire        m03_axi_awlock;
wire [3:0]            m03_axi_awcache;wire [2:0]  m03_axi_awprot;
wire [3:0]            m03_axi_awqos;  wire [3:0]  m03_axi_awregion;
wire                  m03_axi_awvalid;wire        m03_axi_awready;
wire [DATA_WIDTH-1:0] m03_axi_wdata;  wire [STRB_WIDTH-1:0] m03_axi_wstrb;
wire                  m03_axi_wlast;  wire        m03_axi_wvalid; wire m03_axi_wready;
wire [ID_WIDTH-1:0]   m03_axi_bid;    wire [1:0]  m03_axi_bresp;
wire                  m03_axi_bvalid; wire        m03_axi_bready;
wire [ID_WIDTH-1:0]   m03_axi_arid;   wire [ADDR_WIDTH-1:0] m03_axi_araddr;
wire [7:0]            m03_axi_arlen;  wire [2:0]  m03_axi_arsize;
wire [1:0]            m03_axi_arburst;wire        m03_axi_arlock;
wire [3:0]            m03_axi_arcache;wire [2:0]  m03_axi_arprot;
wire [3:0]            m03_axi_arqos;  wire [3:0]  m03_axi_arregion;
wire                  m03_axi_arvalid;wire        m03_axi_arready;
wire [ID_WIDTH-1:0]   m03_axi_rid;    wire [DATA_WIDTH-1:0] m03_axi_rdata;
wire [1:0]            m03_axi_rresp;  wire        m03_axi_rlast;
wire                  m03_axi_rvalid; wire        m03_axi_rready;

// m04
wire [ID_WIDTH-1:0]   m04_axi_awid;   wire [ADDR_WIDTH-1:0] m04_axi_awaddr;
wire [7:0]            m04_axi_awlen;  wire [2:0]  m04_axi_awsize;
wire [1:0]            m04_axi_awburst;wire        m04_axi_awlock;
wire [3:0]            m04_axi_awcache;wire [2:0]  m04_axi_awprot;
wire [3:0]            m04_axi_awqos;  wire [3:0]  m04_axi_awregion;
wire                  m04_axi_awvalid;wire        m04_axi_awready;
wire [DATA_WIDTH-1:0] m04_axi_wdata;  wire [STRB_WIDTH-1:0] m04_axi_wstrb;
wire                  m04_axi_wlast;  wire        m04_axi_wvalid; wire m04_axi_wready;
wire [ID_WIDTH-1:0]   m04_axi_bid;    wire [1:0]  m04_axi_bresp;
wire                  m04_axi_bvalid; wire        m04_axi_bready;
wire [ID_WIDTH-1:0]   m04_axi_arid;   wire [ADDR_WIDTH-1:0] m04_axi_araddr;
wire [7:0]            m04_axi_arlen;  wire [2:0]  m04_axi_arsize;
wire [1:0]            m04_axi_arburst;wire        m04_axi_arlock;
wire [3:0]            m04_axi_arcache;wire [2:0]  m04_axi_arprot;
wire [3:0]            m04_axi_arqos;  wire [3:0]  m04_axi_arregion;
wire                  m04_axi_arvalid;wire        m04_axi_arready;
wire [ID_WIDTH-1:0]   m04_axi_rid;    wire [DATA_WIDTH-1:0] m04_axi_rdata;
wire [1:0]            m04_axi_rresp;  wire        m04_axi_rlast;
wire                  m04_axi_rvalid; wire        m04_axi_rready;

// m05
wire [ID_WIDTH-1:0]   m05_axi_awid;   wire [ADDR_WIDTH-1:0] m05_axi_awaddr;
wire [7:0]            m05_axi_awlen;  wire [2:0]  m05_axi_awsize;
wire [1:0]            m05_axi_awburst;wire        m05_axi_awlock;
wire [3:0]            m05_axi_awcache;wire [2:0]  m05_axi_awprot;
wire [3:0]            m05_axi_awqos;  wire [3:0]  m05_axi_awregion;
wire                  m05_axi_awvalid;wire        m05_axi_awready;
wire [DATA_WIDTH-1:0] m05_axi_wdata;  wire [STRB_WIDTH-1:0] m05_axi_wstrb;
wire                  m05_axi_wlast;  wire        m05_axi_wvalid; wire m05_axi_wready;
wire [ID_WIDTH-1:0]   m05_axi_bid;    wire [1:0]  m05_axi_bresp;
wire                  m05_axi_bvalid; wire        m05_axi_bready;
wire [ID_WIDTH-1:0]   m05_axi_arid;   wire [ADDR_WIDTH-1:0] m05_axi_araddr;
wire [7:0]            m05_axi_arlen;  wire [2:0]  m05_axi_arsize;
wire [1:0]            m05_axi_arburst;wire        m05_axi_arlock;
wire [3:0]            m05_axi_arcache;wire [2:0]  m05_axi_arprot;
wire [3:0]            m05_axi_arqos;  wire [3:0]  m05_axi_arregion;
wire                  m05_axi_arvalid;wire        m05_axi_arready;
wire [ID_WIDTH-1:0]   m05_axi_rid;    wire [DATA_WIDTH-1:0] m05_axi_rdata;
wire [1:0]            m05_axi_rresp;  wire        m05_axi_rlast;
wire                  m05_axi_rvalid; wire        m05_axi_rready;

// m06
wire [ID_WIDTH-1:0]   m06_axi_awid;   wire [ADDR_WIDTH-1:0] m06_axi_awaddr;
wire [7:0]            m06_axi_awlen;  wire [2:0]  m06_axi_awsize;
wire [1:0]            m06_axi_awburst;wire        m06_axi_awlock;
wire [3:0]            m06_axi_awcache;wire [2:0]  m06_axi_awprot;
wire [3:0]            m06_axi_awqos;  wire [3:0]  m06_axi_awregion;
wire                  m06_axi_awvalid;wire        m06_axi_awready;
wire [DATA_WIDTH-1:0] m06_axi_wdata;  wire [STRB_WIDTH-1:0] m06_axi_wstrb;
wire                  m06_axi_wlast;  wire        m06_axi_wvalid; wire m06_axi_wready;
wire [ID_WIDTH-1:0]   m06_axi_bid;    wire [1:0]  m06_axi_bresp;
wire                  m06_axi_bvalid; wire        m06_axi_bready;
wire [ID_WIDTH-1:0]   m06_axi_arid;   wire [ADDR_WIDTH-1:0] m06_axi_araddr;
wire [7:0]            m06_axi_arlen;  wire [2:0]  m06_axi_arsize;
wire [1:0]            m06_axi_arburst;wire        m06_axi_arlock;
wire [3:0]            m06_axi_arcache;wire [2:0]  m06_axi_arprot;
wire [3:0]            m06_axi_arqos;  wire [3:0]  m06_axi_arregion;
wire                  m06_axi_arvalid;wire        m06_axi_arready;
wire [ID_WIDTH-1:0]   m06_axi_rid;    wire [DATA_WIDTH-1:0] m06_axi_rdata;
wire [1:0]            m06_axi_rresp;  wire        m06_axi_rlast;
wire                  m06_axi_rvalid; wire        m06_axi_rready;

// m07
wire [ID_WIDTH-1:0]   m07_axi_awid;   wire [ADDR_WIDTH-1:0] m07_axi_awaddr;
wire [7:0]            m07_axi_awlen;  wire [2:0]  m07_axi_awsize;
wire [1:0]            m07_axi_awburst;wire        m07_axi_awlock;
wire [3:0]            m07_axi_awcache;wire [2:0]  m07_axi_awprot;
wire [3:0]            m07_axi_awqos;  wire [3:0]  m07_axi_awregion;
wire                  m07_axi_awvalid;wire        m07_axi_awready;
wire [DATA_WIDTH-1:0] m07_axi_wdata;  wire [STRB_WIDTH-1:0] m07_axi_wstrb;
wire                  m07_axi_wlast;  wire        m07_axi_wvalid; wire m07_axi_wready;
wire [ID_WIDTH-1:0]   m07_axi_bid;    wire [1:0]  m07_axi_bresp;
wire                  m07_axi_bvalid; wire        m07_axi_bready;
wire [ID_WIDTH-1:0]   m07_axi_arid;   wire [ADDR_WIDTH-1:0] m07_axi_araddr;
wire [7:0]            m07_axi_arlen;  wire [2:0]  m07_axi_arsize;
wire [1:0]            m07_axi_arburst;wire        m07_axi_arlock;
wire [3:0]            m07_axi_arcache;wire [2:0]  m07_axi_arprot;
wire [3:0]            m07_axi_arqos;  wire [3:0]  m07_axi_arregion;
wire                  m07_axi_arvalid;wire        m07_axi_arready;
wire [ID_WIDTH-1:0]   m07_axi_rid;    wire [DATA_WIDTH-1:0] m07_axi_rdata;
wire [1:0]            m07_axi_rresp;  wire        m07_axi_rlast;
wire                  m07_axi_rvalid; wire        m07_axi_rready;

// m08
wire [ID_WIDTH-1:0]   m08_axi_awid;   wire [ADDR_WIDTH-1:0] m08_axi_awaddr;
wire [7:0]            m08_axi_awlen;  wire [2:0]  m08_axi_awsize;
wire [1:0]            m08_axi_awburst;wire        m08_axi_awlock;
wire [3:0]            m08_axi_awcache;wire [2:0]  m08_axi_awprot;
wire [3:0]            m08_axi_awqos;  wire [3:0]  m08_axi_awregion;
wire                  m08_axi_awvalid;wire        m08_axi_awready;
wire [DATA_WIDTH-1:0] m08_axi_wdata;  wire [STRB_WIDTH-1:0] m08_axi_wstrb;
wire                  m08_axi_wlast;  wire        m08_axi_wvalid; wire m08_axi_wready;
wire [ID_WIDTH-1:0]   m08_axi_bid;    wire [1:0]  m08_axi_bresp;
wire                  m08_axi_bvalid; wire        m08_axi_bready;
wire [ID_WIDTH-1:0]   m08_axi_arid;   wire [ADDR_WIDTH-1:0] m08_axi_araddr;
wire [7:0]            m08_axi_arlen;  wire [2:0]  m08_axi_arsize;
wire [1:0]            m08_axi_arburst;wire        m08_axi_arlock;
wire [3:0]            m08_axi_arcache;wire [2:0]  m08_axi_arprot;
wire [3:0]            m08_axi_arqos;  wire [3:0]  m08_axi_arregion;
wire                  m08_axi_arvalid;wire        m08_axi_arready;
wire [ID_WIDTH-1:0]   m08_axi_rid;    wire [DATA_WIDTH-1:0] m08_axi_rdata;
wire [1:0]            m08_axi_rresp;  wire        m08_axi_rlast;
wire                  m08_axi_rvalid; wire        m08_axi_rready;

// m09
wire [ID_WIDTH-1:0]   m09_axi_awid;   wire [ADDR_WIDTH-1:0] m09_axi_awaddr;
wire [7:0]            m09_axi_awlen;  wire [2:0]  m09_axi_awsize;
wire [1:0]            m09_axi_awburst;wire        m09_axi_awlock;
wire [3:0]            m09_axi_awcache;wire [2:0]  m09_axi_awprot;
wire [3:0]            m09_axi_awqos;  wire [3:0]  m09_axi_awregion;
wire                  m09_axi_awvalid;wire        m09_axi_awready;
wire [DATA_WIDTH-1:0] m09_axi_wdata;  wire [STRB_WIDTH-1:0] m09_axi_wstrb;
wire                  m09_axi_wlast;  wire        m09_axi_wvalid; wire m09_axi_wready;
wire [ID_WIDTH-1:0]   m09_axi_bid;    wire [1:0]  m09_axi_bresp;
wire                  m09_axi_bvalid; wire        m09_axi_bready;
wire [ID_WIDTH-1:0]   m09_axi_arid;   wire [ADDR_WIDTH-1:0] m09_axi_araddr;
wire [7:0]            m09_axi_arlen;  wire [2:0]  m09_axi_arsize;
wire [1:0]            m09_axi_arburst;wire        m09_axi_arlock;
wire [3:0]            m09_axi_arcache;wire [2:0]  m09_axi_arprot;
wire [3:0]            m09_axi_arqos;  wire [3:0]  m09_axi_arregion;
wire                  m09_axi_arvalid;wire        m09_axi_arready;
wire [ID_WIDTH-1:0]   m09_axi_rid;    wire [DATA_WIDTH-1:0] m09_axi_rdata;
wire [1:0]            m09_axi_rresp;  wire        m09_axi_rlast;
wire                  m09_axi_rvalid; wire        m09_axi_rready;

// m10
wire [ID_WIDTH-1:0]   m10_axi_awid;   wire [ADDR_WIDTH-1:0] m10_axi_awaddr;
wire [7:0]            m10_axi_awlen;  wire [2:0]  m10_axi_awsize;
wire [1:0]            m10_axi_awburst;wire        m10_axi_awlock;
wire [3:0]            m10_axi_awcache;wire [2:0]  m10_axi_awprot;
wire [3:0]            m10_axi_awqos;  wire [3:0]  m10_axi_awregion;
wire                  m10_axi_awvalid;wire        m10_axi_awready;
wire [DATA_WIDTH-1:0] m10_axi_wdata;  wire [STRB_WIDTH-1:0] m10_axi_wstrb;
wire                  m10_axi_wlast;  wire        m10_axi_wvalid; wire m10_axi_wready;
wire [ID_WIDTH-1:0]   m10_axi_bid;    wire [1:0]  m10_axi_bresp;
wire                  m10_axi_bvalid; wire        m10_axi_bready;
wire [ID_WIDTH-1:0]   m10_axi_arid;   wire [ADDR_WIDTH-1:0] m10_axi_araddr;
wire [7:0]            m10_axi_arlen;  wire [2:0]  m10_axi_arsize;
wire [1:0]            m10_axi_arburst;wire        m10_axi_arlock;
wire [3:0]            m10_axi_arcache;wire [2:0]  m10_axi_arprot;
wire [3:0]            m10_axi_arqos;  wire [3:0]  m10_axi_arregion;
wire                  m10_axi_arvalid;wire        m10_axi_arready;
wire [ID_WIDTH-1:0]   m10_axi_rid;    wire [DATA_WIDTH-1:0] m10_axi_rdata;
wire [1:0]            m10_axi_rresp;  wire        m10_axi_rlast;
wire                  m10_axi_rvalid; wire        m10_axi_rready;

// user_width stubs (1-bit, tied off)
wire s00_axi_buser, s01_axi_buser;
wire s00_axi_ruser, s01_axi_ruser;


// ──────────────────────────────────────────────────────────────────────────────
// DUT: axi_interconnect_wrap_2x11
// ──────────────────────────────────────────────────────────────────────────────
axi_interconnect_wrap_2x11 #(
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDR_WIDTH     (ADDR_WIDTH),
    .ID_WIDTH       (ID_WIDTH),
    .M_REGIONS      (1),
    // ----------------------------------------------------------------
    // Base addresses: naturally aligned to 2^ADDR_WIDTH = 2^24 = 16 MB
    // Rule: BASE & (2^24 - 1) must be 0  →  BASE must be multiple of 0x0100_0000
    // ----------------------------------------------------------------
    .M00_BASE_ADDR  (32'h0000_0000), .M00_ADDR_WIDTH ({1{32'd24}}),  // i2c_master_top
    .M01_BASE_ADDR  (32'h0100_0000), .M01_ADDR_WIDTH ({1{32'd24}}),  // dummy 01
    .M02_BASE_ADDR  (32'h0200_0000), .M02_ADDR_WIDTH ({1{32'd24}}),  // dummy 02
    .M03_BASE_ADDR  (32'h0300_0000), .M03_ADDR_WIDTH ({1{32'd24}}),  // dummy 03
    .M04_BASE_ADDR  (32'h0400_0000), .M04_ADDR_WIDTH ({1{32'd24}}),  // dummy 04
    .M05_BASE_ADDR  (32'h0500_0000), .M05_ADDR_WIDTH ({1{32'd24}}),  // dummy 05
    .M06_BASE_ADDR  (32'h0600_0000), .M06_ADDR_WIDTH ({1{32'd24}}),  // dummy 06
    .M07_BASE_ADDR  (32'h0700_0000), .M07_ADDR_WIDTH ({1{32'd24}}),  // dummy 07
    .M08_BASE_ADDR  (32'h0800_0000), .M08_ADDR_WIDTH ({1{32'd24}}),  // dummy 08
    .M09_BASE_ADDR  (32'h0900_0000), .M09_ADDR_WIDTH ({1{32'd24}}),  // dummy 09
    .M10_BASE_ADDR  (32'h0A00_0000), .M10_ADDR_WIDTH ({1{32'd24}})   // dummy 10
) u_interconnect (
    .clk             (clk),
    .rst             (rst),
    // s00
    .s00_axi_awid    (s00_axi_awid),   .s00_axi_awaddr  (s00_axi_awaddr),
    .s00_axi_awlen   (s00_axi_awlen),  .s00_axi_awsize  (s00_axi_awsize),
    .s00_axi_awburst (s00_axi_awburst),.s00_axi_awlock  (s00_axi_awlock),
    .s00_axi_awcache (s00_axi_awcache),.s00_axi_awprot  (s00_axi_awprot),
    .s00_axi_awqos   (s00_axi_awqos),  .s00_axi_awuser  (1'b0),
    .s00_axi_awvalid (s00_axi_awvalid),.s00_axi_awready (s00_axi_awready),
    .s00_axi_wdata   (s00_axi_wdata),  .s00_axi_wstrb   (s00_axi_wstrb),
    .s00_axi_wlast   (s00_axi_wlast),  .s00_axi_wuser   (1'b0),
    .s00_axi_wvalid  (s00_axi_wvalid), .s00_axi_wready  (s00_axi_wready),
    .s00_axi_bid     (s00_axi_bid),    .s00_axi_bresp   (s00_axi_bresp),
    .s00_axi_buser   (s00_axi_buser),  .s00_axi_bvalid  (s00_axi_bvalid),
    .s00_axi_bready  (s00_axi_bready),
    .s00_axi_arid    (s00_axi_arid),   .s00_axi_araddr  (s00_axi_araddr),
    .s00_axi_arlen   (s00_axi_arlen),  .s00_axi_arsize  (s00_axi_arsize),
    .s00_axi_arburst (s00_axi_arburst),.s00_axi_arlock  (s00_axi_arlock),
    .s00_axi_arcache (s00_axi_arcache),.s00_axi_arprot  (s00_axi_arprot),
    .s00_axi_arqos   (s00_axi_arqos),  .s00_axi_aruser  (1'b0),
    .s00_axi_arvalid (s00_axi_arvalid),.s00_axi_arready (s00_axi_arready),
    .s00_axi_rid     (s00_axi_rid),    .s00_axi_rdata   (s00_axi_rdata),
    .s00_axi_rresp   (s00_axi_rresp),  .s00_axi_rlast   (s00_axi_rlast),
    .s00_axi_ruser   (s00_axi_ruser),  .s00_axi_rvalid  (s00_axi_rvalid),
    .s00_axi_rready  (s00_axi_rready),
    // s01 (idle)
    .s01_axi_awid    (s01_axi_awid),   .s01_axi_awaddr  (s01_axi_awaddr),
    .s01_axi_awlen   (s01_axi_awlen),  .s01_axi_awsize  (s01_axi_awsize),
    .s01_axi_awburst (s01_axi_awburst),.s01_axi_awlock  (s01_axi_awlock),
    .s01_axi_awcache (s01_axi_awcache),.s01_axi_awprot  (s01_axi_awprot),
    .s01_axi_awqos   (s01_axi_awqos),  .s01_axi_awuser  (1'b0),
    .s01_axi_awvalid (s01_axi_awvalid),.s01_axi_awready (s01_axi_awready),
    .s01_axi_wdata   (s01_axi_wdata),  .s01_axi_wstrb   (s01_axi_wstrb),
    .s01_axi_wlast   (s01_axi_wlast),  .s01_axi_wuser   (1'b0),
    .s01_axi_wvalid  (s01_axi_wvalid), .s01_axi_wready  (s01_axi_wready),
    .s01_axi_bid     (s01_axi_bid),    .s01_axi_bresp   (s01_axi_bresp),
    .s01_axi_buser   (s01_axi_buser),  .s01_axi_bvalid  (s01_axi_bvalid),
    .s01_axi_bready  (s01_axi_bready),
    .s01_axi_arid    (s01_axi_arid),   .s01_axi_araddr  (s01_axi_araddr),
    .s01_axi_arlen   (s01_axi_arlen),  .s01_axi_arsize  (s01_axi_arsize),
    .s01_axi_arburst (s01_axi_arburst),.s01_axi_arlock  (s01_axi_arlock),
    .s01_axi_arcache (s01_axi_arcache),.s01_axi_arprot  (s01_axi_arprot),
    .s01_axi_arqos   (s01_axi_arqos),  .s01_axi_aruser  (1'b0),
    .s01_axi_arvalid (s01_axi_arvalid),.s01_axi_arready (s01_axi_arready),
    .s01_axi_rid     (s01_axi_rid),    .s01_axi_rdata   (s01_axi_rdata),
    .s01_axi_rresp   (s01_axi_rresp),  .s01_axi_rlast   (s01_axi_rlast),
    .s01_axi_ruser   (s01_axi_ruser),  .s01_axi_rvalid  (s01_axi_rvalid),
    .s01_axi_rready  (s01_axi_rready),
    // m00
    .m00_axi_awid    (m00_axi_awid),   .m00_axi_awaddr  (m00_axi_awaddr),
    .m00_axi_awlen   (m00_axi_awlen),  .m00_axi_awsize  (m00_axi_awsize),
    .m00_axi_awburst (m00_axi_awburst),.m00_axi_awlock  (m00_axi_awlock),
    .m00_axi_awcache (m00_axi_awcache),.m00_axi_awprot  (m00_axi_awprot),
    .m00_axi_awqos   (m00_axi_awqos),  .m00_axi_awregion(m00_axi_awregion),
    .m00_axi_awuser  (),               .m00_axi_awvalid (m00_axi_awvalid),
    .m00_axi_awready (m00_axi_awready),.m00_axi_wdata   (m00_axi_wdata),
    .m00_axi_wstrb   (m00_axi_wstrb),  .m00_axi_wlast   (m00_axi_wlast),
    .m00_axi_wuser   (),               .m00_axi_wvalid  (m00_axi_wvalid),
    .m00_axi_wready  (m00_axi_wready), .m00_axi_bid     (m00_axi_bid),
    .m00_axi_bresp   (m00_axi_bresp),  .m00_axi_buser   (1'b0),
    .m00_axi_bvalid  (m00_axi_bvalid), .m00_axi_bready  (m00_axi_bready),
    .m00_axi_arid    (m00_axi_arid),   .m00_axi_araddr  (m00_axi_araddr),
    .m00_axi_arlen   (m00_axi_arlen),  .m00_axi_arsize  (m00_axi_arsize),
    .m00_axi_arburst (m00_axi_arburst),.m00_axi_arlock  (m00_axi_arlock),
    .m00_axi_arcache (m00_axi_arcache),.m00_axi_arprot  (m00_axi_arprot),
    .m00_axi_arqos   (m00_axi_arqos),  .m00_axi_arregion(m00_axi_arregion),
    .m00_axi_aruser  (),               .m00_axi_arvalid (m00_axi_arvalid),
    .m00_axi_arready (m00_axi_arready),.m00_axi_rid     (m00_axi_rid),
    .m00_axi_rdata   (m00_axi_rdata),  .m00_axi_rresp   (m00_axi_rresp),
    .m00_axi_rlast   (m00_axi_rlast),  .m00_axi_ruser   (1'b0),
    .m00_axi_rvalid  (m00_axi_rvalid), .m00_axi_rready  (m00_axi_rready),
    // m01
    .m01_axi_awid(m01_axi_awid),.m01_axi_awaddr(m01_axi_awaddr),
    .m01_axi_awlen(m01_axi_awlen),.m01_axi_awsize(m01_axi_awsize),
    .m01_axi_awburst(m01_axi_awburst),.m01_axi_awlock(m01_axi_awlock),
    .m01_axi_awcache(m01_axi_awcache),.m01_axi_awprot(m01_axi_awprot),
    .m01_axi_awqos(m01_axi_awqos),.m01_axi_awregion(m01_axi_awregion),
    .m01_axi_awuser(),.m01_axi_awvalid(m01_axi_awvalid),.m01_axi_awready(m01_axi_awready),
    .m01_axi_wdata(m01_axi_wdata),.m01_axi_wstrb(m01_axi_wstrb),
    .m01_axi_wlast(m01_axi_wlast),.m01_axi_wuser(),.m01_axi_wvalid(m01_axi_wvalid),.m01_axi_wready(m01_axi_wready),
    .m01_axi_bid(m01_axi_bid),.m01_axi_bresp(m01_axi_bresp),.m01_axi_buser(1'b0),.m01_axi_bvalid(m01_axi_bvalid),.m01_axi_bready(m01_axi_bready),
    .m01_axi_arid(m01_axi_arid),.m01_axi_araddr(m01_axi_araddr),
    .m01_axi_arlen(m01_axi_arlen),.m01_axi_arsize(m01_axi_arsize),
    .m01_axi_arburst(m01_axi_arburst),.m01_axi_arlock(m01_axi_arlock),
    .m01_axi_arcache(m01_axi_arcache),.m01_axi_arprot(m01_axi_arprot),
    .m01_axi_arqos(m01_axi_arqos),.m01_axi_arregion(m01_axi_arregion),
    .m01_axi_aruser(),.m01_axi_arvalid(m01_axi_arvalid),.m01_axi_arready(m01_axi_arready),
    .m01_axi_rid(m01_axi_rid),.m01_axi_rdata(m01_axi_rdata),
    .m01_axi_rresp(m01_axi_rresp),.m01_axi_rlast(m01_axi_rlast),.m01_axi_ruser(1'b0),.m01_axi_rvalid(m01_axi_rvalid),.m01_axi_rready(m01_axi_rready),
    // m02
    .m02_axi_awid(m02_axi_awid),.m02_axi_awaddr(m02_axi_awaddr),
    .m02_axi_awlen(m02_axi_awlen),.m02_axi_awsize(m02_axi_awsize),
    .m02_axi_awburst(m02_axi_awburst),.m02_axi_awlock(m02_axi_awlock),
    .m02_axi_awcache(m02_axi_awcache),.m02_axi_awprot(m02_axi_awprot),
    .m02_axi_awqos(m02_axi_awqos),.m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser(),.m02_axi_awvalid(m02_axi_awvalid),.m02_axi_awready(m02_axi_awready),
    .m02_axi_wdata(m02_axi_wdata),.m02_axi_wstrb(m02_axi_wstrb),
    .m02_axi_wlast(m02_axi_wlast),.m02_axi_wuser(),.m02_axi_wvalid(m02_axi_wvalid),.m02_axi_wready(m02_axi_wready),
    .m02_axi_bid(m02_axi_bid),.m02_axi_bresp(m02_axi_bresp),.m02_axi_buser(1'b0),.m02_axi_bvalid(m02_axi_bvalid),.m02_axi_bready(m02_axi_bready),
    .m02_axi_arid(m02_axi_arid),.m02_axi_araddr(m02_axi_araddr),
    .m02_axi_arlen(m02_axi_arlen),.m02_axi_arsize(m02_axi_arsize),
    .m02_axi_arburst(m02_axi_arburst),.m02_axi_arlock(m02_axi_arlock),
    .m02_axi_arcache(m02_axi_arcache),.m02_axi_arprot(m02_axi_arprot),
    .m02_axi_arqos(m02_axi_arqos),.m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser(),.m02_axi_arvalid(m02_axi_arvalid),.m02_axi_arready(m02_axi_arready),
    .m02_axi_rid(m02_axi_rid),.m02_axi_rdata(m02_axi_rdata),
    .m02_axi_rresp(m02_axi_rresp),.m02_axi_rlast(m02_axi_rlast),.m02_axi_ruser(1'b0),.m02_axi_rvalid(m02_axi_rvalid),.m02_axi_rready(m02_axi_rready),
    // m03
    .m03_axi_awid(m03_axi_awid),.m03_axi_awaddr(m03_axi_awaddr),
    .m03_axi_awlen(m03_axi_awlen),.m03_axi_awsize(m03_axi_awsize),
    .m03_axi_awburst(m03_axi_awburst),.m03_axi_awlock(m03_axi_awlock),
    .m03_axi_awcache(m03_axi_awcache),.m03_axi_awprot(m03_axi_awprot),
    .m03_axi_awqos(m03_axi_awqos),.m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser(),.m03_axi_awvalid(m03_axi_awvalid),.m03_axi_awready(m03_axi_awready),
    .m03_axi_wdata(m03_axi_wdata),.m03_axi_wstrb(m03_axi_wstrb),
    .m03_axi_wlast(m03_axi_wlast),.m03_axi_wuser(),.m03_axi_wvalid(m03_axi_wvalid),.m03_axi_wready(m03_axi_wready),
    .m03_axi_bid(m03_axi_bid),.m03_axi_bresp(m03_axi_bresp),.m03_axi_buser(1'b0),.m03_axi_bvalid(m03_axi_bvalid),.m03_axi_bready(m03_axi_bready),
    .m03_axi_arid(m03_axi_arid),.m03_axi_araddr(m03_axi_araddr),
    .m03_axi_arlen(m03_axi_arlen),.m03_axi_arsize(m03_axi_arsize),
    .m03_axi_arburst(m03_axi_arburst),.m03_axi_arlock(m03_axi_arlock),
    .m03_axi_arcache(m03_axi_arcache),.m03_axi_arprot(m03_axi_arprot),
    .m03_axi_arqos(m03_axi_arqos),.m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser(),.m03_axi_arvalid(m03_axi_arvalid),.m03_axi_arready(m03_axi_arready),
    .m03_axi_rid(m03_axi_rid),.m03_axi_rdata(m03_axi_rdata),
    .m03_axi_rresp(m03_axi_rresp),.m03_axi_rlast(m03_axi_rlast),.m03_axi_ruser(1'b0),.m03_axi_rvalid(m03_axi_rvalid),.m03_axi_rready(m03_axi_rready),
    // m04
    .m04_axi_awid(m04_axi_awid),.m04_axi_awaddr(m04_axi_awaddr),
    .m04_axi_awlen(m04_axi_awlen),.m04_axi_awsize(m04_axi_awsize),
    .m04_axi_awburst(m04_axi_awburst),.m04_axi_awlock(m04_axi_awlock),
    .m04_axi_awcache(m04_axi_awcache),.m04_axi_awprot(m04_axi_awprot),
    .m04_axi_awqos(m04_axi_awqos),.m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser(),.m04_axi_awvalid(m04_axi_awvalid),.m04_axi_awready(m04_axi_awready),
    .m04_axi_wdata(m04_axi_wdata),.m04_axi_wstrb(m04_axi_wstrb),
    .m04_axi_wlast(m04_axi_wlast),.m04_axi_wuser(),.m04_axi_wvalid(m04_axi_wvalid),.m04_axi_wready(m04_axi_wready),
    .m04_axi_bid(m04_axi_bid),.m04_axi_bresp(m04_axi_bresp),.m04_axi_buser(1'b0),.m04_axi_bvalid(m04_axi_bvalid),.m04_axi_bready(m04_axi_bready),
    .m04_axi_arid(m04_axi_arid),.m04_axi_araddr(m04_axi_araddr),
    .m04_axi_arlen(m04_axi_arlen),.m04_axi_arsize(m04_axi_arsize),
    .m04_axi_arburst(m04_axi_arburst),.m04_axi_arlock(m04_axi_arlock),
    .m04_axi_arcache(m04_axi_arcache),.m04_axi_arprot(m04_axi_arprot),
    .m04_axi_arqos(m04_axi_arqos),.m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser(),.m04_axi_arvalid(m04_axi_arvalid),.m04_axi_arready(m04_axi_arready),
    .m04_axi_rid(m04_axi_rid),.m04_axi_rdata(m04_axi_rdata),
    .m04_axi_rresp(m04_axi_rresp),.m04_axi_rlast(m04_axi_rlast),.m04_axi_ruser(1'b0),.m04_axi_rvalid(m04_axi_rvalid),.m04_axi_rready(m04_axi_rready),
    // m05
    .m05_axi_awid(m05_axi_awid),.m05_axi_awaddr(m05_axi_awaddr),
    .m05_axi_awlen(m05_axi_awlen),.m05_axi_awsize(m05_axi_awsize),
    .m05_axi_awburst(m05_axi_awburst),.m05_axi_awlock(m05_axi_awlock),
    .m05_axi_awcache(m05_axi_awcache),.m05_axi_awprot(m05_axi_awprot),
    .m05_axi_awqos(m05_axi_awqos),.m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser(),.m05_axi_awvalid(m05_axi_awvalid),.m05_axi_awready(m05_axi_awready),
    .m05_axi_wdata(m05_axi_wdata),.m05_axi_wstrb(m05_axi_wstrb),
    .m05_axi_wlast(m05_axi_wlast),.m05_axi_wuser(),.m05_axi_wvalid(m05_axi_wvalid),.m05_axi_wready(m05_axi_wready),
    .m05_axi_bid(m05_axi_bid),.m05_axi_bresp(m05_axi_bresp),.m05_axi_buser(1'b0),.m05_axi_bvalid(m05_axi_bvalid),.m05_axi_bready(m05_axi_bready),
    .m05_axi_arid(m05_axi_arid),.m05_axi_araddr(m05_axi_araddr),
    .m05_axi_arlen(m05_axi_arlen),.m05_axi_arsize(m05_axi_arsize),
    .m05_axi_arburst(m05_axi_arburst),.m05_axi_arlock(m05_axi_arlock),
    .m05_axi_arcache(m05_axi_arcache),.m05_axi_arprot(m05_axi_arprot),
    .m05_axi_arqos(m05_axi_arqos),.m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser(),.m05_axi_arvalid(m05_axi_arvalid),.m05_axi_arready(m05_axi_arready),
    .m05_axi_rid(m05_axi_rid),.m05_axi_rdata(m05_axi_rdata),
    .m05_axi_rresp(m05_axi_rresp),.m05_axi_rlast(m05_axi_rlast),.m05_axi_ruser(1'b0),.m05_axi_rvalid(m05_axi_rvalid),.m05_axi_rready(m05_axi_rready),
    // m06
    .m06_axi_awid(m06_axi_awid),.m06_axi_awaddr(m06_axi_awaddr),
    .m06_axi_awlen(m06_axi_awlen),.m06_axi_awsize(m06_axi_awsize),
    .m06_axi_awburst(m06_axi_awburst),.m06_axi_awlock(m06_axi_awlock),
    .m06_axi_awcache(m06_axi_awcache),.m06_axi_awprot(m06_axi_awprot),
    .m06_axi_awqos(m06_axi_awqos),.m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser(),.m06_axi_awvalid(m06_axi_awvalid),.m06_axi_awready(m06_axi_awready),
    .m06_axi_wdata(m06_axi_wdata),.m06_axi_wstrb(m06_axi_wstrb),
    .m06_axi_wlast(m06_axi_wlast),.m06_axi_wuser(),.m06_axi_wvalid(m06_axi_wvalid),.m06_axi_wready(m06_axi_wready),
    .m06_axi_bid(m06_axi_bid),.m06_axi_bresp(m06_axi_bresp),.m06_axi_buser(1'b0),.m06_axi_bvalid(m06_axi_bvalid),.m06_axi_bready(m06_axi_bready),
    .m06_axi_arid(m06_axi_arid),.m06_axi_araddr(m06_axi_araddr),
    .m06_axi_arlen(m06_axi_arlen),.m06_axi_arsize(m06_axi_arsize),
    .m06_axi_arburst(m06_axi_arburst),.m06_axi_arlock(m06_axi_arlock),
    .m06_axi_arcache(m06_axi_arcache),.m06_axi_arprot(m06_axi_arprot),
    .m06_axi_arqos(m06_axi_arqos),.m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser(),.m06_axi_arvalid(m06_axi_arvalid),.m06_axi_arready(m06_axi_arready),
    .m06_axi_rid(m06_axi_rid),.m06_axi_rdata(m06_axi_rdata),
    .m06_axi_rresp(m06_axi_rresp),.m06_axi_rlast(m06_axi_rlast),.m06_axi_ruser(1'b0),.m06_axi_rvalid(m06_axi_rvalid),.m06_axi_rready(m06_axi_rready),
    // m07
    .m07_axi_awid(m07_axi_awid),.m07_axi_awaddr(m07_axi_awaddr),
    .m07_axi_awlen(m07_axi_awlen),.m07_axi_awsize(m07_axi_awsize),
    .m07_axi_awburst(m07_axi_awburst),.m07_axi_awlock(m07_axi_awlock),
    .m07_axi_awcache(m07_axi_awcache),.m07_axi_awprot(m07_axi_awprot),
    .m07_axi_awqos(m07_axi_awqos),.m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser(),.m07_axi_awvalid(m07_axi_awvalid),.m07_axi_awready(m07_axi_awready),
    .m07_axi_wdata(m07_axi_wdata),.m07_axi_wstrb(m07_axi_wstrb),
    .m07_axi_wlast(m07_axi_wlast),.m07_axi_wuser(),.m07_axi_wvalid(m07_axi_wvalid),.m07_axi_wready(m07_axi_wready),
    .m07_axi_bid(m07_axi_bid),.m07_axi_bresp(m07_axi_bresp),.m07_axi_buser(1'b0),.m07_axi_bvalid(m07_axi_bvalid),.m07_axi_bready(m07_axi_bready),
    .m07_axi_arid(m07_axi_arid),.m07_axi_araddr(m07_axi_araddr),
    .m07_axi_arlen(m07_axi_arlen),.m07_axi_arsize(m07_axi_arsize),
    .m07_axi_arburst(m07_axi_arburst),.m07_axi_arlock(m07_axi_arlock),
    .m07_axi_arcache(m07_axi_arcache),.m07_axi_arprot(m07_axi_arprot),
    .m07_axi_arqos(m07_axi_arqos),.m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser(),.m07_axi_arvalid(m07_axi_arvalid),.m07_axi_arready(m07_axi_arready),
    .m07_axi_rid(m07_axi_rid),.m07_axi_rdata(m07_axi_rdata),
    .m07_axi_rresp(m07_axi_rresp),.m07_axi_rlast(m07_axi_rlast),.m07_axi_ruser(1'b0),.m07_axi_rvalid(m07_axi_rvalid),.m07_axi_rready(m07_axi_rready),
    // m08
    .m08_axi_awid(m08_axi_awid),.m08_axi_awaddr(m08_axi_awaddr),
    .m08_axi_awlen(m08_axi_awlen),.m08_axi_awsize(m08_axi_awsize),
    .m08_axi_awburst(m08_axi_awburst),.m08_axi_awlock(m08_axi_awlock),
    .m08_axi_awcache(m08_axi_awcache),.m08_axi_awprot(m08_axi_awprot),
    .m08_axi_awqos(m08_axi_awqos),.m08_axi_awregion(m08_axi_awregion),
    .m08_axi_awuser(),.m08_axi_awvalid(m08_axi_awvalid),.m08_axi_awready(m08_axi_awready),
    .m08_axi_wdata(m08_axi_wdata),.m08_axi_wstrb(m08_axi_wstrb),
    .m08_axi_wlast(m08_axi_wlast),.m08_axi_wuser(),.m08_axi_wvalid(m08_axi_wvalid),.m08_axi_wready(m08_axi_wready),
    .m08_axi_bid(m08_axi_bid),.m08_axi_bresp(m08_axi_bresp),.m08_axi_buser(1'b0),.m08_axi_bvalid(m08_axi_bvalid),.m08_axi_bready(m08_axi_bready),
    .m08_axi_arid(m08_axi_arid),.m08_axi_araddr(m08_axi_araddr),
    .m08_axi_arlen(m08_axi_arlen),.m08_axi_arsize(m08_axi_arsize),
    .m08_axi_arburst(m08_axi_arburst),.m08_axi_arlock(m08_axi_arlock),
    .m08_axi_arcache(m08_axi_arcache),.m08_axi_arprot(m08_axi_arprot),
    .m08_axi_arqos(m08_axi_arqos),.m08_axi_arregion(m08_axi_arregion),
    .m08_axi_aruser(),.m08_axi_arvalid(m08_axi_arvalid),.m08_axi_arready(m08_axi_arready),
    .m08_axi_rid(m08_axi_rid),.m08_axi_rdata(m08_axi_rdata),
    .m08_axi_rresp(m08_axi_rresp),.m08_axi_rlast(m08_axi_rlast),.m08_axi_ruser(1'b0),.m08_axi_rvalid(m08_axi_rvalid),.m08_axi_rready(m08_axi_rready),
    // m09
    .m09_axi_awid(m09_axi_awid),.m09_axi_awaddr(m09_axi_awaddr),
    .m09_axi_awlen(m09_axi_awlen),.m09_axi_awsize(m09_axi_awsize),
    .m09_axi_awburst(m09_axi_awburst),.m09_axi_awlock(m09_axi_awlock),
    .m09_axi_awcache(m09_axi_awcache),.m09_axi_awprot(m09_axi_awprot),
    .m09_axi_awqos(m09_axi_awqos),.m09_axi_awregion(m09_axi_awregion),
    .m09_axi_awuser(),.m09_axi_awvalid(m09_axi_awvalid),.m09_axi_awready(m09_axi_awready),
    .m09_axi_wdata(m09_axi_wdata),.m09_axi_wstrb(m09_axi_wstrb),
    .m09_axi_wlast(m09_axi_wlast),.m09_axi_wuser(),.m09_axi_wvalid(m09_axi_wvalid),.m09_axi_wready(m09_axi_wready),
    .m09_axi_bid(m09_axi_bid),.m09_axi_bresp(m09_axi_bresp),.m09_axi_buser(1'b0),.m09_axi_bvalid(m09_axi_bvalid),.m09_axi_bready(m09_axi_bready),
    .m09_axi_arid(m09_axi_arid),.m09_axi_araddr(m09_axi_araddr),
    .m09_axi_arlen(m09_axi_arlen),.m09_axi_arsize(m09_axi_arsize),
    .m09_axi_arburst(m09_axi_arburst),.m09_axi_arlock(m09_axi_arlock),
    .m09_axi_arcache(m09_axi_arcache),.m09_axi_arprot(m09_axi_arprot),
    .m09_axi_arqos(m09_axi_arqos),.m09_axi_arregion(m09_axi_arregion),
    .m09_axi_aruser(),.m09_axi_arvalid(m09_axi_arvalid),.m09_axi_arready(m09_axi_arready),
    .m09_axi_rid(m09_axi_rid),.m09_axi_rdata(m09_axi_rdata),
    .m09_axi_rresp(m09_axi_rresp),.m09_axi_rlast(m09_axi_rlast),.m09_axi_ruser(1'b0),.m09_axi_rvalid(m09_axi_rvalid),.m09_axi_rready(m09_axi_rready),
    // m10
    .m10_axi_awid(m10_axi_awid),.m10_axi_awaddr(m10_axi_awaddr),
    .m10_axi_awlen(m10_axi_awlen),.m10_axi_awsize(m10_axi_awsize),
    .m10_axi_awburst(m10_axi_awburst),.m10_axi_awlock(m10_axi_awlock),
    .m10_axi_awcache(m10_axi_awcache),.m10_axi_awprot(m10_axi_awprot),
    .m10_axi_awqos(m10_axi_awqos),.m10_axi_awregion(m10_axi_awregion),
    .m10_axi_awuser(),.m10_axi_awvalid(m10_axi_awvalid),.m10_axi_awready(m10_axi_awready),
    .m10_axi_wdata(m10_axi_wdata),.m10_axi_wstrb(m10_axi_wstrb),
    .m10_axi_wlast(m10_axi_wlast),.m10_axi_wuser(),.m10_axi_wvalid(m10_axi_wvalid),.m10_axi_wready(m10_axi_wready),
    .m10_axi_bid(m10_axi_bid),.m10_axi_bresp(m10_axi_bresp),.m10_axi_buser(1'b0),.m10_axi_bvalid(m10_axi_bvalid),.m10_axi_bready(m10_axi_bready),
    .m10_axi_arid(m10_axi_arid),.m10_axi_araddr(m10_axi_araddr),
    .m10_axi_arlen(m10_axi_arlen),.m10_axi_arsize(m10_axi_arsize),
    .m10_axi_arburst(m10_axi_arburst),.m10_axi_arlock(m10_axi_arlock),
    .m10_axi_arcache(m10_axi_arcache),.m10_axi_arprot(m10_axi_arprot),
    .m10_axi_arqos(m10_axi_arqos),.m10_axi_arregion(m10_axi_arregion),
    .m10_axi_aruser(),.m10_axi_arvalid(m10_axi_arvalid),.m10_axi_arready(m10_axi_arready),
    .m10_axi_rid(m10_axi_rid),.m10_axi_rdata(m10_axi_rdata),
    .m10_axi_rresp(m10_axi_rresp),.m10_axi_rlast(m10_axi_rlast),.m10_axi_ruser(1'b0),.m10_axi_rvalid(m10_axi_rvalid),.m10_axi_rready(m10_axi_rready)
);

// ──────────────────────────────────────────────────────────────────────────────
// m00: AXI-to-Wishbone bridge
// ──────────────────────────────────────────────────────────────────────────────
axi_to_wb_bridge #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .ID_WIDTH   (ID_WIDTH)
) u_axi_wb_bridge (
    .clk             (clk),
    .rst             (rst),
    .s_axi_awid      (m00_axi_awid),    .s_axi_awaddr    (m00_axi_awaddr),
    .s_axi_awlen     (m00_axi_awlen),   .s_axi_awsize    (m00_axi_awsize),
    .s_axi_awburst   (m00_axi_awburst), .s_axi_awlock    (m00_axi_awlock),
    .s_axi_awcache   (m00_axi_awcache), .s_axi_awprot    (m00_axi_awprot),
    .s_axi_awqos     (m00_axi_awqos),   .s_axi_awregion  (m00_axi_awregion),
    .s_axi_awvalid   (m00_axi_awvalid), .s_axi_awready   (m00_axi_awready),
    .s_axi_wdata     (m00_axi_wdata),   .s_axi_wstrb     (m00_axi_wstrb),
    .s_axi_wlast     (m00_axi_wlast),   .s_axi_wvalid    (m00_axi_wvalid),
    .s_axi_wready    (m00_axi_wready),  .s_axi_bid       (m00_axi_bid),
    .s_axi_bresp     (m00_axi_bresp),   .s_axi_bvalid    (m00_axi_bvalid),
    .s_axi_bready    (m00_axi_bready),  .s_axi_arid      (m00_axi_arid),
    .s_axi_araddr    (m00_axi_araddr),  .s_axi_arlen     (m00_axi_arlen),
    .s_axi_arsize    (m00_axi_arsize),  .s_axi_arburst   (m00_axi_arburst),
    .s_axi_arlock    (m00_axi_arlock),  .s_axi_arcache   (m00_axi_arcache),
    .s_axi_arprot    (m00_axi_arprot),  .s_axi_arqos     (m00_axi_arqos),
    .s_axi_arregion  (m00_axi_arregion),.s_axi_arvalid   (m00_axi_arvalid),
    .s_axi_arready   (m00_axi_arready), .s_axi_rid       (m00_axi_rid),
    .s_axi_rdata     (m00_axi_rdata),   .s_axi_rresp     (m00_axi_rresp),
    .s_axi_rlast     (m00_axi_rlast),   .s_axi_rvalid    (m00_axi_rvalid),
    .s_axi_rready    (m00_axi_rready),
    .wb_adr_o        (wb_adr),          .wb_dat_o        (wb_dat_mosi),
    .wb_dat_i        (wb_dat_miso),     .wb_we_o         (wb_we),
    .wb_stb_o        (wb_stb),          .wb_cyc_o        (wb_cyc),
    .wb_ack_i        (wb_ack)
);

// ──────────────────────────────────────────────────────────────────────────────
// m00: i2c_master_top (Wishbone slave)
// ──────────────────────────────────────────────────────────────────────────────
i2c_master_top #(
    .ARST_LVL (1'b0)   // arst_i tied high → reset inactive when arst_i=1
) u_i2c_master (
    .wb_clk_i    (clk),
    .wb_rst_i    (rst),
    .arst_i      (1'b1),          // async reset inactive (ARST_LVL=0 → ~1=0 → no reset)
    .wb_adr_i    (wb_adr),
    .wb_dat_i    (wb_dat_mosi),
    .wb_dat_o    (wb_dat_miso),
    .wb_we_i     (wb_we),
    .wb_stb_i    (wb_stb),
    .wb_cyc_i    (wb_cyc),
    .wb_ack_o    (wb_ack),
    .wb_inta_o   (),              // interrupt – not used in this test
    .scl_pad_i   (scl_pad_i),
    .scl_pad_o   (scl_pad_o),
    .scl_padoen_o(scl_padoen_o),
    .sda_pad_i   (sda_pad_i),
    .sda_pad_o   (sda_pad_o),
    .sda_padoen_o(sda_padoen_o)
);

// ──────────────────────────────────────────────────────────────────────────────
// m01 – m10: dummy AXI slaves
// ──────────────────────────────────────────────────────────────────────────────
dummy_axi_slave #(.SLAVE_INDEX(1)) u_dummy01 (.clk(clk),.rst(rst),
    .s_axi_awid(m01_axi_awid),.s_axi_awaddr(m01_axi_awaddr),.s_axi_awlen(m01_axi_awlen),
    .s_axi_awsize(m01_axi_awsize),.s_axi_awburst(m01_axi_awburst),.s_axi_awlock(m01_axi_awlock),
    .s_axi_awcache(m01_axi_awcache),.s_axi_awprot(m01_axi_awprot),.s_axi_awqos(m01_axi_awqos),
    .s_axi_awregion(m01_axi_awregion),.s_axi_awvalid(m01_axi_awvalid),.s_axi_awready(m01_axi_awready),
    .s_axi_wdata(m01_axi_wdata),.s_axi_wstrb(m01_axi_wstrb),.s_axi_wlast(m01_axi_wlast),
    .s_axi_wvalid(m01_axi_wvalid),.s_axi_wready(m01_axi_wready),
    .s_axi_bid(m01_axi_bid),.s_axi_bresp(m01_axi_bresp),.s_axi_bvalid(m01_axi_bvalid),.s_axi_bready(m01_axi_bready),
    .s_axi_arid(m01_axi_arid),.s_axi_araddr(m01_axi_araddr),.s_axi_arlen(m01_axi_arlen),
    .s_axi_arsize(m01_axi_arsize),.s_axi_arburst(m01_axi_arburst),.s_axi_arlock(m01_axi_arlock),
    .s_axi_arcache(m01_axi_arcache),.s_axi_arprot(m01_axi_arprot),.s_axi_arqos(m01_axi_arqos),
    .s_axi_arregion(m01_axi_arregion),.s_axi_arvalid(m01_axi_arvalid),.s_axi_arready(m01_axi_arready),
    .s_axi_rid(m01_axi_rid),.s_axi_rdata(m01_axi_rdata),.s_axi_rresp(m01_axi_rresp),
    .s_axi_rlast(m01_axi_rlast),.s_axi_rvalid(m01_axi_rvalid),.s_axi_rready(m01_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(2)) u_dummy02 (.clk(clk),.rst(rst),
    .s_axi_awid(m02_axi_awid),.s_axi_awaddr(m02_axi_awaddr),.s_axi_awlen(m02_axi_awlen),
    .s_axi_awsize(m02_axi_awsize),.s_axi_awburst(m02_axi_awburst),.s_axi_awlock(m02_axi_awlock),
    .s_axi_awcache(m02_axi_awcache),.s_axi_awprot(m02_axi_awprot),.s_axi_awqos(m02_axi_awqos),
    .s_axi_awregion(m02_axi_awregion),.s_axi_awvalid(m02_axi_awvalid),.s_axi_awready(m02_axi_awready),
    .s_axi_wdata(m02_axi_wdata),.s_axi_wstrb(m02_axi_wstrb),.s_axi_wlast(m02_axi_wlast),
    .s_axi_wvalid(m02_axi_wvalid),.s_axi_wready(m02_axi_wready),
    .s_axi_bid(m02_axi_bid),.s_axi_bresp(m02_axi_bresp),.s_axi_bvalid(m02_axi_bvalid),.s_axi_bready(m02_axi_bready),
    .s_axi_arid(m02_axi_arid),.s_axi_araddr(m02_axi_araddr),.s_axi_arlen(m02_axi_arlen),
    .s_axi_arsize(m02_axi_arsize),.s_axi_arburst(m02_axi_arburst),.s_axi_arlock(m02_axi_arlock),
    .s_axi_arcache(m02_axi_arcache),.s_axi_arprot(m02_axi_arprot),.s_axi_arqos(m02_axi_arqos),
    .s_axi_arregion(m02_axi_arregion),.s_axi_arvalid(m02_axi_arvalid),.s_axi_arready(m02_axi_arready),
    .s_axi_rid(m02_axi_rid),.s_axi_rdata(m02_axi_rdata),.s_axi_rresp(m02_axi_rresp),
    .s_axi_rlast(m02_axi_rlast),.s_axi_rvalid(m02_axi_rvalid),.s_axi_rready(m02_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(3)) u_dummy03 (.clk(clk),.rst(rst),
    .s_axi_awid(m03_axi_awid),.s_axi_awaddr(m03_axi_awaddr),.s_axi_awlen(m03_axi_awlen),
    .s_axi_awsize(m03_axi_awsize),.s_axi_awburst(m03_axi_awburst),.s_axi_awlock(m03_axi_awlock),
    .s_axi_awcache(m03_axi_awcache),.s_axi_awprot(m03_axi_awprot),.s_axi_awqos(m03_axi_awqos),
    .s_axi_awregion(m03_axi_awregion),.s_axi_awvalid(m03_axi_awvalid),.s_axi_awready(m03_axi_awready),
    .s_axi_wdata(m03_axi_wdata),.s_axi_wstrb(m03_axi_wstrb),.s_axi_wlast(m03_axi_wlast),
    .s_axi_wvalid(m03_axi_wvalid),.s_axi_wready(m03_axi_wready),
    .s_axi_bid(m03_axi_bid),.s_axi_bresp(m03_axi_bresp),.s_axi_bvalid(m03_axi_bvalid),.s_axi_bready(m03_axi_bready),
    .s_axi_arid(m03_axi_arid),.s_axi_araddr(m03_axi_araddr),.s_axi_arlen(m03_axi_arlen),
    .s_axi_arsize(m03_axi_arsize),.s_axi_arburst(m03_axi_arburst),.s_axi_arlock(m03_axi_arlock),
    .s_axi_arcache(m03_axi_arcache),.s_axi_arprot(m03_axi_arprot),.s_axi_arqos(m03_axi_arqos),
    .s_axi_arregion(m03_axi_arregion),.s_axi_arvalid(m03_axi_arvalid),.s_axi_arready(m03_axi_arready),
    .s_axi_rid(m03_axi_rid),.s_axi_rdata(m03_axi_rdata),.s_axi_rresp(m03_axi_rresp),
    .s_axi_rlast(m03_axi_rlast),.s_axi_rvalid(m03_axi_rvalid),.s_axi_rready(m03_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(4)) u_dummy04 (.clk(clk),.rst(rst),
    .s_axi_awid(m04_axi_awid),.s_axi_awaddr(m04_axi_awaddr),.s_axi_awlen(m04_axi_awlen),
    .s_axi_awsize(m04_axi_awsize),.s_axi_awburst(m04_axi_awburst),.s_axi_awlock(m04_axi_awlock),
    .s_axi_awcache(m04_axi_awcache),.s_axi_awprot(m04_axi_awprot),.s_axi_awqos(m04_axi_awqos),
    .s_axi_awregion(m04_axi_awregion),.s_axi_awvalid(m04_axi_awvalid),.s_axi_awready(m04_axi_awready),
    .s_axi_wdata(m04_axi_wdata),.s_axi_wstrb(m04_axi_wstrb),.s_axi_wlast(m04_axi_wlast),
    .s_axi_wvalid(m04_axi_wvalid),.s_axi_wready(m04_axi_wready),
    .s_axi_bid(m04_axi_bid),.s_axi_bresp(m04_axi_bresp),.s_axi_bvalid(m04_axi_bvalid),.s_axi_bready(m04_axi_bready),
    .s_axi_arid(m04_axi_arid),.s_axi_araddr(m04_axi_araddr),.s_axi_arlen(m04_axi_arlen),
    .s_axi_arsize(m04_axi_arsize),.s_axi_arburst(m04_axi_arburst),.s_axi_arlock(m04_axi_arlock),
    .s_axi_arcache(m04_axi_arcache),.s_axi_arprot(m04_axi_arprot),.s_axi_arqos(m04_axi_arqos),
    .s_axi_arregion(m04_axi_arregion),.s_axi_arvalid(m04_axi_arvalid),.s_axi_arready(m04_axi_arready),
    .s_axi_rid(m04_axi_rid),.s_axi_rdata(m04_axi_rdata),.s_axi_rresp(m04_axi_rresp),
    .s_axi_rlast(m04_axi_rlast),.s_axi_rvalid(m04_axi_rvalid),.s_axi_rready(m04_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(5)) u_dummy05 (.clk(clk),.rst(rst),
    .s_axi_awid(m05_axi_awid),.s_axi_awaddr(m05_axi_awaddr),.s_axi_awlen(m05_axi_awlen),
    .s_axi_awsize(m05_axi_awsize),.s_axi_awburst(m05_axi_awburst),.s_axi_awlock(m05_axi_awlock),
    .s_axi_awcache(m05_axi_awcache),.s_axi_awprot(m05_axi_awprot),.s_axi_awqos(m05_axi_awqos),
    .s_axi_awregion(m05_axi_awregion),.s_axi_awvalid(m05_axi_awvalid),.s_axi_awready(m05_axi_awready),
    .s_axi_wdata(m05_axi_wdata),.s_axi_wstrb(m05_axi_wstrb),.s_axi_wlast(m05_axi_wlast),
    .s_axi_wvalid(m05_axi_wvalid),.s_axi_wready(m05_axi_wready),
    .s_axi_bid(m05_axi_bid),.s_axi_bresp(m05_axi_bresp),.s_axi_bvalid(m05_axi_bvalid),.s_axi_bready(m05_axi_bready),
    .s_axi_arid(m05_axi_arid),.s_axi_araddr(m05_axi_araddr),.s_axi_arlen(m05_axi_arlen),
    .s_axi_arsize(m05_axi_arsize),.s_axi_arburst(m05_axi_arburst),.s_axi_arlock(m05_axi_arlock),
    .s_axi_arcache(m05_axi_arcache),.s_axi_arprot(m05_axi_arprot),.s_axi_arqos(m05_axi_arqos),
    .s_axi_arregion(m05_axi_arregion),.s_axi_arvalid(m05_axi_arvalid),.s_axi_arready(m05_axi_arready),
    .s_axi_rid(m05_axi_rid),.s_axi_rdata(m05_axi_rdata),.s_axi_rresp(m05_axi_rresp),
    .s_axi_rlast(m05_axi_rlast),.s_axi_rvalid(m05_axi_rvalid),.s_axi_rready(m05_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(6)) u_dummy06 (.clk(clk),.rst(rst),
    .s_axi_awid(m06_axi_awid),.s_axi_awaddr(m06_axi_awaddr),.s_axi_awlen(m06_axi_awlen),
    .s_axi_awsize(m06_axi_awsize),.s_axi_awburst(m06_axi_awburst),.s_axi_awlock(m06_axi_awlock),
    .s_axi_awcache(m06_axi_awcache),.s_axi_awprot(m06_axi_awprot),.s_axi_awqos(m06_axi_awqos),
    .s_axi_awregion(m06_axi_awregion),.s_axi_awvalid(m06_axi_awvalid),.s_axi_awready(m06_axi_awready),
    .s_axi_wdata(m06_axi_wdata),.s_axi_wstrb(m06_axi_wstrb),.s_axi_wlast(m06_axi_wlast),
    .s_axi_wvalid(m06_axi_wvalid),.s_axi_wready(m06_axi_wready),
    .s_axi_bid(m06_axi_bid),.s_axi_bresp(m06_axi_bresp),.s_axi_bvalid(m06_axi_bvalid),.s_axi_bready(m06_axi_bready),
    .s_axi_arid(m06_axi_arid),.s_axi_araddr(m06_axi_araddr),.s_axi_arlen(m06_axi_arlen),
    .s_axi_arsize(m06_axi_arsize),.s_axi_arburst(m06_axi_arburst),.s_axi_arlock(m06_axi_arlock),
    .s_axi_arcache(m06_axi_arcache),.s_axi_arprot(m06_axi_arprot),.s_axi_arqos(m06_axi_arqos),
    .s_axi_arregion(m06_axi_arregion),.s_axi_arvalid(m06_axi_arvalid),.s_axi_arready(m06_axi_arready),
    .s_axi_rid(m06_axi_rid),.s_axi_rdata(m06_axi_rdata),.s_axi_rresp(m06_axi_rresp),
    .s_axi_rlast(m06_axi_rlast),.s_axi_rvalid(m06_axi_rvalid),.s_axi_rready(m06_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(7)) u_dummy07 (.clk(clk),.rst(rst),
    .s_axi_awid(m07_axi_awid),.s_axi_awaddr(m07_axi_awaddr),.s_axi_awlen(m07_axi_awlen),
    .s_axi_awsize(m07_axi_awsize),.s_axi_awburst(m07_axi_awburst),.s_axi_awlock(m07_axi_awlock),
    .s_axi_awcache(m07_axi_awcache),.s_axi_awprot(m07_axi_awprot),.s_axi_awqos(m07_axi_awqos),
    .s_axi_awregion(m07_axi_awregion),.s_axi_awvalid(m07_axi_awvalid),.s_axi_awready(m07_axi_awready),
    .s_axi_wdata(m07_axi_wdata),.s_axi_wstrb(m07_axi_wstrb),.s_axi_wlast(m07_axi_wlast),
    .s_axi_wvalid(m07_axi_wvalid),.s_axi_wready(m07_axi_wready),
    .s_axi_bid(m07_axi_bid),.s_axi_bresp(m07_axi_bresp),.s_axi_bvalid(m07_axi_bvalid),.s_axi_bready(m07_axi_bready),
    .s_axi_arid(m07_axi_arid),.s_axi_araddr(m07_axi_araddr),.s_axi_arlen(m07_axi_arlen),
    .s_axi_arsize(m07_axi_arsize),.s_axi_arburst(m07_axi_arburst),.s_axi_arlock(m07_axi_arlock),
    .s_axi_arcache(m07_axi_arcache),.s_axi_arprot(m07_axi_arprot),.s_axi_arqos(m07_axi_arqos),
    .s_axi_arregion(m07_axi_arregion),.s_axi_arvalid(m07_axi_arvalid),.s_axi_arready(m07_axi_arready),
    .s_axi_rid(m07_axi_rid),.s_axi_rdata(m07_axi_rdata),.s_axi_rresp(m07_axi_rresp),
    .s_axi_rlast(m07_axi_rlast),.s_axi_rvalid(m07_axi_rvalid),.s_axi_rready(m07_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(8)) u_dummy08 (.clk(clk),.rst(rst),
    .s_axi_awid(m08_axi_awid),.s_axi_awaddr(m08_axi_awaddr),.s_axi_awlen(m08_axi_awlen),
    .s_axi_awsize(m08_axi_awsize),.s_axi_awburst(m08_axi_awburst),.s_axi_awlock(m08_axi_awlock),
    .s_axi_awcache(m08_axi_awcache),.s_axi_awprot(m08_axi_awprot),.s_axi_awqos(m08_axi_awqos),
    .s_axi_awregion(m08_axi_awregion),.s_axi_awvalid(m08_axi_awvalid),.s_axi_awready(m08_axi_awready),
    .s_axi_wdata(m08_axi_wdata),.s_axi_wstrb(m08_axi_wstrb),.s_axi_wlast(m08_axi_wlast),
    .s_axi_wvalid(m08_axi_wvalid),.s_axi_wready(m08_axi_wready),
    .s_axi_bid(m08_axi_bid),.s_axi_bresp(m08_axi_bresp),.s_axi_bvalid(m08_axi_bvalid),.s_axi_bready(m08_axi_bready),
    .s_axi_arid(m08_axi_arid),.s_axi_araddr(m08_axi_araddr),.s_axi_arlen(m08_axi_arlen),
    .s_axi_arsize(m08_axi_arsize),.s_axi_arburst(m08_axi_arburst),.s_axi_arlock(m08_axi_arlock),
    .s_axi_arcache(m08_axi_arcache),.s_axi_arprot(m08_axi_arprot),.s_axi_arqos(m08_axi_arqos),
    .s_axi_arregion(m08_axi_arregion),.s_axi_arvalid(m08_axi_arvalid),.s_axi_arready(m08_axi_arready),
    .s_axi_rid(m08_axi_rid),.s_axi_rdata(m08_axi_rdata),.s_axi_rresp(m08_axi_rresp),
    .s_axi_rlast(m08_axi_rlast),.s_axi_rvalid(m08_axi_rvalid),.s_axi_rready(m08_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(9)) u_dummy09 (.clk(clk),.rst(rst),
    .s_axi_awid(m09_axi_awid),.s_axi_awaddr(m09_axi_awaddr),.s_axi_awlen(m09_axi_awlen),
    .s_axi_awsize(m09_axi_awsize),.s_axi_awburst(m09_axi_awburst),.s_axi_awlock(m09_axi_awlock),
    .s_axi_awcache(m09_axi_awcache),.s_axi_awprot(m09_axi_awprot),.s_axi_awqos(m09_axi_awqos),
    .s_axi_awregion(m09_axi_awregion),.s_axi_awvalid(m09_axi_awvalid),.s_axi_awready(m09_axi_awready),
    .s_axi_wdata(m09_axi_wdata),.s_axi_wstrb(m09_axi_wstrb),.s_axi_wlast(m09_axi_wlast),
    .s_axi_wvalid(m09_axi_wvalid),.s_axi_wready(m09_axi_wready),
    .s_axi_bid(m09_axi_bid),.s_axi_bresp(m09_axi_bresp),.s_axi_bvalid(m09_axi_bvalid),.s_axi_bready(m09_axi_bready),
    .s_axi_arid(m09_axi_arid),.s_axi_araddr(m09_axi_araddr),.s_axi_arlen(m09_axi_arlen),
    .s_axi_arsize(m09_axi_arsize),.s_axi_arburst(m09_axi_arburst),.s_axi_arlock(m09_axi_arlock),
    .s_axi_arcache(m09_axi_arcache),.s_axi_arprot(m09_axi_arprot),.s_axi_arqos(m09_axi_arqos),
    .s_axi_arregion(m09_axi_arregion),.s_axi_arvalid(m09_axi_arvalid),.s_axi_arready(m09_axi_arready),
    .s_axi_rid(m09_axi_rid),.s_axi_rdata(m09_axi_rdata),.s_axi_rresp(m09_axi_rresp),
    .s_axi_rlast(m09_axi_rlast),.s_axi_rvalid(m09_axi_rvalid),.s_axi_rready(m09_axi_rready));

dummy_axi_slave #(.SLAVE_INDEX(10)) u_dummy10 (.clk(clk),.rst(rst),
    .s_axi_awid(m10_axi_awid),.s_axi_awaddr(m10_axi_awaddr),.s_axi_awlen(m10_axi_awlen),
    .s_axi_awsize(m10_axi_awsize),.s_axi_awburst(m10_axi_awburst),.s_axi_awlock(m10_axi_awlock),
    .s_axi_awcache(m10_axi_awcache),.s_axi_awprot(m10_axi_awprot),.s_axi_awqos(m10_axi_awqos),
    .s_axi_awregion(m10_axi_awregion),.s_axi_awvalid(m10_axi_awvalid),.s_axi_awready(m10_axi_awready),
    .s_axi_wdata(m10_axi_wdata),.s_axi_wstrb(m10_axi_wstrb),.s_axi_wlast(m10_axi_wlast),
    .s_axi_wvalid(m10_axi_wvalid),.s_axi_wready(m10_axi_wready),
    .s_axi_bid(m10_axi_bid),.s_axi_bresp(m10_axi_bresp),.s_axi_bvalid(m10_axi_bvalid),.s_axi_bready(m10_axi_bready),
    .s_axi_arid(m10_axi_arid),.s_axi_araddr(m10_axi_araddr),.s_axi_arlen(m10_axi_arlen),
    .s_axi_arsize(m10_axi_arsize),.s_axi_arburst(m10_axi_arburst),.s_axi_arlock(m10_axi_arlock),
    .s_axi_arcache(m10_axi_arcache),.s_axi_arprot(m10_axi_arprot),.s_axi_arqos(m10_axi_arqos),
    .s_axi_arregion(m10_axi_arregion),.s_axi_arvalid(m10_axi_arvalid),.s_axi_arready(m10_axi_arready),
    .s_axi_rid(m10_axi_rid),.s_axi_rdata(m10_axi_rdata),.s_axi_rresp(m10_axi_rresp),
    .s_axi_rlast(m10_axi_rlast),.s_axi_rvalid(m10_axi_rvalid),.s_axi_rready(m10_axi_rready));


// ──────────────────────────────────────────────────────────────────────────────
// Waveform helper signals
// These named regs make it easy to identify transactions in Verdi/waveform viewer.
// They carry a text label and transaction number so each beat is traceable.
// ──────────────────────────────────────────────────────────────────────────────

// Transaction phase marker  (visible as a bus in Verdi)
//  0=IDLE  1=AW  2=W  3=B  4=AR  5=R
reg [2:0] txn_phase = 3'd0;
localparam PH_IDLE = 3'd0, PH_AW = 3'd1, PH_W  = 3'd2,
           PH_B    = 3'd3, PH_AR = 3'd4, PH_R  = 3'd5;

// Current transaction number (1-5)
reg [3:0] txn_num = 4'd0;

// Pass/fail flag per transaction (1=pass, 2=fail, 3=timeout)
reg [1:0] txn_result = 2'd0;
localparam RES_IDLE    = 2'd0, RES_PASS = 2'd1,
           RES_FAIL    = 2'd2, RES_TO   = 2'd3;

// AXI Write path – convenience aliases (registered, 1-cycle delayed snapshots)
reg [ADDR_WIDTH-1:0] wr_addr_snap  = 0;
reg [DATA_WIDTH-1:0] wr_data_snap  = 0;
reg [1:0]            wr_bresp_snap = 0;

// AXI Read path – convenience aliases
reg [ADDR_WIDTH-1:0] rd_addr_snap  = 0;
reg [DATA_WIDTH-1:0] rd_data_snap  = 0;
reg [DATA_WIDTH-1:0] rd_exp_snap   = 0;
reg [1:0]            rd_rresp_snap = 0;

// Capture AW handshake
always @(posedge clk)
    if (s00_axi_awvalid && s00_axi_awready)
        wr_addr_snap <= s00_axi_awaddr;

// Capture W handshake
always @(posedge clk)
    if (s00_axi_wvalid && s00_axi_wready)
        wr_data_snap <= s00_axi_wdata;

// Capture B handshake
always @(posedge clk)
    if (s00_axi_bvalid && s00_axi_bready)
        wr_bresp_snap <= s00_axi_bresp;

// Capture AR handshake
always @(posedge clk)
    if (s00_axi_arvalid && s00_axi_arready)
        rd_addr_snap <= s00_axi_araddr;

// Capture R handshake
always @(posedge clk)
    if (s00_axi_rvalid && s00_axi_rready) begin
        rd_data_snap  <= s00_axi_rdata;
        rd_rresp_snap <= s00_axi_rresp;
    end

// Track AXI phase on s00 (write path)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        txn_phase <= PH_IDLE;
    end else begin
        if      (s00_axi_awvalid && s00_axi_awready) txn_phase <= PH_AW;
        else if (s00_axi_wvalid  && s00_axi_wready)  txn_phase <= PH_W;
        else if (s00_axi_bvalid  && s00_axi_bready)  txn_phase <= PH_B;
        else if (s00_axi_arvalid && s00_axi_arready) txn_phase <= PH_AR;
        else if (s00_axi_rvalid  && s00_axi_rready)  txn_phase <= PH_R;
        else if (!s00_axi_awvalid && !s00_axi_wvalid &&
                 !s00_axi_bvalid  && !s00_axi_arvalid &&
                 !s00_axi_rvalid)                    txn_phase <= PH_IDLE;
    end
end

// ──────────────────────────────────────────────────────────────────────────────
// Utility tasks: AXI4 single-beat write and read from s00
// ──────────────────────────────────────────────────────────────────────────────

// axi_write(addr, data) – drives AW+W channels, waits for B-channel OKAY
// axi_write(txn_id, addr, data)
task axi_write;
    input [3:0]            txn_id;
    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] data;
    integer timeout;
    begin
        txn_num    <= txn_id;
        txn_result <= RES_IDLE;
        rd_exp_snap <= 0;
        @(posedge clk);
        s00_axi_awaddr  <= addr;
        s00_axi_awid    <= 8'h00;
        s00_axi_awlen   <= 8'd0;
        s00_axi_awsize  <= 3'b010;
        s00_axi_awburst <= 2'b01;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= 4'hF;
        s00_axi_wlast   <= 1'b1;
        s00_axi_wvalid  <= 1'b1;

        timeout = 200;
        @(posedge clk);
        while (!s00_axi_awready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        s00_axi_awvalid <= 1'b0;

        timeout = 200;
        while (!s00_axi_wready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        s00_axi_wvalid <= 1'b0;
        s00_axi_wlast  <= 1'b0;

        s00_axi_bready <= 1'b1;
        timeout = 200;
        @(posedge clk);
        while (!s00_axi_bvalid && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        if (timeout == 0) begin
            txn_result <= RES_TO;
            $display("[ERROR] Write timeout: addr=0x%08h data=0x%08h", addr, data);
        end else if (s00_axi_bresp !== 2'b00) begin
            txn_result <= RES_FAIL;
            $display("[ERROR] Write BRESP!=OKAY: addr=0x%08h bresp=%b", addr, s00_axi_bresp);
        end else begin
            txn_result <= RES_PASS;
            $display("[PASS ] WRITE addr=0x%08h  data=0x%08h  BRESP=OKAY", addr, data);
        end
        @(posedge clk);
        s00_axi_bready <= 1'b1;
    end
endtask

// axi_read(txn_id, addr, exp_data)
task axi_read;
    input [3:0]            txn_id;
    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] exp_data;
    reg   [DATA_WIDTH-1:0] got_data;
    integer timeout;
    begin
        txn_num     <= txn_id;
        txn_result  <= RES_IDLE;
        rd_exp_snap <= exp_data;
        @(posedge clk);
        s00_axi_araddr  <= addr;
        s00_axi_arid    <= 8'h00;
        s00_axi_arlen   <= 8'd0;
        s00_axi_arsize  <= 3'b010;
        s00_axi_arburst <= 2'b01;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;

        timeout = 200;
        @(posedge clk);
        while (!s00_axi_arready && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        s00_axi_arvalid <= 1'b0;

        timeout = 200;
        while (!s00_axi_rvalid && timeout > 0) begin
            timeout = timeout - 1;
            @(posedge clk);
        end
        got_data = s00_axi_rdata;

        if (timeout == 0) begin
            txn_result <= RES_TO;
            $display("[ERROR] Read timeout: addr=0x%08h", addr);
        end else if (s00_axi_rresp !== 2'b00) begin
            txn_result <= RES_FAIL;
            $display("[ERROR] Read RRESP!=OKAY: addr=0x%08h rresp=%b", addr, s00_axi_rresp);
        end else if (got_data[7:0] !== exp_data[7:0]) begin
            txn_result <= RES_FAIL;
            $display("[FAIL ] READ  addr=0x%08h  got=0x%02h  exp=0x%02h  MISMATCH",
                     addr, got_data[7:0], exp_data[7:0]);
        end else begin
            txn_result <= RES_PASS;
            $display("[PASS ] READ  addr=0x%08h  data=0x%02h  RRESP=OKAY", addr, got_data[7:0]);
        end
        @(posedge clk);
        s00_axi_rready <= 1'b1;
    end
endtask

// ──────────────────────────────────────────────────────────────────────────────
// Stimulus
// ──────────────────────────────────────────────────────────────────────────────
initial begin
   // $dumpfile("tb_axi_interconnect_2x11.vcd");
    //$dumpvars(0, tb_axi_interconnect_2x11);

    $fsdbDumpfile("dump.fsdb");  // Record the waveform
    $fsdbDumpvars("+all");       // Dump all parameters/signals
    $fsdbDumpSVA();              // Dump SVA information
    $fsdbDumpMDA();              // Dump multidimensional arrays

    // Hold reset for 10 cycles
    rst = 1'b1;
    repeat (10) @(posedge clk);
    rst = 1'b0;
    repeat (5)  @(posedge clk);

    $display("=================================================================");
    $display("  AXI Interconnect 2x11 Testbench");
    $display("  M00 base=0x0000_0000 (i2c), M01=0x0100_0000 .. M10=0x0A00_0000");
    $display("  3 Writes + 2 Reads to i2c_master_top (m00)");
    $display("=================================================================");

    // ── Write 1: PRER_LO = 0x63 (prescale low byte) ─────────────────────
    $display("\n[TEST] Write 1 - PRER_LO @ 0x%08h = 0x63", ADDR_PRER_LO);
    axi_write(4'd1, ADDR_PRER_LO, 32'h0000_0063);

    // ── Write 2: PRER_HI = 0x00 (prescale high byte) ────────────────────
    $display("\n[TEST] Write 2 - PRER_HI @ 0x%08h = 0x00", ADDR_PRER_HI);
    axi_write(4'd2, ADDR_PRER_HI, 32'h0000_0000);

    // ── Write 3: CTR = 0x80 (enable core) ───────────────────────────────
    $display("\n[TEST] Write 3 - CTR @ 0x%08h = 0x80 (core enable)", ADDR_CTR);
    axi_write(4'd3, ADDR_CTR,     32'h0000_0080);

    repeat (5) @(posedge clk);

    // ── Read 1: PRER_LO – expect 0x63 ───────────────────────────────────
    $display("\n[TEST] Read 1 - PRER_LO @ 0x%08h (expect 0x63)", ADDR_PRER_LO);
    axi_read (4'd4, ADDR_PRER_LO, 32'h0000_0063);

    // ── Read 2: CTR – expect 0x80 ────────────────────────────────────────
    $display("\n[TEST] Read 2 - CTR @ 0x%08h (expect 0x80)", ADDR_CTR);
    axi_read (4'd5, ADDR_CTR,     32'h0000_0080);

    repeat (10) @(posedge clk);

    $display("\n=================================================================");
    $display("  Simulation complete.");
    $display("=================================================================");
    $finish;
end

// Watchdog: kill simulation if it runs too long
initial begin
    #500000;
    $display("[WATCHDOG] Simulation exceeded time limit – aborting.");
    $finish;
end

endmodule

`default_nettype wire
