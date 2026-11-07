class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;
  `uvm_component_utils(uart_monitor)

  localparam BAUD_PERIOD_NS = 1010;
  localparam BAUD_HALF_NS   = 505;

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
    logic [7:0] rx_byte;
    string line_buf = "";

    @(posedge vif.rst_n);

    forever begin
      @(negedge vif.uart_tx_o);
      if (vif.rst_n) begin
        #(BAUD_PERIOD_NS + BAUD_HALF_NS);
        rx_byte = 8'h00;
        for (int i = 0; i < 8; i++) begin
          rx_byte[i] = vif.uart_tx_o;
          #BAUD_PERIOD_NS;
        end

        item = uart_item::type_id::create("item");
        item.uart_tx_o = vif.uart_tx_o;
        item.uart_rx_i = vif.uart_rx_i;
        ap.write(item);

        `uvm_info(get_type_name(), $sformatf("[UART MONITOR RECEIVED] From UART IP: Byte = 0x%02h ('%c')",
                  rx_byte, ((rx_byte >= 32 && rx_byte < 127) ? rx_byte : ".")), UVM_LOW)

        if (rx_byte == 8'h0a) begin
          if (line_buf.len() > 0) begin
            `uvm_info(get_type_name(), $sformatf("[UART MONITOR MESSAGE] Frame Assembled: \"%s\"", line_buf), UVM_LOW)
            line_buf = "";
          end
        end else if (rx_byte >= 32 && rx_byte < 127) begin
          line_buf = {line_buf, string'(rx_byte)};
        end
      end
    end
  endtask
endclass
