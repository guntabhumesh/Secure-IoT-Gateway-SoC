/*
 * File: gpio_wb_test.sv
 * Description: GPIO Wishbone Test
 */

class gpio_wb_test extends base_test;
    `uvm_component_utils(gpio_wb_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        uvm_config_db#(string)::set(this, "m_env", "bus_type", "WB");
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        wb_base_seq seq;
        seq = wb_base_seq::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(m_env.m_wb_agent.sequencer);
        #100ns;
        phase.drop_objection(this);
    endtask

endclass
