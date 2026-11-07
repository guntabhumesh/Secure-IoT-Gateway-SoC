class spi_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(spi_item, spi_scoreboard) ap_imp;

  `uvm_component_utils(spi_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_imp = new("ap_imp", this);
  endfunction

  virtual function void write(spi_item item);
    `uvm_info(get_type_name(), $sformatf("Observed transaction: %s", item.sprint()), UVM_HIGH)
  endfunction
endclass
