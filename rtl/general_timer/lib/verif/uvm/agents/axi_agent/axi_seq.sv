/*
 * File: axi_seq.sv
 * Description: AXI Base Sequences
 */

class axi_base_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_base_seq)

    function new(string name="axi_base_seq");
        super.new(name);
    endfunction
endclass

class axi_rand_seq extends axi_base_seq;
    `uvm_object_utils(axi_rand_seq)
    
    rand int count;
    constraint c_count { count inside {[50:100]}; }

    function new(string name="axi_rand_seq");
        super.new(name);
    endfunction

    task body();
        repeat(count) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_error("RNDFAIL", "AXI Randomization failed")
            end
            finish_item(req);
        end
    endtask
endclass

class axi_slave_resp_seq extends axi_base_seq;
    `uvm_object_utils(axi_slave_resp_seq)

    function new(string name="axi_slave_resp_seq");
        super.new(name);
    endfunction

    task body();
        forever begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            // Slave just waits for request from driver (via sequencer)
            // In a real reactive slave, the driver would send the 'address' phase item up
            // Here we assume a simple driver that pulls items to provide response data
            finish_item(req);
        end
    endtask
endclass
