`timescale 1ps / 1ps
/*
 * File: axi_agent_pkg.sv
 * Description: AXI Agent Package
 */

package axi_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axi_seq_item.sv"
  `include "axi_seq.sv"
  `include "axi_driver.sv"
  `include "axi_slave_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_agent.sv"

endpackage
