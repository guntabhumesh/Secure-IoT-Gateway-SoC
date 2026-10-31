class gpio_env extends uvm_env;
  gpio_agent agent;
  gpio_scoreboard sb;

  `uvm_component_utils(gpio_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = gpio_agent::type_id::create("agent", this);
    sb    = gpio_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.ap_imp);
  endfunction
endclass
