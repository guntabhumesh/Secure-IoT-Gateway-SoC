`timescale 1ps / 1ps
/*
 * File: axi_if.sv
 * Description: AXI4-Lite SystemVerilog Interface
 */
interface axi_if (
    input logic aclk,
    input logic aresetn
);
  // Write Address Channel
  logic [31:0] awaddr;
  logic [ 2:0] awprot;
  logic        awvalid;
  logic        awready;

  // Write Data Channel
  logic [31:0] wdata;
  logic [ 3:0] wstrb;
  logic        wvalid;
  logic        wready;

  // Write Response Channel
  logic [ 1:0] bresp;
  logic        bvalid;
  logic        bready;

  // Read Address Channel
  logic [31:0] araddr;
  logic [ 2:0] arprot;
  logic        arvalid;
  logic        arready;

  // Read Data Channel
  logic [31:0] rdata;
  logic [ 1:0] rresp;
  logic        rvalid;
  logic        rready;

  clocking cb @(posedge aclk);
    output awaddr, awprot, awvalid;
    input awready;
    output wdata, wstrb, wvalid;
    input wready;
    output bready;
    input bresp, bvalid;
    output araddr, arprot, arvalid;
    input arready;
    output rready;
    input rdata, rresp, rvalid;
  endclocking

  clocking monitor_cb @(posedge aclk);
    default input #1step;
    input awaddr, awprot, awvalid, awready;
    input wdata, wstrb, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arprot, arvalid, arready;
    input rdata, rresp, rvalid, rready;
  endclocking

  clocking slave_cb @(posedge aclk);
    default input #1ns output #1ns;
    input awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready;
    output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid;
  endclocking

  modport master(clocking cb, input aclk, aresetn);
  modport monitor(clocking monitor_cb, input aclk, aresetn);

endinterface
