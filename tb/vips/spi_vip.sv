// =============================================================================
// spi_vip.sv
//
// Verification IP for SoC SPI Master interface
// - Protocol-aware monitor sampling SPI MOSI data on SCLK edges under CS assertion
// - Scoreboard checking SPI frame contents against C test payloads
// =============================================================================

class spi_vip_item extends uvm_sequence_item;
    byte unsigned data;
    time          timestamp;

    `uvm_object_utils_begin(spi_vip_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "spi_vip_item");
        super.new(name);
    endfunction
endclass

class spi_vip_monitor extends uvm_monitor;
    virtual spi_if vif;
    uvm_analysis_port #(spi_vip_item) ap;
    `uvm_component_utils(spi_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"Virtual interface vif not found for ", get_full_name()})
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned shift_reg;
        int bit_idx;
        spi_vip_item item;

        forever begin
            // Wait for Chip Select active low
            @(negedge vif.spi_cs_n_o);

            while (!vif.spi_cs_n_o) begin
                shift_reg = 8'h00;
                for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
                    @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
                    if (vif.spi_cs_n_o) break;
                    shift_reg[bit_idx] = vif.spi_mosi_o;
                end

                if (!vif.spi_cs_n_o) begin
                    item = spi_vip_item::type_id::create("spi_item");
                    item.data = shift_reg;
                    item.timestamp = $time;
                    ap.write(item);
                end
            end
        end
    endtask
endclass

class spi_vip_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(spi_vip_item, spi_vip_scoreboard) ap_imp;
    `uvm_component_utils(spi_vip_scoreboard)

    int unsigned byte_idx = 0;
    int unsigned match_count = 0;
    byte unsigned expected_bytes[3] = '{8'hA5, 8'h5A, 8'h3C};

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(spi_vip_item item);
        if (byte_idx < 3) begin
            if (item.data == expected_bytes[byte_idx]) begin
                match_count++;
                `uvm_info("UVM-VIP-SPI", $sformatf("[PASS] SPI Byte #%0d Verified: 0x%02X (Expected: 0x%02X) at %0t",
                                                  byte_idx, item.data, expected_bytes[byte_idx], item.timestamp), UVM_LOW)
            end else begin
                `uvm_error("UVM-VIP-SPI", $sformatf("[FAIL] SPI Byte #%0d Mismatch: 0x%02X != Expected 0x%02X",
                                                   byte_idx, item.data, expected_bytes[byte_idx]))
            end
            byte_idx++;
        end else begin
            `uvm_info("UVM-VIP-SPI", $sformatf("Additional SPI Byte Captured: 0x%02X at %0t", item.data, item.timestamp), UVM_LOW)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UVM-VIP-SPI", "==================================================", UVM_LOW)
        `uvm_info("UVM-VIP-SPI", $sformatf(" SUMMARY: Total SPI bytes captured: %0d (Matches: %0d/3)", byte_idx, match_count), UVM_LOW)
        if (match_count == 3) begin
            `uvm_info("UVM-VIP-SPI", " *** SPI VIP VERIFICATION PASSED (0 ERRORS) ***", UVM_LOW)
        end else begin
            `uvm_error("UVM-VIP-SPI", " *** SPI VIP VERIFICATION FAILED ***")
        end
        `uvm_info("UVM-VIP-SPI", "==================================================", UVM_LOW)
    endfunction
endclass

class spi_vip_agent extends uvm_agent;
    virtual spi_if vif;
    spi_vip_monitor mon;
    `uvm_component_utils(spi_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = spi_vip_monitor::type_id::create("mon", this);
    endfunction
endclass
