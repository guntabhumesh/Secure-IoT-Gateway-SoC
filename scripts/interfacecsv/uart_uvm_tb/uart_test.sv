class uart_test extends uvm_test;
  uart_env env;

  `uvm_component_utils(uart_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    uart_base_sequence seq;
    phase.raise_objection(this);
    seq = uart_base_sequence::type_id::create("seq");
    seq.start(env.agent.seqr);
    #100;
    phase.drop_objection(this);
  endtask
endclass
