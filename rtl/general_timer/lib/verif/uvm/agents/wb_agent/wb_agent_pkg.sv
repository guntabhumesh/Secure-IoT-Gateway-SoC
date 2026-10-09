`timescale 1ps / 1ps
/*
 * File: wb_agent_pkg.sv
 * Description: Wishbone Agent Package
 */

package wb_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "wb_seq_item.sv"
  `include "wb_seq.sv"
  `include "wb_monitor.sv"
  `include "wb_driver.sv"
  `include "wb_slave_driver.sv"
  `include "wb_agent.sv"

endpackage
