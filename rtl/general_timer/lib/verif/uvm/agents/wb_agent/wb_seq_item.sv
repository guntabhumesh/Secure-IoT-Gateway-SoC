/*
 * File: wb_seq_item.sv
 * Description: Wishbone Sequence Item
 */

class wb_seq_item extends uvm_sequence_item;
    
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        we; // 1=Write, 0=Read
    rand logic [3:0]  sel;

    // Response
    logic [31:0] rdata;
    logic        ack;

    `uvm_object_utils_begin(wb_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(sel, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(ack, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "wb_seq_item");
        super.new(name);
    endfunction

    constraint c_alignment { addr[1:0] == 2'b00; }

endclass
