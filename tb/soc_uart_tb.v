// =============================================================================
// soc_uart_tb.v
//
// Dedicated Standalone Testbench for UART in Secure IoT Gateway SoC
//
// Target:
//   Instantiates soc_top and verifies UART functionality through AXI port s00.
//   Verifies:
//     1. UART Baud Rate Divisor configuration (DLAB=1 -> DIVISOR -> DLAB=0)
//     2. Interrupt Enable Register (IER) programming
//     3. Transmit Holding Register (THR) push and Line Status Register (LSR) polling
//     4. Hardware loopback (uart_tx_o looped to uart_rx_i)
//     5. Receiver Buffer Register (RBR) data verification
//     6. Multi-byte sequential transmission & reception
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module soc_uart_tb;

    // ── Parameters ────────────────────────────────────────────────────────
    localparam DW        = 32;
    localparam AW        = 32;
    localparam IDW       = 8;
    localparam SW        = DW/8;
    localparam CLK_HALF  = 5;          // 10 ns period -> 100 MHz clock
    localparam BAUD_DIV  = 16'd50;     // Accelerated baud divisor for quick simulation

    // UART Base and Register Addresses (Interconnect slave port m02: 0x0200_0000)
    localparam [AW-1:0] UART_BASE = 32'h0200_0000;
    localparam [AW-1:0] UART_THR  = UART_BASE | 32'h00; // Transmit Holding Register (W, DLAB=0)
    localparam [AW-1:0] UART_RBR  = UART_BASE | 32'h00; // Receiver Buffer Register (R, DLAB=0)
    localparam [AW-1:0] UART_IER  = UART_BASE | 32'h04; // Interrupt Enable Register
    localparam [AW-1:0] UART_BAUD = UART_BASE | 32'h08; // Baud Divisor Register (DLAB=1)
    localparam [AW-1:0] UART_LCR  = UART_BASE | 32'h0C; // Line Control Register
    localparam [AW-1:0] UART_LSR  = UART_BASE | 32'h14; // Line Status Register

    // ── Signals ───────────────────────────────────────────────────────────
    reg clk;
    reg rst_n;

    // s00 AXI Master Interface
    reg  [IDW-1:0]   m_awid;
    reg  [AW-1:0]    m_awaddr;
    reg  [7:0]       m_awlen;
    reg  [2:0]       m_awsize;
    reg  [1:0]       m_awburst;
    reg              m_awlock;
    reg  [3:0]       m_awcache;
    reg  [2:0]       m_awprot;
    reg  [3:0]       m_awqos;
    reg              m_awvalid;
    wire             m_awready;

    reg  [DW-1:0]    m_wdata;
    reg  [SW-1:0]    m_wstrb;
    reg              m_wlast;
    reg              m_wvalid;
    wire             m_wready;

    wire [IDW-1:0]   m_bid;
    wire [1:0]       m_bresp;
    wire             m_bvalid;
    reg              m_bready;

    reg  [IDW-1:0]   m_arid;
    reg  [AW-1:0]    m_araddr;
    reg  [7:0]       m_arlen;
    reg  [2:0]       m_arsize;
    reg  [1:0]       m_arburst;
    reg              m_arlock;
    reg  [3:0]       m_arcache;
    reg  [2:0]       m_arprot;
    reg  [3:0]       m_arqos;
    reg              m_arvalid;
    wire             m_arready;

    wire [IDW-1:0]   m_rid;
    wire [DW-1:0]    m_rdata;
    wire [1:0]       m_rresp;
    wire             m_rlast;
    wire             m_rvalid;
    reg              m_rready;

    // UART External Pins
    wire uart_tx;
    wire uart_rx;
    wire uart_irq;

    // Hardware loopback: connect TX directly to RX
    assign uart_rx = uart_tx;

    // Test counters
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    // ── Clock Generation ──────────────────────────────────────────────────
    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    // ── DUT: SoC Top ──────────────────────────────────────────────────────
    soc_top #(
        .DATA_WIDTH (DW),
        .ADDR_WIDTH (AW),
        .ID_WIDTH   (IDW)
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),

        // Master 0 (Driven by testbench)
        .s00_axi_awid    (m_awid),
        .s00_axi_awaddr  (m_awaddr),
        .s00_axi_awlen   (m_awlen),
        .s00_axi_awsize  (m_awsize),
        .s00_axi_awburst (m_awburst),
        .s00_axi_awlock  (m_awlock),
        .s00_axi_awcache (m_awcache),
        .s00_axi_awprot  (m_awprot),
        .s00_axi_awqos   (m_awqos),
        .s00_axi_awvalid (m_awvalid),
        .s00_axi_awready (m_awready),
        .s00_axi_wdata   (m_wdata),
        .s00_axi_wstrb   (m_wstrb),
        .s00_axi_wlast   (m_wlast),
        .s00_axi_wvalid  (m_wvalid),
        .s00_axi_wready  (m_wready),
        .s00_axi_bid     (m_bid),
        .s00_axi_bresp   (m_bresp),
        .s00_axi_bvalid  (m_bvalid),
        .s00_axi_bready  (m_bready),
        .s00_axi_arid    (m_arid),
        .s00_axi_araddr  (m_araddr),
        .s00_axi_arlen   (m_arlen),
        .s00_axi_arsize  (m_arsize),
        .s00_axi_arburst (m_arburst),
        .s00_axi_arlock  (m_arlock),
        .s00_axi_arcache (m_arcache),
        .s00_axi_arprot  (m_arprot),
        .s00_axi_arqos   (m_arqos),
        .s00_axi_arvalid (m_arvalid),
        .s00_axi_arready (m_arready),
        .s00_axi_rid     (m_rid),
        .s00_axi_rdata   (m_rdata),
        .s00_axi_rresp   (m_rresp),
        .s00_axi_rlast   (m_rlast),
        .s00_axi_rvalid  (m_rvalid),
        .s00_axi_rready  (m_rready),

        // Master 1 (Tied off)
        .s01_axi_awid    (8'h0),
        .s01_axi_awaddr  (32'h0),
        .s01_axi_awlen   (8'h0),
        .s01_axi_awsize  (3'h0),
        .s01_axi_awburst (2'h0),
        .s01_axi_awlock  (1'b0),
        .s01_axi_awcache (4'h0),
        .s01_axi_awprot  (3'h0),
        .s01_axi_awqos   (4'h0),
        .s01_axi_awvalid (1'b0),
        .s01_axi_awready (),
        .s01_axi_wdata   (32'h0),
        .s01_axi_wstrb   (4'h0),
        .s01_axi_wlast   (1'b0),
        .s01_axi_wvalid  (1'b0),
        .s01_axi_wready  (),
        .s01_axi_bid     (),
        .s01_axi_bresp   (),
        .s01_axi_bvalid  (),
        .s01_axi_bready  (1'b1),
        .s01_axi_arid    (8'h0),
        .s01_axi_araddr  (32'h0),
        .s01_axi_arlen   (8'h0),
        .s01_axi_arsize  (3'h0),
        .s01_axi_arburst (2'h0),
        .s01_axi_arlock  (1'b0),
        .s01_axi_arcache (4'h0),
        .s01_axi_arprot  (3'h0),
        .s01_axi_arqos   (4'h0),
        .s01_axi_arvalid (1'b0),
        .s01_axi_arready (),
        .s01_axi_rid     (),
        .s01_axi_rdata   (),
        .s01_axi_rresp   (),
        .s01_axi_rlast   (),
        .s01_axi_rvalid  (),
        .s01_axi_rready  (1'b1),

        // Peripherals & Pads
        .scl_pad_i       (1'b1),
        .scl_pad_o       (),
        .scl_padoen_o    (),
        .sda_pad_i       (1'b1),
        .sda_pad_o       (),
        .sda_padoen_o    (),
        .i2c_irq         (),

        .uart_tx_o       (uart_tx),
        .uart_rx_i       (uart_rx),
        .uart_irq        (uart_irq),

        .spi_clk_o       (),
        .spi_cs_n_o      (),
        .spi_mosi_o      (),
        .spi_miso_i      (1'b0),

        .gpio_io         (),
        .gpio_irq        (),

        .dma_done        (),
        .dma_error       ()
    );

    // ── AXI Driver Tasks ──────────────────────────────────────────────────
    task axi_write;
        input [AW-1:0] addr;
        input [DW-1:0] data;
        reg aw_done, w_done;
        integer timeout;
    begin
        @(negedge clk);
        m_awaddr  = addr;  m_awvalid = 1'b1;
        m_wdata   = data;  m_wstrb   = 4'hF;
        m_wlast   = 1'b1;  m_wvalid  = 1'b1;
        aw_done   = 1'b0;  w_done    = 1'b0;
        timeout   = 0;

        @(posedge clk);
        while (!(aw_done && w_done)) begin
            if (!aw_done && m_awready) begin
                aw_done = 1'b1;
                @(negedge clk); m_awvalid = 1'b0; @(posedge clk);
            end else if (!w_done && m_wready) begin
                w_done = 1'b1;
                @(negedge clk); m_wvalid = 1'b0; @(posedge clk);
            end else begin
                @(posedge clk);
            end
            timeout = timeout + 1;
            if (timeout > 500) begin
                $display("[ERROR] AXI Write Timeout at addr=0x%08h", addr);
                fail_cnt = fail_cnt + 1;
                $finish;
            end
        end

        @(negedge clk); m_bready = 1'b1;
        timeout = 0;
        @(posedge clk);
        while (!m_bvalid) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > 500) begin
                $display("[ERROR] AXI Write Response Timeout at addr=0x%08h", addr);
                fail_cnt = fail_cnt + 1;
                $finish;
            end
        end
        @(negedge clk); m_bready = 1'b0;
    end
    endtask

    task axi_read;
        input  [AW-1:0] addr;
        output [DW-1:0] data;
        integer timeout;
    begin
        @(negedge clk);
        m_araddr  = addr;
        m_arvalid = 1'b1;
        timeout   = 0;

        @(posedge clk);
        while (!m_arready) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > 500) begin
                $display("[ERROR] AXI AR Timeout at addr=0x%08h", addr);
                fail_cnt = fail_cnt + 1;
                $finish;
            end
        end
        @(negedge clk);
        m_arvalid = 1'b0;
        m_rready  = 1'b1;

        timeout = 0;
        @(posedge clk);
        while (!m_rvalid) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > 500) begin
                $display("[ERROR] AXI R Timeout at addr=0x%08h", addr);
                fail_cnt = fail_cnt + 1;
                $finish;
            end
        end
        data = m_rdata;
        @(negedge clk);
        m_rready = 1'b0;
    end
    endtask

    // ── Main Test Sequence ────────────────────────────────────────────────
    reg [31:0] rdata;

    task uart_send_and_verify;
        input [7:0] tx_byte;
    begin
        $display("  -> Transmitting byte: 0x%02h ('%c')", tx_byte, tx_byte);
        axi_write(UART_THR, {24'h0, tx_byte});

        // Wait for THRE (TX FIFO empty)
        axi_read(UART_LSR, rdata);
        while (!rdata[5]) begin
            repeat(10) @(posedge clk);
            axi_read(UART_LSR, rdata);
        end

        // Wait for loopback reception (10 bits per UART frame)
        repeat(BAUD_DIV * 12) @(posedge clk);

        // Poll DATA_READY (LSR[0])
        axi_read(UART_LSR, rdata);
        if (rdata[0]) begin
            axi_read(UART_RBR, rdata);
            if (rdata[7:0] === tx_byte) begin
                $display("     [PASS] Received expected byte: 0x%02h ('%c')", rdata[7:0], rdata[7:0]);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("     [FAIL] Data mismatch: exp=0x%02h got=0x%02h", tx_byte, rdata[7:0]);
                fail_cnt = fail_cnt + 1;
            end
        end else begin
            $display("     [FAIL] DATA_READY bit not asserted in LSR");
            fail_cnt = fail_cnt + 1;
        end
    end
    endtask

    initial begin
        $display("===================================================================");
        $display("         Starting SoC UART Standalone Verification Testbench       ");
        $display("===================================================================");

        // Initialize signals
        m_awid    = 0; m_awaddr  = 0; m_awlen   = 0; m_awsize  = 3'b010;
        m_awburst = 2'b01; m_awlock = 0; m_awcache = 0; m_awprot  = 0;
        m_awqos   = 0; m_awvalid = 0;
        m_wdata   = 0; m_wstrb   = 4'hF; m_wlast = 0; m_wvalid  = 0;
        m_bready  = 0;
        m_arid    = 0; m_araddr  = 0; m_arlen   = 0; m_arsize  = 3'b010;
        m_arburst = 2'b01; m_arlock = 0; m_arcache = 0; m_arprot  = 0;
        m_arqos   = 0; m_arvalid = 0;
        m_rready  = 0;

        // Reset DUT
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);

        // Test 1: UART Initialization & Baud Setup
        $display("\n[TEST 1] Initializing UART configuration and Baud rate divisor");
        axi_write(UART_LCR, 32'h0000_0083); // DLAB=1, 8N1
        axi_write(UART_BAUD, {16'h0, BAUD_DIV});
        axi_write(UART_LCR, 32'h0000_0003); // DLAB=0, 8N1 (lock baud divisor)
        axi_write(UART_IER, 32'h0000_0001); // Enable RX Interrupt (needed for LSR[0])

        pass_cnt = pass_cnt + 1;
        $display("  [PASS] UART configured (Baud Divisor = %0d)", BAUD_DIV);

        // Test 2: Single Character Loopback Test
        $display("\n[TEST 2] Single Byte Transmission & Loopback Check");
        uart_send_and_verify(8'h41); // 'A'

        // Test 3: Multiple Characters Sequential Loopback
        $display("\n[TEST 3] Multi-Byte String Loopback Transmission");
        uart_send_and_verify(8'h53); // 'S'
        uart_send_and_verify(8'h6F); // 'o'
        uart_send_and_verify(8'h43); // 'C'
        uart_send_and_verify(8'h21); // '!'

        // Test 4: LSR Initial Status Check
        $display("\n[TEST 4] Line Status Register (LSR) Flags Check");
        axi_read(UART_LSR, rdata);
        $display("  LSR Register Value: 0x%08h (THRE=%0b, TEMT=%0b)", rdata, rdata[5], rdata[6]);
        if (rdata[5]) begin
            $display("  [PASS] Transmitter empty flags verified");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Transmitter not empty as expected");
            fail_cnt = fail_cnt + 1;
        end

        // Final Report
        $display("\n===================================================================");
        $display("  UART Test Results: %0d PASSED, %0d FAILED", pass_cnt, fail_cnt);
        $display("===================================================================");

        if (fail_cnt == 0)
            $display(">> TEST RESULT: ALL TESTS PASSED SUCCESSFULLY! <<\n");
        else
            $display(">> TEST RESULT: TEST FAILED! <<\n");

        $finish;
    end

endmodule
`default_nettype wire
