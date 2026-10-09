/*
 * File: timer_agent.sv
 * Description: UVM Agent for Timer specific IO
 */
class timer_agent extends uvm_agent;
    `uvm_component_utils(timer_agent)

    timer_driver    driver;
    timer_monitor   monitor;
    uvm_sequencer #(timer_seq_item) sequencer;

    function new(string name = "timer_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = timer_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver = timer_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(timer_seq_item)::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
