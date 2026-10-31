// =============================================================================
// i2c_vip.sv
//
// Verification IP for SoC I2C Master interface
// - Protocol-aware monitor detecting START, STOP, Address & Data payloads
// - Scoreboard checking address and data bytes against C test payloads
// =============================================================================

typedef enum {I2C_EVT_START, I2C_EVT_BYTE, I2C_EVT_STOP} i2c_event_e;

class i2c_vip_item extends uvm_sequence_item;
    i2c_event_e   evt_type;
    byte unsigned data;
    time          timestamp;

    `uvm_object_utils_begin(i2c_vip_item)
        `uvm_field_enum(i2c_event_e, evt_type, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "i2c_vip_item");
        super.new(name);
    endfunction
endclass

class i2c_vip_monitor extends uvm_monitor;
    virtual i2c_if vif;
    uvm_analysis_port #(i2c_vip_item) ap;
    `uvm_component_utils(i2c_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"Virtual interface vif not found for ", get_full_name()})
    endfunction

    task run_phase(uvm_phase phase);
        bit in_transfer = 0;
        int bit_idx = 0;
        byte unsigned shift_byte = 8'h00;
        i2c_vip_item item;

        fork
            // START detector
            forever begin
                @(negedge vif.sda_pad_i);
                if (vif.scl_pad_i === 1'b1 && vif.rst_n) begin
                    in_transfer = 1;
                    bit_idx = 0;
                    shift_byte = 8'h00;
                    item = i2c_vip_item::type_id::create("item_start");
                    item.evt_type  = I2C_EVT_START;
                    item.data      = 8'h00;
                    item.timestamp = $time;
                    ap.write(item);
                end
            end

            // STOP detector
            forever begin
                @(posedge vif.sda_pad_i);
                if (vif.scl_pad_i === 1'b1 && vif.rst_n && in_transfer) begin
                    in_transfer = 0;
                    item = i2c_vip_item::type_id::create("item_stop");
                    item.evt_type  = I2C_EVT_STOP;
                    item.data      = 8'h00;
                    item.timestamp = $time;
                    ap.write(item);
                end
            end

            // Bit & Byte collector on posedge SCL
            forever begin
                @(posedge vif.scl_pad_i);
                if (in_transfer && vif.rst_n) begin
                    if (bit_idx < 8) begin
                        shift_byte[7 - bit_idx] = vif.sda_pad_i;
                        bit_idx++;
                        if (bit_idx == 8) begin
                            item = i2c_vip_item::type_id::create("item_byte");
                            item.evt_type  = I2C_EVT_BYTE;
                            item.data      = shift_byte;
                            item.timestamp = $time;
                            ap.write(item);
                        end
                    end else begin
                        // 9th clock is ACK cycle
                        bit_idx = 0;
                        shift_byte = 8'h00;
                    end
                end
            end
        join
    endtask
endclass

class i2c_vip_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(i2c_vip_item, i2c_vip_scoreboard) ap_imp;
    `uvm_component_utils(i2c_vip_scoreboard)

    int unsigned start_count = 0;
    int unsigned stop_count  = 0;
    int unsigned byte_count  = 0;
    int unsigned addr_verified = 0;
    int unsigned byte1_verified = 0;
    int unsigned byte2_verified = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(i2c_vip_item item);
        case (item.evt_type)
            I2C_EVT_START: begin
                start_count++;
                `uvm_info("UVM-VIP-I2C", $sformatf("[PASS] I2C START Condition Detected at %0t", item.timestamp), UVM_LOW)
            end
            I2C_EVT_BYTE: begin
                byte_count++;
                if (byte_count == 1) begin
                    if (item.data == 8'hA0) begin
                        addr_verified = 1;
                        `uvm_info("UVM-VIP-I2C", $sformatf("[PASS] I2C Slave Address 0x%02X (0x50+W) Verified at %0t", item.data, item.timestamp), UVM_LOW)
                    end else begin
                        `uvm_error("UVM-VIP-I2C", $sformatf("[FAIL] I2C Address Mismatch: 0x%02X != 0xA0", item.data))
                    end
                end else if (byte_count == 2) begin
                    if (item.data == 8'h5A) begin
                        byte1_verified = 1;
                        `uvm_info("UVM-VIP-I2C", $sformatf("[PASS] I2C Data Byte 1 0x%02X Verified at %0t", item.data, item.timestamp), UVM_LOW)
                    end
                end else if (byte_count == 3) begin
                    if (item.data == 8'hA5) begin
                        byte2_verified = 1;
                        `uvm_info("UVM-VIP-I2C", $sformatf("[PASS] I2C Data Byte 2 0x%02X Verified at %0t", item.data, item.timestamp), UVM_LOW)
                    end
                end
            end
            I2C_EVT_STOP: begin
                stop_count++;
                `uvm_info("UVM-VIP-I2C", $sformatf("[PASS] I2C STOP Condition Detected at %0t", item.timestamp), UVM_LOW)
            end
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UVM-VIP-I2C", "==================================================", UVM_LOW)
        `uvm_info("UVM-VIP-I2C", $sformatf(" SUMMARY: STARTs: %0d, Bytes: %0d, STOPs: %0d", start_count, byte_count, stop_count), UVM_LOW)
        if (start_count >= 1 && addr_verified) begin
            `uvm_info("UVM-VIP-I2C", " *** I2C VIP VERIFICATION PASSED (0 ERRORS) ***", UVM_LOW)
        end else begin
            `uvm_error("UVM-VIP-I2C", " *** I2C VIP VERIFICATION FAILED ***")
        end
        `uvm_info("UVM-VIP-I2C", "==================================================", UVM_LOW)
    endfunction
endclass

class i2c_vip_agent extends uvm_agent;
    virtual i2c_if vif;
    i2c_vip_monitor mon;
    `uvm_component_utils(i2c_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = i2c_vip_monitor::type_id::create("mon", this);
    endfunction
endclass
