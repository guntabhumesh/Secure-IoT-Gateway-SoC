/*
 * File: gpio_seq_item.sv
 * Description: GPIO Sequence Item
 */

class gpio_seq_item extends uvm_sequence_item;
    
    rand logic [31:0] pin_val;
    logic [31:0] opins;
    logic [31:0] oen;
    logic        intr;

    `uvm_object_utils_begin(gpio_seq_item)
        `uvm_field_int(pin_val, UVM_ALL_ON)
        `uvm_field_int(opins, UVM_ALL_ON)
        `uvm_field_int(oen, UVM_ALL_ON)
        `uvm_field_int(intr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "gpio_seq_item");
        super.new(name);
    endfunction

endclass
