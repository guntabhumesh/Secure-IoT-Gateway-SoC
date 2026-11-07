class uart_item extends uvm_sequence_item;

  rand bit uart_rx_i;
  bit uart_tx_o;

  `uvm_object_utils_begin(uart_item)
    `uvm_field_int(uart_rx_i, UVM_ALL_ON)
    `uvm_field_int(uart_tx_o, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="uart_item");
    super.new(name);
  endfunction
endclass
