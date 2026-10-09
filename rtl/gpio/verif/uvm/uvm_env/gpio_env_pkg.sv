/*
 * File: gpio_env_pkg.sv
 * Description: GPIO Environment Package
 */

package gpio_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import apb_agent_pkg::*;
    import axi_agent_pkg::*;
    import wb_agent_pkg::*;
    import gpio_agent_pkg::*;

    // Define analysis imports for scoreboard
    `uvm_analysis_imp_decl(_apb)
    `uvm_analysis_imp_decl(_axi)
    `uvm_analysis_imp_decl(_wb)
    `uvm_analysis_imp_decl(_gpio)

    `include "gpio_scoreboard.sv"
    `include "gpio_env.sv"

endpackage
