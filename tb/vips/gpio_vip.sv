// =============================================================================
// gpio_vip.sv
//
// Verification IP for SoC GPIO interface
// - Protocol-aware monitor sampling GPIO pin state transitions
// - Scoreboard checking atomic SET, CLEAR, TOGGLE pin manipulations
// =============================================================================

class gpio_vip_item extends uvm_sequence_item;
    bit [31:0] data;
    time       timestamp;

    `uvm_object_utils_begin(gpio_vip_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "gpio_vip_item");
        super.new(name);
    endfunction
endclass

class gpio_vip_monitor extends uvm_monitor;
    virtual gpio_if vif;
    uvm_analysis_port #(gpio_vip_item) ap;
    `uvm_component_utils(gpio_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"Virtual interface vif not found for ", get_full_name()})
    endfunction

    task run_phase(uvm_phase phase);
        bit [31:0] prev_val = 32'h0;
        gpio_vip_item item;

        forever begin
            @(vif.gpio_o);
            if (vif.rst_n && (vif.gpio_o !== prev_val)) begin
                item = gpio_vip_item::type_id::create("gpio_item");
                item.data = vif.gpio_o;
                item.timestamp = $time;
                prev_val = vif.gpio_o;
                ap.write(item);
            end
        end
    endtask
endclass

class gpio_vip_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(gpio_vip_item, gpio_vip_scoreboard) ap_imp;
    `uvm_component_utils(gpio_vip_scoreboard)

    int unsigned trans_idx = 0;
    int unsigned match_count = 0;
    bit [31:0] expected_vals[4] = '{
        32'hDEADBEEF,  // Initial full word write
        32'hDEAD00EF,  // After Clear bits 8-15
        32'hDEAD00FF,  // After Set bit 4
        32'hDEAD00F0   // After Toggle bits 0-3
    };

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(gpio_vip_item item);
        if (trans_idx < 4) begin
            if (item.data == expected_vals[trans_idx]) begin
                match_count++;
                `uvm_info("UVM-VIP-GPIO", $sformatf("[PASS] GPIO Pin State #%0d Verified: 0x%08X (Expected: 0x%08X) at %0t",
                                                   trans_idx, item.data, expected_vals[trans_idx], item.timestamp), UVM_LOW)
            end else begin
                `uvm_error("UVM-VIP-GPIO", $sformatf("[FAIL] GPIO Pin State #%0d Mismatch: 0x%08X != Expected 0x%08X",
                                                    trans_idx, item.data, expected_vals[trans_idx]))
            end
            trans_idx++;
        end else begin
            `uvm_info("UVM-VIP-GPIO", $sformatf("Additional GPIO State: 0x%08X at %0t", item.data, item.timestamp), UVM_LOW)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UVM-VIP-GPIO", "==================================================", UVM_LOW)
        `uvm_info("UVM-VIP-GPIO", $sformatf(" SUMMARY: Total GPIO transitions verified: %0d/4", match_count), UVM_LOW)
        if (match_count == 4) begin
            `uvm_info("UVM-VIP-GPIO", " *** GPIO VIP VERIFICATION PASSED (0 ERRORS) ***", UVM_LOW)
        end else begin
            `uvm_error("UVM-VIP-GPIO", " *** GPIO VIP VERIFICATION FAILED ***")
        end
        `uvm_info("UVM-VIP-GPIO", "==================================================", UVM_LOW)
    endfunction
endclass

class gpio_vip_agent extends uvm_agent;
    virtual gpio_if vif;
    gpio_vip_monitor mon;
    `uvm_component_utils(gpio_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = gpio_vip_monitor::type_id::create("mon", this);
    endfunction
endclass
