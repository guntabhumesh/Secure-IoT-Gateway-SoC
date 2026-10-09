/*
 * File: wb_random_seq.sv
 * Description: Wishbone Constrained Random Verification Sequence
 */

class wb_random_seq extends uvm_sequence #(wb_seq_item);
    `uvm_object_utils(wb_random_seq)

    function new(string name = "wb_random_seq");
        super.new(name);
    endfunction

    // Task to run
    task body();
        wb_seq_item item;
        
        // 1. Initial Setup: Configure some registers deterministically
        // Set DIR to output for some bits (Address 0x08)
        // WB uses 'sel' for byte enables, 'we' for write enable
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFF0000; we == 1; sel == 4'hF; })
        
        // 2. Random Loop
        repeat (1000) begin
            // Constraints:
            // - Address: 0x00 to 0x54 (Valid Range)
            // - Alignment: 4-byte (handled by item constraint)
            
            `uvm_do_with(item, { 
                addr >= 32'h00; 
                addr <= 32'h54; 
                addr[1:0] == 2'b00;
                sel == 4'hF;
            })
        end
        
        // 3. Cleanup / Final check
         `uvm_do_with(item, { addr == 32'h00; we == 0; })

    endtask

endclass
