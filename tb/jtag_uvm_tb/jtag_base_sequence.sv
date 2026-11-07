class jtag_base_sequence extends uvm_sequence #(jtag_item);
  `uvm_object_utils(jtag_base_sequence)

  function new(string name="jtag_base_sequence");
    super.new(name);
  endfunction

  task body();
    jtag_item item;
    repeat (10) begin
      item = jtag_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
