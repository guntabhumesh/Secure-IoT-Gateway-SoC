/*
 * File: gpio_monitor.sv
 * Description: GPIO Monitor
 */

class gpio_monitor extends uvm_monitor;
    `uvm_component_utils(gpio_monitor)

    virtual gpio_if vif;
    uvm_analysis_port #(gpio_seq_item) item_collected_port;
    
    // Previous state to detect changes
    logic [31:0] prev_opins;
    logic [31:0] prev_oen;
    logic        prev_intr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        prev_opins = 0;
        prev_oen   = 0;
        prev_intr  = 0;

        forever begin
            @(posedge vif.clk);
            
            // Monitor for changes
            if (vif.opins !== prev_opins || vif.oen !== prev_oen || vif.intr !== prev_intr) begin
                gpio_seq_item item = gpio_seq_item::type_id::create("item");
                item.opins = vif.opins;
                item.oen   = vif.oen;
                item.intr  = vif.intr;
                item.pin_val = vif.ipins;
                
                item_collected_port.write(item);

                prev_opins = vif.opins;
                prev_oen   = vif.oen;
                prev_intr  = vif.intr;
            end
        end
    endtask

endclass
