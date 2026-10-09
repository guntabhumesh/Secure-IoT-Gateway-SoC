/*
 * File: timer_driver.sv
 * Description: UVM Driver for Timer specific IO
 */
class timer_driver extends uvm_driver #(timer_seq_item);
    `uvm_component_utils(timer_driver)

    virtual timer_if vif;

    function new(string name = "timer_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual timer_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize
        vif.cb.ext_meas_i <= 0;
        vif.cb.capture_i  <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            vif.cb.ext_meas_i <= req.ext_meas_i;
            vif.cb.capture_i  <= req.capture_i;
            seq_item_port.item_done();
        end
    endtask

endclass
