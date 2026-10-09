/*
 * File: gpio_apb_test.sv
 * Description: GPIO APB Test
 */

class gpio_apb_test extends base_test;
    `uvm_component_utils(gpio_apb_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        uvm_config_db#(string)::set(this, "m_env", "bus_type", "APB");
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        apb_base_seq seq;
        seq = apb_base_seq::type_id::create("seq");

        phase.raise_objection(this);
        seq.start(m_env.m_apb_agent.sequencer);
        #100ns;
        phase.drop_objection(this);
    endtask

endclass
