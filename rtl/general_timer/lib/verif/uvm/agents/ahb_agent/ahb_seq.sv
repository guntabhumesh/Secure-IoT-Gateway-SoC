/*
 * File: ahb_seq.sv
 * Description: AHB Base Sequences
 */

class ahb_base_seq extends uvm_sequence #(ahb_seq_item);
    `uvm_object_utils(ahb_base_seq)

    function new(string name="ahb_base_seq");
        super.new(name);
    endfunction
endclass

class ahb_rand_seq extends ahb_base_seq;
    `uvm_object_utils(ahb_rand_seq)
    
    rand int count;
    constraint c_count { count inside {[50:100]}; }

    function new(string name="ahb_rand_seq");
        super.new(name);
    endfunction

    task body();
        repeat(count) begin
            req = ahb_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_error("RNDFAIL", "AHB Randomization failed")
            end
            finish_item(req);
        end
    endtask
endclass

class ahb_slave_resp_seq extends ahb_base_seq;
    `uvm_object_utils(ahb_slave_resp_seq)

    function new(string name="ahb_slave_resp_seq");
        super.new(name);
    endfunction

    task body();
        forever begin
            req = ahb_seq_item::type_id::create("req");
            start_item(req);
            // Slave responder for AHB simply allows driver to pull it 
            // and respond with HREADY/HRESP/HRDATA
            finish_item(req);
        end
    endtask
endclass
