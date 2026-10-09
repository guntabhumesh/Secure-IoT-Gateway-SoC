/*
 * File: ahb_monitor.sv
 * Description: AHB Monitor
 */

class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    virtual ahb_if vif;
    uvm_analysis_port #(ahb_seq_item) item_collected_port;

    ahb_seq_item current_addr_phase;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        wait(vif.hresetn == 1);
        forever begin
            @ (vif.monitor_cb);
            // Pipeline Logic:
            // 1. If we have a pending Address Phase (captured previous cycle) AND HREADY=1,
            //    then Data Phase is completing NOW.
            if (current_addr_phase != null && vif.monitor_cb.hready === 1) begin
                complete_transaction();
            end
            
            // 2. Sample new Address Phase if HSEL && HREADY && HTRANS != IDLE
            if (vif.monitor_cb.hsel === 1 && vif.monitor_cb.hready === 1 && (vif.monitor_cb.htrans == 2 || vif.monitor_cb.htrans == 3)) begin
                current_addr_phase = ahb_seq_item::type_id::create("captured_item");
                current_addr_phase.addr  = vif.monitor_cb.haddr;
                current_addr_phase.write = vif.monitor_cb.hwrite;
                current_addr_phase.size  = vif.monitor_cb.hsize;
                current_addr_phase.burst = vif.monitor_cb.hburst;
            end
        end
    endtask
    
    function void complete_transaction();
        if (current_addr_phase.write) begin
            current_addr_phase.data = vif.monitor_cb.hwdata;
        end else begin
            current_addr_phase.rdata = vif.monitor_cb.hrdata;
        end
        current_addr_phase.resp = vif.monitor_cb.hresp;
        
        item_collected_port.write(current_addr_phase);
        current_addr_phase = null;
    endfunction

endclass
