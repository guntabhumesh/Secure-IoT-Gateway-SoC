class uart_driver extends uvm_driver #(uart_item);
  virtual uart_if vif;
  `uvm_component_utils(uart_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("[DRIVER RECEIVED] uart_rx_i = %0b", req.uart_rx_i), UVM_LOW)
      @(posedge vif.clk);
      vif.uart_rx_i <= req.uart_rx_i;
      seq_item_port.item_done();
    end
  endtask
endclass
