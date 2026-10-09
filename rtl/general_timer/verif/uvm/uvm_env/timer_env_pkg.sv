/*
 * File: timer_env_pkg.sv
 * Description: UVM Package for Timer environment
 */
package timer_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_agent_pkg::*;
    import apb_agent_pkg::*;
    import wb_agent_pkg::*;
    import timer_agent_pkg::*;
    
    // Macros for multiple analysis implementations
    `uvm_analysis_imp_decl(_apb)
    `uvm_analysis_imp_decl(_axi)
    `uvm_analysis_imp_decl(_wb)
    `uvm_analysis_imp_decl(_timer)

    `include "timer_scoreboard.sv"
    `include "timer_coverage.sv"
    `include "timer_env.sv"

endpackage
