`timescale 1ns/1ps

module tb_spi_gpio_vcs;

  // --------------------------------------------------------
  // Clocks and Reset
  // --------------------------------------------------------
  logic clk;
  logic fixed_clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  initial begin
    fixed_clk = 0;
    forever #10 fixed_clk = ~fixed_clk; // 50MHz
  end

  initial begin
    rst_n = 0;
    #50;
    rst_n = 1;
  end

  // --------------------------------------------------------
  // SPI AXI Lite Interface
  // --------------------------------------------------------
  logic [31:0] spi_awaddr;
  logic        spi_awvalid;
  logic        spi_awready;
  logic [31:0] spi_wdata;
  logic [3:0]  spi_wstrb;
  logic        spi_wvalid;
  logic        spi_wready;
  logic [1:0]  spi_bresp;
  logic        spi_bvalid;
  logic        spi_bready;
  logic [31:0] spi_araddr;
  logic        spi_arvalid;
  logic        spi_arready;
  logic [31:0] spi_rdata;
  logic [1:0]  spi_rresp;
  logic        spi_rvalid;
  logic        spi_rready;

  // SPI I/O
  logic spi_clk_out;
  logic spi_cs_n_out;
  logic spi_mosi_out;
  logic spi_miso_in;

  // Instantiate SPI IP
  axi_spi_top u_spi_top (
    .fixed_clk_i   (fixed_clk),
    .axi_aclk_i    (clk),
    .axi_aresetn_i (rst_n),

    // Write Address
    .axi_awid_i    (8'h0),
    .axi_awaddr_i  (spi_awaddr),
    .axi_awvalid_i (spi_awvalid),
    .axi_awready_o (spi_awready),

    // Write Data
    .axi_wdata_i   (spi_wdata),
    .axi_wstrb_i   (spi_wstrb),
    .axi_wvalid_i  (spi_wvalid),
    .axi_wready_o  (spi_wready),

    // Write Response
    .axi_bready_i  (spi_bready),
    .axi_bid_o     (),
    .axi_bresp_o   (spi_bresp),
    .axi_bvalid_o  (spi_bvalid),

    // Read Address
    .axi_arid_i    (8'h0),
    .axi_araddr_i  (spi_araddr),
    .axi_arvalid_i (spi_arvalid),
    .axi_arready_o (spi_arready),

    // Read Data
    .axi_rready_i  (spi_rready),
    .axi_rid_o     (),
    .axi_rdata_o   (spi_rdata),
    .axi_rresp_o   (spi_rresp),
    .axi_rvalid_o  (spi_rvalid),

    // External SPI Interface
    .spi_clk_o     (spi_clk_out),
    .spi_cs_n_o    (spi_cs_n_out),
    .spi_mosi_o    (spi_mosi_out),
    .spi_miso_i    (spi_miso_in)
  );

  // --------------------------------------------------------
  // GPIO Integration Placeholder
  // --------------------------------------------------------
  // Note: The PULP Platform GPIO IP relies on external packages 
  // (`register_interface`, `common_cells`, `axi`) which are currently missing 
  // from the repository. Below is the framework to instantiate the 
  // AXI Lite wrapper once those dependencies are resolved.

  /*
  logic [31:0] gpio_in;
  logic [31:0] gpio_out;
  logic [31:0] gpio_tx_en;
  
  gpio_axi_lite_wrap #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) u_gpio_wrap (
    .clk_i        (clk),
    .rst_ni       (rst_n),
    .gpio_in      (gpio_in),
    .gpio_out     (gpio_out),
    .gpio_tx_en_o (gpio_tx_en),
    // AXI Lite Req/Rsp structs would be mapped here
    // based on the `axi_lite_req_t` defined in `axi/typedef.svh`
    .axi_lite_req_i ( '0 ),
    .axi_lite_rsp_o ( )
  );
  */

  // --------------------------------------------------------
  // AXI Lite Tasks
  // --------------------------------------------------------
  task axi_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      spi_awaddr  <= addr;
      spi_awvalid <= 1;
      spi_wdata   <= data;
      spi_wstrb   <= 4'hF;
      spi_wvalid  <= 1;
      spi_bready  <= 1;

      // Wait for AWREADY and WREADY
      fork
        begin
          wait(spi_awvalid && spi_awready);
          @(posedge clk);
          spi_awvalid <= 0;
        end
        begin
          wait(spi_wvalid && spi_wready);
          @(posedge clk);
          spi_wvalid <= 0;
        end
      join

      // Wait for BVALID
      wait(spi_bvalid && spi_bready);
      @(posedge clk);
      spi_bready <= 0;
      $display("[%0t] AXI Write to %08h: %08h", $time, addr, data);
    end
  endtask

  task axi_read(input [31:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      spi_araddr  <= addr;
      spi_arvalid <= 1;
      spi_rready  <= 1;

      // Wait for ARREADY
      wait(spi_arvalid && spi_arready);
      @(posedge clk);
      spi_arvalid <= 0;

      // Wait for RVALID
      wait(spi_rvalid && spi_rready);
      data = spi_rdata;
      @(posedge clk);
      spi_rready <= 0;
      $display("[%0t] AXI Read from %08h: %08h", $time, addr, data);
    end
  endtask

  // --------------------------------------------------------
  // Test Stimulus
  // --------------------------------------------------------
  logic [31:0] rd_data;

  initial begin
    // Init AXI Lite signals
    spi_awaddr  = 0;
    spi_awvalid = 0;
    spi_wdata   = 0;
    spi_wstrb   = 0;
    spi_wvalid  = 0;
    spi_bready  = 0;
    spi_araddr  = 0;
    spi_arvalid = 0;
    spi_rready  = 0;
    spi_miso_in = 0;

    #100;
    $display("Starting SPI & GPIO Testbench...");

    // 1. Reset SPI core (soft reset)
    axi_write(32'h40, 32'h0000000a); // SPI_SRR (0x40)
    #100;

    // 2. Configure SPI Control Register (Master mode, Enable)
    // SPI_CR (0x60). Init is 0x180. Master bit=2, Enable bit=1. -> 0x186
    axi_write(32'h60, 32'h00000186);

    // 3. Select Slave 0
    // SPI_SSR (0x70)
    axi_write(32'h70, 32'hFFFFFFFE);

    // 4. Write data to TX FIFO
    // SPI_DTR (0x68)
    axi_write(32'h68, 32'h000000AB);

    // 5. Poll Status Register until TX FIFO is empty
    // SPI_SR (0x64), bit 2 is TX_EMPTY
    rd_data = 0;
    while ((rd_data & 32'h4) == 0) begin
      axi_read(32'h64, rd_data);
      #50;
    end
    
    $display("SPI Data Transmitted!");

    #1000;
    $display("Test Finished.");
    $finish;
  end

endmodule
