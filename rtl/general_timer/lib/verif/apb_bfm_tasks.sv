//------------------------------------------------------------------------------
// File: apb_bfm_tasks.sv
// Description: Common APB4 Bus Functional Model (BFM) tasks for verification.
//
// Tasks:
//   - apb_write(addr, data): Standard write transaction.
//   - apb_read(addr, data): Standard read transaction.
//
// Assumptions:
//   - Signals are expected to be available in the parent scope:
//     paddr, pwdata, pwrite, psel, pprot, pstrb, penable, pready, prdata
//   - Clock is 'pclk'
//------------------------------------------------------------------------------

// APB Write Task
task apb_write(input [31:0] addr, input [31:0] data);
  paddr   = addr;
  pwdata  = data;
  pwrite  = 1;
  psel    = 1;
  pprot   = 3'b000;
  pstrb   = 4'hF;
  penable = 0;

  @(posedge pclk);
  #1;
  penable = 1;

  wait (pready);
  @(posedge pclk);
  #1;
  psel    = 0;
  penable = 0;
endtask

// APB Read Task
task apb_read(input [31:0] addr, output [31:0] data);
  paddr   = addr;
  pwrite  = 0;
  psel    = 1;
  penable = 0;
  pprot   = 3'b000;

  @(posedge pclk);
  #1;
  penable = 1;

  wait (pready);
  wait (pready);
  @(posedge pclk);
  data = prdata;
  #1;
  psel    = 0;
  penable = 0;
endtask
