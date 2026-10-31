class i2c_base_sequence extends uvm_sequence #(i2c_item);
  `uvm_object_utils(i2c_base_sequence)

  function new(string name="i2c_base_sequence");
    super.new(name);
  endfunction

  task body();
    i2c_item item;
    repeat (10) begin
      item = i2c_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
