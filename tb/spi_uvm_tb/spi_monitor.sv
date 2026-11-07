class spi_monitor extends uvm_monitor;
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;
  `uvm_component_utils(spi_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    spi_item item;
    logic [7:0] mosi_byte;
    int bit_cnt;

    @(posedge vif.rst_n);

    forever begin
      @(negedge vif.spi_cs_n_o);
      `uvm_info(get_type_name(), "[SPI MONITOR] Chip Select Asserted (CS=0). Listening for SPI transfer...", UVM_LOW)

      while (vif.spi_cs_n_o == 1'b0) begin
        mosi_byte = 8'h00;
        bit_cnt = 0;
        while (bit_cnt < 8 && vif.spi_cs_n_o == 1'b0) begin
          @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
          if (vif.spi_cs_n_o == 1'b0) begin
            mosi_byte = {mosi_byte[6:0], vif.spi_mosi_o};
            bit_cnt++;
          end
        end

        if (bit_cnt == 8) begin
          item = spi_item::type_id::create("item");
          item.spi_clk_o  = vif.spi_clk_o;
          item.spi_cs_n_o = vif.spi_cs_n_o;
          item.spi_mosi_o = vif.spi_mosi_o;
          item.spi_miso_i = vif.spi_miso_i;
          ap.write(item);

          `uvm_info(get_type_name(), $sformatf("[SPI MONITOR RECEIVED] From SPI IP: MOSI Byte = 0x%02h ('%c')",
                    mosi_byte, ((mosi_byte >= 32 && mosi_byte < 127) ? mosi_byte : ".")), UVM_LOW)
        end
      end

      `uvm_info(get_type_name(), "[SPI MONITOR] Chip Select De-asserted (CS=1). Transfer complete.", UVM_LOW)
    end
  endtask
endclass
