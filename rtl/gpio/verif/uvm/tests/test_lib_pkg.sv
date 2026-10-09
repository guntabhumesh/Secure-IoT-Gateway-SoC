/*
 * File: test_lib_pkg.sv
 * Description: UVM Test Library Package
 */

package test_lib_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import apb_agent_pkg::*;
    import axi_agent_pkg::*;
    import wb_agent_pkg::*;
    import gpio_agent_pkg::*;
    import gpio_env_pkg::*;

    `include "../seq/apb_base_seq.sv"
    `include "../seq/axi_base_seq.sv"
    `include "../seq/axi_random_seq.sv"
    `include "../seq/wb_base_seq.sv"
    `include "../seq/wb_random_seq.sv"
    `include "../seq/gpio_random_seq.sv"
    `include "base_test.sv"
    `include "gpio_apb_test.sv"
    `include "gpio_axi_test.sv"
    `include "gpio_axi_random_test.sv"
    `include "gpio_wb_test.sv"
    `include "gpio_wb_random_test.sv"
    `include "gpio_random_test.sv"

endpackage
