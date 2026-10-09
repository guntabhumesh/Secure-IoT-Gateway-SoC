/*
 * File: axi_base_seq.sv
 * Description: AXI Base Sequence
 */

class axi_base_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_base_seq)

    function new(string name = "axi_base_seq");
        super.new(name);
    endfunction

    task body();
        axi_seq_item item;
        
        // Write DIR = Output (0xFFFFFFFF)
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFFFFFF; write == 1; strb == 4'hF; prot == 0; })
        
        // Write DATA_O = 0xAA55AA55
        `uvm_do_with(item, { addr == 32'h04; data == 32'hAA55AA55; write == 1; strb == 4'hF; prot == 0; })
        
        // Read DATA_O
        `uvm_do_with(item, { addr == 32'h04; write == 0; prot == 0; })
    endtask

endclass
