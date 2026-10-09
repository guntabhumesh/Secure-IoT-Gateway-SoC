/*
 * File: apb_monitor.sv
 * Description: APB Monitor
 */

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_seq_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            // Wait for SETUP phase (psel=1, penable=0)
            do begin
                @(posedge vif.pclk);
            end while (vif.psel !== 1'b1 || vif.penable !== 1'b0);

            // Capture initial info
            begin
                apb_seq_item item = apb_seq_item::type_id::create("item");
                item.addr   = vif.paddr;
                item.write  = vif.pwrite;
                item.strb   = vif.pstrb;
                item.prot   = vif.pprot;
                if (item.write)
                    item.data = vif.pwdata;
                
                // Wait for ACCESS phase completion (pready=1 along with penable=1)
                do begin
                     @(posedge vif.pclk);
                end while (vif.pready !== 1'b1);
                
                if (!item.write)
                    item.data = vif.prdata; // For read, data is prdata
                    item.rdata = vif.prdata;

                item.slverr = vif.pslverr;
                
                item_collected_port.write(item);
            end
        end
    endtask

endclass
