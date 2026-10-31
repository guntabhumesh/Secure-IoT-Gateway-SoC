class gpio_driver extends uvm_driver #(gpio_item);
  virtual gpio_if vif;
  `uvm_component_utils(gpio_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.gpio_i <= req.gpio_i;
      seq_item_port.item_done();
    end
  endtask
endclass
