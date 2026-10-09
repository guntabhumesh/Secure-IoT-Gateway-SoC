/*
 * File: wb_seq.sv
 * Description: Wishbone Base Sequences
 */

class wb_base_seq extends uvm_sequence #(wb_seq_item);
  `uvm_object_utils(wb_base_seq)

  function new(string name = "wb_base_seq");
    super.new(name);
  endfunction
endclass

class wb_rand_seq extends wb_base_seq;
  `uvm_object_utils(wb_rand_seq)

  rand int count;
  constraint c_count {count inside {[50 : 100]};}

  function new(string name = "wb_rand_seq");
    super.new(name);
  endfunction

  task body();
    repeat (count) begin
      req = wb_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) begin
        `uvm_error("RNDFAIL", "WB Randomization failed")
      end
      finish_item(req);
    end
  endtask
endclass

class wb_slave_resp_seq extends wb_base_seq;
  `uvm_object_utils(wb_slave_resp_seq)

  function new(string name = "wb_slave_resp_seq");
    super.new(name);
  endfunction

  task body();
    forever begin
      req = wb_seq_item::type_id::create("req");
      start_item(req);
      // Slave responder for WB allows driver to pull it 
      // and respond with ACK/ERR/DAT
      finish_item(req);
    end
  endtask
endclass
