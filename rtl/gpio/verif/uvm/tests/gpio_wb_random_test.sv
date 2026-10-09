/*
 * File: gpio_wb_random_test.sv
 * Description: GPIO Wishbone Random Test
 */

class gpio_wb_random_test extends base_test;
    `uvm_component_utils(gpio_wb_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        uvm_config_db#(string)::set(this, "m_env", "bus_type", "WB");
        super.build_phase(phase);
    endfunction

    // Run Phase
    task run_phase(uvm_phase phase);
        wb_random_seq seq;
        seq = wb_random_seq::type_id::create("seq");

        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting WB Random Sequence...", UVM_LOW)
        // Ensure we are connecting to the WB agent's sequencer
        if (m_env.m_wb_agent == null)
             `uvm_fatal("TEST", "WB Agent not created! Check bus_type configuration.")

        seq.start(m_env.m_wb_agent.sequencer);
        `uvm_info("TEST", "WB Random Sequence Complete.", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass
