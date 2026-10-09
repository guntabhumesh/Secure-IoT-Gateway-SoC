/*
 * File: axi_monitor.sv
 * Description: AXI Monitor with stable sampling and debug logs
 */

class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;
  uvm_analysis_port #(axi_seq_item) item_collected_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info("MON", "Starting AXI Monitor Loops", UVM_LOW);
    fork
      collect_writes();
      collect_reads();
    join
  endtask

  task collect_writes();
    forever begin
      axi_seq_item item;
      item = axi_seq_item::type_id::create("item");
      item.write = 1;

      // Address Channel
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.awvalid || !vif.monitor_cb.awready);
      item.addr = vif.monitor_cb.awaddr;
      `uvm_info("MON", $sformatf("Captured AW: Addr=%h", item.addr), UVM_LOW);

      // Data Channel
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.wvalid || !vif.monitor_cb.wready);
      item.data = vif.monitor_cb.wdata;
      item.strb = vif.monitor_cb.wstrb;
      `uvm_info("MON", $sformatf("Captured W: Data=%h Strb=%h", item.data, item.strb), UVM_LOW);

      // Wait for BVALID
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.bvalid || !vif.monitor_cb.bready);
      item.resp = vif.monitor_cb.bresp;
      `uvm_info("MON", $sformatf("Captured B: Resp=%h", item.resp), UVM_LOW);

      item_collected_port.write(item);
    end
  endtask

  task collect_reads();
    forever begin
      axi_seq_item item;
      item = axi_seq_item::type_id::create("item");
      item.write = 0;

      // Address Channel
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.arvalid || !vif.monitor_cb.arready);
      item.addr = vif.monitor_cb.araddr;
      `uvm_info("MON", $sformatf("Captured AR: Addr=%h", item.addr), UVM_LOW);

      // Data Channel
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.rvalid || !vif.monitor_cb.rready);
      item.rdata = vif.monitor_cb.rdata;
      item.resp  = vif.monitor_cb.rresp;
      `uvm_info("MON", $sformatf("Captured R: Data=%h Resp=%h", item.rdata, item.resp), UVM_LOW);

      item_collected_port.write(item);
    end
  endtask

endclass
