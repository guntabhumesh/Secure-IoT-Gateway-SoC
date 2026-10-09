`timescale 1ps / 1ps
/*
 * File: apb_if.sv
 * Description: APB SystemVerilog Interface
 */
interface apb_if (
    input logic pclk,
    input logic presetn
);
  logic [31:0] paddr;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [31:0] pwdata;
  logic [ 3:0] pstrb;
  logic [ 2:0] pprot;
  logic        pready;
  logic [31:0] prdata;
  logic        pslverr;

  clocking cb @(posedge pclk);
    output paddr, psel, penable, pwrite, pwdata, pstrb, pprot;
    input pready, prdata, pslverr;
  endclocking

  clocking slave_cb @(posedge pclk);
    input paddr, psel, penable, pwrite, pwdata, pstrb, pprot;
    output pready, prdata, pslverr;
  endclocking

  modport master(clocking cb, input pclk, presetn);
  modport slave(clocking slave_cb, input pclk, presetn);
  modport monitor(
      input pclk, presetn, paddr, psel, penable, pwrite, pwdata, pstrb, pprot, pready, prdata, pslverr
  );

endinterface
