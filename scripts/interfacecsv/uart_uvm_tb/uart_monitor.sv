class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;
  `uvm_component_utils(uart_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    uart_item item;
    forever begin
      @(posedge vif.clk);
      item = uart_item::type_id::create("item");
      item.uart_rx_i = vif.uart_rx_i;
      item.uart_tx_o = vif.uart_tx_o;
      ap.write(item);
    end
  endtask
endclass
