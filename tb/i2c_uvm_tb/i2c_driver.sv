class i2c_driver extends uvm_driver #(i2c_item);
  virtual i2c_if vif;
  `uvm_component_utils(i2c_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("[DRIVER RECEIVED] scl_pad_i = %0b, sda_pad_i = %0b", req.scl_pad_i, req.sda_pad_i), UVM_LOW)
      @(posedge vif.clk);
      vif.scl_pad_i <= req.scl_pad_i;
      vif.sda_pad_i <= req.sda_pad_i;
      seq_item_port.item_done();
    end
  endtask
endclass
