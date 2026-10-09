`timescale 1ns/1ps

module tb_soc_all_ips ();

    // Clock and Reset
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    localparam ID_WIDTH = 8;
    localparam DATA_WIDTH = 32;

    // AXI S00 Interfaces
    logic [ID_WIDTH-1:0]    s00_axi_awid;
    logic [31:0]            s00_axi_awaddr;
    logic [7:0]             s00_axi_awlen;
    logic [2:0]             s00_axi_awsize;
    logic [1:0]             s00_axi_awburst;
    logic                   s00_axi_awlock;
    logic [3:0]             s00_axi_awcache;
    logic [2:0]             s00_axi_awprot;
    logic [3:0]             s00_axi_awqos;
    logic                   s00_axi_awvalid;
    logic                   s00_axi_awready;

    logic [DATA_WIDTH-1:0]  s00_axi_wdata;
    logic [3:0]             s00_axi_wstrb;
    logic                   s00_axi_wlast;
    logic                   s00_axi_wvalid;
    logic                   s00_axi_wready;

    logic [ID_WIDTH-1:0]    s00_axi_bid;
    logic [1:0]             s00_axi_bresp;
    logic                   s00_axi_bvalid;
    logic                   s00_axi_bready;

    logic [ID_WIDTH-1:0]    s00_axi_arid;
    logic [31:0]            s00_axi_araddr;
    logic [7:0]             s00_axi_arlen;
    logic [2:0]             s00_axi_arsize;
    logic [1:0]             s00_axi_arburst;
    logic                   s00_axi_arlock;
    logic [3:0]             s00_axi_arcache;
    logic [2:0]             s00_axi_arprot;
    logic [3:0]             s00_axi_arqos;
    logic                   s00_axi_arvalid;
    logic                   s00_axi_arready;

    logic [ID_WIDTH-1:0]    s00_axi_rid;
    logic [DATA_WIDTH-1:0]  s00_axi_rdata;
    logic [1:0]             s00_axi_rresp;
    logic                   s00_axi_rlast;
    logic                   s00_axi_rvalid;
    logic                   s00_axi_rready;

    // Other signals
    logic scl_pad_i, scl_pad_o, scl_padoen_o;
    logic sda_pad_i, sda_pad_o, sda_padoen_o;
    logic i2c_irq;

    logic uart_tx_o, uart_rx_i, uart_irq;

    logic spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i;

    wire [31:0] gpio_io;
    logic gpio_irq;

    assign scl_pad_i = 1'b1;
    assign sda_pad_i = 1'b1;
    assign uart_rx_i = 1'b1;
    assign spi_miso_i = 1'b0;

    // Instantiate SoC Top
    soc_top u_soc (
        .clk(clk),
        .rst_n(rst_n),

        // S00 AXI (CPU)
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos), .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready), .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos), .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready), .s00_axi_rid(s00_axi_rid),
        .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast), .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),

        // S01 AXI (Tie off)
        .s01_axi_awid(0), .s01_axi_awaddr(0), .s01_axi_awlen(0),
        .s01_axi_awsize(0), .s01_axi_awburst(0), .s01_axi_awlock(0),
        .s01_axi_awcache(0), .s01_axi_awprot(0), .s01_axi_awqos(0),
        .s01_axi_awvalid(0), .s01_axi_wdata(0), .s01_axi_wstrb(0),
        .s01_axi_wlast(0), .s01_axi_wvalid(0), .s01_axi_bready(1),
        .s01_axi_arid(0), .s01_axi_araddr(0), .s01_axi_arlen(0),
        .s01_axi_arsize(0), .s01_axi_arburst(0), .s01_axi_arlock(0),
        .s01_axi_arcache(0), .s01_axi_arprot(0), .s01_axi_arqos(0),
        .s01_axi_arvalid(0), .s01_axi_rready(1),

        // Peripherals
        .scl_pad_i(scl_pad_i), .scl_pad_o(scl_pad_o), .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda_pad_i), .sda_pad_o(sda_pad_o), .sda_padoen_o(sda_padoen_o),
        .i2c_irq(i2c_irq),

        .uart_tx_o(uart_tx_o), .uart_rx_i(uart_rx_i), .uart_irq(uart_irq),

        .spi_clk_o(spi_clk_o), .spi_cs_n_o(spi_cs_n_o), .spi_mosi_o(spi_mosi_o), .spi_miso_i(spi_miso_i),

        .gpio_io(gpio_io), .gpio_irq(gpio_irq)
    );

    // Initializations
    initial begin
        s00_axi_awid = 0; s00_axi_awaddr = 0; s00_axi_awlen = 0;
        s00_axi_awsize = 3'b010; s00_axi_awburst = 2'b01; s00_axi_awlock = 0;
        s00_axi_awcache = 0; s00_axi_awprot = 0; s00_axi_awqos = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata = 0; s00_axi_wstrb = 4'hF; s00_axi_wlast = 0;
        s00_axi_wvalid = 0;
        s00_axi_bready = 0;
        s00_axi_arid = 0; s00_axi_araddr = 0; s00_axi_arlen = 0;
        s00_axi_arsize = 3'b010; s00_axi_arburst = 2'b01; s00_axi_arlock = 0;
        s00_axi_arcache = 0; s00_axi_arprot = 0; s00_axi_arqos = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready = 0;
    end

    // Structured logging helper tasks
    task log_op(input string op, input string ip_name, input string reg_name, input logic [31:0] addr, input logic [31:0] data, input string desc);
        $display("   [SUCCESS] %s -> %s %s (0x%08h) = 0x%08h", ip_name, op, reg_name, addr, data);
        $display("             Meaning: %s", desc);
    endtask

    // AXI Write Task
    task axi_write(input string ip_name, input string reg_name, input logic [31:0] addr, input logic [31:0] data, input string desc);
        begin
            $display("\n[AXI WRITE] Routing to %s from interconnect port s00_axi", ip_name);
            $display("   -> AWADDR (Write Address Phase): 0x%08h", addr);
            $display("   -> WDATA  (Write Data Phase)   : 0x%08h", data);
            
            @(posedge clk);
            s00_axi_awaddr = addr;
            s00_axi_awvalid = 1;
            s00_axi_wdata = data;
            s00_axi_wvalid = 1;
            s00_axi_wlast = 1;
            s00_axi_bready = 1;

            fork
                begin
                    wait(s00_axi_awready && s00_axi_awvalid);
                    @(posedge clk);
                    s00_axi_awvalid = 0;
                end
                begin
                    wait(s00_axi_wready && s00_axi_wvalid);
                    @(posedge clk);
                    s00_axi_wvalid = 0;
                    s00_axi_wlast = 0;
                end
            join

            wait(s00_axi_bvalid && s00_axi_bready);
            @(posedge clk);
            s00_axi_bready = 0;

            log_op("WRITE", ip_name, reg_name, addr, data, desc);
        end
    endtask

    // AXI Read Task
    task axi_read(input string ip_name, input string reg_name, input logic [31:0] addr, output logic [31:0] rdata, input string desc);
        begin
            $display("\n[AXI READ]  Routing to %s from interconnect port s00_axi", ip_name);
            $display("   -> ARADDR (Read Address Phase) : 0x%08h", addr);
            
            @(posedge clk);
            s00_axi_araddr = addr;
            s00_axi_arvalid = 1;
            s00_axi_rready = 1;

            wait(s00_axi_arready && s00_axi_arvalid);
            @(posedge clk);
            s00_axi_arvalid = 0;

            wait(s00_axi_rvalid && s00_axi_rready);
            rdata = s00_axi_rdata;
            @(posedge clk);
            s00_axi_rready = 0;

            $display("   -> RDATA  (Read Data Phase)    : 0x%08h", rdata);
            log_op("READ", ip_name, reg_name, addr, rdata, desc);
        end
    endtask

    // Main Test Sequence
    logic [31:0] read_val;
    logic [31:0] tmo;

    initial begin
        wait(rst_n == 1);
        #100;
        $display("=========================================================================");
        $display("             Starting Complete IP Configuration Test (Verbose)           ");
        $display("=========================================================================");

        // -----------------------------------------------------------
        // Test I2C (m00 @ 0x0000_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING I2C_MASTER ---");
        $display("-----------------------------------------------------------");
        axi_write("I2C_MASTER", "PRER_LO", 32'h0000_0000, 32'h00000063, "Prescaler Register Low Byte - sets the lower byte of the I2C clock divider.");
        axi_write("I2C_MASTER", "PRER_HI", 32'h0000_0004, 32'h00000000, "Prescaler Register High Byte - sets the upper byte of the I2C clock divider.");
        axi_write("I2C_MASTER", "CTR",     32'h0000_0008, 32'h00000080, "Control Register - Bit 7 (EN) is set to 1 to enable the I2C core.");
        axi_read ("I2C_MASTER", "CTR",     32'h0000_0008, read_val,     "Verify that the Control Register EN bit was set to 1.");
        if (read_val[7:0] !== 8'h80) $display("ERROR: I2C CTR mismatch!");

        // -----------------------------------------------------------
        // Test AES (m01 @ 0x0100_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING AES_CORE ---");
        $display("-----------------------------------------------------------");
        axi_write("AES_CORE", "KEY0", 32'h0100_0008, 32'h2B7E1516, "Cryptographic Key Word 0 (Bits [127:96])");
        axi_write("AES_CORE", "KEY1", 32'h0100_000C, 32'h28AED2A6, "Cryptographic Key Word 1 (Bits [95:64])");
        axi_write("AES_CORE", "KEY2", 32'h0100_0010, 32'hABF71588, "Cryptographic Key Word 2 (Bits [63:32])");
        axi_write("AES_CORE", "KEY3", 32'h0100_0014, 32'h09CF4F3C, "Cryptographic Key Word 3 (Bits [31:0])");
        
        axi_write("AES_CORE", "TXIN0", 32'h0100_0018, 32'h6BC1BEE2, "Plaintext Input Word 0 (Bits [127:96])");
        axi_write("AES_CORE", "TXIN1", 32'h0100_001C, 32'h2E409F96, "Plaintext Input Word 1 (Bits [95:64])");
        axi_write("AES_CORE", "TXIN2", 32'h0100_0020, 32'hE93D7E11, "Plaintext Input Word 2 (Bits [63:32])");
        axi_write("AES_CORE", "TXIN3", 32'h0100_0024, 32'h7393172A, "Plaintext Input Word 3 (Bits [31:0])");
        
        axi_write("AES_CORE", "CTRL",  32'h0100_0000, 32'h00000001, "Control Register - Bit 0 is set to trigger the start of encryption.");
        
        tmo = 0;
        read_val = 0;
        while ((read_val & 1) == 0 && tmo < 100) begin
            axi_read("AES_CORE", "STATUS", 32'h0100_0004, read_val, "Status Register - Polling Bit 0 to check if encryption is complete.");
            tmo++;
        end
        
        axi_read("AES_CORE", "TXOUT0", 32'h0100_0028, read_val, "Ciphertext Output Word 0 (Bits [127:96])");
        axi_read("AES_CORE", "TXOUT1", 32'h0100_002C, read_val, "Ciphertext Output Word 1 (Bits [95:64])");
        axi_read("AES_CORE", "TXOUT2", 32'h0100_0030, read_val, "Ciphertext Output Word 2 (Bits [63:32])");
        axi_read("AES_CORE", "TXOUT3", 32'h0100_0034, read_val, "Ciphertext Output Word 3 (Bits [31:0])");

        // -----------------------------------------------------------
        // Test UART (m02 @ 0x0200_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING UART ---");
        $display("-----------------------------------------------------------");
        axi_write("UART", "LCR",     32'h0200_000C, 32'h00000083, "Line Control Register - Writing 0x83 sets DLAB=1 (allows setting baud divisor) and 8N1 mode.");
        axi_write("UART", "DIVISOR", 32'h0200_0008, 32'h000001B2, "Baud Divisor Register - Writing 434 (0x1B2) to set baud rate to 115200 @ 50MHz.");
        axi_write("UART", "LCR",     32'h0200_000C, 32'h00000003, "Line Control Register - Writing 0x03 clears DLAB (locking baud rate) and keeps 8N1 mode.");
        axi_write("UART", "THR",     32'h0200_0000, 32'h00000041, "Transmit Holding Register - Pushing ASCII 'A' (0x41) into the TX FIFO to be transmitted.");
        
        tmo = 0;
        read_val = 0;
        while ((read_val & 32'h20) == 0 && tmo < 100) begin
            axi_read("UART", "LSR", 32'h0200_0014, read_val, "Line Status Register - Polling Bit 5 (THRE) to ensure the Transmit FIFO is empty.");
            tmo++;
        end

        // -----------------------------------------------------------
        // Test SPI (m03 @ 0x0300_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING SPI ---");
        $display("-----------------------------------------------------------");
        axi_write("SPI", "RCLK", 32'h0300_0030, 32'h00000004, "Ratio Clock Register - Sets the internal SPI clock divisor to 4.");
        axi_write("SPI", "CR",   32'h0300_0060, 32'h00000186, "Control Register - Bit 1 (SPI Enable) and Bit 2 (Master Mode) are set.");
        axi_write("SPI", "SSR",  32'h0300_0070, 32'hFFFFFFFE, "Slave Select Register - Bit 0 is pulled low to assert Chip Select 0.");
        axi_write("SPI", "DTR",  32'h0300_0068, 32'h00000055, "Data Transmit Register - Pushing 0x55 into the TX FIFO to be shifted out on MOSI.");
        
        tmo = 0;
        read_val = 0;
        while ((read_val & 32'h04) == 0 && tmo < 100) begin
            axi_read("SPI", "SR", 32'h0300_0064, read_val, "Status Register - Polling Bit 2 (TX Empty) to ensure data was sent.");
            tmo++;
        end
        axi_read ("SPI", "DRR", 32'h0300_006C, read_val, "Data Receive Register - Reads whatever was shifted in on MISO during the transaction.");

        // -----------------------------------------------------------
        // Test GPIO (m04 @ 0x0400_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING GPIO ---");
        $display("-----------------------------------------------------------");
        axi_write("GPIO", "DIR",    32'h0400_0008, 32'hFFFFFFFF, "Direction Register - Writing all 1s configures all 32 GPIO pins as outputs.");
        axi_write("GPIO", "DATA_O", 32'h0400_0004, 32'h12345678, "Output Data Register - Driving the physical output pins with 0x12345678.");
        axi_read ("GPIO", "DATA_I", 32'h0400_0000, read_val,     "Input Data Register - Reading the current state of the physical pins (loopback).");

        // -----------------------------------------------------------
        // Test DMA CSR (m11 @ 0x0B00_0000)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- CONFIGURING DMA CSR ---");
        $display("-----------------------------------------------------------");
        // Write to dma_control register at offset 0x00
        axi_write("DMA_CSR", "CTRL", 32'h0B00_0000, 32'h00000000, "Writing to DMA Control register (Offset 0x00). Should succeed without deadlocking.");
        axi_read ("DMA_CSR", "CTRL", 32'h0B00_0000, read_val,     "Reading back from DMA Control register.");
        
        // Read dma_status register at offset 0x08
        axi_read ("DMA_CSR", "STATUS", 32'h0B00_0008, read_val,   "Reading DMA Status register (Offset 0x08).");

        // -----------------------------------------------------------
        // Test PROG RAM & DATA RAM (m05, m06)
        // -----------------------------------------------------------
        $display("\n-----------------------------------------------------------");
        $display("--- TESTING MEMORIES ---");
        $display("-----------------------------------------------------------");
        axi_write("PROG_RAM", "RAM", 32'h0500_1000, 32'hAABBCCDD, "Writing to Program RAM at offset 0x1000.");
        axi_read ("PROG_RAM", "RAM", 32'h0500_1000, read_val,     "Reading back from Program RAM to verify.");
        if (read_val !== 32'hAABBCCDD) $display("ERROR: PROG_RAM mismatch!");

        axi_write("DATA_RAM", "RAM", 32'h0600_2000, 32'h11223344, "Writing to Data RAM at offset 0x2000.");
        axi_read ("DATA_RAM", "RAM", 32'h0600_2000, read_val,     "Reading back from Data RAM to verify.");
        if (read_val !== 32'h11223344) $display("ERROR: DATA_RAM mismatch!");

        $display("\n=========================================================================");
        $display("                   Integration Test Completed Successfully               ");
        $display("=========================================================================\n");
        $finish;
    end

endmodule
