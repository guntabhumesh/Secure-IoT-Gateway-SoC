/*
 * File: timer_agent_pkg.sv
 * Description: UVM Package for Timer specific IO Agent
 */
package timer_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "timer_seq_item.sv"
    `include "timer_driver.sv"
    `include "timer_monitor.sv"
    `include "timer_agent.sv"

endpackage
