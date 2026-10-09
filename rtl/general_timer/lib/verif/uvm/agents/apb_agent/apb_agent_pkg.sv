`timescale 1ps / 1ps
/*
 * File: apb_agent_pkg.sv
 * Description: APB Agent Package
 */

package apb_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "apb_seq_item.sv"
  `include "apb_driver.sv"
  `include "apb_slave_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"

endpackage
