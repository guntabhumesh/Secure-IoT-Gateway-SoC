/*
 * File: apb_agent.sv
 * Description: APB Agent
 */

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    bit is_slave = 0;
    uvm_driver #(apb_seq_item) driver;
    uvm_sequencer #(apb_seq_item) sequencer;
    apb_monitor   monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(bit)::get(this, "", "is_slave", is_slave));

        monitor = apb_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            if (is_slave)
                driver = apb_slave_driver::type_id::create("driver", this);
            else
                driver = apb_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(apb_seq_item)::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
