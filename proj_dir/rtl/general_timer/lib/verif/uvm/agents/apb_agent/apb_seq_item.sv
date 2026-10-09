/*
 * File: apb_seq_item.sv
 * Description: APB Sequence Item
 */

class apb_seq_item extends uvm_sequence_item;
    
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        write; // 1=Write, 0=Read
    rand logic [3:0]  strb;
    rand logic [2:0]  prot;

    // Response control (used by slave driver)
    rand int          wait_cycles;
    rand bit          slverr_resp;

    // Response
    logic [31:0] rdata;
    logic        slverr;

    `uvm_object_utils_begin(apb_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_int(wait_cycles, UVM_ALL_ON)
        `uvm_field_int(slverr_resp, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(slverr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    constraint c_alignment { addr[1:0] == 2'b00; }
    constraint c_wait { wait_cycles inside {[0:5]}; }
    constraint c_slverr { slverr_resp dist {0 := 95, 1 := 5}; }

endclass
