module tb_top;
  import uvm_pkg::*;
  import spi_pkg::*;

  logic clk;
  logic rst_n;

  // Clock Generation (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset Generation
  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // Interface instantiation
  spi_if vif(clk, rst_n);

  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
    run_test("spi_test");
  end
endmodule
