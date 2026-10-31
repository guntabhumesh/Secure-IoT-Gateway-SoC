class jtag_item extends uvm_sequence_item;

  rand bit jtag_tck;
  rand bit jtag_tms;
  rand bit jtag_tdi;
  bit jtag_tdo;

  `uvm_object_utils_begin(jtag_item)
    `uvm_field_int(jtag_tck, UVM_ALL_ON)
    `uvm_field_int(jtag_tms, UVM_ALL_ON)
    `uvm_field_int(jtag_tdi, UVM_ALL_ON)
    `uvm_field_int(jtag_tdo, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="jtag_item");
    super.new(name);
  endfunction
endclass
