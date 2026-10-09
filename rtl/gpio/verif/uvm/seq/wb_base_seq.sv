/*
 * File: wb_base_seq.sv
 * Description: Wishbone Base Sequence
 */

class wb_base_seq extends uvm_sequence #(wb_seq_item);
    `uvm_object_utils(wb_base_seq)

    function new(string name = "wb_base_seq");
        super.new(name);
    endfunction

    task body();
        wb_seq_item item;
        
        // Write DIR = Output (0xFFFFFFFF)
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFFFFFF; we == 1; sel == 4'hF; })
        
        // Write DATA_O = 0xAA55AA55
        `uvm_do_with(item, { addr == 32'h04; data == 32'hAA55AA55; we == 1; sel == 4'hF; })
        
        // Read DATA_O
        `uvm_do_with(item, { addr == 32'h04; we == 0; })
    endtask

endclass
