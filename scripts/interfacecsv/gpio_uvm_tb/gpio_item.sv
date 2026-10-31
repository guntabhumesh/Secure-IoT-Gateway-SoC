class gpio_item extends uvm_sequence_item;

  rand bit [31:0] gpio_i;
  bit [31:0] gpio_o;
  bit [31:0] gpio_oe;

  `uvm_object_utils_begin(gpio_item)
    `uvm_field_int(gpio_i, UVM_ALL_ON)
    `uvm_field_int(gpio_o, UVM_ALL_ON)
    `uvm_field_int(gpio_oe, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="gpio_item");
    super.new(name);
  endfunction
endclass
