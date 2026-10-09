/*
 * File: axi_driver.sv
 * Description: AXI Driver (AXI4-Lite Master)
 */

class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction

  task run_phase(uvm_phase phase);
    // Reset inputs
    vif.cb.awaddr  <= 0;
    vif.cb.awprot  <= 0;
    vif.cb.awvalid <= 0;
    vif.cb.wdata   <= 0;
    vif.cb.wstrb   <= 0;
    vif.cb.wvalid  <= 0;
    vif.cb.bready  <= 0;
    vif.cb.araddr  <= 0;
    vif.cb.arprot  <= 0;
    vif.cb.arvalid <= 0;
    vif.cb.rready  <= 0;

    wait (vif.aresetn == 1);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transfer(axi_seq_item item);
    if (item.write) begin
      // Write Transaction
      // Address Channel
      @(vif.cb);
      vif.cb.awaddr  <= item.addr;
      vif.cb.awprot  <= item.prot;
      vif.cb.awvalid <= 1;
      `uvm_info("DRV", "Waiting for awready", UVM_LOW);
      do begin
        @(vif.cb);
      end while (vif.cb.awready !== 1'b1);
      `uvm_info("DRV", "Got awready", UVM_LOW);
      vif.cb.awvalid <= 0;

      // Data Channel
      @(vif.cb);
      vif.cb.wdata  <= item.data;
      vif.cb.wstrb  <= item.strb;
      vif.cb.wvalid <= 1;
      `uvm_info("DRV", "Waiting for wready", UVM_LOW);
      do begin
        @(vif.cb);
      end while (vif.cb.wready !== 1'b1);
      `uvm_info("DRV", "Got wready", UVM_LOW);
      vif.cb.wvalid <= 0;

      // Response Channel
      vif.cb.bready <= 1;
      `uvm_info("DRV", "Waiting for bvalid", UVM_LOW);
      do begin
        @(vif.cb);
      end while (vif.cb.bvalid !== 1'b1);
      `uvm_info("DRV", "Got bvalid", UVM_LOW);
      item.resp = vif.cb.bresp;
      vif.cb.bready <= 0;

    end else begin
      // Read Transaction
      // Address Channel
      @(vif.cb);
      vif.cb.araddr  <= item.addr;
      vif.cb.arprot  <= item.prot;
      vif.cb.arvalid <= 1;
      do begin
        @(vif.cb);
      end while (vif.cb.arready !== 1'b1);
      vif.cb.arvalid <= 0;

      // Data/Resp Channel
      vif.cb.rready  <= 1;
      do begin
        @(vif.cb);
      end while (vif.cb.rvalid !== 1'b1);
      item.rdata = vif.cb.rdata;
      item.resp  = vif.cb.rresp;
      vif.cb.rready <= 0;
    end
  endtask

endclass
