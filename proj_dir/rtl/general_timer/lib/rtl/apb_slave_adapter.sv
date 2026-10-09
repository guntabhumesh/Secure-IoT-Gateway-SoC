
//------------------------------------------------------------------------------
// File: apb_slave_adapter.sv
// Description: Generic APB4 Slave Adapter.
// Converts APB transactions into a simple native register bus.
//
// Author: Gemini-3 AI
// License: MIT
//------------------------------------------------------------------------------



module apb_slave_adapter #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    // verilator lint_off UNUSEDSIGNAL
    input logic pclk,
    input logic presetn,
    // verilator lint_on UNUSEDSIGNAL

    // APB4 Interface
    input  logic [    ADDR_WIDTH-1:0] paddr,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [               2:0] pprot,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                      psel,
    input  logic                      penable,
    input  logic                      pwrite,
    input  logic [    DATA_WIDTH-1:0] pwdata,
    input  logic [(DATA_WIDTH/8)-1:0] pstrb,
    output logic [    DATA_WIDTH-1:0] prdata,
    output logic                      pready,
    output logic                      pslverr,

    // Native Register Bus
    output logic [    ADDR_WIDTH-1:0] reg_addr,
    output logic [    DATA_WIDTH-1:0] reg_wdata,
    input  logic [    DATA_WIDTH-1:0] reg_rdata,
    output logic                      reg_we,
    output logic                      reg_re,
    output logic [(DATA_WIDTH/8)-1:0] reg_be
);

  // APB Logic
  // Zero-wait state implementation
  assign pready   = 1'b1;
  assign pslverr  = 1'b0;

  // Read Data Pass-through
  assign prdata   = reg_rdata;

  // Native Bus assignments
  assign reg_addr  = paddr;
  assign reg_wdata = pwdata;
  assign reg_be    = pstrb;

  // Write Enable: Active when PSEL, PENABLE and PWRITE are high
  assign reg_we    = psel && penable && pwrite;

  // Read Enable: Active when PSEL, PENABLE and !PWRITE
  // Note: Some cores might need RE during PSEL only phase, but standard is PENABLE.
  // GPIO/Timer work with PSEL && !PWRITE. 
  // Let's use PSEL && !PWRITE for setup, ensuring data valid by PENABLE?
  // GPIO_APB used: assign reg_re = psel && !pwrite;
  assign reg_re    = psel && !pwrite;

endmodule
