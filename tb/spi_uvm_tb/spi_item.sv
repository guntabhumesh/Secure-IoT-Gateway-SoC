class spi_item extends uvm_sequence_item;

  bit spi_clk_o;
  bit spi_cs_n_o;
  bit spi_mosi_o;
  rand bit spi_miso_i;

  `uvm_object_utils_begin(spi_item)
    `uvm_field_int(spi_clk_o, UVM_ALL_ON)
    `uvm_field_int(spi_cs_n_o, UVM_ALL_ON)
    `uvm_field_int(spi_mosi_o, UVM_ALL_ON)
    `uvm_field_int(spi_miso_i, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="spi_item");
    super.new(name);
  endfunction
endclass
