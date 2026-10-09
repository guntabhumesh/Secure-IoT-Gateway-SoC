/*
 * File: wb_monitor.sv
 * Description: Wishbone Monitor
 */

class wb_monitor extends uvm_monitor;
    `uvm_component_utils(wb_monitor)

    virtual wb_if vif;
    uvm_analysis_port #(wb_seq_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            wb_seq_item item;
            
            // Wait for Cycle Start
            do begin
                @(posedge vif.clk);
            end while (vif.cyc !== 1'b1 || vif.stb !== 1'b1);

            // Capture request
            item = wb_seq_item::type_id::create("item");
            item.addr = vif.adr;
            item.we   = vif.we;
            item.sel  = vif.sel;
            if (item.we) begin
                item.data = vif.dat_i;
                // WRITE: Report immediately so Scoreboard updates before GPIO output changes.
                item_collected_port.write(item);
            end
            
            // Wait for Ack
            do begin
                @(posedge vif.clk);
            end while (vif.ack !== 1'b1);
            
            if (!item.we) begin
                item.rdata = vif.dat_o;
                item.data  = vif.dat_o; // for checking
                item.ack = vif.ack;
                // READ: Report after ACK to capture data
                item_collected_port.write(item);
            end

            // Wait for cylce end if we want strictly one transaction per capture loop
            while (vif.cyc === 1'b1 && vif.stb === 1'b1) @(posedge vif.clk);
        end
    endtask

endclass
