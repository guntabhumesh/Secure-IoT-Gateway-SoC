class jtag_sequencer extends uvm_sequencer #(jtag_item);
  `uvm_component_utils(jtag_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
