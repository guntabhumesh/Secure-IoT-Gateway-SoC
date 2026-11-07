class gpio_base_sequence extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_base_sequence)

  function new(string name="gpio_base_sequence");
    super.new(name);
  endfunction

  task body();
    gpio_item item;
    repeat (10) begin
      item = gpio_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
