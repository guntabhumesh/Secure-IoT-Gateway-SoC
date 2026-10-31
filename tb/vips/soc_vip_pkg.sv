// =============================================================================
// soc_vip_pkg.sv
//
// Integrated UVM VIP Package for Secure-IoT-Gateway-SoC:
//   - UART VIP: Monitors serial framing, verifies loopback & ASCII messages
//   - SPI VIP:  Monitors SCLK, CS_N, and verifies MOSI byte transmissions
//   - I2C VIP:  Monitors START/STOP/Addr/Data, emulates Slave ACK response
//   - GPIO VIP: Monitors pin change events & verifies atomic manipulations
// =============================================================================

package soc_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // VIP includes
    `include "uart_vip.sv"
    `include "spi_vip.sv"
    `include "i2c_vip.sv"
    `include "gpio_vip.sv"

    // =========================================================================
    // SoC VIP Environment: Instantiates all 4 VIP agents & scoreboards
    // =========================================================================
    class soc_vip_env extends uvm_env;
        uart_vip_agent      uart_ag;
        uart_vip_scoreboard uart_sb;

        spi_vip_agent       spi_ag;
        spi_vip_scoreboard  spi_sb;

        i2c_vip_agent       i2c_ag;
        i2c_vip_scoreboard  i2c_sb;

        gpio_vip_agent      gpio_ag;
        gpio_vip_scoreboard gpio_sb;

        `uvm_component_utils(soc_vip_env)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // Build agents
            uart_ag = uart_vip_agent::type_id::create("uart_ag", this);
            uart_sb = uart_vip_scoreboard::type_id::create("uart_sb", this);

            spi_ag  = spi_vip_agent::type_id::create("spi_ag", this);
            spi_sb  = spi_vip_scoreboard::type_id::create("spi_sb", this);

            i2c_ag  = i2c_vip_agent::type_id::create("i2c_ag", this);
            i2c_sb  = i2c_vip_scoreboard::type_id::create("i2c_sb", this);

            gpio_ag = gpio_vip_agent::type_id::create("gpio_ag", this);
            gpio_sb = gpio_vip_scoreboard::type_id::create("gpio_sb", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            // Connect monitor analysis ports to scoreboards
            uart_ag.mon.ap.connect(uart_sb.ap_imp);
            spi_ag.mon.ap.connect(spi_sb.ap_imp);
            i2c_ag.mon.ap.connect(i2c_sb.ap_imp);
            gpio_ag.mon.ap.connect(gpio_sb.ap_imp);
        endfunction
    endclass

    // =========================================================================
    // SoC C Test: Top-level test running firmware execution with VIP verification
    // =========================================================================
    class soc_c_test extends uvm_test;
        soc_vip_env env;
        `uvm_component_utils(soc_c_test)

        function new(string name = "soc_c_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = soc_vip_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            uvm_event done_ev;
            phase.raise_objection(this);
            `uvm_info("UVM-TEST", "==========================================================", UVM_LOW)
            `uvm_info("UVM-TEST", " Starting SoC C-Test Simulation with Integrated VIPs...", UVM_LOW)
            `uvm_info("UVM-TEST", " Monitoring UART, SPI, I2C, and GPIO external signals...", UVM_LOW)
            `uvm_info("UVM-TEST", "==========================================================", UVM_LOW)

            // Wait for testbench test_done event via global UVM event pool
            done_ev = uvm_event_pool::get_global("test_done_ev");
            done_ev.wait_trigger();
            #50000; // Allow remaining bus transitions to settle
            phase.drop_objection(this);
        endtask
    endclass

endpackage
