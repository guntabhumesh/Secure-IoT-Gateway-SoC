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
    @(posedge vif.rst_n);
    forever begin
      @(posedge vif.jtag_tck);
      item = jtag_item::type_id::create("item");
      item.jtag_tck = vif.jtag_tck;
      item.jtag_tms = vif.jtag_tms;
      item.jtag_tdi = vif.jtag_tdi;
      item.jtag_tdo = vif.jtag_tdo;
      ap.write(item);
      `uvm_info(get_type_name(), $sformatf("[JTAG MONITOR RECEIVED] TCK posedge: TMS=%0b, TDI=%0b, TDO=%0b",
                vif.jtag_tms, vif.jtag_tdi, vif.jtag_tdo), UVM_HIGH)
    end
  endtask
endclass
