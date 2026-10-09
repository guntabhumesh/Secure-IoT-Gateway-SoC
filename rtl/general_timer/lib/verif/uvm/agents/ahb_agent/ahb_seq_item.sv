/*
 * File: ahb_seq_item.sv
 * Description: AHB Sequence Item
 */

class ahb_seq_item extends uvm_sequence_item;
    
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        write; // 1=Write, 0=Read
    rand bit [2:0]  size;  // 2=32bit
    rand bit [2:0]  burst; // 0=Single
    rand bit [3:0]  prot;  // Protection
    rand bit [1:0]  trans_type; // 0=IDLE, 1=BUSY, 2=NONSEQ, 3=SEQ
    
    // Output
    bit [31:0] rdata;
    bit        resp;

    `uvm_object_utils_begin(ahb_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_int(trans_type, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ahb_seq_item");
        super.new(name);
    endfunction
    
    constraint c_size { size inside {[0:2]}; } 
    constraint c_burst { burst inside {[0:7]}; }
    constraint c_trans { trans_type == 2; } // Only NONSEQ for now

endclass
