// =============================================================================
// tb_soc_all_ip_veer.v
//
// Testbench for Secure IoT Gateway SoC + VeeR EL2 — All-IP Firmware Test
//
// DUT: soc_top_with_veer  (VeeR EL2 RISC-V + AXI interconnect 3x12 + all IPs)
//
// Firmware (.hex) is pre-loaded into VeeR ICCM at 0xEE000000.
// Reset vector: 0x80000000
//
// Features:
//   - UART loopback (TX→RX) for firmware serial output
//   - UART byte deserializer monitor (prints each received character)
//   - VeeR instruction trace monitor
//   - FSDB waveform dump for Verdi (all SoC signals + deep hierarchy)
//   - GPIO loopback (io[31:0] self-connect for readback tests)
//   - I2C open-drain pullup emulation
//   - SPI MISO tie to 0
//   - Timeout watchdog
//
// Usage:
//   vcs -sverilog -full64 -f run_soc_all_ip_veer.f \
//       -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab \
//          $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
//       -o simv_all_ip
//   ./simv_all_ip +hex_file+../firmware/soc_all_ip_test.hex
//   verdi -f run_soc_all_ip_veer.f -ssf dump_all_ip.fsdb &
// =============================================================================

`timescale 1ns/1ps

module tb_soc_all_ip_veer;

    // ── Parameters ─────────────────────────────────────────────────────
    localparam DW        = 32;
    localparam AW        = 32;
    localparam IDW       = 8;
    localparam SW        = DW/8;
    localparam CLK_HALF  = 5;            // 5 ns half-period → 100 MHz
    localparam SIM_TIMEOUT = 200_000_000; // 200 ms in ns (sufficient for all UART output)

    // ── VeeR boot vector ───────────────────────────────────────────────
    // VeeR reset vector is 0xEE000000 (ICCM base).  The [31:1] representation is 0x77000000.
    localparam [31:1] RESET_VEC = 31'h7700_0000;  // 0xEE000000 >> 1
    localparam [31:1] NMI_VEC   = 31'h7700_0100;
    localparam [31:1] JTAG_ID   = 31'h0000_0001;

    // ── DUT signals ────────────────────────────────────────────────────
    reg         clk;
    reg         rst_n;

    // VeeR boot / debug control
    wire [31:1] rst_vec    = RESET_VEC;
    wire [31:1] nmi_vec    = NMI_VEC;
    wire [31:1] jtag_id    = JTAG_ID;
    wire        nmi_int    = 1'b0;

    // JTAG — tie off (no debug access in simulation)
    wire        jtag_tck   = 1'b0;
    wire        jtag_tms   = 1'b1;
    wire        jtag_tdi   = 1'b0;
    wire        jtag_tdo;

    // Spare AXI master port (s01) — tied off
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

    // s01 outputs (ignored)
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

    // I2C — open-drain pullup emulation
    wire scl_pad_o, scl_padoen_o;
    wire sda_pad_o, sda_padoen_o;
    wire i2c_irq;
    // Open-drain: pad = 0 when master drives low, else pulled high
    wire scl_pad_i = scl_padoen_o ? 1'b1 : scl_pad_o;
    wire sda_pad_i = sda_padoen_o ? 1'b1 : sda_pad_o;

    // UART — loopback TX→RX for firmware serial I/O
    wire uart_tx_o;
    wire uart_irq;
    reg  uart_rx_i;

    // SPI — MISO tied to 0 (no SPI slave in simulation)
    wire spi_clk_o, spi_cs_n_o, spi_mosi_o;
    wire spi_miso_i = 1'b0;

    // GPIO — self-loopback for readback tests
    // Connect gpio_io as bidirectional: outputs feed back as inputs
    wire [31:0] gpio_io;
    wire        gpio_irq;

    // GPIO self-loopback: drive gpio_io from a weak driver so the firmware
    // can write (set as output) and read back its own values.
    // In RTL inout, the direction is controlled by the GPIO DIR register.
    // For simulation, we just let the wire float (Z) when input, and
    // the SoC drives it when output.  No external pull needed for
    // register readback tests (firmware reads DATA_O, not DATA_I).

    // DMA status
    wire dma_done, dma_error;

    // VeeR trace outputs
    wire [31:0] trace_rv_i_insn_ip;
    wire [31:0] trace_rv_i_address_ip;
    wire        trace_rv_i_valid_ip;
    wire        trace_rv_i_exception_ip;
    wire [4:0]  trace_rv_i_ecause_ip;
    wire        trace_rv_i_interrupt_ip;
    wire [31:0] trace_rv_i_tval_ip;

    // ── Clock Generation ───────────────────────────────────────────────
    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    // UART loopback (TX → RX with zero delay for RTL simulation)
    always @(*) uart_rx_i = uart_tx_o;

    // ── DUT Instantiation ──────────────────────────────────────────────
    soc_top_with_veer #(
        .DATA_WIDTH (DW),
        .ADDR_WIDTH (AW),
        .ID_WIDTH   (IDW)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),

        // VeeR control
        .rst_vec          (rst_vec),
        .nmi_vec          (nmi_vec),
        .jtag_id          (jtag_id),
        .nmi_int          (nmi_int),

        // JTAG
        .jtag_tck         (jtag_tck),
        .jtag_tms         (jtag_tms),
        .jtag_tdi         (jtag_tdi),
        .jtag_tdo         (jtag_tdo),

        // Spare AXI master (s01) — tied off
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

        // I2C
        .scl_pad_i        (scl_pad_i),
        .scl_pad_o        (scl_pad_o),
        .scl_padoen_o     (scl_padoen_o),
        .sda_pad_i        (sda_pad_i),
        .sda_pad_o        (sda_pad_o),
        .sda_padoen_o     (sda_padoen_o),
        .i2c_irq          (i2c_irq),

        // UART
        .uart_tx_o        (uart_tx_o),
        .uart_rx_i        (uart_rx_i),
        .uart_irq         (uart_irq),

        // SPI
        .spi_clk_o        (spi_clk_o),
        .spi_cs_n_o       (spi_cs_n_o),
        .spi_mosi_o       (spi_mosi_o),
        .spi_miso_i       (spi_miso_i),

        // GPIO
        .gpio_io          (gpio_io),
        .gpio_irq         (gpio_irq),

        // DMA
        .dma_done         (dma_done),
        .dma_error        (dma_error),

        // VeeR trace
        .trace_rv_i_insn_ip      (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip   (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip     (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip    (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip (trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip      (trace_rv_i_tval_ip)
    );

    // ── Firmware load into ICCM ────────────────────────────────────────
    // VeeR EL2 ICCM SRAM is accessed via the behavioral memory model.
    // The hex file is loaded using $readmemh into the ICCM array.
    //
    // Plusarg: +hex_file+path/to/firmware.hex
    // Default: ../firmware/soc_all_ip_test.hex
    //
    // The ICCM is inside: dut.u_veer (el2_veer_wrapper)
    //   → el2_mem → iccm banks
    // The exact hierarchical path depends on VeeR config.
    // Common path: dut.u_veer.veer.mem.iccm.mem.iccm_bank[0].mem_bank.ram_data
    // ─────────────────────────────────────────────────────────────────
    string hex_file;
    string hex_bank0, hex_bank1, hex_bank2, hex_bank3;
    string dccm_bank0, dccm_bank1, dccm_bank2, dccm_bank3;
    integer i;

    initial begin
        // Get hex file path from plusarg or use default
        if (!$value$plusargs("hex_file+%s", hex_file))
            hex_file = "firmware/soc_all_ip_test.hex";

        $display("[TB] ============================================");
        $display("[TB]   Secure-IoT-Gateway-SoC  All-IP VeeR Test");
        $display("[TB] ============================================");
        $display("[TB] Firmware : %s", hex_file);
        $display("[TB] Reset vec: 0xEE000000");
        $display("[TB] ICCM base: 0xEE000000");
        $display("[TB] Sim timeout: %0t ns", SIM_TIMEOUT);

        // Build per-bank file paths: same directory, soc_all_ip_test_bankN.hex
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
            $sformat(hex_bank0, "%s/soc_all_ip_test_bank0.hex", base_dir);
            $sformat(hex_bank1, "%s/soc_all_ip_test_bank1.hex", base_dir);
            $sformat(hex_bank2, "%s/soc_all_ip_test_bank2.hex", base_dir);
            $sformat(hex_bank3, "%s/soc_all_ip_test_bank3.hex", base_dir);

            $sformat(dccm_bank0, "%s/soc_all_ip_test_dccm_bank0.hex", base_dir);
            $sformat(dccm_bank1, "%s/soc_all_ip_test_dccm_bank1.hex", base_dir);
            $sformat(dccm_bank2, "%s/soc_all_ip_test_dccm_bank2.hex", base_dir);
            $sformat(dccm_bank3, "%s/soc_all_ip_test_dccm_bank3.hex", base_dir);
        end

        // Zero-initialize all ICCM and DCCM banks so unwritten lines have valid data + ECC
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

        $display("[TB] Loading ICCM per-bank interleaved hex via hierarchical $readmemh ...");
        $readmemh(hex_bank0, dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core);
        $readmemh(hex_bank1, dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core);
        $readmemh(hex_bank2, dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core);
        $readmemh(hex_bank3, dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core);

        // Fix up ECC for every ICCM word (7-bit SECDED Hamming code)
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
        $display("[TB] ICCM per-bank load + ECC fix-up complete.");
        $display("[TB] ICCM: bank0[0]=0x%08h, bank1[0]=0x%08h, bank2[0]=0x%08h, bank3[0]=0x%08h",
            dut.Gen_iccm_enable.iccm_loop[0].iccm_bank.ram_core[0][31:0],
            dut.Gen_iccm_enable.iccm_loop[1].iccm_bank.ram_core[0][31:0],
            dut.Gen_iccm_enable.iccm_loop[2].iccm_bank.ram_core[0][31:0],
            dut.Gen_iccm_enable.iccm_loop[3].iccm_bank.ram_core[0][31:0]);

        $display("[TB] Loading DCCM per-bank interleaved hex via hierarchical $readmemh ...");
        $readmemh(dccm_bank0, dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core);
        $readmemh(dccm_bank1, dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core);
        $readmemh(dccm_bank2, dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core);
        $readmemh(dccm_bank3, dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core);

        // Fix up ECC for every DCCM word (7-bit SECDED Hamming code)
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
        $display("[TB] DCCM per-bank load + ECC fix-up complete.");
        $display("[TB] DCCM: bank0[0]=0x%08h, bank1[0]=0x%08h, bank2[0]=0x%08h, bank3[0]=0x%08h",
            dut.Gen_dccm_enable.dccm_loop[0].dccm_bank.ram_core[0][31:0],
            dut.Gen_dccm_enable.dccm_loop[1].dccm_bank.ram_core[0][31:0],
            dut.Gen_dccm_enable.dccm_loop[2].dccm_bank.ram_core[0][31:0],
            dut.Gen_dccm_enable.dccm_loop[3].dccm_bank.ram_core[0][31:0]);
    end

    // ── Reset sequence ─────────────────────────────────────────────────
    initial begin
        rst_n = 1'b0;
        repeat(20) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[TB] Reset released at time %0t ns", $time);
    end

    // =========================================================================
    // FSDB Waveform Dump for Verdi
    // =========================================================================
    // Dumps the entire TB hierarchy plus key DUT internal signals.
    // The FSDB file is named "dump_all_ip.fsdb".
    //
    // Requires VCS compiled with:
    //   -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab
    //      $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a
    // =========================================================================
`ifdef FSDB
    initial begin
        // Create FSDB file
        $fsdbDumpfile("dump_all_ip.fsdb");

        // Dump top-level TB signals (all DUT ports, clocks, reset)
        $fsdbDumpvars(0, tb_soc_all_ip_veer);

        // Dump VeeR core internals (el2_veer_wrapper hierarchy)
        $fsdbDumpvars(2, dut.u_veer);

        // Dump SoC subsystem (interconnect + all IPs)
        $fsdbDumpvars(1, dut.u_soc);

        // Dump interconnect internal signals
        $fsdbDumpvars(1, dut.u_soc.u_ic);

        // Dump each IP's internal signals for debugging
        $fsdbDumpvars(1, dut.u_soc.u_i2c);       // I2C master
        $fsdbDumpvars(1, dut.u_soc.u_wb_bridge);  // AXI→WB bridge
        $fsdbDumpvars(1, dut.u_soc.u_aes);        // AES
        $fsdbDumpvars(1, dut.u_soc.u_uart);       // UART
        $fsdbDumpvars(1, dut.u_soc.u_spi);        // SPI
        $fsdbDumpvars(1, dut.u_soc.u_gpio);       // GPIO
        $fsdbDumpvars(1, dut.u_soc.u_prog_mem);   // AXI RAM (program)
        $fsdbDumpvars(1, dut.u_soc.u_data_mem);   // AXI RAM (data)
        $fsdbDumpvars(1, dut.u_soc.u_dma_wrapper_v); // DMA

        // Dump the 64-to-32 AXI adapter
        $fsdbDumpvars(1, dut.u_lsu_adapter);

        // Dump all MDAs (memory arrays) for ICCM/DCCM
        $fsdbDumpMDA();

        $display("[TB] FSDB dump started: dump_all_ip.fsdb");
    end
`endif

    // =========================================================================
    // Instruction Trace Monitor
    // =========================================================================
    // Prints each executed instruction from the VeeR trace port.
    // Useful for debugging firmware execution flow.
    // =========================================================================
    reg enable_trace;
    reg enable_axi_trace;
    initial begin
        enable_trace     = $test$plusargs("trace");
        enable_axi_trace = $test$plusargs("axi_trace");
    end

    always @(posedge clk) begin
        if (trace_rv_i_valid_ip && rst_n) begin
            if (trace_rv_i_exception_ip) begin
                $display("[EXCEPTION] t=%0t PC=0x%08h INSN=0x%08h ecause=%0d tval=0x%08h",
                    $time, trace_rv_i_address_ip, trace_rv_i_insn_ip,
                    trace_rv_i_ecause_ip, trace_rv_i_tval_ip);
            end else if (enable_trace) begin
                $display("[TRACE] t=%0t PC=0x%08h INSN=0x%08h",
                    $time, trace_rv_i_address_ip, trace_rv_i_insn_ip);
            end
        end
    end

    // =========================================================================
    // UART Byte Deserializer Monitor & Pass/Fail Detection
    // =========================================================================
    // Detects start bit on uart_tx_o and deserializes 8 data bits.
    // Prints each received character to the log.
    // Baud period depends on firmware UART init (BAUD_DIV = 868 → 115200).
    // =========================================================================
    localparam BAUD_PERIOD_NS = 1010;  // (100+1) clocks @ 10 ns (matches SIM_BAUD_DIV = 100)
    localparam BAUD_HALF_NS   = BAUD_PERIOD_NS / 2;

    reg [7:0] uart_rx_byte;
    integer   uart_bit_cnt;
    reg       uart_sampling;
    integer   uart_byte_count;
    reg [8*24-1:0] rx_window;

    reg test_done;
    reg test_result;  // 1 = pass, 0 = fail

    string uart_line;

    initial begin
        uart_sampling   = 0;
        uart_byte_count = 0;
        rx_window       = '0;
        test_done       = 0;
        test_result     = 0;
        uart_line       = "";
    end

    always @(negedge uart_tx_o) begin
        if (!uart_sampling && rst_n) begin
            uart_sampling = 1;
            // Skip start bit, sample at center of each data bit
            #(BAUD_PERIOD_NS + BAUD_HALF_NS);
            uart_rx_byte = 8'h00;
            for (uart_bit_cnt = 0; uart_bit_cnt < 8; uart_bit_cnt = uart_bit_cnt + 1) begin
                uart_rx_byte[uart_bit_cnt] = uart_tx_o;
                #BAUD_PERIOD_NS;
            end
            uart_byte_count = uart_byte_count + 1;
            rx_window = {rx_window[8*23-1:0], uart_rx_byte};

            if (uart_rx_byte == 8'h0a) begin  // Newline: print buffered line
                if (uart_line.len() > 0) begin
                    $display("[UART-OUT] %s", uart_line);
                    uart_line = "";
                end
            end else if (uart_rx_byte >= 8'h20 && uart_rx_byte < 8'h7f) begin
                uart_line = {uart_line, string'(uart_rx_byte)};
            end

            // Check for test completion:
            // 1. Control characters: 0x04 (EOT = all pass), 0x15 (NAK = some fail)
            // 2. Sliding window string matching: "ALL TESTS PASSED" or "SOME TESTS FAILED"
            if (!test_done) begin
                if (uart_rx_byte == 8'h04 || rx_window[8*16-1:0] == "ALL TESTS PASSED") begin
                    test_done   = 1;
                    test_result = 1;
                    $display("");
                    $display("[RESULT] =================================================");
                    $display("[RESULT] *** ALL IP TESTS PASSED ***");
                    $display("[RESULT] =================================================");
                    $display("");
                end else if (uart_rx_byte == 8'h15 || rx_window[8*17-1:0] == "SOME TESTS FAILED") begin
                    test_done   = 1;
                    test_result = 0;
                    $display("");
                    $display("[RESULT] =================================================");
                    $display("[RESULT] *** SOME IP TESTS FAILED ***");
                    $display("[RESULT] =================================================");
                    $display("");
                end
            end

            uart_sampling = 0;
        end
    end

    // =========================================================================
    // AXI Transaction Monitor (VeeR LSU → Interconnect s00)
    // =========================================================================
    // Tracks AXI writes/reads from the VeeR core to identify which IP
    // is being accessed at what time.
    // =========================================================================
    reg [31:0] last_awaddr;
    reg [31:0] last_araddr;

    always @(posedge clk) begin
        if (rst_n) begin
            // Monitor AXI write address handshakes
            if (dut.lsu_axi_awvalid && dut.lsu_axi_awready) begin
                last_awaddr = dut.lsu_axi_awaddr;
                $display("[AXI-W] t=%0t AWADDR=0x%08h (IP: %s)",
                    $time, dut.lsu_axi_awaddr,
                    (dut.lsu_axi_awaddr[31:24] == 8'h00) ? "I2C"  :
                    (dut.lsu_axi_awaddr[31:24] == 8'h01) ? "AES"  :
                    (dut.lsu_axi_awaddr[31:24] == 8'h02) ? "UART" :
                    (dut.lsu_axi_awaddr[31:24] == 8'h03) ? "SPI"  :
                    (dut.lsu_axi_awaddr[31:24] == 8'h04) ? "GPIO" :
                    (dut.lsu_axi_awaddr[31:24] == 8'h05) ? "PROG_RAM" :
                    (dut.lsu_axi_awaddr[31:24] == 8'h06) ? "DATA_RAM" :
                    (dut.lsu_axi_awaddr[31:24] == 8'h0B) ? "DMA"  :
                    "DUMMY/UNKNOWN");
            end

            // Monitor AXI read address handshakes (filter repeated polling of same address)
            if (dut.lsu_axi_arvalid && dut.lsu_axi_arready) begin
                if (dut.lsu_axi_araddr != last_araddr) begin
                    last_araddr = dut.lsu_axi_araddr;
                    $display("[AXI-R] t=%0t ARADDR=0x%08h (IP: %s)",
                        $time, dut.lsu_axi_araddr,
                        (dut.lsu_axi_araddr[31:24] == 8'h00) ? "I2C"  :
                        (dut.lsu_axi_araddr[31:24] == 8'h01) ? "AES"  :
                        (dut.lsu_axi_araddr[31:24] == 8'h02) ? "UART" :
                        (dut.lsu_axi_araddr[31:24] == 8'h03) ? "SPI"  :
                        (dut.lsu_axi_araddr[31:24] == 8'h04) ? "GPIO" :
                        (dut.lsu_axi_araddr[31:24] == 8'h05) ? "PROG_RAM" :
                        (dut.lsu_axi_araddr[31:24] == 8'h06) ? "DATA_RAM" :
                        (dut.lsu_axi_araddr[31:24] == 8'h0B) ? "DMA"  :
                        "DUMMY/UNKNOWN");
                end
            end

            if (dut.lsu_axi_bvalid && dut.lsu_axi_bready && enable_axi_trace) begin
                $display("[AXI-B] t=%0t BRESP=%b BID=%h", $time, dut.lsu_axi_bresp, dut.lsu_axi_bid);
            end
            if (dut.lsu_axi_rvalid && dut.lsu_axi_rready && enable_axi_trace) begin
                $display("[AXI-R] t=%0t RDATA=0x%08h RRESP=%b RID=%h", $time, dut.lsu_axi_rdata, dut.lsu_axi_rresp, dut.lsu_axi_rid);
            end
        end
    end

    // =========================================================================
    // Simulation Timeout & Finish
    // =========================================================================
    initial begin
        #(SIM_TIMEOUT);
        if (!test_done) begin
            $display("[TB] TIMEOUT at %0t ns — no final result from firmware.", $time);
            $display("[TB] Check waveforms: dump_all_ip.fsdb");
            $display("[TB] UART bytes received: %0d", uart_byte_count);
        end
        $finish;
    end

    // Finish simulation shortly after test result is detected
    always @(posedge clk) begin
        if (test_done) begin
            repeat(100) @(posedge clk);
            $display("[TB] Simulation finished at %0t ns", $time);
            $finish;
        end
    end

    // =========================================================================
    // VeeR EL2 ECC generation function (7-bit SECDED Hamming over 32 data bits)
    // =========================================================================
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
