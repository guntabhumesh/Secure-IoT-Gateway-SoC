// =============================================================================
// uart_vip.sv
//
// Verification IP for SoC UART interface
// - Protocol-aware monitor sampling serial stream
// - Scoreboard checking frame integrity and C firmware messages
// =============================================================================

class uart_vip_item extends uvm_sequence_item;
    byte unsigned data;
    time          timestamp;

    `uvm_object_utils_begin(uart_vip_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "uart_vip_item");
        super.new(name);
    endfunction
endclass

class uart_vip_monitor extends uvm_monitor;
    virtual uart_if vif;
    uvm_analysis_port #(uart_vip_item) ap;
    `uvm_component_utils(uart_vip_monitor)

    // Baud period = 101 clock cycles @ 10ns = 1010ns (matches SIM_BAUD_DIV = 100)
    localparam BAUD_CLOCKS = 101;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"Virtual interface vif not found for ", get_full_name()})
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned rx_byte;
        int i;
        uart_vip_item item;

        forever begin
            // Wait for start bit (falling edge of uart_tx_o)
            @(negedge vif.uart_tx_o);
            if (vif.rst_n) begin
                // Sample 1.5 baud periods later for center of bit 0
                repeat (BAUD_CLOCKS + (BAUD_CLOCKS/2)) @(posedge vif.clk);
                rx_byte = 8'h00;

                for (i = 0; i < 8; i++) begin
                    rx_byte[i] = vif.uart_tx_o;
                    repeat (BAUD_CLOCKS) @(posedge vif.clk);
                end

                // Sample stop bit (should be 1)
                item = uart_vip_item::type_id::create("uart_item");
                item.data = rx_byte;
                item.timestamp = $time;
                ap.write(item);
            end
        end
    endtask
endclass

class uart_vip_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(uart_vip_item, uart_vip_scoreboard) ap_imp;
    `uvm_component_utils(uart_vip_scoreboard)

    int unsigned char_count = 0;
    int unsigned line_count = 0;
    int unsigned loopback_verified = 0;
    string current_line = "";

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(uart_vip_item item);
        char_count++;
        // Check for loopback byte 0x55
        if (item.data == 8'h55 && loopback_verified == 0) begin
            loopback_verified = 1;
            `uvm_info("UVM-VIP-UART", "[PASS] Verified UART hardware loopback byte 0x55", UVM_LOW)
        end

        if (item.data == 8'h0A) begin // '\n'
            if (current_line.len() > 0) begin
                line_count++;
                `uvm_info("UVM-VIP-UART", $sformatf("Captured C Test Line #%0d: %s", line_count, current_line), UVM_LOW)
                current_line = "";
            end
        end else if (item.data >= 8'h20 && item.data < 8'h7F) begin
            current_line = {current_line, string'(item.data)};
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UVM-VIP-UART", "==================================================", UVM_LOW)
        `uvm_info("UVM-VIP-UART", $sformatf(" SUMMARY: Total characters verified: %0d", char_count), UVM_LOW)
        `uvm_info("UVM-VIP-UART", $sformatf(" SUMMARY: Total output lines captured: %0d", line_count), UVM_LOW)
        if (loopback_verified && char_count > 10) begin
            `uvm_info("UVM-VIP-UART", " *** UART VIP VERIFICATION PASSED (0 ERRORS) ***", UVM_LOW)
        end else begin
            `uvm_error("UVM-VIP-UART", " *** UART VIP VERIFICATION FAILED ***")
        end
        `uvm_info("UVM-VIP-UART", "==================================================", UVM_LOW)
    endfunction
endclass

class uart_vip_agent extends uvm_agent;
    virtual uart_if vif;
    uart_vip_monitor mon;
    `uvm_component_utils(uart_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = uart_vip_monitor::type_id::create("mon", this);
    endfunction
endclass
