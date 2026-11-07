class uart_base_sequence extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_base_sequence)

  function new(string name="uart_base_sequence");
    super.new(name);
  endfunction

  task body();
    uart_item item;
    repeat (10) begin
      item = uart_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
