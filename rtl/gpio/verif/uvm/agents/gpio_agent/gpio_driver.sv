/*
 * File: gpio_driver.sv
 * Description: GPIO Driver
 */

class gpio_driver extends uvm_driver #(gpio_seq_item);
    `uvm_component_utils(gpio_driver)

    virtual gpio_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        vif.cb.ipins <= 0;

        wait(vif.rst_n == 1);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(gpio_seq_item item);
        @ (vif.cb);
        vif.cb.ipins <= item.pin_val;
    endtask

endclass
