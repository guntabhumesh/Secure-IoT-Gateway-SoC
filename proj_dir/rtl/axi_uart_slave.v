// =============================================================================
// axi_uart_slave.v
//
// AXI4-full slave wrapper around axi_uart_top (AXI4-Lite UART).
//
// ── Key bridge requirements ──────────────────────────────────────────────
//
// The UART write FSM starts when axi_wren = (awvalid & wvalid) is TRUE
// simultaneously.  A standard AXI4 master may send the AW beat before
// the W beat.  This wrapper buffers the AW address/id and holds
// axi_awvalid_i HIGH to the UART core until the W beat also arrives,
// presenting both channels together.
//
// ── Address mapping ──────────────────────────────────────────────────────
//
// UART base in SoC: 0x0200_0000 (M02 on interconnect)
// Register offsets (byte, bits[4:2] = reg-sel decoded by axi_uart_top):
//
//   Offset  reg[4:2]  Register        DLAB gate
//   0x00      0       THR (write)     DLAB must be 0
//   0x00      0       RBR (read)      DLAB must be 0
//   0x04      1       IER             DLAB must be 0
//   0x08      2       BAUD_DIVISOR    DLAB must be 1
//   0x0C      3       LCR             always
//   0x14      5       LSR (read-only) always
//
// Correct initialisation sequence:
//   1. Write LCR = 0x83  (DLAB=1, 8N1)    → enables baud divisor access
//   2. Write BAUD = divisor               → e.g. 868 for 115200 @ 100 MHz
//   3. Write LCR = 0x03  (DLAB=0, 8N1)   → locks baud, enables data regs
//   4. Write IER = 0x01                   → enable RX interrupt (needed for
//                                           LSR DATA_READY to assert)
//   5. Write THR = byte                   → transmit
//
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module axi_uart_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    // Clock / reset (active-low reset)
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,

    // ── Write address channel ───────────────────────────────────────
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
    output wire                    s_axi_awready,

    // ── Write data channel ──────────────────────────────────────────
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,

    // ── Write response channel ──────────────────────────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output wire [1:0]              s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,

    // ── Read address channel ────────────────────────────────────────
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
    output wire                    s_axi_arready,

    // ── Read data channel ───────────────────────────────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output wire [DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                    s_axi_rlast,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,

    // ── UART physical interface ─────────────────────────────────────
    output wire                    uart_tx_o,
    input  wire                    uart_rx_i,
    output wire                    uart_irq_o
);

    // ══════════════════════════════════════════════════════════════════
    // Write-address buffer
    //
    // The UART core's write FSM fires on (awvalid & wvalid).
    // Buffer the AW beat so we can hold awvalid_i asserted to the UART
    // until the corresponding W beat also arrives.
    // ══════════════════════════════════════════════════════════════════

    reg                   aw_buf_valid;          // AW beat is buffered
    reg [4:0]             aw_buf_addr;           // buffered address [4:0]
    reg [11:0]            aw_buf_id;             // buffered ID (12-bit for UART)

    // Signal to the UART core
    wire                  uart_awvalid_i;
    wire [4:0]            uart_awaddr_i;
    wire [11:0]           uart_awid_i;
    wire                  uart_awready_o;

    // We can accept a new AW beat whenever our buffer is empty
    // (or simultaneously being consumed this cycle with a W beat)
    wire aw_accepted = s_axi_awvalid && s_axi_awready;
    wire w_accepted  = uart_awvalid_i && s_axi_wvalid && uart_awready_o;

    assign s_axi_awready = !aw_buf_valid;  // accept AW when buffer is free

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_buf_valid <= 1'b0;
            aw_buf_addr  <= 5'b0;
            aw_buf_id    <= 12'b0;
        end else begin
            if (aw_accepted && !w_accepted) begin
                // AW arrived, W not yet — buffer it
                aw_buf_valid <= 1'b1;
                aw_buf_addr  <= s_axi_awaddr[4:0];
                aw_buf_id    <= {{(12-ID_WIDTH){1'b0}}, s_axi_awid};
            end else if (w_accepted) begin
                // W beat consumed the transaction — clear buffer
                aw_buf_valid <= 1'b0;
            end else if (aw_accepted && w_accepted) begin
                // Both arrived same cycle — no need to buffer
                aw_buf_valid <= 1'b0;
            end
        end
    end

    // Present to UART: either from buffer or directly from incoming port
    // Both are presented simultaneously so the UART FSM sees awvalid=wvalid=1
    assign uart_awvalid_i = aw_buf_valid | (s_axi_awvalid & !aw_buf_valid);
    assign uart_awaddr_i  = aw_buf_valid ? aw_buf_addr  : s_axi_awaddr[4:0];
    assign uart_awid_i    = aw_buf_valid ? aw_buf_id    : {{(12-ID_WIDTH){1'b0}}, s_axi_awid};

    // UART awready feeds back to the s_axi_awready only when no buffer is used
    // (when buffer is used we already accepted the AW beat earlier)

    // ══════════════════════════════════════════════════════════════════
    // BID / RID capture
    // ══════════════════════════════════════════════════════════════════

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            s_axi_bid <= {ID_WIDTH{1'b0}};
        else if (uart_awvalid_i && uart_awready_o && s_axi_wvalid)
            // Capture at the moment the UART accepts the write
            s_axi_bid <= aw_buf_valid ? aw_buf_id[ID_WIDTH-1:0]
                                      : s_axi_awid;
    end

    wire uart_arready_o;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            s_axi_rid <= {ID_WIDTH{1'b0}};
        else if (s_axi_arvalid && uart_arready_o)
            s_axi_rid <= s_axi_arid;
    end

    // rlast: single-beat reads only — assert with rvalid
    assign s_axi_rlast = s_axi_rvalid;

    // ══════════════════════════════════════════════════════════════════
    // axi_uart_top instantiation
    // ══════════════════════════════════════════════════════════════════
    wire [11:0] uart_arid_i = {{(12-ID_WIDTH){1'b0}}, s_axi_arid};

    axi_uart_top u_uart (
        // Clocks – both tied to system clock (single-clock domain)
        .fixed_clk_i    (s_axi_aclk),
        .axi_aclk_i     (s_axi_aclk),
        .axi_aresetn_i  (s_axi_aresetn),

        // ── Write address (from buffer logic) ──────────────────────
        .axi_awid_i     (uart_awid_i),
        .axi_awaddr_i   (uart_awaddr_i),
        .axi_awvalid_i  (uart_awvalid_i),
        .axi_awready_o  (uart_awready_o),

        // ── Write data (directly from master) ──────────────────────
        .axi_wdata_i    (s_axi_wdata),
        .axi_wstrb_i    (s_axi_wstrb),
        .axi_wvalid_i   (s_axi_wvalid),
        .axi_wready_o   (s_axi_wready),

        // ── Write response ─────────────────────────────────────────
        .axi_bid_o      (),           // bid returned from latch above
        .axi_bresp_o    (s_axi_bresp),
        .axi_bvalid_o   (s_axi_bvalid),
        .axi_bready_i   (s_axi_bready),

        // ── Read address ───────────────────────────────────────────
        .axi_arid_i     (uart_arid_i),
        .axi_araddr_i   (s_axi_araddr[4:0]),
        .axi_arvalid_i  (s_axi_arvalid),
        .axi_arready_o  (uart_arready_o),

        // ── Read data ──────────────────────────────────────────────
        .axi_rid_o      (),           // rid returned from latch above
        .axi_rdata_o    (s_axi_rdata),
        .axi_rresp_o    (s_axi_rresp),
        .axi_rvalid_o   (s_axi_rvalid),
        .axi_rready_i   (s_axi_rready),

        // ── UART physical ──────────────────────────────────────────
        .uart_tx_o          (uart_tx_o),
        .uart_rx_i          (uart_rx_i),
        .read_interrupt_o   (uart_irq_o)
    );

    // AR ready feeds straight back to interconnect
    assign s_axi_arready = uart_arready_o;

endmodule

`default_nettype wire
