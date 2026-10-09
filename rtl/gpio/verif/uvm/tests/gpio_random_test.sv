/*
 * File: gpio_random_test.sv
 * Description: GPIO Random Test
 */

class gpio_random_test extends base_test;
    `uvm_component_utils(gpio_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: inherited from base_test
    
    // Run Phase
    task run_phase(uvm_phase phase);
        gpio_random_seq seq;
        seq = gpio_random_seq::type_id::create("seq");

        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Random Sequence...", UVM_LOW)
        seq.start(m_env.m_apb_agent.sequencer);
        `uvm_info("TEST", "Random Sequence Complete.", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass
