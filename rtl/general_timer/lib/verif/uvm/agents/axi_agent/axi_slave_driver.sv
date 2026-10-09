/*
 * File: axi_slave_driver.sv
 * Description: AXI Slave Driver for responder mode
 */

class axi_slave_driver extends uvm_driver #(axi_seq_item);
    `uvm_component_utils(axi_slave_driver)

    virtual axi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual interface must be set");
    endfunction

    task run_phase(uvm_phase phase);
        // Reset
        vif.slave_cb.awready <= 0;
        vif.slave_cb.wready  <= 0;
        vif.slave_cb.bvalid  <= 0;
        vif.slave_cb.arready <= 0;
        vif.slave_cb.rvalid  <= 0;
        
        wait(vif.aresetn == 1);
        
        forever begin
            fork
                handle_write();
                handle_read();
            join_none
            @ (vif.slave_cb);
        end
    endtask

    task handle_write();
        // Respond to AW and W
        if (vif.slave_cb.awvalid) begin
             vif.slave_cb.awready <= 1;
             @ (vif.slave_cb);
             vif.slave_cb.awready <= 0;
        end
        if (vif.slave_cb.wvalid) begin
             vif.slave_cb.wready <= 1;
             @ (vif.slave_cb);
             vif.slave_cb.wready <= 0;
             // Send B response
             vif.slave_cb.bresp  <= 0; // OKAY
             vif.slave_cb.bvalid <= 1;
             do begin
                 @ (vif.slave_cb);
             end while (!vif.slave_cb.bready);
             vif.slave_cb.bvalid <= 0;
        end
    endtask

    task handle_read();
        if (vif.slave_cb.arvalid) begin
             vif.slave_cb.arready <= 1;
             @ (vif.slave_cb);
             vif.slave_cb.arready <= 0;
             // Send R response
             vif.slave_cb.rdata  <= 32'hA5A5A5A5;
             vif.slave_cb.rresp  <= 0; // OKAY
             vif.slave_cb.rvalid <= 1;
             do begin
                 @ (vif.slave_cb);
             end while (!vif.slave_cb.rready);
             vif.slave_cb.rvalid <= 0;
        end
    endtask

endclass
