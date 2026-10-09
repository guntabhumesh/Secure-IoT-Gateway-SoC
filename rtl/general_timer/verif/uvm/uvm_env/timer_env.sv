/*
 * File: timer_env.sv
 * Description: UVM Environment for General Timer IP
 */
class timer_env extends uvm_env;
    `uvm_component_utils(timer_env)

    // Agents
    apb_agent apb_agt;
    axi_agent axi_agt;
    wb_agent  wb_agt;
    timer_agent t_agt;

    // Scoreboard and Coverage
    timer_scoreboard scb;
    timer_coverage   cov;

    // Configuration
    string bus_type = "AXI";

    function new(string name = "timer_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get bus type from config db
        if (!uvm_config_db#(string)::get(this, "", "bus_type", bus_type)) begin
            `uvm_info("ENV", "Bus type not set, defaulting to AXI", UVM_LOW)
        end

        // Instantiate agents based on bus type
        if (bus_type == "APB") apb_agt = apb_agent::type_id::create("apb_agt", this);
        if (bus_type == "AXI") axi_agt = axi_agent::type_id::create("axi_agt", this);
        if (bus_type == "WB")  wb_agt  = wb_agent::type_id::create("wb_agt", this);
        
        t_agt = timer_agent::type_id::create("t_agt", this);
        scb   = timer_scoreboard::type_id::create("scb", this);
        cov   = timer_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect bus agent to scoreboard and coverage
        if (bus_type == "APB") begin
            apb_agt.monitor.item_collected_port.connect(scb.apb_export);
            apb_agt.monitor.item_collected_port.connect(cov.apb_export);
        end
        if (bus_type == "AXI") begin
            axi_agt.monitor.item_collected_port.connect(scb.axi_export);
            axi_agt.monitor.item_collected_port.connect(cov.axi_export);
        end
        if (bus_type == "WB") begin
            wb_agt.monitor.item_collected_port.connect(scb.wb_export);
            wb_agt.monitor.item_collected_port.connect(cov.wb_export);
        end
        
        // Connect timer agent to scoreboard and coverage
        t_agt.monitor.item_collected_port.connect(scb.timer_export);
        t_agt.monitor.item_collected_port.connect(cov.timer_export);
    endfunction

endclass
