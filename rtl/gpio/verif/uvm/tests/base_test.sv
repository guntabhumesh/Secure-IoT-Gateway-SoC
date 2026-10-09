/*
 * File: base_test.sv
 * Description: UVM Base Test
 */

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    gpio_env m_env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = gpio_env::type_id::create("m_env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass
