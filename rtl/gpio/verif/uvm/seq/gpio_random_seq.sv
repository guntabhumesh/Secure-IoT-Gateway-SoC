/*
 * File: gpio_random_seq.sv
 * Description: Constrained Random Verification Sequence
 */

class gpio_random_seq extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(gpio_random_seq)

    function new(string name = "gpio_random_seq");
        super.new(name);
    endfunction

    // Task to run
    task body();
        apb_seq_item item;
        
        // 1. Initial Setup: Configure some registers deterministically
        // Set DIR to output for some bits
        `uvm_do_with(item, { addr == 32'h08; data == 32'hFFFF0000; write == 1; strb == 4'hF; })
        
        // 2. Random Loop
        repeat (1000) begin
            // We use `uvm_do_with` to create and randomize the item
            // Constraints:
            // - Address: 0x00 to 0x54 (Valid Range)
            // - Alignment: 4-byte (handled by item constraint, but good to reinforce if needed)
            
            `uvm_do_with(item, { 
                addr >= 32'h00; 
                addr <= 32'h54; 
                addr[1:0] == 2'b00;
            })
        end
        
        // 3. Cleanup / Final check (Optional)
        // Read back some key registers to ensure no hang
         `uvm_do_with(item, { addr == 32'h00; write == 0; })

    endtask

endclass
