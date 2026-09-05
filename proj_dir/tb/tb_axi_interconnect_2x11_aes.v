// =============================================================================
// tb_axi_interconnect_2x11_aes.v
//
// Integrated testbench for axi_interconnect_wrap_2x11 with:
//   m00 → axi_to_wb_bridge → i2c_master_top   (Wishbone slave)
//   m01 → axi_to_aes_bridge → aes_cipher_top + aes_inv_cipher_top
//   m02–m10 → dummy_axi_slave
//
// AXI master s00 issues all transactions (s01 is tied idle).
//
// Address map (16 MB windows, 2^24 bytes each):
//   m00 base = 0x0000_0000   I2C master
//   m01 base = 0x0100_0000   AES bridge
//   m02 base = 0x0200_0000   dummy
//   ...
//   m10 base = 0x0A00_0000   dummy
//
// Test sequence:
//   1. Configure I2C prescaler and enable core (via m00).
//   2. Readback I2C registers (via m00).
//   3. Program AES key and plaintext, trigger encrypt, poll done, read result
//      (all via m01).
//   4. Feed ciphertext back as input, trigger decrypt, poll done, check
//      plaintext recovers.
//   5. Dummy slave read (via m02) – verifies routing to m02.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module tb_axi_interconnect_2x11_aes;

// ──────────────────────────────────────────────────────────────────────────────
// Parameters
// ──────────────────────────────────────────────────────────────────────────────
localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam STRB_WIDTH = DATA_WIDTH/8;
localparam ID_WIDTH   = 8;

localparam CLK_PERIOD = 10; // 100 MHz

// ── Address map ────────────────────────────────────────────────────────────
localparam [ADDR_WIDTH-1:0] I2C_BASE  = 32'h0000_0000;
localparam [ADDR_WIDTH-1:0] AES_BASE  = 32'h0100_0000;
localparam [ADDR_WIDTH-1:0] DUM2_BASE = 32'h0200_0000;

// I2C register offsets (AXI byte address = I2C_BASE + wb_reg*4)
localparam [ADDR_WIDTH-1:0] ADDR_PRER_LO = I2C_BASE + 32'h00;  // wb 0
localparam [ADDR_WIDTH-1:0] ADDR_PRER_HI = I2C_BASE + 32'h04;  // wb 1
localparam [ADDR_WIDTH-1:0] ADDR_CTR     = I2C_BASE + 32'h08;  // wb 2
localparam [ADDR_WIDTH-1:0] ADDR_TXR     = I2C_BASE + 32'h0C;  // wb 3
localparam [ADDR_WIDTH-1:0] ADDR_SR      = I2C_BASE + 32'h10;  // wb 4

// AES bridge register offsets (AXI byte address = AES_BASE + offset)
localparam [ADDR_WIDTH-1:0] AES_CTRL    = AES_BASE + 32'h00;
localparam [ADDR_WIDTH-1:0] AES_STATUS  = AES_BASE + 32'h04;
localparam [ADDR_WIDTH-1:0] AES_KEY0    = AES_BASE + 32'h08;
localparam [ADDR_WIDTH-1:0] AES_KEY1    = AES_BASE + 32'h0C;
localparam [ADDR_WIDTH-1:0] AES_KEY2    = AES_BASE + 32'h10;
localparam [ADDR_WIDTH-1:0] AES_KEY3    = AES_BASE + 32'h14;
localparam [ADDR_WIDTH-1:0] AES_TXIN0   = AES_BASE + 32'h18;
localparam [ADDR_WIDTH-1:0] AES_TXIN1   = AES_BASE + 32'h1C;
localparam [ADDR_WIDTH-1:0] AES_TXIN2   = AES_BASE + 32'h20;
localparam [ADDR_WIDTH-1:0] AES_TXIN3   = AES_BASE + 32'h24;
localparam [ADDR_WIDTH-1:0] AES_TXOUT0  = AES_BASE + 32'h28;
localparam [ADDR_WIDTH-1:0] AES_TXOUT1  = AES_BASE + 32'h2C;
localparam [ADDR_WIDTH-1:0] AES_TXOUT2  = AES_BASE + 32'h30;
localparam [ADDR_WIDTH-1:0] AES_TXOUT3  = AES_BASE + 32'h34;

// ──────────────────────────────────────────────────────────────────────────────
// Clock / reset
// ──────────────────────────────────────────────────────────────────────────────
reg clk = 1'b0;
reg rst = 1'b1;   // active-high for AXI interconnect / bridges

always #(CLK_PERIOD/2) clk = ~clk;

// ──────────────────────────────────────────────────────────────────────────────
// s00 AXI master stimulus signals
// ──────────────────────────────────────────────────────────────────────────────
// Write address channel
reg  [ID_WIDTH-1:0]   s00_axi_awid    = 0;
reg  [ADDR_WIDTH-1:0] s00_axi_awaddr  = 0;
reg  [7:0]            s00_axi_awlen   = 0;
reg  [2:0]            s00_axi_awsize  = 3'b010;
reg  [1:0]            s00_axi_awburst = 2'b01;
reg                   s00_axi_awlock  = 0;
reg  [3:0]            s00_axi_awcache = 0;
reg  [2:0]            s00_axi_awprot  = 0;
reg  [3:0]            s00_axi_awqos   = 0;
reg                   s00_axi_awvalid = 0;
wire                  s00_axi_awready;

// Write data channel
reg  [DATA_WIDTH-1:0] s00_axi_wdata  = 0;
reg  [STRB_WIDTH-1:0] s00_axi_wstrb  = 4'hf;
reg                   s00_axi_wlast  = 1;
reg                   s00_axi_wvalid = 0;
wire                  s00_axi_wready;

// Write response channel
wire [ID_WIDTH-1:0]   s00_axi_bid;
wire [1:0]            s00_axi_bresp;
wire                  s00_axi_bvalid;
reg                   s00_axi_bready = 1;

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
wire                  s01_axi_awready;
wire                  s01_axi_wready;
wire [ID_WIDTH-1:0]   s01_axi_bid;
wire [1:0]            s01_axi_bresp;
wire                  s01_axi_bvalid;
wire                  s01_axi_arready;
wire [ID_WIDTH-1:0]   s01_axi_rid;
wire [DATA_WIDTH-1:0] s01_axi_rdata;
wire [1:0]            s01_axi_rresp;
wire                  s01_axi_rlast;
wire                  s01_axi_rvalid;

// ──────────────────────────────────────────────────────────────────────────────
// m00 interconnect → axi_to_wb_bridge wires
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
wire [0:0]            m00_axi_awuser;
wire                  m00_axi_awvalid;
wire                  m00_axi_awready;
wire [DATA_WIDTH-1:0] m00_axi_wdata;
wire [STRB_WIDTH-1:0] m00_axi_wstrb;
wire                  m00_axi_wlast;
wire [0:0]            m00_axi_wuser;
wire                  m00_axi_wvalid;
wire                  m00_axi_wready;
wire [ID_WIDTH-1:0]   m00_axi_bid;
wire [1:0]            m00_axi_bresp;
wire [0:0]            m00_axi_buser;
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
wire [0:0]            m00_axi_aruser;
wire                  m00_axi_arvalid;
wire                  m00_axi_arready;
wire [ID_WIDTH-1:0]   m00_axi_rid;
wire [DATA_WIDTH-1:0] m00_axi_rdata;
wire [1:0]            m00_axi_rresp;
wire                  m00_axi_rlast;
wire [0:0]            m00_axi_ruser;
wire                  m00_axi_rvalid;
wire                  m00_axi_rready;

// ──────────────────────────────────────────────────────────────────────────────
// m01 interconnect → axi_to_aes_bridge wires
// ──────────────────────────────────────────────────────────────────────────────
wire [ID_WIDTH-1:0]   m01_axi_awid;
wire [ADDR_WIDTH-1:0] m01_axi_awaddr;
wire [7:0]            m01_axi_awlen;
wire [2:0]            m01_axi_awsize;
wire [1:0]            m01_axi_awburst;
wire                  m01_axi_awlock;
wire [3:0]            m01_axi_awcache;
wire [2:0]            m01_axi_awprot;
wire [3:0]            m01_axi_awqos;
wire [3:0]            m01_axi_awregion;
wire [0:0]            m01_axi_awuser;
wire                  m01_axi_awvalid;
wire                  m01_axi_awready;
wire [DATA_WIDTH-1:0] m01_axi_wdata;
wire [STRB_WIDTH-1:0] m01_axi_wstrb;
wire                  m01_axi_wlast;
wire [0:0]            m01_axi_wuser;
wire                  m01_axi_wvalid;
wire                  m01_axi_wready;
wire [ID_WIDTH-1:0]   m01_axi_bid;
wire [1:0]            m01_axi_bresp;
wire [0:0]            m01_axi_buser;
wire                  m01_axi_bvalid;
wire                  m01_axi_bready;
wire [ID_WIDTH-1:0]   m01_axi_arid;
wire [ADDR_WIDTH-1:0] m01_axi_araddr;
wire [7:0]            m01_axi_arlen;
wire [2:0]            m01_axi_arsize;
wire [1:0]            m01_axi_arburst;
wire                  m01_axi_arlock;
wire [3:0]            m01_axi_arcache;
wire [2:0]            m01_axi_arprot;
wire [3:0]            m01_axi_arqos;
wire [3:0]            m01_axi_arregion;
wire [0:0]            m01_axi_aruser;
wire                  m01_axi_arvalid;
wire                  m01_axi_arready;
wire [ID_WIDTH-1:0]   m01_axi_rid;
wire [DATA_WIDTH-1:0] m01_axi_rdata;
wire [1:0]            m01_axi_rresp;
wire                  m01_axi_rlast;
wire [0:0]            m01_axi_ruser;
wire                  m01_axi_rvalid;
wire                  m01_axi_rready;

// ──────────────────────────────────────────────────────────────────────────────
// m02–m10 dummy slave wires (grouped as arrays for compactness)
// ──────────────────────────────────────────────────────────────────────────────
// We declare them individually to match the non-parameterised interconnect port names

`define DUMMY_WIRES(N) \
  wire [ID_WIDTH-1:0]   m``N``_axi_awid; \
  wire [ADDR_WIDTH-1:0] m``N``_axi_awaddr; \
  wire [7:0]            m``N``_axi_awlen; \
  wire [2:0]            m``N``_axi_awsize; \
  wire [1:0]            m``N``_axi_awburst; \
  wire                  m``N``_axi_awlock; \
  wire [3:0]            m``N``_axi_awcache; \
  wire [2:0]            m``N``_axi_awprot; \
  wire [3:0]            m``N``_axi_awqos; \
  wire [3:0]            m``N``_axi_awregion; \
  wire [0:0]            m``N``_axi_awuser; \
  wire                  m``N``_axi_awvalid; \
  wire                  m``N``_axi_awready; \
  wire [DATA_WIDTH-1:0] m``N``_axi_wdata; \
  wire [STRB_WIDTH-1:0] m``N``_axi_wstrb; \
  wire                  m``N``_axi_wlast; \
  wire [0:0]            m``N``_axi_wuser; \
  wire                  m``N``_axi_wvalid; \
  wire                  m``N``_axi_wready; \
  wire [ID_WIDTH-1:0]   m``N``_axi_bid; \
  wire [1:0]            m``N``_axi_bresp; \
  wire [0:0]            m``N``_axi_buser; \
  wire                  m``N``_axi_bvalid; \
  wire                  m``N``_axi_bready; \
  wire [ID_WIDTH-1:0]   m``N``_axi_arid; \
  wire [ADDR_WIDTH-1:0] m``N``_axi_araddr; \
  wire [7:0]            m``N``_axi_arlen; \
  wire [2:0]            m``N``_axi_arsize; \
  wire [1:0]            m``N``_axi_arburst; \
  wire                  m``N``_axi_arlock; \
  wire [3:0]            m``N``_axi_arcache; \
  wire [2:0]            m``N``_axi_arprot; \
  wire [3:0]            m``N``_axi_arqos; \
  wire [3:0]            m``N``_axi_arregion; \
  wire [0:0]            m``N``_axi_aruser; \
  wire                  m``N``_axi_arvalid; \
  wire                  m``N``_axi_arready; \
  wire [ID_WIDTH-1:0]   m``N``_axi_rid; \
  wire [DATA_WIDTH-1:0] m``N``_axi_rdata; \
  wire [1:0]            m``N``_axi_rresp; \
  wire                  m``N``_axi_rlast; \
  wire [0:0]            m``N``_axi_ruser; \
  wire                  m``N``_axi_rvalid; \
  wire                  m``N``_axi_rready;

`DUMMY_WIRES(02)
`DUMMY_WIRES(03)
`DUMMY_WIRES(04)
`DUMMY_WIRES(05)
`DUMMY_WIRES(06)
`DUMMY_WIRES(07)
`DUMMY_WIRES(08)
`DUMMY_WIRES(09)
`DUMMY_WIRES(10)

// ──────────────────────────────────────────────────────────────────────────────
// I2C bus (tri-state handled by pad simulation)
// ──────────────────────────────────────────────────────────────────────────────
wire scl_pad_i, scl_pad_o, scl_padoen_o;
wire sda_pad_i, sda_pad_o, sda_padoen_o;

// Tie I2C bus high (no external device, we just test register access)
assign scl_pad_i = scl_padoen_o ? 1'b1 : scl_pad_o;
assign sda_pad_i = sda_padoen_o ? 1'b1 : sda_pad_o;

// Wishbone bus between bridge and I2C master
wire [2:0] wb_adr;
wire [7:0] wb_dat_o_bridge;  // bridge → i2c
wire [7:0] wb_dat_i_bridge;  // i2c   → bridge
wire       wb_we, wb_stb, wb_cyc, wb_ack;

// ──────────────────────────────────────────────────────────────────────────────
// DUT instantiations
// ──────────────────────────────────────────────────────────────────────────────

// ── AXI Interconnect ─────────────────────────────────────────────────────────
axi_interconnect_wrap_2x11 #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .ID_WIDTH   (ID_WIDTH),
    // m00 = I2C master
    .M00_BASE_ADDR  (32'h0000_0000),
    .M00_ADDR_WIDTH ({1{32'd24}}),
    // m01 = AES bridge
    .M01_BASE_ADDR  (32'h0100_0000),
    .M01_ADDR_WIDTH ({1{32'd24}}),
    // m02–m10 = dummy slaves
    .M02_BASE_ADDR  (32'h0200_0000),  .M02_ADDR_WIDTH ({1{32'd24}}),
    .M03_BASE_ADDR  (32'h0300_0000),  .M03_ADDR_WIDTH ({1{32'd24}}),
    .M04_BASE_ADDR  (32'h0400_0000),  .M04_ADDR_WIDTH ({1{32'd24}}),
    .M05_BASE_ADDR  (32'h0500_0000),  .M05_ADDR_WIDTH ({1{32'd24}}),
    .M06_BASE_ADDR  (32'h0600_0000),  .M06_ADDR_WIDTH ({1{32'd24}}),
    .M07_BASE_ADDR  (32'h0700_0000),  .M07_ADDR_WIDTH ({1{32'd24}}),
    .M08_BASE_ADDR  (32'h0800_0000),  .M08_ADDR_WIDTH ({1{32'd24}}),
    .M09_BASE_ADDR  (32'h0900_0000),  .M09_ADDR_WIDTH ({1{32'd24}}),
    .M10_BASE_ADDR  (32'h0A00_0000),  .M10_ADDR_WIDTH ({1{32'd24}})
) u_interconnect (
    .clk  (clk),
    .rst  (rst),

    // ── s00 master ────────────────────────────────────────────────────
    .s00_axi_awid    (s00_axi_awid),
    .s00_axi_awaddr  (s00_axi_awaddr),
    .s00_axi_awlen   (s00_axi_awlen),
    .s00_axi_awsize  (s00_axi_awsize),
    .s00_axi_awburst (s00_axi_awburst),
    .s00_axi_awlock  (s00_axi_awlock),
    .s00_axi_awcache (s00_axi_awcache),
    .s00_axi_awprot  (s00_axi_awprot),
    .s00_axi_awqos   (s00_axi_awqos),
    .s00_axi_awuser  (1'b0),
    .s00_axi_awvalid (s00_axi_awvalid),
    .s00_axi_awready (s00_axi_awready),
    .s00_axi_wdata   (s00_axi_wdata),
    .s00_axi_wstrb   (s00_axi_wstrb),
    .s00_axi_wlast   (s00_axi_wlast),
    .s00_axi_wuser   (1'b0),
    .s00_axi_wvalid  (s00_axi_wvalid),
    .s00_axi_wready  (s00_axi_wready),
    .s00_axi_bid     (s00_axi_bid),
    .s00_axi_bresp   (s00_axi_bresp),
    .s00_axi_bvalid  (s00_axi_bvalid),
    .s00_axi_bready  (s00_axi_bready),
    .s00_axi_arid    (s00_axi_arid),
    .s00_axi_araddr  (s00_axi_araddr),
    .s00_axi_arlen   (s00_axi_arlen),
    .s00_axi_arsize  (s00_axi_arsize),
    .s00_axi_arburst (s00_axi_arburst),
    .s00_axi_arlock  (s00_axi_arlock),
    .s00_axi_arcache (s00_axi_arcache),
    .s00_axi_arprot  (s00_axi_arprot),
    .s00_axi_arqos   (s00_axi_arqos),
    .s00_axi_aruser  (1'b0),
    .s00_axi_arvalid (s00_axi_arvalid),
    .s00_axi_arready (s00_axi_arready),
    .s00_axi_rid     (s00_axi_rid),
    .s00_axi_rdata   (s00_axi_rdata),
    .s00_axi_rresp   (s00_axi_rresp),
    .s00_axi_rlast   (s00_axi_rlast),
    .s00_axi_rvalid  (s00_axi_rvalid),
    .s00_axi_rready  (s00_axi_rready),

    // ── s01 master – tied off ─────────────────────────────────────────
    .s01_axi_awid    ({ID_WIDTH{1'b0}}),
    .s01_axi_awaddr  ({ADDR_WIDTH{1'b0}}),
    .s01_axi_awlen   (8'b0),
    .s01_axi_awsize  (3'b010),
    .s01_axi_awburst (2'b01),
    .s01_axi_awlock  (1'b0),
    .s01_axi_awcache (4'b0),
    .s01_axi_awprot  (3'b0),
    .s01_axi_awqos   (4'b0),
    .s01_axi_awuser  (1'b0),
    .s01_axi_awvalid (1'b0),
    .s01_axi_awready (s01_axi_awready),
    .s01_axi_wdata   ({DATA_WIDTH{1'b0}}),
    .s01_axi_wstrb   ({STRB_WIDTH{1'b0}}),
    .s01_axi_wlast   (1'b0),
    .s01_axi_wuser   (1'b0),
    .s01_axi_wvalid  (1'b0),
    .s01_axi_wready  (s01_axi_wready),
    .s01_axi_bid     (s01_axi_bid),
    .s01_axi_bresp   (s01_axi_bresp),
    .s01_axi_bvalid  (s01_axi_bvalid),
    .s01_axi_bready  (1'b1),
    .s01_axi_arid    ({ID_WIDTH{1'b0}}),
    .s01_axi_araddr  ({ADDR_WIDTH{1'b0}}),
    .s01_axi_arlen   (8'b0),
    .s01_axi_arsize  (3'b010),
    .s01_axi_arburst (2'b01),
    .s01_axi_arlock  (1'b0),
    .s01_axi_arcache (4'b0),
    .s01_axi_arprot  (3'b0),
    .s01_axi_arqos   (4'b0),
    .s01_axi_aruser  (1'b0),
    .s01_axi_arvalid (1'b0),
    .s01_axi_arready (s01_axi_arready),
    .s01_axi_rid     (s01_axi_rid),
    .s01_axi_rdata   (s01_axi_rdata),
    .s01_axi_rresp   (s01_axi_rresp),
    .s01_axi_rlast   (s01_axi_rlast),
    .s01_axi_rvalid  (s01_axi_rvalid),
    .s01_axi_rready  (1'b1),

    // ── m00 – I2C bridge ─────────────────────────────────────────────
    .m00_axi_awid     (m00_axi_awid),
    .m00_axi_awaddr   (m00_axi_awaddr),
    .m00_axi_awlen    (m00_axi_awlen),
    .m00_axi_awsize   (m00_axi_awsize),
    .m00_axi_awburst  (m00_axi_awburst),
    .m00_axi_awlock   (m00_axi_awlock),
    .m00_axi_awcache  (m00_axi_awcache),
    .m00_axi_awprot   (m00_axi_awprot),
    .m00_axi_awqos    (m00_axi_awqos),
    .m00_axi_awregion (m00_axi_awregion),
    .m00_axi_awuser   (m00_axi_awuser),
    .m00_axi_awvalid  (m00_axi_awvalid),
    .m00_axi_awready  (m00_axi_awready),
    .m00_axi_wdata    (m00_axi_wdata),
    .m00_axi_wstrb    (m00_axi_wstrb),
    .m00_axi_wlast    (m00_axi_wlast),
    .m00_axi_wuser    (m00_axi_wuser),
    .m00_axi_wvalid   (m00_axi_wvalid),
    .m00_axi_wready   (m00_axi_wready),
    .m00_axi_bid      (m00_axi_bid),
    .m00_axi_bresp    (m00_axi_bresp),
    .m00_axi_buser    (m00_axi_buser),
    .m00_axi_bvalid   (m00_axi_bvalid),
    .m00_axi_bready   (m00_axi_bready),
    .m00_axi_arid     (m00_axi_arid),
    .m00_axi_araddr   (m00_axi_araddr),
    .m00_axi_arlen    (m00_axi_arlen),
    .m00_axi_arsize   (m00_axi_arsize),
    .m00_axi_arburst  (m00_axi_arburst),
    .m00_axi_arlock   (m00_axi_arlock),
    .m00_axi_arcache  (m00_axi_arcache),
    .m00_axi_arprot   (m00_axi_arprot),
    .m00_axi_arqos    (m00_axi_arqos),
    .m00_axi_arregion (m00_axi_arregion),
    .m00_axi_aruser   (m00_axi_aruser),
    .m00_axi_arvalid  (m00_axi_arvalid),
    .m00_axi_arready  (m00_axi_arready),
    .m00_axi_rid      (m00_axi_rid),
    .m00_axi_rdata    (m00_axi_rdata),
    .m00_axi_rresp    (m00_axi_rresp),
    .m00_axi_rlast    (m00_axi_rlast),
    .m00_axi_ruser    (m00_axi_ruser),
    .m00_axi_rvalid   (m00_axi_rvalid),
    .m00_axi_rready   (m00_axi_rready),

    // ── m01 – AES bridge ─────────────────────────────────────────────
    .m01_axi_awid     (m01_axi_awid),
    .m01_axi_awaddr   (m01_axi_awaddr),
    .m01_axi_awlen    (m01_axi_awlen),
    .m01_axi_awsize   (m01_axi_awsize),
    .m01_axi_awburst  (m01_axi_awburst),
    .m01_axi_awlock   (m01_axi_awlock),
    .m01_axi_awcache  (m01_axi_awcache),
    .m01_axi_awprot   (m01_axi_awprot),
    .m01_axi_awqos    (m01_axi_awqos),
    .m01_axi_awregion (m01_axi_awregion),
    .m01_axi_awuser   (m01_axi_awuser),
    .m01_axi_awvalid  (m01_axi_awvalid),
    .m01_axi_awready  (m01_axi_awready),
    .m01_axi_wdata    (m01_axi_wdata),
    .m01_axi_wstrb    (m01_axi_wstrb),
    .m01_axi_wlast    (m01_axi_wlast),
    .m01_axi_wuser    (m01_axi_wuser),
    .m01_axi_wvalid   (m01_axi_wvalid),
    .m01_axi_wready   (m01_axi_wready),
    .m01_axi_bid      (m01_axi_bid),
    .m01_axi_bresp    (m01_axi_bresp),
    .m01_axi_buser    (m01_axi_buser),
    .m01_axi_bvalid   (m01_axi_bvalid),
    .m01_axi_bready   (m01_axi_bready),
    .m01_axi_arid     (m01_axi_arid),
    .m01_axi_araddr   (m01_axi_araddr),
    .m01_axi_arlen    (m01_axi_arlen),
    .m01_axi_arsize   (m01_axi_arsize),
    .m01_axi_arburst  (m01_axi_arburst),
    .m01_axi_arlock   (m01_axi_arlock),
    .m01_axi_arcache  (m01_axi_arcache),
    .m01_axi_arprot   (m01_axi_arprot),
    .m01_axi_arqos    (m01_axi_arqos),
    .m01_axi_arregion (m01_axi_arregion),
    .m01_axi_aruser   (m01_axi_aruser),
    .m01_axi_arvalid  (m01_axi_arvalid),
    .m01_axi_arready  (m01_axi_arready),
    .m01_axi_rid      (m01_axi_rid),
    .m01_axi_rdata    (m01_axi_rdata),
    .m01_axi_rresp    (m01_axi_rresp),
    .m01_axi_rlast    (m01_axi_rlast),
    .m01_axi_ruser    (m01_axi_ruser),
    .m01_axi_rvalid   (m01_axi_rvalid),
    .m01_axi_rready   (m01_axi_rready),

    // ── m02–m10 – dummy slaves (wires passed through) ─────────────────
    .m02_axi_awid(m02_axi_awid), .m02_axi_awaddr(m02_axi_awaddr),
    .m02_axi_awlen(m02_axi_awlen), .m02_axi_awsize(m02_axi_awsize),
    .m02_axi_awburst(m02_axi_awburst), .m02_axi_awlock(m02_axi_awlock),
    .m02_axi_awcache(m02_axi_awcache), .m02_axi_awprot(m02_axi_awprot),
    .m02_axi_awqos(m02_axi_awqos), .m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser(m02_axi_awuser), .m02_axi_awvalid(m02_axi_awvalid),
    .m02_axi_awready(m02_axi_awready), .m02_axi_wdata(m02_axi_wdata),
    .m02_axi_wstrb(m02_axi_wstrb), .m02_axi_wlast(m02_axi_wlast),
    .m02_axi_wuser(m02_axi_wuser), .m02_axi_wvalid(m02_axi_wvalid),
    .m02_axi_wready(m02_axi_wready), .m02_axi_bid(m02_axi_bid),
    .m02_axi_bresp(m02_axi_bresp), .m02_axi_buser(m02_axi_buser),
    .m02_axi_bvalid(m02_axi_bvalid), .m02_axi_bready(m02_axi_bready),
    .m02_axi_arid(m02_axi_arid), .m02_axi_araddr(m02_axi_araddr),
    .m02_axi_arlen(m02_axi_arlen), .m02_axi_arsize(m02_axi_arsize),
    .m02_axi_arburst(m02_axi_arburst), .m02_axi_arlock(m02_axi_arlock),
    .m02_axi_arcache(m02_axi_arcache), .m02_axi_arprot(m02_axi_arprot),
    .m02_axi_arqos(m02_axi_arqos), .m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser(m02_axi_aruser), .m02_axi_arvalid(m02_axi_arvalid),
    .m02_axi_arready(m02_axi_arready), .m02_axi_rid(m02_axi_rid),
    .m02_axi_rdata(m02_axi_rdata), .m02_axi_rresp(m02_axi_rresp),
    .m02_axi_rlast(m02_axi_rlast), .m02_axi_ruser(m02_axi_ruser),
    .m02_axi_rvalid(m02_axi_rvalid), .m02_axi_rready(m02_axi_rready),

    .m03_axi_awid(m03_axi_awid), .m03_axi_awaddr(m03_axi_awaddr),
    .m03_axi_awlen(m03_axi_awlen), .m03_axi_awsize(m03_axi_awsize),
    .m03_axi_awburst(m03_axi_awburst), .m03_axi_awlock(m03_axi_awlock),
    .m03_axi_awcache(m03_axi_awcache), .m03_axi_awprot(m03_axi_awprot),
    .m03_axi_awqos(m03_axi_awqos), .m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser(m03_axi_awuser), .m03_axi_awvalid(m03_axi_awvalid),
    .m03_axi_awready(m03_axi_awready), .m03_axi_wdata(m03_axi_wdata),
    .m03_axi_wstrb(m03_axi_wstrb), .m03_axi_wlast(m03_axi_wlast),
    .m03_axi_wuser(m03_axi_wuser), .m03_axi_wvalid(m03_axi_wvalid),
    .m03_axi_wready(m03_axi_wready), .m03_axi_bid(m03_axi_bid),
    .m03_axi_bresp(m03_axi_bresp), .m03_axi_buser(m03_axi_buser),
    .m03_axi_bvalid(m03_axi_bvalid), .m03_axi_bready(m03_axi_bready),
    .m03_axi_arid(m03_axi_arid), .m03_axi_araddr(m03_axi_araddr),
    .m03_axi_arlen(m03_axi_arlen), .m03_axi_arsize(m03_axi_arsize),
    .m03_axi_arburst(m03_axi_arburst), .m03_axi_arlock(m03_axi_arlock),
    .m03_axi_arcache(m03_axi_arcache), .m03_axi_arprot(m03_axi_arprot),
    .m03_axi_arqos(m03_axi_arqos), .m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser(m03_axi_aruser), .m03_axi_arvalid(m03_axi_arvalid),
    .m03_axi_arready(m03_axi_arready), .m03_axi_rid(m03_axi_rid),
    .m03_axi_rdata(m03_axi_rdata), .m03_axi_rresp(m03_axi_rresp),
    .m03_axi_rlast(m03_axi_rlast), .m03_axi_ruser(m03_axi_ruser),
    .m03_axi_rvalid(m03_axi_rvalid), .m03_axi_rready(m03_axi_rready),

    .m04_axi_awid(m04_axi_awid), .m04_axi_awaddr(m04_axi_awaddr),
    .m04_axi_awlen(m04_axi_awlen), .m04_axi_awsize(m04_axi_awsize),
    .m04_axi_awburst(m04_axi_awburst), .m04_axi_awlock(m04_axi_awlock),
    .m04_axi_awcache(m04_axi_awcache), .m04_axi_awprot(m04_axi_awprot),
    .m04_axi_awqos(m04_axi_awqos), .m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser(m04_axi_awuser), .m04_axi_awvalid(m04_axi_awvalid),
    .m04_axi_awready(m04_axi_awready), .m04_axi_wdata(m04_axi_wdata),
    .m04_axi_wstrb(m04_axi_wstrb), .m04_axi_wlast(m04_axi_wlast),
    .m04_axi_wuser(m04_axi_wuser), .m04_axi_wvalid(m04_axi_wvalid),
    .m04_axi_wready(m04_axi_wready), .m04_axi_bid(m04_axi_bid),
    .m04_axi_bresp(m04_axi_bresp), .m04_axi_buser(m04_axi_buser),
    .m04_axi_bvalid(m04_axi_bvalid), .m04_axi_bready(m04_axi_bready),
    .m04_axi_arid(m04_axi_arid), .m04_axi_araddr(m04_axi_araddr),
    .m04_axi_arlen(m04_axi_arlen), .m04_axi_arsize(m04_axi_arsize),
    .m04_axi_arburst(m04_axi_arburst), .m04_axi_arlock(m04_axi_arlock),
    .m04_axi_arcache(m04_axi_arcache), .m04_axi_arprot(m04_axi_arprot),
    .m04_axi_arqos(m04_axi_arqos), .m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser(m04_axi_aruser), .m04_axi_arvalid(m04_axi_arvalid),
    .m04_axi_arready(m04_axi_arready), .m04_axi_rid(m04_axi_rid),
    .m04_axi_rdata(m04_axi_rdata), .m04_axi_rresp(m04_axi_rresp),
    .m04_axi_rlast(m04_axi_rlast), .m04_axi_ruser(m04_axi_ruser),
    .m04_axi_rvalid(m04_axi_rvalid), .m04_axi_rready(m04_axi_rready),

    .m05_axi_awid(m05_axi_awid), .m05_axi_awaddr(m05_axi_awaddr),
    .m05_axi_awlen(m05_axi_awlen), .m05_axi_awsize(m05_axi_awsize),
    .m05_axi_awburst(m05_axi_awburst), .m05_axi_awlock(m05_axi_awlock),
    .m05_axi_awcache(m05_axi_awcache), .m05_axi_awprot(m05_axi_awprot),
    .m05_axi_awqos(m05_axi_awqos), .m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser(m05_axi_awuser), .m05_axi_awvalid(m05_axi_awvalid),
    .m05_axi_awready(m05_axi_awready), .m05_axi_wdata(m05_axi_wdata),
    .m05_axi_wstrb(m05_axi_wstrb), .m05_axi_wlast(m05_axi_wlast),
    .m05_axi_wuser(m05_axi_wuser), .m05_axi_wvalid(m05_axi_wvalid),
    .m05_axi_wready(m05_axi_wready), .m05_axi_bid(m05_axi_bid),
    .m05_axi_bresp(m05_axi_bresp), .m05_axi_buser(m05_axi_buser),
    .m05_axi_bvalid(m05_axi_bvalid), .m05_axi_bready(m05_axi_bready),
    .m05_axi_arid(m05_axi_arid), .m05_axi_araddr(m05_axi_araddr),
    .m05_axi_arlen(m05_axi_arlen), .m05_axi_arsize(m05_axi_arsize),
    .m05_axi_arburst(m05_axi_arburst), .m05_axi_arlock(m05_axi_arlock),
    .m05_axi_arcache(m05_axi_arcache), .m05_axi_arprot(m05_axi_arprot),
    .m05_axi_arqos(m05_axi_arqos), .m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser(m05_axi_aruser), .m05_axi_arvalid(m05_axi_arvalid),
    .m05_axi_arready(m05_axi_arready), .m05_axi_rid(m05_axi_rid),
    .m05_axi_rdata(m05_axi_rdata), .m05_axi_rresp(m05_axi_rresp),
    .m05_axi_rlast(m05_axi_rlast), .m05_axi_ruser(m05_axi_ruser),
    .m05_axi_rvalid(m05_axi_rvalid), .m05_axi_rready(m05_axi_rready),

    .m06_axi_awid(m06_axi_awid), .m06_axi_awaddr(m06_axi_awaddr),
    .m06_axi_awlen(m06_axi_awlen), .m06_axi_awsize(m06_axi_awsize),
    .m06_axi_awburst(m06_axi_awburst), .m06_axi_awlock(m06_axi_awlock),
    .m06_axi_awcache(m06_axi_awcache), .m06_axi_awprot(m06_axi_awprot),
    .m06_axi_awqos(m06_axi_awqos), .m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser(m06_axi_awuser), .m06_axi_awvalid(m06_axi_awvalid),
    .m06_axi_awready(m06_axi_awready), .m06_axi_wdata(m06_axi_wdata),
    .m06_axi_wstrb(m06_axi_wstrb), .m06_axi_wlast(m06_axi_wlast),
    .m06_axi_wuser(m06_axi_wuser), .m06_axi_wvalid(m06_axi_wvalid),
    .m06_axi_wready(m06_axi_wready), .m06_axi_bid(m06_axi_bid),
    .m06_axi_bresp(m06_axi_bresp), .m06_axi_buser(m06_axi_buser),
    .m06_axi_bvalid(m06_axi_bvalid), .m06_axi_bready(m06_axi_bready),
    .m06_axi_arid(m06_axi_arid), .m06_axi_araddr(m06_axi_araddr),
    .m06_axi_arlen(m06_axi_arlen), .m06_axi_arsize(m06_axi_arsize),
    .m06_axi_arburst(m06_axi_arburst), .m06_axi_arlock(m06_axi_arlock),
    .m06_axi_arcache(m06_axi_arcache), .m06_axi_arprot(m06_axi_arprot),
    .m06_axi_arqos(m06_axi_arqos), .m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser(m06_axi_aruser), .m06_axi_arvalid(m06_axi_arvalid),
    .m06_axi_arready(m06_axi_arready), .m06_axi_rid(m06_axi_rid),
    .m06_axi_rdata(m06_axi_rdata), .m06_axi_rresp(m06_axi_rresp),
    .m06_axi_rlast(m06_axi_rlast), .m06_axi_ruser(m06_axi_ruser),
    .m06_axi_rvalid(m06_axi_rvalid), .m06_axi_rready(m06_axi_rready),

    .m07_axi_awid(m07_axi_awid), .m07_axi_awaddr(m07_axi_awaddr),
    .m07_axi_awlen(m07_axi_awlen), .m07_axi_awsize(m07_axi_awsize),
    .m07_axi_awburst(m07_axi_awburst), .m07_axi_awlock(m07_axi_awlock),
    .m07_axi_awcache(m07_axi_awcache), .m07_axi_awprot(m07_axi_awprot),
    .m07_axi_awqos(m07_axi_awqos), .m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser(m07_axi_awuser), .m07_axi_awvalid(m07_axi_awvalid),
    .m07_axi_awready(m07_axi_awready), .m07_axi_wdata(m07_axi_wdata),
    .m07_axi_wstrb(m07_axi_wstrb), .m07_axi_wlast(m07_axi_wlast),
    .m07_axi_wuser(m07_axi_wuser), .m07_axi_wvalid(m07_axi_wvalid),
    .m07_axi_wready(m07_axi_wready), .m07_axi_bid(m07_axi_bid),
    .m07_axi_bresp(m07_axi_bresp), .m07_axi_buser(m07_axi_buser),
    .m07_axi_bvalid(m07_axi_bvalid), .m07_axi_bready(m07_axi_bready),
    .m07_axi_arid(m07_axi_arid), .m07_axi_araddr(m07_axi_araddr),
    .m07_axi_arlen(m07_axi_arlen), .m07_axi_arsize(m07_axi_arsize),
    .m07_axi_arburst(m07_axi_arburst), .m07_axi_arlock(m07_axi_arlock),
    .m07_axi_arcache(m07_axi_arcache), .m07_axi_arprot(m07_axi_arprot),
    .m07_axi_arqos(m07_axi_arqos), .m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser(m07_axi_aruser), .m07_axi_arvalid(m07_axi_arvalid),
    .m07_axi_arready(m07_axi_arready), .m07_axi_rid(m07_axi_rid),
    .m07_axi_rdata(m07_axi_rdata), .m07_axi_rresp(m07_axi_rresp),
    .m07_axi_rlast(m07_axi_rlast), .m07_axi_ruser(m07_axi_ruser),
    .m07_axi_rvalid(m07_axi_rvalid), .m07_axi_rready(m07_axi_rready),

    .m08_axi_awid(m08_axi_awid), .m08_axi_awaddr(m08_axi_awaddr),
    .m08_axi_awlen(m08_axi_awlen), .m08_axi_awsize(m08_axi_awsize),
    .m08_axi_awburst(m08_axi_awburst), .m08_axi_awlock(m08_axi_awlock),
    .m08_axi_awcache(m08_axi_awcache), .m08_axi_awprot(m08_axi_awprot),
    .m08_axi_awqos(m08_axi_awqos), .m08_axi_awregion(m08_axi_awregion),
    .m08_axi_awuser(m08_axi_awuser), .m08_axi_awvalid(m08_axi_awvalid),
    .m08_axi_awready(m08_axi_awready), .m08_axi_wdata(m08_axi_wdata),
    .m08_axi_wstrb(m08_axi_wstrb), .m08_axi_wlast(m08_axi_wlast),
    .m08_axi_wuser(m08_axi_wuser), .m08_axi_wvalid(m08_axi_wvalid),
    .m08_axi_wready(m08_axi_wready), .m08_axi_bid(m08_axi_bid),
    .m08_axi_bresp(m08_axi_bresp), .m08_axi_buser(m08_axi_buser),
    .m08_axi_bvalid(m08_axi_bvalid), .m08_axi_bready(m08_axi_bready),
    .m08_axi_arid(m08_axi_arid), .m08_axi_araddr(m08_axi_araddr),
    .m08_axi_arlen(m08_axi_arlen), .m08_axi_arsize(m08_axi_arsize),
    .m08_axi_arburst(m08_axi_arburst), .m08_axi_arlock(m08_axi_arlock),
    .m08_axi_arcache(m08_axi_arcache), .m08_axi_arprot(m08_axi_arprot),
    .m08_axi_arqos(m08_axi_arqos), .m08_axi_arregion(m08_axi_arregion),
    .m08_axi_aruser(m08_axi_aruser), .m08_axi_arvalid(m08_axi_arvalid),
    .m08_axi_arready(m08_axi_arready), .m08_axi_rid(m08_axi_rid),
    .m08_axi_rdata(m08_axi_rdata), .m08_axi_rresp(m08_axi_rresp),
    .m08_axi_rlast(m08_axi_rlast), .m08_axi_ruser(m08_axi_ruser),
    .m08_axi_rvalid(m08_axi_rvalid), .m08_axi_rready(m08_axi_rready),

    .m09_axi_awid(m09_axi_awid), .m09_axi_awaddr(m09_axi_awaddr),
    .m09_axi_awlen(m09_axi_awlen), .m09_axi_awsize(m09_axi_awsize),
    .m09_axi_awburst(m09_axi_awburst), .m09_axi_awlock(m09_axi_awlock),
    .m09_axi_awcache(m09_axi_awcache), .m09_axi_awprot(m09_axi_awprot),
    .m09_axi_awqos(m09_axi_awqos), .m09_axi_awregion(m09_axi_awregion),
    .m09_axi_awuser(m09_axi_awuser), .m09_axi_awvalid(m09_axi_awvalid),
    .m09_axi_awready(m09_axi_awready), .m09_axi_wdata(m09_axi_wdata),
    .m09_axi_wstrb(m09_axi_wstrb), .m09_axi_wlast(m09_axi_wlast),
    .m09_axi_wuser(m09_axi_wuser), .m09_axi_wvalid(m09_axi_wvalid),
    .m09_axi_wready(m09_axi_wready), .m09_axi_bid(m09_axi_bid),
    .m09_axi_bresp(m09_axi_bresp), .m09_axi_buser(m09_axi_buser),
    .m09_axi_bvalid(m09_axi_bvalid), .m09_axi_bready(m09_axi_bready),
    .m09_axi_arid(m09_axi_arid), .m09_axi_araddr(m09_axi_araddr),
    .m09_axi_arlen(m09_axi_arlen), .m09_axi_arsize(m09_axi_arsize),
    .m09_axi_arburst(m09_axi_arburst), .m09_axi_arlock(m09_axi_arlock),
    .m09_axi_arcache(m09_axi_arcache), .m09_axi_arprot(m09_axi_arprot),
    .m09_axi_arqos(m09_axi_arqos), .m09_axi_arregion(m09_axi_arregion),
    .m09_axi_aruser(m09_axi_aruser), .m09_axi_arvalid(m09_axi_arvalid),
    .m09_axi_arready(m09_axi_arready), .m09_axi_rid(m09_axi_rid),
    .m09_axi_rdata(m09_axi_rdata), .m09_axi_rresp(m09_axi_rresp),
    .m09_axi_rlast(m09_axi_rlast), .m09_axi_ruser(m09_axi_ruser),
    .m09_axi_rvalid(m09_axi_rvalid), .m09_axi_rready(m09_axi_rready),

    .m10_axi_awid(m10_axi_awid), .m10_axi_awaddr(m10_axi_awaddr),
    .m10_axi_awlen(m10_axi_awlen), .m10_axi_awsize(m10_axi_awsize),
    .m10_axi_awburst(m10_axi_awburst), .m10_axi_awlock(m10_axi_awlock),
    .m10_axi_awcache(m10_axi_awcache), .m10_axi_awprot(m10_axi_awprot),
    .m10_axi_awqos(m10_axi_awqos), .m10_axi_awregion(m10_axi_awregion),
    .m10_axi_awuser(m10_axi_awuser), .m10_axi_awvalid(m10_axi_awvalid),
    .m10_axi_awready(m10_axi_awready), .m10_axi_wdata(m10_axi_wdata),
    .m10_axi_wstrb(m10_axi_wstrb), .m10_axi_wlast(m10_axi_wlast),
    .m10_axi_wuser(m10_axi_wuser), .m10_axi_wvalid(m10_axi_wvalid),
    .m10_axi_wready(m10_axi_wready), .m10_axi_bid(m10_axi_bid),
    .m10_axi_bresp(m10_axi_bresp), .m10_axi_buser(m10_axi_buser),
    .m10_axi_bvalid(m10_axi_bvalid), .m10_axi_bready(m10_axi_bready),
    .m10_axi_arid(m10_axi_arid), .m10_axi_araddr(m10_axi_araddr),
    .m10_axi_arlen(m10_axi_arlen), .m10_axi_arsize(m10_axi_arsize),
    .m10_axi_arburst(m10_axi_arburst), .m10_axi_arlock(m10_axi_arlock),
    .m10_axi_arcache(m10_axi_arcache), .m10_axi_arprot(m10_axi_arprot),
    .m10_axi_arqos(m10_axi_arqos), .m10_axi_arregion(m10_axi_arregion),
    .m10_axi_aruser(m10_axi_aruser), .m10_axi_arvalid(m10_axi_arvalid),
    .m10_axi_arready(m10_axi_arready), .m10_axi_rid(m10_axi_rid),
    .m10_axi_rdata(m10_axi_rdata), .m10_axi_rresp(m10_axi_rresp),
    .m10_axi_rlast(m10_axi_rlast), .m10_axi_ruser(m10_axi_ruser),
    .m10_axi_rvalid(m10_axi_rvalid), .m10_axi_rready(m10_axi_rready)
);

// ── AXI-to-Wishbone bridge (m00 → I2C master) ─────────────────────────────
axi_to_wb_bridge #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .ID_WIDTH   (ID_WIDTH)
) u_wb_bridge (
    .clk             (clk),
    .rst             (rst),
    .s_axi_awid      (m00_axi_awid),
    .s_axi_awaddr    (m00_axi_awaddr),
    .s_axi_awlen     (m00_axi_awlen),
    .s_axi_awsize    (m00_axi_awsize),
    .s_axi_awburst   (m00_axi_awburst),
    .s_axi_awlock    (m00_axi_awlock),
    .s_axi_awcache   (m00_axi_awcache),
    .s_axi_awprot    (m00_axi_awprot),
    .s_axi_awqos     (m00_axi_awqos),
    .s_axi_awregion  (m00_axi_awregion),
    .s_axi_awvalid   (m00_axi_awvalid),
    .s_axi_awready   (m00_axi_awready),
    .s_axi_wdata     (m00_axi_wdata),
    .s_axi_wstrb     (m00_axi_wstrb),
    .s_axi_wlast     (m00_axi_wlast),
    .s_axi_wvalid    (m00_axi_wvalid),
    .s_axi_wready    (m00_axi_wready),
    .s_axi_bid       (m00_axi_bid),
    .s_axi_bresp     (m00_axi_bresp),
    .s_axi_bvalid    (m00_axi_bvalid),
    .s_axi_bready    (m00_axi_bready),
    .s_axi_arid      (m00_axi_arid),
    .s_axi_araddr    (m00_axi_araddr),
    .s_axi_arlen     (m00_axi_arlen),
    .s_axi_arsize    (m00_axi_arsize),
    .s_axi_arburst   (m00_axi_arburst),
    .s_axi_arlock    (m00_axi_arlock),
    .s_axi_arcache   (m00_axi_arcache),
    .s_axi_arprot    (m00_axi_arprot),
    .s_axi_arqos     (m00_axi_arqos),
    .s_axi_arregion  (m00_axi_arregion),
    .s_axi_arvalid   (m00_axi_arvalid),
    .s_axi_arready   (m00_axi_arready),
    .s_axi_rid       (m00_axi_rid),
    .s_axi_rdata     (m00_axi_rdata),
    .s_axi_rresp     (m00_axi_rresp),
    .s_axi_rlast     (m00_axi_rlast),
    .s_axi_rvalid    (m00_axi_rvalid),
    .s_axi_rready    (m00_axi_rready),
    .wb_adr_o        (wb_adr),
    .wb_dat_o        (wb_dat_o_bridge),
    .wb_dat_i        (wb_dat_i_bridge),
    .wb_we_o         (wb_we),
    .wb_stb_o        (wb_stb),
    .wb_cyc_o        (wb_cyc),
    .wb_ack_i        (wb_ack)
);

// ── I2C master top (Wishbone slave) ──────────────────────────────────────
i2c_master_top u_i2c (
    .wb_clk_i      (clk),
    .wb_rst_i      (rst),    // active-high synchronous
    .arst_i        (1'b1),   // tie high (not used; wb_rst_i takes precedence)
    .wb_adr_i      (wb_adr),
    .wb_dat_i      (wb_dat_o_bridge),
    .wb_dat_o      (wb_dat_i_bridge),
    .wb_we_i       (wb_we),
    .wb_stb_i      (wb_stb),
    .wb_cyc_i      (wb_cyc),
    .wb_ack_o      (wb_ack),
    .wb_inta_o     (),       // interrupt – unused in this TB
    .scl_pad_i     (scl_pad_i),
    .scl_pad_o     (scl_pad_o),
    .scl_padoen_o  (scl_padoen_o),
    .sda_pad_i     (sda_pad_i),
    .sda_pad_o     (sda_pad_o),
    .sda_padoen_o  (sda_padoen_o)
);

// ── AXI-to-AES bridge (m01 → AES cores) ──────────────────────────────────
axi_to_aes_bridge #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .ID_WIDTH   (ID_WIDTH)
) u_aes_bridge (
    .clk             (clk),
    .rst             (rst),
    .s_axi_awid      (m01_axi_awid),
    .s_axi_awaddr    (m01_axi_awaddr),
    .s_axi_awlen     (m01_axi_awlen),
    .s_axi_awsize    (m01_axi_awsize),
    .s_axi_awburst   (m01_axi_awburst),
    .s_axi_awlock    (m01_axi_awlock),
    .s_axi_awcache   (m01_axi_awcache),
    .s_axi_awprot    (m01_axi_awprot),
    .s_axi_awqos     (m01_axi_awqos),
    .s_axi_awregion  (m01_axi_awregion),
    .s_axi_awvalid   (m01_axi_awvalid),
    .s_axi_awready   (m01_axi_awready),
    .s_axi_wdata     (m01_axi_wdata),
    .s_axi_wstrb     (m01_axi_wstrb),
    .s_axi_wlast     (m01_axi_wlast),
    .s_axi_wvalid    (m01_axi_wvalid),
    .s_axi_wready    (m01_axi_wready),
    .s_axi_bid       (m01_axi_bid),
    .s_axi_bresp     (m01_axi_bresp),
    .s_axi_bvalid    (m01_axi_bvalid),
    .s_axi_bready    (m01_axi_bready),
    .s_axi_arid      (m01_axi_arid),
    .s_axi_araddr    (m01_axi_araddr),
    .s_axi_arlen     (m01_axi_arlen),
    .s_axi_arsize    (m01_axi_arsize),
    .s_axi_arburst   (m01_axi_arburst),
    .s_axi_arlock    (m01_axi_arlock),
    .s_axi_arcache   (m01_axi_arcache),
    .s_axi_arprot    (m01_axi_arprot),
    .s_axi_arqos     (m01_axi_arqos),
    .s_axi_arregion  (m01_axi_arregion),
    .s_axi_arvalid   (m01_axi_arvalid),
    .s_axi_arready   (m01_axi_arready),
    .s_axi_rid       (m01_axi_rid),
    .s_axi_rdata     (m01_axi_rdata),
    .s_axi_rresp     (m01_axi_rresp),
    .s_axi_rlast     (m01_axi_rlast),
    .s_axi_rvalid    (m01_axi_rvalid),
    .s_axi_rready    (m01_axi_rready)
);

// ── Dummy slaves m02–m10 ──────────────────────────────────────────────────
`define DUMMY_INST(N, IDX) \
  dummy_axi_slave #(.SLAVE_INDEX(IDX)) u_dummy_``N ( \
    .clk(clk), .rst(rst), \
    .s_axi_awid(m``N``_axi_awid), .s_axi_awaddr(m``N``_axi_awaddr), \
    .s_axi_awlen(m``N``_axi_awlen), .s_axi_awsize(m``N``_axi_awsize), \
    .s_axi_awburst(m``N``_axi_awburst), .s_axi_awlock(m``N``_axi_awlock), \
    .s_axi_awcache(m``N``_axi_awcache), .s_axi_awprot(m``N``_axi_awprot), \
    .s_axi_awqos(m``N``_axi_awqos), .s_axi_awregion(m``N``_axi_awregion), \
    .s_axi_awvalid(m``N``_axi_awvalid), .s_axi_awready(m``N``_axi_awready), \
    .s_axi_wdata(m``N``_axi_wdata), .s_axi_wstrb(m``N``_axi_wstrb), \
    .s_axi_wlast(m``N``_axi_wlast), .s_axi_wvalid(m``N``_axi_wvalid), \
    .s_axi_wready(m``N``_axi_wready), \
    .s_axi_bid(m``N``_axi_bid), .s_axi_bresp(m``N``_axi_bresp), \
    .s_axi_bvalid(m``N``_axi_bvalid), .s_axi_bready(m``N``_axi_bready), \
    .s_axi_arid(m``N``_axi_arid), .s_axi_araddr(m``N``_axi_araddr), \
    .s_axi_arlen(m``N``_axi_arlen), .s_axi_arsize(m``N``_axi_arsize), \
    .s_axi_arburst(m``N``_axi_arburst), .s_axi_arlock(m``N``_axi_arlock), \
    .s_axi_arcache(m``N``_axi_arcache), .s_axi_arprot(m``N``_axi_arprot), \
    .s_axi_arqos(m``N``_axi_arqos), .s_axi_arregion(m``N``_axi_arregion), \
    .s_axi_arvalid(m``N``_axi_arvalid), .s_axi_arready(m``N``_axi_arready), \
    .s_axi_rid(m``N``_axi_rid), .s_axi_rdata(m``N``_axi_rdata), \
    .s_axi_rresp(m``N``_axi_rresp), .s_axi_rlast(m``N``_axi_rlast), \
    .s_axi_rvalid(m``N``_axi_rvalid), .s_axi_rready(m``N``_axi_rready) \
  );

`DUMMY_INST(02, 2)
`DUMMY_INST(03, 3)
`DUMMY_INST(04, 4)
`DUMMY_INST(05, 5)
`DUMMY_INST(06, 6)
`DUMMY_INST(07, 7)
`DUMMY_INST(08, 8)
`DUMMY_INST(09, 9)
`DUMMY_INST(10, 10)

// ──────────────────────────────────────────────────────────────────────────────
// Waveform dump
// ──────────────────────────────────────────────────────────────────────────────
`ifdef FSDB
initial begin
    $fsdbDumpfile("tb_axi_interconnect_2x11_aes.fsdb");
    $fsdbDumpvars(0, tb_axi_interconnect_2x11_aes);
end
`elsif VCD
initial begin
    $dumpfile("tb_axi_interconnect_2x11_aes.vcd");
    $dumpvars(0, tb_axi_interconnect_2x11_aes);
end
`endif

// ──────────────────────────────────────────────────────────────────────────────
// AXI helper tasks
// ──────────────────────────────────────────────────────────────────────────────

// Single-beat AXI4 write
task axi_write;
    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] data;
begin
    @(posedge clk); #1;
    // Drive AW and W simultaneously
    s00_axi_awaddr  <= addr;
    s00_axi_awvalid <= 1'b1;
    s00_axi_wdata   <= data;
    s00_axi_wstrb   <= 4'hf;
    s00_axi_wlast   <= 1'b1;
    s00_axi_wvalid  <= 1'b1;

    // Wait for AW handshake
    @(posedge clk);
    while (!s00_axi_awready) @(posedge clk);
    #1; s00_axi_awvalid <= 1'b0;

    // Wait for W handshake
    while (!s00_axi_wready) @(posedge clk);
    #1; s00_axi_wvalid <= 1'b0;

    // Wait for B handshake
    s00_axi_bready <= 1'b1;
    while (!s00_axi_bvalid) @(posedge clk);
    @(posedge clk);
    s00_axi_bready <= 1'b0;
end
endtask

// Single-beat AXI4 read
reg [DATA_WIDTH-1:0] rd_data;
task axi_read;
    input [ADDR_WIDTH-1:0] addr;
    output [DATA_WIDTH-1:0] data;
begin
    @(posedge clk); #1;
    s00_axi_araddr  <= addr;
    s00_axi_arvalid <= 1'b1;

    // Wait for AR handshake
    @(posedge clk);
    while (!s00_axi_arready) @(posedge clk);
    #1; s00_axi_arvalid <= 1'b0;

    // Wait for R handshake
    s00_axi_rready <= 1'b1;
    while (!s00_axi_rvalid) @(posedge clk);
    data = s00_axi_rdata;
    @(posedge clk);
    s00_axi_rready <= 1'b0;
end
endtask

// AES polling: poll STATUS register bit until set (with timeout)
task aes_poll_done;
    input bit_sel;        // 0 = enc_done, 1 = dec_done
    output timed_out;
    integer cnt;
begin
    cnt = 0; timed_out = 1'b0;
    begin : poll_loop
        forever begin
            axi_read(AES_STATUS, rd_data);
            if (rd_data[bit_sel]) disable poll_loop;
            cnt = cnt + 1;
            if (cnt > 200) begin
                timed_out = 1'b1;
                disable poll_loop;
            end
        end
    end
end
endtask

// ──────────────────────────────────────────────────────────────────────────────
// Test counters
// ──────────────────────────────────────────────────────────────────────────────
integer pass_cnt, fail_cnt;
reg [DATA_WIDTH-1:0] rd0, rd1, rd2, rd3;
reg [127:0] aes_out;
reg tmo;

// NIST FIPS-197 Appendix B vectors
localparam [127:0] NIST_KEY   = 128'h2b7e151628aed2a6abf7158809cf4f3c;
localparam [127:0] NIST_PLAIN = 128'h3243f6a8885a308d313198a2e0370734;
localparam [127:0] NIST_CIPH  = 128'h3925841d02dc09fbdc118597196a0b32;

// ──────────────────────────────────────────────────────────────────────────────
// Stimulus
// ──────────────────────────────────────────────────────────────────────────────
initial begin
    pass_cnt = 0; fail_cnt = 0;

    // ── Reset ────────────────────────────────────────────────────────────
    rst = 1'b1;
    repeat(8) @(posedge clk);
    rst = 1'b0;
    repeat(4) @(posedge clk);

    $display("=====================================================");
    $display(" Integrated SoC Interconnect Testbench");
    $display(" m00=I2C  m01=AES  m02-m10=dummy");
    $display("=====================================================");

    // ════════════════════════════════════════════════════════════════════
    // Section 1: I2C master register access (via m00)
    // ════════════════════════════════════════════════════════════════════
    $display("\n--- Section 1: I2C Register Access (m00) ---");

    // Write PRER_LO = 0x63 (set prescaler low byte)
    axi_write(ADDR_PRER_LO, 32'h00000063);
    $display("  Wrote PRER_LO = 0x63");

    // Write PRER_HI = 0x00
    axi_write(ADDR_PRER_HI, 32'h00000000);
    $display("  Wrote PRER_HI = 0x00");

    // Write CTR = 0x80 (enable core)
    axi_write(ADDR_CTR, 32'h00000080);
    $display("  Wrote CTR = 0x80 (core enable)");

    // Readback PRER_LO
    axi_read(ADDR_PRER_LO, rd_data);
    if (rd_data[7:0] === 8'h63) begin
        $display("  [PASS] PRER_LO readback = 0x%02h", rd_data[7:0]);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] PRER_LO: expected=0x63, got=0x%02h", rd_data[7:0]);
        fail_cnt = fail_cnt + 1;
    end

    // Readback CTR
    axi_read(ADDR_CTR, rd_data);
    if (rd_data[7:0] === 8'h80) begin
        $display("  [PASS] CTR readback = 0x%02h", rd_data[7:0]);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] CTR: expected=0x80, got=0x%02h", rd_data[7:0]);
        fail_cnt = fail_cnt + 1;
    end

    // ════════════════════════════════════════════════════════════════════
    // Section 2: AES Encryption via m01 (NIST FIPS-197 Appendix B)
    // ════════════════════════════════════════════════════════════════════
    $display("\n--- Section 2: AES Encryption via m01 ---");
    $display("  Key   = %032h", NIST_KEY);
    $display("  Plain = %032h", NIST_PLAIN);
    $display("  Exp.  = %032h", NIST_CIPH);

    // Write KEY
    axi_write(AES_KEY0, NIST_KEY[127:96]);
    axi_write(AES_KEY1, NIST_KEY[ 95:64]);
    axi_write(AES_KEY2, NIST_KEY[ 63:32]);
    axi_write(AES_KEY3, NIST_KEY[ 31: 0]);

    // Write TXIN (plaintext)
    axi_write(AES_TXIN0, NIST_PLAIN[127:96]);
    axi_write(AES_TXIN1, NIST_PLAIN[ 95:64]);
    axi_write(AES_TXIN2, NIST_PLAIN[ 63:32]);
    axi_write(AES_TXIN3, NIST_PLAIN[ 31: 0]);

    // Trigger encrypt: CTRL[0] = 1
    axi_write(AES_CTRL, 32'h0000_0001);
    $display("  AES encrypt triggered");

    // Poll STATUS[0] for enc_done
    aes_poll_done(0, tmo);
    if (tmo) begin
        $display("  [FAIL] AES encrypt timeout");
        fail_cnt = fail_cnt + 1;
    end else begin
        // Read result
        axi_read(AES_TXOUT0, rd0);
        axi_read(AES_TXOUT1, rd1);
        axi_read(AES_TXOUT2, rd2);
        axi_read(AES_TXOUT3, rd3);
        aes_out = {rd0, rd1, rd2, rd3};
        $display("  AES ciphertext = %032h", aes_out);
        if (aes_out === NIST_CIPH) begin
            $display("  [PASS] AES encryption matches NIST vector");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] AES encryption mismatch");
            $display("         expected=%032h", NIST_CIPH);
            $display("         got     =%032h", aes_out);
            fail_cnt = fail_cnt + 1;
        end
    end

    // ════════════════════════════════════════════════════════════════════
    // Section 3: AES Round-trip check via m01
    //
    // The aes_inv_cipher_top is auto-chained after aes_cipher_top:
    //   inv_cipher.kld  = enc_ld  (key schedule loaded same cycle)
    //   inv_cipher.ld   = enc_done (auto-triggered when cipher finishes)
    //   inv_cipher.text_in = enc_text_out
    //
    // So we just poll STATUS[1] (dec_done_sticky) — no need to write
    // anything; it fires automatically ~11 cycles after enc_done.
    // TXOUT will update to dec_text_out (should equal original plaintext).
    // ════════════════════════════════════════════════════════════════════
    $display("\n--- Section 3: AES Round-trip (auto dec after enc) ---");
    $display("  Polling STATUS[1] for inv_cipher done (auto-chained)...");

    // Poll STATUS[1] for dec_done (already in flight from Section 2)
    aes_poll_done(1, tmo);
    if (tmo) begin
        $display("  [FAIL] AES auto-decrypt timeout");
        fail_cnt = fail_cnt + 1;
    end else begin
        axi_read(AES_TXOUT0, rd0);
        axi_read(AES_TXOUT1, rd1);
        axi_read(AES_TXOUT2, rd2);
        axi_read(AES_TXOUT3, rd3);
        aes_out = {rd0, rd1, rd2, rd3};
        $display("  AES inv_cipher output = %032h", aes_out);
        if (aes_out === NIST_PLAIN) begin
            $display("  [PASS] Round-trip: inv_cipher recovered original plaintext");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Round-trip mismatch");
            $display("         expected=%032h", NIST_PLAIN);
            $display("         got     =%032h", aes_out);
            fail_cnt = fail_cnt + 1;
        end
    end

    // ════════════════════════════════════════════════════════════════════
    // Section 4: Dummy slave read (routing check via m02)
    // ════════════════════════════════════════════════════════════════════
    $display("\n--- Section 4: Dummy slave m02 routing check ---");
    axi_read(DUM2_BASE, rd_data);
    // dummy_axi_slave initialises mem to {16'hDEAD, SLAVE_INDEX[15:0]}
    // SLAVE_INDEX for m02 = 2 → 0xDEAD_0002
    if (rd_data === 32'hDEAD_0002) begin
        $display("  [PASS] Dummy m02 readback = 0x%08h", rd_data);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] Dummy m02: expected=0xDEAD0002, got=0x%08h", rd_data);
        fail_cnt = fail_cnt + 1;
    end

    // ════════════════════════════════════════════════════════════════════
    // Summary
    // ════════════════════════════════════════════════════════════════════
    $display("\n=====================================================");
    $display(" SUMMARY: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display(" ** ALL TESTS PASSED **");
    else
        $display(" ** SOME TESTS FAILED **");
    $display("=====================================================\n");

    repeat(20) @(posedge clk);
    $finish;
end

// Safety watchdog
initial begin
    #200000;
    $display("ERROR: Simulation watchdog expired!");
    $finish;
end

endmodule

`default_nettype wire
