`timescale 1ns/1ps
// =============================================================================
// tb_soc_top.v
//
// Secure IoT Gateway SoC — Full Integration Testbench
//
// Slave address map:
//   m00  0x0000_0000  I2C (Wishbone)
//   m01  0x0100_0000  AES encrypt/decrypt
//   m02  0x0200_0000  UART (AXI4-Lite wrapped)
//   m03  0x0300_0000  dummy slave
//   ...
//
// Test plan:
//   [01] I2C prescaler & control register read/write
//   [02] AES key-load (CTRL.KLD) → poll KDONE
//   [03] AES encrypt  NIST FIPS-197 App-B
//   [04] AES round-trip inv-cipher auto-chain
//   [05] AES encrypt  NIST FIPS-197 App-C.1
//   [06] AES key readback
//   [07] UART init: LCR DLAB=1 → baud divisor → LCR DLAB=0 → IER=1
//   [08] UART transmit 0x55 via AXI write to THR
//   [09] UART TX: poll LSR THRE — TX hold reg empty
//   [10] UART RX loopback: after baud-rate time, check LSR DATA_READY & read RBR
//   [11] Dummy slave m03 routing  (0x0300_0000 → 0xDEAD_0003)
//   [12] AES soft-reset CTRL.RST
//
// UART register offsets (from UART_BASE = 0x0200_0000):
//   0x00  THR (write, DLAB=0) / RBR (read,  DLAB=0)
//   0x04  IER (DLAB=0)
//   0x08  BAUD_DIVISOR (DLAB=1)
//   0x0C  LCR
//   0x14  LSR
//
// UART DLAB rules (enforced inside axi_uart_top):
//   LCR[7]=1 → access BAUD_DIVISOR at offset 0x08
//   LCR[7]=0 → access THR/RBR/IER
//
// Waveform signals captured (see $fsdbDumpvars section):
//   - AXI master channel (s00)
//   - Interconnect m02 channel (UART)
//   - axi_uart_slave internal: aw_buf_valid, aw_buf_addr, uart_awvalid_i
//   - axi_uart_top internals: write_state, read_state, uart_config_reg_int
//                             baudrate_divisor_int, tx_fifo_push_int
//                             tx_fifo_data_in_int, uart_lsr_reg_int
//   - uart_tx_o, uart_rx_i line
//   - uart_controller: uart_tx_o, uart_rx_i, rx_data_o, rx_push_o
// =============================================================================

module tb_soc_top;

    // ── Parameters ────────────────────────────────────────────────────────
    localparam DW       = 32;
    localparam AW       = 32;
    localparam IDW      = 8;
    localparam SW       = DW/8;
    localparam CLK_HALF = 5;        // 10 ns period → 100 MHz

    // ── Slave base addresses ──────────────────────────────────────────────
    localparam [AW-1:0] I2C_BASE  = 32'h0000_0000;
    localparam [AW-1:0] AES_BASE  = 32'h0100_0000;
    localparam [AW-1:0] UART_BASE = 32'h0200_0000;
    localparam [AW-1:0] DUM_BASE  = 32'h0300_0000;

    // ── I2C register offsets ──────────────────────────────────────────────
    localparam [AW-1:0] I2C_PRER_LO = I2C_BASE + 32'h00;
    localparam [AW-1:0] I2C_PRER_HI = I2C_BASE + 32'h04;
    localparam [AW-1:0] I2C_CTR     = I2C_BASE + 32'h08;
     // I2C data/command/status registers
    localparam [AW-1:0] I2C_RXR = I2C_BASE + 32'h0C;
    localparam [AW-1:0] I2C_TXR = I2C_BASE + 32'h0C;

    localparam [AW-1:0] I2C_CR  = I2C_BASE + 32'h10;
    localparam [AW-1:0] I2C_SR  = I2C_BASE + 32'h10;

    // ── AES register offsets ──────────────────────────────────────────────
    localparam [AW-1:0] AES_CTRL  = AES_BASE | 32'h00;
    localparam [AW-1:0] AES_KEY0  = AES_BASE | 32'h04;
    localparam [AW-1:0] AES_KEY1  = AES_BASE | 32'h08;
    localparam [AW-1:0] AES_KEY2  = AES_BASE | 32'h0C;
    localparam [AW-1:0] AES_KEY3  = AES_BASE | 32'h10;
    localparam [AW-1:0] AES_TEXT0 = AES_BASE | 32'h14;
    localparam [AW-1:0] AES_TEXT1 = AES_BASE | 32'h18;
    localparam [AW-1:0] AES_TEXT2 = AES_BASE | 32'h1C;
    localparam [AW-1:0] AES_TEXT3 = AES_BASE | 32'h20;
    localparam [AW-1:0] AES_OUT0  = AES_BASE | 32'h24;
    localparam [AW-1:0] AES_OUT1  = AES_BASE | 32'h28;
    localparam [AW-1:0] AES_OUT2  = AES_BASE | 32'h2C;
    localparam [AW-1:0] AES_OUT3  = AES_BASE | 32'h30;

    // ── UART register addresses ───────────────────────────────────────────
    // reg-select = addr[4:2]:  0=THR/RBR  1=IER  2=BAUD  3=LCR  5=LSR


     localparam [AW-1:0] UART_THR  = UART_BASE | 32'h00;
     localparam [AW-1:0] UART_RBR  = UART_BASE | 32'h00;
     localparam [AW-1:0] UART_IER  = UART_BASE | 32'h04;
     localparam [AW-1:0] UART_BAUD = UART_BASE | 32'h08;
     localparam [AW-1:0] UART_LCR  = UART_BASE | 32'h0C;
     localparam [AW-1:0] UART_LSR  = UART_BASE | 32'h14;
    // Baud divisor for 115200 baud @ 100 MHz: 100_000_000 / 115200 = 868
    localparam [31:0] BAUD_DIV = 32'd868;

    // ── NIST AES test vectors ─────────────────────────────────────────────
    localparam [127:0] NIST_KEY    = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_PLAIN  = 128'h3243f6a8885a308d313198a2e0370734;
    localparam [127:0] NIST_CIPH   = 128'h3925841d02dc09fbdc118597196a0b32;
    localparam [127:0] NIST2_KEY   = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] NIST2_PLAIN = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] NIST2_CIPH  = 128'h69c4e0d86a7b04300d8a8b41b570efad;

    // ── Clock / reset ─────────────────────────────────────────────────────
    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    always #CLK_HALF clk = ~clk;

    // ── AXI master signals ────────────────────────────────────────────────
    reg  [IDW-1:0] m_awid    = 0;
    reg  [AW-1:0]  m_awaddr  = 0;
    reg  [7:0]     m_awlen   = 0;
    reg  [2:0]     m_awsize  = 3'b010;
    reg  [1:0]     m_awburst = 2'b01;
    reg            m_awlock  = 0;
    reg  [3:0]     m_awcache = 0;
    reg  [2:0]     m_awprot  = 0;
    reg  [3:0]     m_awqos   = 0;
    reg            m_awvalid = 0;
    wire           m_awready;

    reg  [DW-1:0]  m_wdata  = 0;
    reg  [SW-1:0]  m_wstrb  = 4'hf;
    reg            m_wlast  = 1;
    reg            m_wvalid = 0;
    wire           m_wready;

    wire [IDW-1:0] m_bid;
    wire [1:0]     m_bresp;
    wire           m_bvalid;
    reg            m_bready = 0;

    reg  [IDW-1:0] m_arid    = 0;
    reg  [AW-1:0]  m_araddr  = 0;
    reg  [7:0]     m_arlen   = 0;
    reg  [2:0]     m_arsize  = 3'b010;
    reg  [1:0]     m_arburst = 2'b01;
    reg            m_arlock  = 0;
    reg  [3:0]     m_arcache = 0;
    reg  [2:0]     m_arprot  = 0;
    reg  [3:0]     m_arqos   = 0;
    reg            m_arvalid = 0;
    wire           m_arready;

    wire [IDW-1:0] m_rid;
    wire [DW-1:0]  m_rdata;
    wire [1:0]     m_rresp;
    wire           m_rlast;
    wire           m_rvalid;
    reg            m_rready = 0;

    // ── I2C loopback ──────────────────────────────────────────────────────
    wire scl_pad_o, scl_padoen_o, sda_pad_o, sda_padoen_o;
    wire scl_pad_i = scl_padoen_o ? 1'b1 : scl_pad_o;
    wire sda_pad_i = sda_padoen_o ? 1'b1 : sda_pad_o;

    // ── UART loopback: TX wired back to RX ───────────────────────────────
    wire uart_tx;
    wire uart_rx;
    assign uart_rx = uart_tx;   // physical loopback

    // ── DUT ───────────────────────────────────────────────────────────────
    soc_top #(.DATA_WIDTH(DW), .ADDR_WIDTH(AW), .ID_WIDTH(IDW)) u_soc (
        .clk   (clk),
        .rst_n (rst_n),
        // primary master (s00)
        .s00_axi_awid(m_awid),      .s00_axi_awaddr(m_awaddr),
        .s00_axi_awlen(m_awlen),    .s00_axi_awsize(m_awsize),
        .s00_axi_awburst(m_awburst),.s00_axi_awlock(m_awlock),
        .s00_axi_awcache(m_awcache),.s00_axi_awprot(m_awprot),
        .s00_axi_awqos(m_awqos),    .s00_axi_awvalid(m_awvalid),
        .s00_axi_awready(m_awready),
        .s00_axi_wdata(m_wdata),    .s00_axi_wstrb(m_wstrb),
        .s00_axi_wlast(m_wlast),    .s00_axi_wvalid(m_wvalid),
        .s00_axi_wready(m_wready),
        .s00_axi_bid(m_bid),        .s00_axi_bresp(m_bresp),
        .s00_axi_bvalid(m_bvalid),  .s00_axi_bready(m_bready),
        .s00_axi_arid(m_arid),      .s00_axi_araddr(m_araddr),
        .s00_axi_arlen(m_arlen),    .s00_axi_arsize(m_arsize),
        .s00_axi_arburst(m_arburst),.s00_axi_arlock(m_arlock),
        .s00_axi_arcache(m_arcache),.s00_axi_arprot(m_arprot),
        .s00_axi_arqos(m_arqos),    .s00_axi_arvalid(m_arvalid),
        .s00_axi_arready(m_arready),
        .s00_axi_rid(m_rid),        .s00_axi_rdata(m_rdata),
        .s00_axi_rresp(m_rresp),    .s00_axi_rlast(m_rlast),
        .s00_axi_rvalid(m_rvalid),  .s00_axi_rready(m_rready),
        // secondary master (s01) — unused, tie off
        .s01_axi_awid({IDW{1'b0}}), .s01_axi_awaddr({AW{1'b0}}),
        .s01_axi_awlen(8'b0),       .s01_axi_awsize(3'b010),
        .s01_axi_awburst(2'b01),    .s01_axi_awlock(1'b0),
        .s01_axi_awcache(4'b0),     .s01_axi_awprot(3'b0),
        .s01_axi_awqos(4'b0),       .s01_axi_awvalid(1'b0),
        .s01_axi_awready(),
        .s01_axi_wdata({DW{1'b0}}), .s01_axi_wstrb({SW{1'b0}}),
        .s01_axi_wlast(1'b0),       .s01_axi_wvalid(1'b0),
        .s01_axi_wready(),
        .s01_axi_bid(),  .s01_axi_bresp(), .s01_axi_bvalid(), .s01_axi_bready(1'b1),
        .s01_axi_arid({IDW{1'b0}}), .s01_axi_araddr({AW{1'b0}}),
        .s01_axi_arlen(8'b0),       .s01_axi_arsize(3'b010),
        .s01_axi_arburst(2'b01),    .s01_axi_arlock(1'b0),
        .s01_axi_arcache(4'b0),     .s01_axi_arprot(3'b0),
        .s01_axi_arqos(4'b0),       .s01_axi_arvalid(1'b0),
        .s01_axi_arready(),
        .s01_axi_rid(), .s01_axi_rdata(), .s01_axi_rresp(),
        .s01_axi_rlast(), .s01_axi_rvalid(), .s01_axi_rready(1'b1),
        // I2C
        .scl_pad_i(scl_pad_i), .scl_pad_o(scl_pad_o), .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda_pad_i), .sda_pad_o(sda_pad_o), .sda_padoen_o(sda_padoen_o),
        .i2c_irq(),
        // UART
        .uart_tx_o(uart_tx),
        .uart_rx_i(uart_rx),
        .uart_irq()
    );

    // ══════════════════════════════════════════════════════════════════════
    // Waveform dump — explicit signal list for Verdi
    // ══════════════════════════════════════════════════════════════════════
    initial begin
        $fsdbDumpfile("dump_soc_uart.fsdb");
        // ── Level 0: top-level testbench signals ──────────────────────────
        $fsdbDumpvars(0, tb_soc_top);

        // ── AXI master bus at s00 (CPU → interconnect) ───────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_ic);

        // ── UART AXI slave wrapper (m02 bus + internal buffer) ───────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_uart);

        // ── axi_uart_top internal signals ─────────────────────────────────
        // Write FSM, read FSM, config regs, FIFOs, LSR
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_uart.u_uart);

        // ── UART controller (transmitter/receiver) ────────────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_uart.u_uart.uart_controller_inst);

        // ── TX FIFO ───────────────────────────────────────────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_uart.u_uart.axi_internal_fifo_tx_inst);

        // ── RX FIFO ───────────────────────────────────────────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_uart.u_uart.axi_internal_fifo_rx_inst);

        // ── AES slave ─────────────────────────────────────────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_aes);

        // ── I2C master ────────────────────────────────────────────────────
        $fsdbDumpvars(0, tb_soc_top.u_soc.u_i2c);

        $fsdbDumpSVA();
        $fsdbDumpMDA();
    end

    // ══════════════════════════════════════════════════════════════════════
    // AXI write task
    //
    // Both AW and W are driven simultaneously so the UART slave wrapper
    // sees awvalid & wvalid in the same cycle.
    //
    // The AXI interconnect acknowledges AW and W in separate clock cycles:
    //   - awready : one-cycle pulse from the interconnect (STATE_IDLE)
    //   - wready  : forwarded from the target slave (STATE_WRITE)
    // We keep each valid HIGH until its corresponding ready fires.
    // ══════════════════════════════════════════════════════════════════════
    integer aw_to, b_to;

    task axi_write;
        input [AW-1:0] addr;
        input [DW-1:0] data;
        reg aw_done, w_done;
    begin
        // Assert both AW and W together
        @(negedge clk);
        m_awaddr  = addr;  m_awvalid = 1'b1;
        m_wdata   = data;  m_wstrb   = 4'hf;
        m_wlast   = 1'b1;  m_wvalid  = 1'b1;
        aw_done   = 1'b0;  w_done    = 1'b0;
        aw_to     = 0;

        // Deassert each channel once its ready fires; loop until both done
        @(posedge clk);
        while (!(aw_done && w_done)) begin
            // Capture ready signals combinatorially this posedge
            if (!aw_done && m_awready) begin
                aw_done = 1'b1;
                @(negedge clk); m_awvalid = 1'b0; @(posedge clk);
            end else if (!w_done && m_wready) begin
                w_done = 1'b1;
                @(negedge clk); m_wvalid = 1'b0; @(posedge clk);
            end else begin
                @(posedge clk);
            end
            aw_to = aw_to + 1;
            if (aw_to > 1000) begin
                $display("TIMEOUT axi_write addr=0x%08h aw_done=%0b w_done=%0b t=%0t",
                          addr, aw_done, w_done, $time);
                $finish;
            end
        end

        // Collect B response
        @(negedge clk); m_bready = 1'b1;
        b_to = 0;
        @(posedge clk);
        while (!m_bvalid) begin
            @(posedge clk);
            b_to = b_to + 1;
            if (b_to > 1000) begin
                $display("TIMEOUT bvalid addr=0x%08h t=%0t", addr, $time);
                $finish;
            end
        end
        @(negedge clk); m_bready = 1'b0;
    end
    endtask

    // ── AXI read task ─────────────────────────────────────────────────────
    integer ar_to, r_to;
    reg [DW-1:0] rd_data;

    task axi_read;
        input  [AW-1:0] addr;
        output [DW-1:0] data;
    begin
        @(negedge clk);
        m_araddr  = addr;
        m_arvalid = 1'b1;

        ar_to = 0;
        @(posedge clk);
        while (!m_arready) begin
            @(posedge clk);
            ar_to = ar_to + 1;
            if (ar_to > 500) begin
                $display("TIMEOUT arready  addr=0x%08h t=%0t", addr, $time);
                $finish;
            end
        end
        @(negedge clk);
        m_arvalid = 1'b0;

        m_rready = 1'b1;
        r_to = 0;
        @(posedge clk);
        while (!m_rvalid) begin
            @(posedge clk);
            r_to = r_to + 1;
            if (r_to > 500) begin
                $display("TIMEOUT rvalid   addr=0x%08h t=%0t", addr, $time);
                $finish;
            end
        end
        data = m_rdata;
        @(negedge clk);
        m_rready = 1'b0;
    end
    endtask

    // ── AES poll helper ───────────────────────────────────────────────────
    integer poll_cnt;

    task aes_poll;
        input  integer bit_pos;
        output         timed_out;
        reg [DW-1:0]   stat;
    begin
        poll_cnt = 0; timed_out = 1'b0;
        begin : ploop
            forever begin
                axi_read(AES_CTRL, stat);
                if (stat[bit_pos]) disable ploop;
                poll_cnt = poll_cnt + 1;
                if (poll_cnt > 1000) begin timed_out = 1'b1; disable ploop; end
            end
        end
    end
    endtask

    task aes_encrypt;
        input  [127:0] key;
        input  [127:0] plain;
        output [127:0] ciph_out;
        output         tmo;
        reg [DW-1:0]   r0,r1,r2,r3;
    begin
        axi_write(AES_KEY0,  key[127:96]);
        axi_write(AES_KEY1,  key[ 95:64]);
        axi_write(AES_KEY2,  key[ 63:32]);
        axi_write(AES_KEY3,  key[ 31: 0]);
        axi_write(AES_TEXT0, plain[127:96]);
        axi_write(AES_TEXT1, plain[ 95:64]);
        axi_write(AES_TEXT2, plain[ 63:32]);
        axi_write(AES_TEXT3, plain[ 31: 0]);
        axi_write(AES_CTRL,  32'h0000_0003);
        aes_poll(16, tmo);
        if (!tmo) begin
            axi_read(AES_OUT0, r0);
            axi_read(AES_OUT1, r1);
            axi_read(AES_OUT2, r2);
            axi_read(AES_OUT3, r3);
            ciph_out = {r0, r1, r2, r3};
        end else
            ciph_out = 128'bx;
    end
    endtask

    // ── UART LSR poll: wait for THRE (bit 5) ─────────────────────────────
    task uart_wait_thre;
        output         timed_out;
        reg [DW-1:0]   lsr;
        integer        wcnt;
    begin
        wcnt = 0; timed_out = 1'b0;
        begin : thre_loop
            forever begin
                axi_read(UART_LSR, lsr);
                if (lsr[5]) disable thre_loop;   // THRE set
                wcnt = wcnt + 1;
                if (wcnt > 5000) begin timed_out = 1'b1; disable thre_loop; end
            end
        end
    end
    endtask

    // ── Main test sequence ────────────────────────────────────────────────
    integer pass_cnt, fail_cnt;
    reg         tmo, uart_tmo;
    reg [DW-1:0]  r0, r1, r2, r3;
    reg [127:0]   result128, enc_out;
    reg           enc_tmo;

    initial begin
        pass_cnt = 0; fail_cnt = 0;

        rst_n = 1'b0;
        repeat(12) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;
        repeat(5)  @(posedge clk);

        $display("");
        $display("=============================================================");
        $display("  Secure IoT Gateway SoC — Full Integration Testbench");
        $display("  m00=I2C   m01=AES   m02=UART   m03..m10=dummy");
        $display("  Clock: 100 MHz  UART baud divisor: %0d (115200 baud)", BAUD_DIV);
        $display("=============================================================");

       /* // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 01] I2C prescaler & control register");
        // ─────────────────────────────────────────────────────────────
        axi_write(I2C_PRER_LO, 32'h0000_0063);
        axi_write(I2C_PRER_HI, 32'h0000_0000);
        axi_write(I2C_CTR,     32'h0000_0080);

        axi_read(I2C_PRER_LO, rd_data);
        if (rd_data[7:0] === 8'h63) begin
            $display("  [PASS] PRER_LO = 0x%02h", rd_data[7:0]); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] PRER_LO: exp=0x63 got=0x%02h", rd_data[7:0]); fail_cnt = fail_cnt + 1;
        end
        axi_read(I2C_CTR, rd_data);
        if (rd_data[7:0] === 8'h80) begin
            $display("  [PASS] CTR = 0x80 (core enabled)"); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] CTR: exp=0x80 got=0x%02h", rd_data[7:0]); fail_cnt = fail_cnt + 1;
        end*/
 		//gpt
        // ═════════════════════════════════════════════════════════════════════
      // TEST 01: I2C configuration + START/WRITE waveform verification
      // ═════════════════════════════════════════════════════════════════════
      $display("\n[TEST 01] I2C configuration + START/WRITE");

   // -------------------------------------------------------------
// Step 1: Program I2C prescaler
// -------------------------------------------------------------
axi_write(I2C_PRER_LO, 32'h0000_0063);
axi_write(I2C_PRER_HI, 32'h0000_0000);

// -------------------------------------------------------------
// Step 2: Enable I2C core
// -------------------------------------------------------------
axi_write(I2C_CTR, 32'h0000_0080);

// -------------------------------------------------------------
// Verify PRER_LO
// -------------------------------------------------------------
axi_read(I2C_PRER_LO, rd_data);

if (rd_data[7:0] === 8'h63) begin
    $display("  [PASS] PRER_LO = 0x%02h", rd_data[7:0]);
    pass_cnt = pass_cnt + 1;
end
else begin
    $display("  [FAIL] PRER_LO: exp=0x63 got=0x%02h",
             rd_data[7:0]);
    fail_cnt = fail_cnt + 1;
end

// -------------------------------------------------------------
// Verify CTR
// -------------------------------------------------------------
axi_read(I2C_CTR, rd_data);

if (rd_data[7:0] === 8'h80) begin
    $display("  [PASS] CTR = 0x80");
    pass_cnt = pass_cnt + 1;
end
else begin
    $display("  [FAIL] CTR: exp=0x80 got=0x%02h",
             rd_data[7:0]);
    fail_cnt = fail_cnt + 1;
end

// =============================================================
// Step 3: Load a byte into TXR
//
// Use 0xA0 as an example 8-bit I2C address byte.
// This is:
//     7-bit address = 0x50
//     R/W           = 0 (WRITE)
//
// There is currently NO I2C slave model in tb_soc_top,
// so we expect the slave ACK to be missing.
// The purpose here is to verify START/SCL/SDA generation.
// =============================================================
axi_write(I2C_TXR, 32'h0000_00A0);

$display("  TXR <= 0xA0");

// -------------------------------------------------------------
// Step 4: Issue START + WRITE
//
// CR[7] = STA = START
// CR[4] = WR  = WRITE
//
// 8'h90 = 1001_0000
//          ^      ^
//          STA    WR
// -------------------------------------------------------------
axi_write(I2C_CR, 32'h0000_0090);

$display("  CR <= 0x90 : START + WRITE");

// -------------------------------------------------------------
// Step 5: Poll SR until transfer completes
//
// SR[1] = TIP (Transfer In Progress)
// SR[7] = RXACK
// SR[6] = BUSY
// SR[5] = AL (Arbitration Lost)
// -------------------------------------------------------------
axi_read(I2C_SR, rd_data);

while (rd_data[1]) begin
    axi_read(I2C_SR, rd_data);
end

$display("  I2C transfer completed");
$display("  SR = 0x%02h", rd_data[7:0]);

// -------------------------------------------------------------
// Check ACK
//
// Because tb_soc_top currently has no external I2C slave,
// RXACK is expected to be 1 (NACK).
//
// This is NOT an I2C controller failure.
// It simply means no slave pulled SDA low for ACK.
// -------------------------------------------------------------
if (rd_data[7]) begin
    $display("  [INFO] No slave ACK detected (expected with current TB)");
end
else begin
    $display("  [INFO] Slave ACK detected");
end

// -------------------------------------------------------------
// Step 6: STOP
// -------------------------------------------------------------
axi_write(I2C_CR, 32'h0000_0040);

$display("  CR <= 0x40 : STOP");

repeat (20) @(posedge clk);

$display("  I2C START/WRITE/STOP waveform test complete");

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 02] AES key-only load (CTRL.KLD)");
        // ─────────────────────────────────────────────────────────────
        axi_write(AES_KEY0, NIST_KEY[127:96]);
        axi_write(AES_KEY1, NIST_KEY[ 95:64]);
        axi_write(AES_KEY2, NIST_KEY[ 63:32]);
        axi_write(AES_KEY3, NIST_KEY[ 31: 0]);
        axi_write(AES_CTRL, 32'h0000_0002);
        aes_poll(17, tmo);
        if (!tmo) begin
            $display("  [PASS] KDONE asserted"); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] KDONE timeout"); fail_cnt = fail_cnt + 1;
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 03] AES encrypt — NIST FIPS-197 App-B");
        $display("  Key   = %032h", NIST_KEY);
        $display("  Plain = %032h", NIST_PLAIN);
        $display("  Exp   = %032h", NIST_CIPH);
        // ─────────────────────────────────────────────────────────────
        aes_encrypt(NIST_KEY, NIST_PLAIN, enc_out, enc_tmo);
        if (enc_tmo) begin
            $display("  [FAIL] AES DONE timeout"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("  OUT   = %032h", enc_out);
            if (enc_out === NIST_CIPH) begin
                $display("  [PASS] Ciphertext matches NIST"); pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Ciphertext mismatch"); fail_cnt = fail_cnt + 1;
            end
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 04] AES round-trip (inv-cipher auto-chain)");
        // ─────────────────────────────────────────────────────────────
        repeat(30) @(posedge clk);
        axi_read(AES_OUT0, r0); axi_read(AES_OUT1, r1);
        axi_read(AES_OUT2, r2); axi_read(AES_OUT3, r3);
        result128 = {r0,r1,r2,r3};
        $display("  inv OUT = %032h", result128);
        if (result128 === NIST_PLAIN) begin
            $display("  [PASS] Round-trip recovered plaintext"); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Round-trip: exp=%032h got=%032h", NIST_PLAIN, result128);
            fail_cnt = fail_cnt + 1;
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 05] AES encrypt — NIST FIPS-197 App-C.1");
        $display("  Key   = %032h", NIST2_KEY);
        $display("  Plain = %032h", NIST2_PLAIN);
        $display("  Exp   = %032h", NIST2_CIPH);
        // ─────────────────────────────────────────────────────────────
        aes_encrypt(NIST2_KEY, NIST2_PLAIN, enc_out, enc_tmo);
        if (enc_tmo) begin
            $display("  [FAIL] AES DONE timeout"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("  OUT   = %032h", enc_out);
            if (enc_out === NIST2_CIPH) begin
                $display("  [PASS] Ciphertext matches NIST vector 2"); pass_cnt = pass_cnt + 1;
            end else begin
                $display("  [FAIL] Ciphertext mismatch (vector 2)"); fail_cnt = fail_cnt + 1;
            end
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 06] AES KEY readback");
        // ─────────────────────────────────────────────────────────────
        axi_read(AES_KEY0, r0); axi_read(AES_KEY1, r1);
        axi_read(AES_KEY2, r2); axi_read(AES_KEY3, r3);
        result128 = {r0,r1,r2,r3};
        if (result128 === NIST2_KEY) begin
            $display("  [PASS] KEY = %032h", result128); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] KEY: exp=%032h got=%032h", NIST2_KEY, result128);
            fail_cnt = fail_cnt + 1;
        end

        // ═════════════════════════════════════════════════════════════
        // UART tests (m02 @ 0x0200_0000)
        //
        // Correct init sequence per axi_uart_top FSM:
        //  Step 1. Write LCR = 0x83   LCR[7]=DLAB=1, 8N1 config
        //          This unlocks BAUD_DIVISOR register at offset 0x08
        //  Step 2. Write BAUD = 868   100MHz / 115200
        //  Step 3. Write LCR = 0x03   DLAB=0, 8N1 — locks baud,
        //          unlocks THR/RBR/IER
        //  Step 4. Write IER = 0x01   enable RX interrupt
        //          (LSR DATA_READY bit only asserts when irq_en=1)
        //  Step 5. Transmit 0x55 to THR
        // ═════════════════════════════════════════════════════════════

        $display("\n[TEST 07] UART init sequence via m02 (0x0200_0000)");
        $display("  Step 1: LCR=0x83 (DLAB=1, 8N1) to open baud divisor");
        axi_write(UART_LCR, 32'h0000_0083);

        $display("  Step 2: BAUD_DIV=0x%04h (%0d) for 115200 baud @ 100MHz",
                  BAUD_DIV, BAUD_DIV);
        axi_write(UART_BAUD, BAUD_DIV);

        $display("  Step 3: LCR=0x03 (DLAB=0, 8N1) to lock baud, open data regs");
        axi_write(UART_LCR, 32'h0000_0003);

        $display("  Step 4: IER=0x01 — enable RX interrupt");
        axi_write(UART_IER, 32'h0000_0001);

        // Verify LCR readback
       
        /*
        axi_read(UART_LCR, rd_data);
        if (rd_data[7:0] === 8'h03) begin
            $display("  [PASS] LCR readback = 0x%02h (DLAB=0, 8N1)", rd_data[7:0]);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] LCR readback: exp=0x03 got=0x%02h", rd_data[7:0]);
            fail_cnt = fail_cnt + 1;
        end*/

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 08] UART transmit 0x55 ('U') — write to THR");
        $display("  AXI write  addr=0x%08h  data=0x55 → THR", UART_THR);
        // ─────────────────────────────────────────────────────────────
        axi_write(UART_THR, 32'h0000_0055);
        $display("  Write accepted by UART (bvalid received)");
        pass_cnt = pass_cnt + 1;

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 09] UART LSR — poll THRE (TX holding register empty)");
        // ─────────────────────────────────────────────────────────────
        uart_wait_thre(uart_tmo);
        axi_read(UART_LSR, rd_data);
        $display("  LSR = 0x%08h  [THRE=%0b TEMT=%0b DATA_READY=%0b]",
                  rd_data, rd_data[5], rd_data[6], rd_data[0]);
        if (!uart_tmo && rd_data[5]) begin
            $display("  [PASS] THRE asserted — TX FIFO drained to shift reg");
            pass_cnt = pass_cnt + 1;
        end else if (uart_tmo) begin
            $display("  [FAIL] THRE never asserted (timeout)"); fail_cnt = fail_cnt + 1;
        end else begin
            $display("  [FAIL] THRE not set in LSR"); fail_cnt = fail_cnt + 1;
        end

        if (rd_data[6]) begin
            $display("  [PASS] TEMT asserted — shift register also empty");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [INFO] TEMT not yet set (byte still shifting out)");
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 10] UART RX loopback — 0x55 TX→RX via loopback wire");
        $display("  Waiting %0d clock cycles (~1 byte at %0d baud)",
                  BAUD_DIV*12, BAUD_DIV);
        // One UART byte = 10 bit-periods (1 start + 8 data + 1 stop)
        // Add 20% margin → wait 12 * BAUD_DIV clocks
        // ─────────────────────────────────────────────────────────────
        repeat(BAUD_DIV * 12) @(posedge clk);

        // Check LSR[0] = DATA_READY (requires IER[0]=1)
        axi_read(UART_LSR, rd_data);
        $display("  LSR after wait = 0x%08h [DATA_READY=%0b]",
                  rd_data, rd_data[0]);

        if (rd_data[0]) begin
            $display("  [PASS] LSR DATA_READY — received byte ready in RBR");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] LSR DATA_READY not set after loopback wait");
            fail_cnt = fail_cnt + 1;
        end

        // Read RBR — received byte
        axi_read(UART_RBR, rd_data);
        $display("  RBR = 0x%02h  (expected 0x55 = ASCII 'U')", rd_data[7:0]);
        if (rd_data[7:0] === 8'h55) begin
            $display("  [PASS] Loopback byte 0x55 correctly received"); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Loopback byte mismatch: exp=0x55 got=0x%02h", rd_data[7:0]);
            fail_cnt = fail_cnt + 1;
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 11] Dummy slave m03 routing (0x0300_0000)");
        // ─────────────────────────────────────────────────────────────
        axi_read(DUM_BASE, rd_data);
        if (rd_data === 32'hDEAD_0003) begin
            $display("  [PASS] Dummy m03 = 0x%08h", rd_data); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Dummy m03: exp=0xDEAD0003 got=0x%08h", rd_data);
            fail_cnt = fail_cnt + 1;
        end

        // ─────────────────────────────────────────────────────────────
        $display("\n[TEST 12] AES soft-reset (CTRL.RST)");
        // ─────────────────────────────────────────────────────────────
        axi_write(AES_CTRL, 32'h0000_0004);
        repeat(4) @(posedge clk);
        axi_read(AES_CTRL, rd_data);
        if (rd_data[17:16] === 2'b00) begin
            $display("  [PASS] STATUS[17:16]=0 after soft-reset"); pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] STATUS not cleared: [17:16]=%02b", rd_data[17:16]);
            fail_cnt = fail_cnt + 1;
        end

        // ─────────────────────────────────────────────────────────────
        $display("");
        $display("=============================================================");
        $display("  RESULTS:  %0d PASS   %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED ***");
        $display("=============================================================");
        $display("");

        repeat(20) @(posedge clk);
        $finish;
    end

    // ── Watchdog ──────────────────────────────────────────────────────────
    // 868 cycles/bit * 12 bits/byte * ~50 bytes margin = ~520k cycles
    // 520k * 10 ns = 5.2 ms  → use 20 ms watchdog
    initial begin
        #20_000_000;
        $display("ERROR: simulation watchdog fired at %0t ns", $realtime);
        $finish;
    end

endmodule
