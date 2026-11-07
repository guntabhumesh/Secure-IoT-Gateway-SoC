class i2c_monitor extends uvm_monitor;
  virtual i2c_if vif;
  uvm_analysis_port #(i2c_item) ap;
  `uvm_component_utils(i2c_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    logic [7:0] shift_reg = 8'h00;
    int bit_count = 0;
    bit bus_active = 0;
    i2c_item item;

    @(posedge vif.rst_n);

    fork
      // Thread 1: Detect START conditions (SDA falls while SCL is HIGH)
      forever begin
        @(negedge vif.sda_pad_i);
        if (vif.scl_pad_i === 1'b1 && vif.rst_n) begin
          bus_active = 1;
          bit_count = 0;
          shift_reg = 8'h00;
          `uvm_info(get_type_name(), "[I2C MONITOR] START Condition Detected on I2C Bus", UVM_LOW)
        end
      end

      // Thread 2: Detect STOP conditions (SDA rises while SCL is HIGH)
      forever begin
        @(posedge vif.sda_pad_i);
        if (vif.scl_pad_i === 1'b1 && vif.rst_n) begin
          bus_active = 0;
          bit_count = 0;
          `uvm_info(get_type_name(), "[I2C MONITOR] STOP Condition Detected on I2C Bus", UVM_LOW)
        end
      end

      // Thread 3: Sample data bits on SCL rising edge
      forever begin
        @(posedge vif.scl_pad_i);
        if (bus_active && vif.rst_n) begin
          if (bit_count < 8) begin
            shift_reg = {shift_reg[6:0], vif.sda_pad_i};
            bit_count++;
            if (bit_count == 8) begin
              item = i2c_item::type_id::create("item");
              item.scl_pad_i    = vif.scl_pad_i;
              item.scl_pad_o    = vif.scl_pad_o;
              item.scl_padoen_o = vif.scl_padoen_o;
              item.sda_pad_i    = vif.sda_pad_i;
              item.sda_pad_o    = vif.sda_pad_o;
              item.sda_padoen_o = vif.sda_padoen_o;
              ap.write(item);

              `uvm_info(get_type_name(), $sformatf("[I2C MONITOR RECEIVED] From I2C IP: Byte = 0x%02h", shift_reg), UVM_LOW)
            end
          end else begin
            // 9th clock pulse: ACK/NACK bit
            bit_count = 0;
          end
        end
      end
    join
  endtask
endclass
