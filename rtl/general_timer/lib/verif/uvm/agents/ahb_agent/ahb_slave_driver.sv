/*
 * File: ahb_slave_driver.sv
 * Description: AHB Slave Driver for responder mode
 */

class ahb_slave_driver extends uvm_driver #(ahb_seq_item);
    `uvm_component_utils(ahb_slave_driver)

    virtual ahb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual interface must be set");
    endfunction

    task run_phase(uvm_phase phase);
        // Reset
        vif.slave_cb.hready <= 1; // Default ready
        vif.slave_cb.hresp  <= 0;
        vif.slave_cb.hrdata <= 0;
        
        wait(vif.hresetn == 1);
        
        forever begin
            @ (vif.slave_cb);
            if (vif.slave_cb.hsel && (vif.slave_cb.htrans > 1)) begin
                // Non-Sequential or Sequential Address phase
                // Respond in next cycle (Data phase)
                @ (vif.slave_cb);
                vif.slave_cb.hready <= 1;
                vif.slave_cb.hresp  <= 0;
                if (!vif.slave_cb.hwrite) begin
                    vif.slave_cb.hrdata <= 32'hBEEFBEEF;
                end
            end
        end
    endtask
endclass
