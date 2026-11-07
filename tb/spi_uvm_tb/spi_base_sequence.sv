class spi_base_sequence extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_base_sequence)

  function new(string name="spi_base_sequence");
    super.new(name);
  endfunction

  task body();
    spi_item item;
    repeat (10) begin
      item = spi_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
