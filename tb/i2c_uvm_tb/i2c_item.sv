class i2c_item extends uvm_sequence_item;

  rand bit scl_pad_i;
  bit scl_pad_o;
  bit scl_padoen_o;
  rand bit sda_pad_i;
  bit sda_pad_o;
  bit sda_padoen_o;

  `uvm_object_utils_begin(i2c_item)
    `uvm_field_int(scl_pad_i, UVM_ALL_ON)
    `uvm_field_int(scl_pad_o, UVM_ALL_ON)
    `uvm_field_int(scl_padoen_o, UVM_ALL_ON)
    `uvm_field_int(sda_pad_i, UVM_ALL_ON)
    `uvm_field_int(sda_pad_o, UVM_ALL_ON)
    `uvm_field_int(sda_padoen_o, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="i2c_item");
    super.new(name);
  endfunction
endclass
