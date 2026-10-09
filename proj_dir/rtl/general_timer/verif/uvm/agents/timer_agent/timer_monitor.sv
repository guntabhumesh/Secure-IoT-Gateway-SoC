/*
 * File: timer_monitor.sv
 * Description: UVM Monitor for Timer specific IO
 */
class timer_monitor extends uvm_monitor;
    `uvm_component_utils(timer_monitor)

    virtual timer_if vif;
    uvm_analysis_port #(timer_seq_item) item_collected_port;

    function new(string name = "timer_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual timer_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            timer_seq_item item = timer_seq_item::type_id::create("item");
            @(posedge vif.clk);
            if (vif.rst_n) begin
                item.ext_meas_i = vif.ext_meas_i;
                item.capture_i  = vif.capture_i;
                item.pwm_o      = vif.pwm_o;
                item.trigger_o  = vif.trigger_o;
                item.irq        = vif.irq;
                item_collected_port.write(item);
            end
        end
    endtask

endclass
