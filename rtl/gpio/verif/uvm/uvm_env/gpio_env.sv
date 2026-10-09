/*
 * File: gpio_env.sv
 * Description: GPIO UVM Environment
 */

class gpio_env extends uvm_env;
    `uvm_component_utils(gpio_env)

    apb_agent       m_apb_agent;
    axi_agent       m_axi_agent;
    wb_agent        m_wb_agent;
    gpio_agent      m_gpio_agent;
    gpio_scoreboard m_scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        string bus_type = "APB";
        super.build_phase(phase);
        
        void'(uvm_config_db#(string)::get(this, "", "bus_type", bus_type));

        m_gpio_agent = gpio_agent::type_id::create("m_gpio_agent", this);
        m_scoreboard = gpio_scoreboard::type_id::create("m_scoreboard", this);

        if (bus_type == "APB") m_apb_agent = apb_agent::type_id::create("m_apb_agent", this);
        if (bus_type == "AXI") m_axi_agent = axi_agent::type_id::create("m_axi_agent", this);
        if (bus_type == "WB")  m_wb_agent  = wb_agent::type_id::create("m_wb_agent", this);

    endfunction

    function void connect_phase(uvm_phase phase);
        m_gpio_agent.monitor.item_collected_port.connect(m_scoreboard.gpio_export);
        
        if (m_apb_agent) m_apb_agent.monitor.item_collected_port.connect(m_scoreboard.apb_export);
        if (m_axi_agent) m_axi_agent.monitor.item_collected_port.connect(m_scoreboard.axi_export);
        if (m_wb_agent)  m_wb_agent.monitor.item_collected_port.connect(m_scoreboard.wb_export);
    endfunction

endclass
