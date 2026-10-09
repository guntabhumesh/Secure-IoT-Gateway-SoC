/*
 * File: apb_slave_driver.sv
 * Description: APB Slave Driver for responder mode
 */

class apb_slave_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_slave_driver)

    virtual apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual interface must be set");
    endfunction

    task run_phase(uvm_phase phase);
        // Reset
        vif.slave_cb.pready  <= 1; // Default ready
        vif.slave_cb.pslverr <= 0;
        vif.slave_cb.prdata  <= 0;
        
        wait(vif.presetn == 1);
        
        forever begin
            @ (vif.slave_cb);
            if (vif.slave_cb.psel && !vif.slave_cb.penable) begin
                // SETUP Phase
                seq_item_port.try_next_item(req);
                
                // If we have a req, use its settings
                if (req != null) begin
                    // Wait Cycles (ACCESS phase delay)
                    vif.slave_cb.pready <= (req.wait_cycles == 0) ? 1 : 0;
                    
                    // Wait until ACCESS phase
                    @ (vif.slave_cb);
                    if (vif.slave_cb.psel && vif.slave_cb.penable) begin
                        // ACCESS Phase started
                        repeat(req.wait_cycles) begin
                            vif.slave_cb.pready <= 0;
                            @ (vif.slave_cb);
                        end
                        
                        vif.slave_cb.pready  <= 1;
                        vif.slave_cb.pslverr <= req.slverr_resp;
                        if (!vif.slave_cb.pwrite) begin
                            vif.slave_cb.prdata <= (req.slverr_resp) ? 32'hDEADBEEF : req.data; 
                        end
                        
                        // Transaction completes at next edge where PREADY=1
                        @ (vif.slave_cb);
                        vif.slave_cb.pready  <= 1; // Prepare for next
                        vif.slave_cb.pslverr <= 0;
                    end
                    seq_item_port.item_done();
                end else begin
                    // Default behavior if no item ready
                    @ (vif.slave_cb);
                    if (vif.slave_cb.psel && vif.slave_cb.penable) begin
                        vif.slave_cb.pready <= 1;
                        vif.slave_cb.pslverr <= 0;
                        @ (vif.slave_cb);
                    end
                end
            end
        end
    endtask
endclass
