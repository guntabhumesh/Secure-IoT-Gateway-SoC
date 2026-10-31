// =============================================================================
// tb_soc_vips.sv
//
// Integrated UVM Testbench for Secure-IoT-Gateway-SoC with Active VIPs:
//   - UART VIP:  Protocol verification of serial TX, loopback byte, C-test lines
//   - SPI VIP:   Protocol verification of CS_N, SCLK, and MOSI multi-byte data
//   - I2C VIP:   Protocol verification of START/STOP, Addr 0xA0, Bytes 0x5A/0xA5, Slave ACK
//   - GPIO VIP:  Protocol verification of atomic pin transitions
//
// Runs the C firmware testplan (soc_testplan.hex) inside the VeeR EL2 core
// and validates every external interface transaction via UVM VIP scoreboards.
// =============================================================================

`timescale 1ns/1ps
`default_nettype wire

`include "common_defines.vh"

import uvm_pkg::*;
`include "uvm_macros.svh"
import soc_vip_pkg::*;

module tb_soc_vips;

    // ── Parameters ─────────────────────────────────────────────────────────
    localparam CLK_PERIOD_NS = 10;          // 100 MHz clock
    localparam RST_HOLD_NS   = 200000;      // 200 us reset hold
    localparam SIM_TIMEOUT   = 100_000_000; // 100 ms simulation timeout
    localparam DW            = 32;
    localparam AW            = 32;
    localparam IDW           = 8;

    // ── System Signals ─────────────────────────────────────────────────────
    reg clk;
    reg rst_n;

    // ── Clocks & Resets ────────────────────────────────────────────────────
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #(RST_HOLD_NS);
        rst_n = 1'b1;
        $display("[TB] Reset released at time %0t ns", $time);
    end

    // ── UVM Interface Instantiations ───────────────────────────────────────
    uart_if u_uart_if (.clk(clk), .rst_n(rst_n));
    spi_if  u_spi_if  (.clk(clk), .rst_n(rst_n));
    i2c_if  u_i2c_if  (.clk(clk), .rst_n(rst_n));
    gpio_if u_gpio_if (.clk(clk), .rst_n(rst_n));

    // ── Tie-offs for unused top-level ports ─────────────────────────────────
    wire [IDW-1:0] s01_axi_awid    = {IDW{1'b0}};
    wire [AW-1:0]  s01_axi_awaddr  = {AW{1'b0}};
    wire [7:0]     s01_axi_awlen   = 8'h0;
    wire [2:0]     s01_axi_awsize  = 3'b010;
    wire [1:0]     s01_axi_awburst = 2'b01;
    wire           s01_axi_awlock  = 1'b0;
    wire [3:0]     s01_axi_awcache = 4'b0;
    wire [2:0]     s01_axi_awprot  = 3'b0;
    wire [3:0]     s01_axi_awqos   = 4'b0;
    wire           s01_axi_awvalid = 1'b0;
    wire           s01_axi_awready;
    wire [DW-1:0]  s01_axi_wdata   = {DW{1'b0}};
    wire [DW/8-1:0] s01_axi_wstrb  = 4'h0;
    wire           s01_axi_wlast   = 1'b0;
    wire           s01_axi_wvalid  = 1'b0;
    wire           s01_axi_wready;
    wire [IDW-1:0] s01_axi_bid;
    wire [1:0]     s01_axi_bresp;
    wire           s01_axi_bvalid;
    wire           s01_axi_bready  = 1'b0;
    wire [IDW-1:0] s01_axi_arid    = {IDW{1'b0}};
    wire [AW-1:0]  s01_axi_araddr  = {AW{1'b0}};
    wire [7:0]     s01_axi_arlen   = 8'h0;
    wire [2:0]     s01_axi_arsize  = 3'b010;
    wire [1:0]     s01_axi_arburst = 2'b01;
    wire           s01_axi_arlock  = 1'b0;
    wire [3:0]     s01_axi_arcache = 4'b0;
    wire [2:0]     s01_axi_arprot  = 3'b0;
    wire [3:0]     s01_axi_arqos   = 4'b0;
    wire           s01_axi_arvalid = 1'b0;
    wire           s01_axi_arready;
    wire [IDW-1:0] s01_axi_rid;
    wire [DW-1:0]  s01_axi_rdata;
    wire [1:0]     s01_axi_rresp;
    wire           s01_axi_rlast;
    wire           s01_axi_rvalid;
    wire           s01_axi_rready  = 1'b0;

    // ── VeeR boot vector ───────────────────────────────────────────────
    localparam [31:1] RESET_VEC = 31'h7700_0000;  // 0xEE000000 >> 1
    localparam [31:1] NMI_VEC   = 31'h7700_0100;
    localparam [31:1] JTAG_ID   = 31'h0000_0001;

    wire [31:1] rst_vec    = RESET_VEC;
    wire [31:1] nmi_vec    = NMI_VEC;
    wire [31:1] jtag_id    = JTAG_ID;
    wire        nmi_int    = 1'b0;
    wire        jtag_tck   = 1'b0;
    wire        jtag_tms   = 1'b0;
    wire        jtag_tdi   = 1'b0;
    wire        jtag_tdo;

    // ── External Pins & VIP Connections ────────────────────────────────────
    wire [31:0] gpio_io;
    assign u_gpio_if.gpio_o  = gpio_io;
    assign u_gpio_if.gpio_oe = 32'h0;
    assign u_gpio_if.gpio_i  = 32'h0;

    // UART loopback connection
    assign u_uart_if.uart_rx_i = u_uart_if.uart_tx_o;

    // SPI tie-offs
    assign u_spi_if.spi_miso_i = 1'b0;

    // I2C open-drain pullup emulation
    wire scl_pad_i = u_i2c_if.scl_padoen_o ? 1'b1 : u_i2c_if.scl_pad_o;
    wire sda_pad_i = u_i2c_if.sda_padoen_o ? 1'b1 : u_i2c_if.sda_pad_o;
    assign u_i2c_if.scl_pad_i = scl_pad_i;
    assign u_i2c_if.sda_pad_i = sda_pad_i;

    // Interrupts & Status
    wire i2c_irq;
    wire uart_irq;
    wire gpio_irq;
    wire dma_done;
    wire dma_error;

    // ── DUT: soc_top_with_veer ─────────────────────────────────────────────
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

        // Master port 1 (spare)
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

        // I2C -> Connected to i2c_if
        .scl_pad_i        (scl_pad_i),
        .scl_pad_o        (u_i2c_if.scl_pad_o),
        .scl_padoen_o     (u_i2c_if.scl_padoen_o),
        .sda_pad_i        (sda_pad_i),
        .sda_pad_o        (u_i2c_if.sda_pad_o),
        .sda_padoen_o     (u_i2c_if.sda_padoen_o),
        .i2c_irq          (i2c_irq),

        // UART -> Connected to uart_if
        .uart_tx_o        (u_uart_if.uart_tx_o),
        .uart_rx_i        (u_uart_if.uart_rx_i),
        .uart_irq         (uart_irq),

        // SPI -> Connected to spi_if
        .spi_clk_o        (u_spi_if.spi_clk_o),
        .spi_cs_n_o       (u_spi_if.spi_cs_n_o),
        .spi_mosi_o       (u_spi_if.spi_mosi_o),
        .spi_miso_i       (u_spi_if.spi_miso_i),

        // GPIO -> Connected to gpio_if
        .gpio_io          (gpio_io),
        .gpio_irq         (gpio_irq),

        // DMA
        .dma_done         (dma_done),
        .dma_error        (dma_error)
    );

    // ── 7-bit SECDED ECC Function ──────────────────────────────────────────
    function automatic [6:0] rvecc32(input [31:0] d);
        reg [6:0] e;
        begin
            e[0] = d[0]  ^ d[1]  ^ d[3]  ^ d[4]  ^ d[6]  ^ d[8]  ^ d[10] ^ d[11] ^
                   d[13] ^ d[15] ^ d[17] ^ d[19] ^ d[21] ^ d[23] ^ d[25] ^ d[26] ^
                   d[28] ^ d[30];
            e[1] = d[0]  ^ d[2]  ^ d[3]  ^ d[5]  ^ d[6]  ^ d[9]  ^ d[10] ^ d[12] ^
                   d[13] ^ d[16] ^ d[17] ^ d[20] ^ d[21] ^ d[24] ^ d[25] ^ d[27] ^
                   d[28] ^ d[31];
            e[2] = d[1]  ^ d[2]  ^ d[3]  ^ d[7]  ^ d[8]  ^ d[9]  ^ d[10] ^ d[14] ^
                   d[15] ^ d[16] ^ d[17] ^ d[22] ^ d[23] ^ d[24] ^ d[25] ^ d[29] ^
                   d[30] ^ d[31];
            e[3] = d[4]  ^ d[5]  ^ d[6]  ^ d[7]  ^ d[8]  ^ d[9]  ^ d[10] ^ d[18] ^
                   d[19] ^ d[20] ^ d[21] ^ d[22] ^ d[23] ^ d[24] ^ d[25];
            e[4] = d[11] ^ d[12] ^ d[13] ^ d[14] ^ d[15] ^ d[16] ^ d[17] ^ d[18] ^
                   d[19] ^ d[20] ^ d[21] ^ d[22] ^ d[23] ^ d[24] ^ d[25];
            e[5] = d[26] ^ d[27] ^ d[28] ^ d[29] ^ d[30] ^ d[31];
            e[6] = ^{d, e[5:0]};
            rvecc32 = e;
        end
    endfunction

    // ── Firmware Preload & UVM DB Registration ─────────────────────────────
    string hex_file;
    string base_dir;
    string hex_bank0, hex_bank1, hex_bank2, hex_bank3;
    string dccm_bank0, dccm_bank1, dccm_bank2, dccm_bank3;

    initial begin
        $display("==========================================================");
        $display("  Secure-IoT-Gateway-SoC : C-Test + UVM VIP Verification ");
        $display("==========================================================");

        if (!$value$plusargs("hex_file=%s", hex_file)) begin
            hex_file = "firmware/soc_testplan.hex";
        end
        $display("[TB] Target C Firmware : %s", hex_file);

        // Derive bank paths
        begin : path_split
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

        // Zero-initialize memories
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

        $display("[TB] Preloading ICCM bank hex files...");
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

        $display("[TB] Preloading DCCM bank hex files...");
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

        $display("[TB] Preload and ECC generation complete.");

        // Register virtual interfaces with UVM config database
        uvm_config_db#(virtual uart_if)::set(null, "*uart_ag*", "vif", u_uart_if);
        uvm_config_db#(virtual spi_if)::set(null,  "*spi_ag*",  "vif", u_spi_if);
        uvm_config_db#(virtual i2c_if)::set(null,  "*i2c_ag*",  "vif", u_i2c_if);
        uvm_config_db#(virtual gpio_if)::set(null, "*gpio_ag*", "vif", u_gpio_if);

        // Start UVM Test
        run_test("soc_c_test");
    end

    // ── Waveform Dump ──────────────────────────────────────────────────────
`ifdef FSDB
    initial begin
        $fsdbDumpfile("dump_soc_vips.fsdb");
        $fsdbDumpvars(0, tb_soc_vips);
        $fsdbDumpvars(0, dut.u_soc);
        $fsdbDumpvars(2, dut.u_veer);
        $fsdbDumpMDA();
        $display("[TB] FSDB waveform dump enabled: dump_soc_vips.fsdb");
    end
`endif

    // ── Watchdog and End of Simulation Detection ───────────────────────────
    localparam BAUD_PERIOD_NS = 1010;
    localparam BAUD_HALF_NS   = BAUD_PERIOD_NS / 2;

    reg [7:0] uart_rx_byte;
    integer   uart_bit_cnt;
    reg       uart_sampling = 0;
    reg       test_done     = 0;

    always @(negedge u_uart_if.uart_tx_o) begin
        if (!uart_sampling && rst_n) begin
            uart_sampling = 1;
            #(BAUD_PERIOD_NS + BAUD_HALF_NS);
            uart_rx_byte = 8'h00;
            for (uart_bit_cnt = 0; uart_bit_cnt < 8; uart_bit_cnt = uart_bit_cnt + 1) begin
                uart_rx_byte[uart_bit_cnt] = u_uart_if.uart_tx_o;
                #BAUD_PERIOD_NS;
            end
            if (uart_rx_byte == 8'h04) begin // EOT detected from C firmware
                test_done = 1;
            end
            uart_sampling = 0;
        end
    end

    initial begin
        #(SIM_TIMEOUT);
        if (!test_done) begin
            $display("[TB] ERROR: Simulation TIMEOUT reached (%0t ns)!", $time);
        end
        $finish;
    end

    uvm_event done_ev;
    initial begin
        done_ev = uvm_event_pool::get_global("test_done_ev");
    end

    always @(posedge clk) begin
        if (test_done) begin
            $display("\n=======================================================");
            $display("   *** ALL C-TEST AND VIP VERIFICATIONS COMPLETE ***   ");
            $display("   Handing over to UVM report_phase for VIP scoreboards");
            $display("=======================================================\n");
            done_ev.trigger();
            @(posedge clk);
            wait(!test_done);
        end
    end

endmodule
`default_nettype wire
