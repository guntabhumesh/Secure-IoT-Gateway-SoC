//------------------------------------------------------------------------------
// File: wb_bfm_tasks.sv
// Description: Common Wishbone B4 Bus Functional Model (BFM) tasks for verification.
//
// Tasks:
//   - wb_write(addr, data): Standard write transaction.
//   - wb_read(addr, data): Standard read transaction.
//
// Assumptions:
//   - Signals are expected to be available in the parent scope:
//     wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, 
//     wb_cti_i, wb_bte_i, wb_ack_o, wb_dat_o, wb_err_o
//   - Clock is 'wb_clk_i'
//------------------------------------------------------------------------------

// Wishbone Write Task
// Wishbone Write Task
task wb_write(input [31:0] addr, input [31:0] data);
  @(posedge wb_clk_i);  // Sync to clock
  wb_adr_i <= addr;
  wb_dat_i <= data;
  wb_we_i  <= 1;
  wb_cyc_i <= 1;
  wb_stb_i <= 1;
  wb_sel_i <= 4'hF;
  wb_cti_i <= 3'b000;
  wb_bte_i <= 2'b00;

  do begin
    @(posedge wb_clk_i);
  end while (wb_ack_o === 1'b0);

  wb_cyc_i <= 0;
  wb_stb_i <= 0;
  wb_we_i  <= 0;
  wb_adr_i <= 32'h0;
  wb_dat_i <= 32'h0;
endtask

// Wishbone Read Task
task wb_read(input [31:0] addr, output [31:0] data);
  @(posedge wb_clk_i);  // Sync to clock
  wb_adr_i <= addr;
  wb_we_i  <= 0;
  wb_cyc_i <= 1;
  wb_stb_i <= 1;
  wb_sel_i <= 4'hF;

  wait (wb_ack_o);
  data = wb_dat_o;
  @(posedge wb_clk_i);
  wb_cyc_i <= 0;
  wb_stb_i <= 0;
  wb_adr_i <= 32'h0;
endtask
