/*
 * File: apb_base_seq.sv
 * Description: APB Base Sequence
 */

class apb_base_seq extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_base_seq)

    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction

    task body();
        apb_seq_item item;
        
        // Write DIR = Output (0xFFFFFFFF)
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFFFFFF; write == 1; strb == 4'hF; })
        
        // Write DATA_O = 0xAA55AA55
        `uvm_do_with(item, { addr == 32'h04; data == 32'hAA55AA55; write == 1; strb == 4'hF; })
        
        // Read DATA_O
        `uvm_do_with(item, { addr == 32'h04; write == 0; })
    endtask

endclass
