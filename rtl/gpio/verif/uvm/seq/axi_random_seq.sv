/*
 * File: axi_random_seq.sv
 * Description: AXI Constrained Random Verification Sequence
 */

class axi_random_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_random_seq)

    function new(string name = "axi_random_seq");
        super.new(name);
    endfunction

    // Task to run
    task body();
        axi_seq_item item;
        
        // 1. Initial Setup: Configure some registers deterministically
        // Set DIR to output for some bits (Address 0x08)
        // AXI uses 'strb' for byte enables
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFF0000; write == 1; strb == 4'hF; })
        
        // 2. Random Loop
        repeat (1000) begin
            // Constraints:
            // - Address: 0x00 to 0x54 (Valid Range)
            // - Alignment: 4-byte (handled by item constraint)
            // - strb should be randomized (automatically handled by uvm_do_with unless constrained)
            
            `uvm_do_with(item, { 
                addr >= 32'h00; 
                addr <= 32'h54; 
                addr[1:0] == 2'b00;
                strb == 4'hF;
            })
        end
        
        // 3. Cleanup / Final check
         `uvm_do_with(item, { addr == 32'h00; write == 0; })

    endtask

endclass
