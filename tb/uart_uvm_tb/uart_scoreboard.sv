class uart_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(uart_item, uart_scoreboard) ap_imp;

  `uvm_component_utils(uart_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_imp = new("ap_imp", this);
  endfunction

  virtual function void write(uart_item item);
    `uvm_info(get_type_name(), $sformatf("Observed transaction: %s", item.sprint()), UVM_HIGH)
  endfunction
endclass
