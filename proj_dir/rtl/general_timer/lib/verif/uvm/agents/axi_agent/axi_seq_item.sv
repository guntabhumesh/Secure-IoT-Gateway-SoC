/*
 * File: axi_seq_item.sv
 * Description: AXI Sequence Item
 */

class axi_seq_item extends uvm_sequence_item;
    
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        write; // 1=Write, 0=Read
    rand logic [3:0]  strb;
    rand logic [2:0]  prot;

    // Response
    logic [31:0] rdata;
    logic [1:0]  resp; // bresp or rresp

    `uvm_object_utils_begin(axi_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

    constraint c_alignment { addr[1:0] == 2'b00; }

endclass
