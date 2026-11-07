interface jtag_if (input logic clk, input logic rst_n);
  logic jtag_tck;
  logic jtag_tms;
  logic jtag_tdi;
  logic jtag_tdo;
endinterface
