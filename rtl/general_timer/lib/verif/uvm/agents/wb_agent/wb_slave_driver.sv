/*
 * File: wb_slave_driver.sv
 * Description: Wishbone Slave Driver for responder mode
 */

class wb_slave_driver extends uvm_driver #(wb_seq_item);
  `uvm_component_utils(wb_slave_driver)

  virtual wb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "virtual interface must be set");
  endfunction

  task run_phase(uvm_phase phase);
    // Reset responses
    vif.slave_cb.ack   <= 0;
    vif.slave_cb.err   <= 0;
    vif.slave_cb.dat_o <= 0;

    wait (vif.rst_n == 1);

    forever begin
      @(vif.slave_cb);
      if (vif.slave_cb.cyc && vif.slave_cb.stb) begin
        // Synchronous response
        vif.slave_cb.ack <= 1;
        vif.slave_cb.err <= 0;
        if (!vif.slave_cb.we) begin
          vif.slave_cb.dat_o <= 32'hBEEFBEEF;
        end

        // Keep ACK for one cycle
        @(vif.slave_cb);
        vif.slave_cb.ack <= 0;
      end
    end
  endtask
endclass
