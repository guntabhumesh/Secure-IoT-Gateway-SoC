class i2c_monitor extends uvm_monitor;
  virtual i2c_if vif;
  uvm_analysis_port #(i2c_item) ap;
  `uvm_component_utils(i2c_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    i2c_item item;
    forever begin
      @(posedge vif.clk);
      item = i2c_item::type_id::create("item");
      item.scl_pad_i = vif.scl_pad_i;
      item.scl_pad_o = vif.scl_pad_o;
      item.scl_padoen_o = vif.scl_padoen_o;
      item.sda_pad_i = vif.sda_pad_i;
      item.sda_pad_o = vif.sda_pad_o;
      item.sda_padoen_o = vif.sda_padoen_o;
      ap.write(item);
    end
  endtask
endclass
