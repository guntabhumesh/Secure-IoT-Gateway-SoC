class jtag_driver extends uvm_driver #(jtag_item);
  virtual jtag_if vif;
  `uvm_component_utils(jtag_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual jtag_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.jtag_tck <= req.jtag_tck;
      vif.jtag_tms <= req.jtag_tms;
      vif.jtag_tdi <= req.jtag_tdi;
      seq_item_port.item_done();
    end
  endtask
endclass
