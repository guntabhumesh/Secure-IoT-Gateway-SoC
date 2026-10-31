class jtag_monitor extends uvm_monitor;
  virtual jtag_if vif;
  uvm_analysis_port #(jtag_item) ap;
  `uvm_component_utils(jtag_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual jtag_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    jtag_item item;
    forever begin
      @(posedge vif.clk);
      item = jtag_item::type_id::create("item");
      item.jtag_tck = vif.jtag_tck;
      item.jtag_tms = vif.jtag_tms;
      item.jtag_tdi = vif.jtag_tdi;
      item.jtag_tdo = vif.jtag_tdo;
      ap.write(item);
    end
  endtask
endclass
