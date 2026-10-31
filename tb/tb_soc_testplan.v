// =============================================================================
// tb_soc_testplan.v
//
// Testbench for Secure IoT Gateway SoC + VeeR EL2: UVM Test Plan Verification
//
// DUT: soc_top_with_veer  (VeeR EL2 RISC-V + AXI interconnect 3x12 + all IPs)
//
// Firmware: firmware/soc_testplan.hex (preloaded into ICCM at 0xEE000000)
//
// Features:
//   - Zero-delay UART loopback (TX -> RX)
//   - Real-time UART monitor displaying all [TEST:...] PASS/FAIL results
//   - FSDB waveform dumping ("dump_soc_testplan.fsdb") for Verdi
//   - Verification of all UVM testplan target IDs
//   - Comprehensive end-of-test scoreboard and summary
// =============================================================================

`timescale 1ns/1ps

module tb_soc_testplan;

    // ── Parameters ─────────────────────────────────────────────────────
    localparam DW        = 32;
    localparam AW        = 32;
    localparam IDW       = 8;
    localparam SW        = DW/8;
    localparam CLK_HALF  = 5;            // 5 ns half-period -> 100 MHz
    localparam SIM_TIMEOUT = 2_000_000_000; // 2 seconds in ns

    // ── VeeR boot vector ───────────────────────────────────────────────
    localparam [31:1] RESET_VEC = 31'h7700_0000;  // 0xEE000000 >> 1
    localparam [31:1] NMI_VEC   = 31'h7700_0100;
    localparam [31:1] JTAG_ID   = 31'h0000_0001;

    // ── DUT signals ────────────────────────────────────────────────────
    reg         clk;
    reg         rst_n;

    wire [31:1] rst_vec    = RESET_VEC;
    wire [31:1] nmi_vec    = NMI_VEC;
    wire [31:1] jtag_id    = JTAG_ID;
    wire        nmi_int    = 1'b0;

    // JTAG tied off
    wire        jtag_tck   = 1'b0;
    wire        jtag_tms   = 1'b1;
    wire        jtag_tdi   = 1'b0;
    wire        jtag_tdo;

    // Spare AXI master (s01) tied off
    wire [IDW-1:0]   s01_axi_awid    = {IDW{1'b0}};
    wire [AW-1:0]    s01_axi_awaddr  = {AW{1'b0}};
    wire [7:0]       s01_axi_awlen   = 8'h0;
    wire [2:0]       s01_axi_awsize  = 3'h0;
    wire [1:0]       s01_axi_awburst = 2'b01;
    wire             s01_axi_awlock  = 1'b0;
    wire [3:0]       s01_axi_awcache = 4'h0;
    wire [2:0]       s01_axi_awprot  = 3'h0;
    wire [3:0]       s01_axi_awqos   = 4'h0;
    wire             s01_axi_awvalid = 1'b0;
    wire [DW-1:0]    s01_axi_wdata   = {DW{1'b0}};
    wire [SW-1:0]    s01_axi_wstrb   = {SW{1'b0}};
    wire             s01_axi_wlast   = 1'b0;
    wire             s01_axi_wvalid  = 1'b0;
    wire             s01_axi_bready  = 1'b0;
    wire [IDW-1:0]   s01_axi_arid    = {IDW{1'b0}};
    wire [AW-1:0]    s01_axi_araddr  = {AW{1'b0}};
    wire [7:0]       s01_axi_arlen   = 8'h0;
    wire [2:0]       s01_axi_arsize  = 3'h0;
    wire [1:0]       s01_axi_arburst = 2'b01;
    wire             s01_axi_arlock  = 1'b0;
    wire [3:0]       s01_axi_arcache = 4'h0;
    wire [2:0]       s01_axi_arprot  = 3'h0;
    wire [3:0]       s01_axi_arqos   = 4'h0;
    wire             s01_axi_arvalid = 1'b0;
    wire             s01_axi_rready  = 1'b0;

    wire             s01_axi_awready;
    wire             s01_axi_wready;
    wire [IDW-1:0]   s01_axi_bid;
    wire [1:0]       s01_axi_bresp;
    wire             s01_axi_bvalid;
    wire             s01_axi_arready;
    wire [IDW-1:0]   s01_axi_rid;
    wire [DW-1:0]    s01_axi_rdata;
    wire [1:0]       s01_axi_rresp;
    wire             s01_axi_rlast;
    wire             s01_axi_rvalid;

    // I2C open-drain pullup emulation
    wire scl_pad_o, scl_padoen_o;
    wire sda_pad_o, sda_padoen_o;
    wire i2c_irq;
    wire scl_pad_i = scl_padoen_o ? 1'b1 : scl_pad_o;
    wire sda_pad_i = sda_padoen_o ? 1'b1 : sda_pad_o;
    wire i2c_scl_line = scl_pad_i;
    wire i2c_sda_line = sda_pad_i;

    // UART
    wire uart_tx_o;
    wire uart_irq;
    reg  uart_rx_i;

    // SPI
    wire spi_clk_o, spi_cs_n_o, spi_mosi_o;
    wire spi_miso_i = 1'b0;

    // GPIO
    wire [31:0] gpio_io;
    wire        gpio_irq;

    // DMA
    wire dma_done, dma_error;

    // VeeR trace
    wire [31:0] trace_rv_i_insn_ip;
    wire [31:0] trace_rv_i_address_ip;
    wire        trace_rv_i_valid_ip;
    wire        trace_rv_i_exception_ip;
    wire [4:0]  trace_rv_i_ecause_ip;
    wire        trace_rv_i_interrupt_ip;
    wire [31:0] trace_rv_i_tval_ip;

    // Clock Generation
    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    // UART loopback (zero delay)
    always @(*) uart_rx_i = uart_tx_o;

    // ── DUT Instantiation ──────────────────────────────────────────────
    soc_top_with_veer #(
        .DATA_WIDTH (DW),
        .ADDR_WIDTH (AW),
        .ID_WIDTH   (IDW)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),

        .rst_vec          (rst_vec),
        .nmi_vec          (nmi_vec),
        .jtag_id          (jtag_id),
        .nmi_int          (nmi_int),

        .jtag_tck         (jtag_tck),
        .jtag_tms         (jtag_tms),
        .jtag_tdi         (jtag_tdi),
        .jtag_tdo         (jtag_tdo),

        .s01_axi_awid     (s01_axi_awid),
        .s01_axi_awaddr   (s01_axi_awaddr),
        .s01_axi_awlen    (s01_axi_awlen),
        .s01_axi_awsize   (s01_axi_awsize),
        .s01_axi_awburst  (s01_axi_awburst),
        .s01_axi_awlock   (s01_axi_awlock),
        .s01_axi_awcache  (s01_axi_awcache),
        .s01_axi_awprot   (s01_axi_awprot),
        .s01_axi_awqos    (s01_axi_awqos),
        .s01_axi_awvalid  (s01_axi_awvalid),
        .s01_axi_awready  (s01_axi_awready),
        .s01_axi_wdata    (s01_axi_wdata),
        .s01_axi_wstrb    (s01_axi_wstrb),
        .s01_axi_wlast    (s01_axi_wlast),
        .s01_axi_wvalid   (s01_axi_wvalid),
        .s01_axi_wready   (s01_axi_wready),
        .s01_axi_bid      (s01_axi_bid),
        .s01_axi_bresp    (s01_axi_bresp),
        .s01_axi_bvalid   (s01_axi_bvalid),
        .s01_axi_bready   (s01_axi_bready),
        .s01_axi_arid     (s01_axi_arid),
        .s01_axi_araddr   (s01_axi_araddr),
        .s01_axi_arlen    (s01_axi_arlen),
        .s01_axi_arsize   (s01_axi_arsize),
        .s01_axi_arburst  (s01_axi_arburst),
        .s01_axi_arlock   (s01_axi_arlock),
        .s01_axi_arcache  (s01_axi_arcache),
        .s01_axi_arprot   (s01_axi_arprot),
        .s01_axi_arqos    (s01_axi_arqos),
        .s01_axi_arvalid  (s01_axi_arvalid),
        .s01_axi_arready  (s01_axi_arready),
        .s01_axi_rid      (s01_axi_rid),
        .s01_axi_rdata    (s01_axi_rdata),
        .s01_axi_rresp    (s01_axi_rresp),
        .s01_axi_rlast    (s01_axi_rlast),
        .s01_axi_rvalid   (s01_axi_rvalid),
        .s01_axi_rready   (s01_axi_rready),

        .scl_pad_i        (scl_pad_i),
        .scl_pad_o        (scl_pad_o),
        .scl_padoen_o     (scl_padoen_o),
        .sda_pad_i        (sda_pad_i),
        .sda_pad_o        (sda_pad_o),
        .sda_padoen_o     (sda_padoen_o),
        .i2c_irq          (i2c_irq),

        .uart_tx_o        (uart_tx_o),
        .uart_rx_i        (uart_rx_i),
        .uart_irq         (uart_irq),

        .spi_clk_o        (spi_clk_o),
        .spi_cs_n_o       (spi_cs_n_o),
        .spi_mosi_o       (spi_mosi_o),
        .spi_miso_i       (spi_miso_i),

        .gpio_io          (gpio_io),
        .gpio_irq         (gpio_irq),

        .dma_done         (dma_done),
        .dma_error        (dma_error),

        .trace_rv_i_insn_ip      (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip   (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip     (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip    (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip (trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip      (trace_rv_i_tval_ip)
    );

    // ── Firmware load into ICCM & DCCM ──────────────────────────────────
    string hex_file;
    string hex_bank0, hex_bank1, hex_bank2, hex_bank3;
    string dccm_bank0, dccm_bank1, dccm_bank2, dccm_bank3;

    initial begin
        if (!$value$plusargs("hex_file+%s", hex_file))
            hex_file = "firmware/soc_testplan.hex";

        $display("[TB] ===================================================");
        $display("[TB]   Secure-IoT-Gateway-SoC : UVM Test Plan Run");
        $display("[TB] ===================================================");
        $display("[TB] Firmware target: %s", hex_file);
        $display("[TB] Reset vector   : 0xEE000000");

        begin : build_bank_paths
            string base_dir;
            integer ci, last_slash;
            last_slash = -1;
            for (ci = 0; ci < hex_file.len(); ci = ci + 1)
                if (hex_file.getc(ci) == "/") last_slash = ci;
            if (last_slash >= 0)
                base_dir = hex_file.substr(0, last_slash);
            else
                base_dir = ".";

            $sformat(hex_bank0, "%s/soc_testplan_bank0.hex", base_dir);
            $sformat(hex_bank1, "%s/soc_testplan_bank1.hex", base_dir);
            $sformat(hex_bank2, "%s/soc_testplan_bank2.hex", base_dir);
            $sformat(hex_bank3, "%s/soc_testplan_bank3.hex", base_dir);

            $sformat(dccm_bank0, "%s/soc_testplan_dccm_bank0.hex", base_dir);
            $sformat(dccm_bank1, "%s/soc_testplan_dccm_bank1.hex", base_dir);
            $sformat(dccm_bank2, "%s/soc_testplan_dccm_bank2.hex", base_dir);
            $sformat(dccm_bank3, "%s/soc_testplan_dccm_bank3.hex", base_dir);
        end

        // Zero-initialize memory arrays
        begin : mem_zero_init
            integer idx;
            for (idx = 0; idx < `RV_ICCM_ROWS; idx = idx + 1) begin
                dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core[idx] = 39'h0;
            end
            for (idx = 0; idx < `RV_DCCM_ROWS; idx = idx + 1) begin
                dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core[idx] = 39'h0;
                dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core[idx] = 39'h0;
            end
        end

        $display("[TB] Loading ICCM per-bank interleaved hex files...");
        $readmemh(hex_bank0, dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core);
        $readmemh(hex_bank1, dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core);
        $readmemh(hex_bank2, dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core);
        $readmemh(hex_bank3, dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core);

        // Fix up ECC for ICCM
        begin : iccm_ecc_fixup
            integer idx;
            reg [31:0] d;
            reg [6:0]  e;
            for (idx = 0; idx < `RV_ICCM_ROWS; idx = idx + 1) begin
                d = dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core[idx][38:32] = e;
            end
        end

        $display("[TB] Loading DCCM per-bank interleaved hex files...");
        $readmemh(dccm_bank0, dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core);
        $readmemh(dccm_bank1, dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core);
        $readmemh(dccm_bank2, dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core);
        $readmemh(dccm_bank3, dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core);

        // Fix up ECC for DCCM
        begin : dccm_ecc_fixup
            integer idx;
            reg [31:0] d;
            reg [6:0]  e;
            for (idx = 0; idx < `RV_DCCM_ROWS; idx = idx + 1) begin
                d = dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core[idx][38:32] = e;

                d = dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core[idx][31:0];
                e = rvecc32(d);
                dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core[idx][38:32] = e;
            end
        end
        $display("[TB] Memory loading and 7-bit SECDED ECC initialization complete.");
    end

    // ── Reset sequence ─────────────────────────────────────────────────
    initial begin
        rst_n = 1'b0;
        repeat(20) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[TB] Reset released at time %0t ns", $time);
    end

    // ── Waveform dump (FSDB for Verdi) ─────────────────────────────────
`ifdef FSDB
    initial begin
        $fsdbDumpfile("dump_soc_testplan.fsdb");
        $fsdbDumpvars(0, tb_soc_testplan);
        $fsdbDumpvars(0, dut.u_soc);
        $fsdbDumpvars(2, dut.u_veer);
        $fsdbDumpMDA();
        $display("[TB] FSDB waveform dump enabled: dump_soc_testplan.fsdb");
    end
`endif

    // ── UART Deserializer and Test Plan Tracker ────────────────────────
    localparam BAUD_PERIOD_NS = 1010;  // matches SIM_BAUD_DIV = 100
    localparam BAUD_HALF_NS   = BAUD_PERIOD_NS / 2;

    reg [7:0] uart_rx_byte;
    integer   uart_bit_cnt;
    reg       uart_sampling;
    integer   test_pass_count = 0;
    integer   test_fail_count = 0;

    reg test_done;
    string uart_line;

    initial begin
        uart_sampling   = 0;
        test_done       = 0;
        uart_line       = "";
    end

    always @(negedge uart_tx_o) begin
        if (!uart_sampling && rst_n) begin
            uart_sampling = 1;
            #(BAUD_PERIOD_NS + BAUD_HALF_NS);
            uart_rx_byte = 8'h00;
            for (uart_bit_cnt = 0; uart_bit_cnt < 8; uart_bit_cnt = uart_bit_cnt + 1) begin
                uart_rx_byte[uart_bit_cnt] = uart_tx_o;
                #BAUD_PERIOD_NS;
            end

            if (uart_rx_byte == 8'h0a) begin
                if (uart_line.len() > 0) begin
                    $display("[TESTPLAN-LOG] %s", uart_line);
                    if (uart_line.substr(uart_line.len()-4, uart_line.len()-1) == "PASS")
                        test_pass_count = test_pass_count + 1;
                    else if (uart_line.substr(uart_line.len()-4, uart_line.len()-1) == "FAIL")
                        test_fail_count = test_fail_count + 1;
                    uart_line = "";
                end
            end else if (uart_rx_byte >= 8'h20 && uart_rx_byte < 8'h7f) begin
                uart_line = {uart_line, string'(uart_rx_byte)};
            end

            // Check for test completion
            if (uart_rx_byte == 8'h04) begin
                test_done = 1;
            end

            uart_sampling = 0;
        end
    end

    // Timeout watchdog
    initial begin
        #(SIM_TIMEOUT);
        if (!test_done) begin
            $display("[TB] ERROR: Simulation TIMEOUT reached (%0t ns)!", $time);
        end
        $finish;
    end

    // End simulation after test completion
    always @(posedge clk) begin
        if (test_done) begin
            repeat(100) @(posedge clk);
            $display("\n=======================================================");
            $display("         UVM TEST PLAN VERIFICATION SUMMARY           ");
            $display("=======================================================");
            $display(" Total Test Cases Passed: %0d", test_pass_count);
            $display(" Total Test Cases Failed: %0d", test_fail_count);
            if (test_fail_count == 0 && test_pass_count > 0) begin
                $display(" OVERALL RESULT: *** ALL TEST PLAN CASES PASSED ***");
            end else begin
                $display(" OVERALL RESULT: *** TEST PLAN SUITE FAILED ***");
            end
            $display(" Waveform file : dump_soc_testplan.fsdb");
            $display("=======================================================\n");
            $finish;
        end
    end

    // ECC 7-bit Hamming SECDED generator function
    function automatic [6:0] rvecc32;
        input [31:0] din;
        reg [5:0] t;
        begin
            t[0] = din[0]^din[1]^din[3]^din[4]^din[6]^din[8]^din[10]^din[11]^din[13]^din[15]^din[17]^din[19]^din[21]^din[23]^din[25]^din[26]^din[28]^din[30];
            t[1] = din[0]^din[2]^din[3]^din[5]^din[6]^din[9]^din[10]^din[12]^din[13]^din[16]^din[17]^din[20]^din[21]^din[24]^din[25]^din[27]^din[28]^din[31];
            t[2] = din[1]^din[2]^din[3]^din[7]^din[8]^din[9]^din[10]^din[14]^din[15]^din[16]^din[17]^din[22]^din[23]^din[24]^din[25]^din[29]^din[30]^din[31];
            t[3] = din[4]^din[5]^din[6]^din[7]^din[8]^din[9]^din[10]^din[18]^din[19]^din[20]^din[21]^din[22]^din[23]^din[24]^din[25];
            t[4] = din[11]^din[12]^din[13]^din[14]^din[15]^din[16]^din[17]^din[18]^din[19]^din[20]^din[21]^din[22]^din[23]^din[24]^din[25];
            t[5] = din[26]^din[27]^din[28]^din[29]^din[30]^din[31];
            rvecc32 = {(^din[31:0])^(^t[5:0]), t[5:0]};
        end
    endfunction

endmodule
