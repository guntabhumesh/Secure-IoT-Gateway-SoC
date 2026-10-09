/*
 * File: wb_driver.sv
 * Description: Wishbone Driver
 */

class wb_driver extends uvm_driver #(wb_seq_item);
  `uvm_component_utils(wb_driver)

  virtual wb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction

  task run_phase(uvm_phase phase);
    // Reset inputs
    vif.cb.cyc <= 0;
    vif.cb.stb <= 0;
    vif.cb.we <= 0;
    vif.cb.adr <= 0;
    vif.cb.dat_i <= 0;
    vif.cb.sel <= 0;

    wait (vif.rst_n == 1);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transfer(wb_seq_item item);
    @(vif.cb);
    vif.cb.adr <= item.addr;
    vif.cb.we  <= item.we;
    vif.cb.sel <= item.sel;
    if (item.we) begin
      vif.cb.dat_i <= item.data;
    end

    vif.cb.cyc <= 1;
    vif.cb.stb <= 1;

    // Wait for ACK or ERR
    do begin
      @(vif.cb);
    end while (vif.cb.ack !== 1'b1 && vif.cb.err !== 1'b1);

    if (!item.we) begin
      item.rdata = vif.cb.dat_o;
    end

    vif.cb.cyc <= 0;
    vif.cb.stb <= 0;
    vif.cb.we  <= 0;
  endtask

endclass
