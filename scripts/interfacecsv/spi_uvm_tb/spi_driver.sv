class spi_driver extends uvm_driver #(spi_item);
  virtual spi_if vif;
  `uvm_component_utils(spi_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.spi_miso_i <= req.spi_miso_i;
      seq_item_port.item_done();
    end
  endtask
endclass
