class jtag_env extends uvm_env;
  jtag_agent agent;
  jtag_scoreboard sb;

  `uvm_component_utils(jtag_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = jtag_agent::type_id::create("agent", this);
    sb    = jtag_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.ap_imp);
  endfunction
endclass
