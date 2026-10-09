/*
 * File: ahb_driver.sv
 * Description: AHB Driver (Pipelined)
 */

class ahb_driver extends uvm_driver #(ahb_seq_item);
    `uvm_component_utils(ahb_driver)

    virtual ahb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    semaphore pipeline_lock = new(1);

    task run_phase(uvm_phase phase);
        // Reset
        vif.cb.hsel   <= 0;
        vif.cb.htrans <= 0; // IDLE
        vif.cb.hwrite <= 0;
        vif.cb.haddr  <= 0;
        vif.cb.hwdata <= 0;
        
        wait(vif.hresetn == 1);
        
        fork
            address_phase_handler();
            idle_handler();
        join
    endtask

    task address_phase_handler();
        forever begin
            seq_item_port.get(req);
            
            // Address Phase must be exclusive
            pipeline_lock.get(1);
            
            // Address Phase
            vif.cb.haddr  <= req.addr;
            vif.cb.htrans <= req.trans_type; 
            vif.cb.hwrite <= req.write;
            vif.cb.hsize  <= req.size;
            vif.cb.hburst <= req.burst;
            vif.cb.hsel   <= 1;
            vif.cb.hprot  <= req.prot;
            
            // Wait for Address Phase acceptance
            @ (vif.cb);
            while (vif.cb.hready !== 1) @ (vif.cb);
            
            // Release lock so next address phase can start
            pipeline_lock.put(1);
            
            // Data Phase (starts in next cycle)
            fork
                begin
                    ahb_seq_item item = req;
                    if (item.write) begin
                        vif.cb.hwdata <= item.data;
                    end
                    
                    // Wait for Data Phase completion
                    @ (vif.cb);
                    while (vif.cb.hready !== 1) @ (vif.cb);
                    
                    // Capture Read Data / Response
                    if (!item.write) item.rdata = vif.cb.hrdata;
                    item.resp = vif.cb.hresp;
                    
                    if (item.write) vif.cb.hwdata <= 0;
                    
                    // Signal completion -- since we used get(), we don't need item_done() 
                    // but we can send a response if the sequence is waiting for it.
                    // seq_item_port.put_response(item); 
                end
            join_none
        end
    endtask

    task idle_handler();
        forever begin
            @ (vif.cb);
            if (pipeline_lock.try_get(1)) begin
                vif.cb.htrans <= 0;
                vif.cb.hsel   <= 0;
                pipeline_lock.put(1);
            end
        end
    endtask

endclass
