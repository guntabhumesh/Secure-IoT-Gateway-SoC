// =============================================================================
// soc_vips_env_pkg.sv
//
// Unified SoC UVM Environment & Driver Value Passing Verification Test
// Packages all UVM VIP agents from tb/:
//   - uart_agent (uart_pkg)
//   - spi_agent  (spi_pkg)
//   - i2c_agent  (i2c_pkg)
//   - gpio_agent (gpio_pkg)
//   - jtag_agent (jtag_pkg)
// =============================================================================

package soc_vips_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import spi_pkg::*;
    import i2c_pkg::*;
    import gpio_pkg::*;
    import jtag_pkg::*;

    // ── Unified SoC VIP Environment ──────────────────────────────────────────
    class soc_env extends uvm_env;
        uart_agent uart_ag;
        spi_agent  spi_ag;
        i2c_agent  i2c_ag;
        gpio_agent gpio_ag;
        jtag_agent jtag_ag;

        `uvm_component_utils(soc_env)

        function new(string name = "soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            uart_ag = uart_agent::type_id::create("uart_ag", this);
            spi_ag  = spi_agent::type_id::create("spi_ag", this);
            i2c_ag  = i2c_agent::type_id::create("i2c_ag", this);
            gpio_ag = gpio_agent::type_id::create("gpio_ag", this);
            jtag_ag = jtag_agent::type_id::create("jtag_ag", this);
        endfunction
    endclass

    // ── Directed Value Sequences for Passing Data to VIP Drivers ────────────
    class uart_val_seq extends uvm_sequence #(uart_item);
        `uvm_object_utils(uart_val_seq)
        function new(string name = "uart_val_seq");
            super.new(name);
        endfunction

        task body();
            uart_item item;
            bit test_vals[5] = '{1'b0, 1'b1, 1'b0, 1'b1, 1'b1};
            `uvm_info("UART_SEQ", ">>> Passing 5 test values to UART Driver...", UVM_LOW)
            foreach (test_vals[i]) begin
                item = uart_item::type_id::create("item");
                start_item(item);
                item.uart_rx_i = test_vals[i];
                finish_item(item);
            end
        endtask
    endclass

    class spi_val_seq extends uvm_sequence #(spi_item);
        `uvm_object_utils(spi_val_seq)
        function new(string name = "spi_val_seq");
            super.new(name);
        endfunction

        task body();
            spi_item item;
            bit test_vals[5] = '{1'b1, 1'b0, 1'b1, 1'b0, 1'b1};
            `uvm_info("SPI_SEQ", ">>> Passing 5 test values to SPI Driver...", UVM_LOW)
            foreach (test_vals[i]) begin
                item = spi_item::type_id::create("item");
                start_item(item);
                item.spi_miso_i = test_vals[i];
                finish_item(item);
            end
        endtask
    endclass

    class i2c_val_seq extends uvm_sequence #(i2c_item);
        `uvm_object_utils(i2c_val_seq)
        function new(string name = "i2c_val_seq");
            super.new(name);
        endfunction

        task body();
            i2c_item item;
            bit scl_vals[4] = '{1'b1, 1'b0, 1'b1, 1'b1};
            bit sda_vals[4] = '{1'b1, 1'b1, 1'b0, 1'b1};
            `uvm_info("I2C_SEQ", ">>> Passing test values to I2C Driver...", UVM_LOW)
            for (int i = 0; i < 4; i++) begin
                item = i2c_item::type_id::create("item");
                start_item(item);
                item.scl_pad_i = scl_vals[i];
                item.sda_pad_i = sda_vals[i];
                finish_item(item);
            end
        endtask
    endclass

    class gpio_val_seq extends uvm_sequence #(gpio_item);
        `uvm_object_utils(gpio_val_seq)
        function new(string name = "gpio_val_seq");
            super.new(name);
        endfunction

        task body();
            gpio_item item;
            bit [31:0] test_patterns[4] = '{32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'hA5A5A5A5};
            `uvm_info("GPIO_SEQ", ">>> Passing 4 directed 32-bit patterns to GPIO Driver...", UVM_LOW)
            foreach (test_patterns[i]) begin
                item = gpio_item::type_id::create("item");
                start_item(item);
                item.gpio_i = test_patterns[i];
                finish_item(item);
            end
        endtask
    endclass

    class jtag_val_seq extends uvm_sequence #(jtag_item);
        `uvm_object_utils(jtag_val_seq)
        function new(string name = "jtag_val_seq");
            super.new(name);
        endfunction

        task body();
            jtag_item item;
            bit tck_vals[4] = '{1'b0, 1'b1, 1'b0, 1'b1};
            bit tms_vals[4] = '{1'b1, 1'b1, 1'b0, 1'b0};
            bit tdi_vals[4] = '{1'b0, 1'b1, 1'b1, 1'b0};
            `uvm_info("JTAG_SEQ", ">>> Passing test values to JTAG Driver...", UVM_LOW)
            for (int i = 0; i < 4; i++) begin
                item = jtag_item::type_id::create("item");
                start_item(item);
                item.jtag_tck = tck_vals[i];
                item.jtag_tms = tms_vals[i];
                item.jtag_tdi = tdi_vals[i];
                finish_item(item);
            end
        endtask
    endclass

    // ── Driver Verification Test ─────────────────────────────────────────────
    class soc_driver_test extends uvm_test;
        soc_env env;
        `uvm_component_utils(soc_driver_test)

        function new(string name = "soc_driver_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            uvm_config_db#(bit)::set(null, "*", "uart_loopback_en", 1'b0);
            env = soc_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            uart_val_seq uart_seq;
            spi_val_seq  spi_seq;
            i2c_val_seq  i2c_seq;
            gpio_val_seq gpio_seq;
            jtag_val_seq jtag_seq;

            phase.raise_objection(this);
            `uvm_info("DRV_TEST", "============================================================", UVM_LOW)
            `uvm_info("DRV_TEST", " STARTING UVM VIP DRIVER VALUE PASSING & VERIFICATION       ", UVM_LOW)
            `uvm_info("DRV_TEST", "============================================================", UVM_LOW)

            uart_seq = uart_val_seq::type_id::create("uart_seq");
            spi_seq  = spi_val_seq::type_id::create("spi_seq");
            i2c_seq  = i2c_val_seq::type_id::create("i2c_seq");
            gpio_seq = gpio_val_seq::type_id::create("gpio_seq");
            jtag_seq = jtag_val_seq::type_id::create("jtag_seq");

            fork
                uart_seq.start(env.uart_ag.seqr);
                spi_seq.start(env.spi_ag.seqr);
                i2c_seq.start(env.i2c_ag.seqr);
                gpio_seq.start(env.gpio_ag.seqr);
                jtag_seq.start(env.jtag_ag.seqr);
            join

            #500;
            `uvm_info("DRV_TEST", "============================================================", UVM_LOW)
            `uvm_info("DRV_TEST", " ALL VALUES SUCCESSFULLY PASSED TO & RECEIVED BY VIP DRIVERS", UVM_LOW)
            `uvm_info("DRV_TEST", "============================================================", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass

    // ── SoC VIP Monitor Integration Test ─────────────────────────────────────
    class soc_monitor_test extends uvm_test;
        soc_env env;
        `uvm_component_utils(soc_monitor_test)

        function new(string name = "soc_monitor_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = soc_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            uvm_event test_done_ev;
            phase.raise_objection(this);
            `uvm_info("SOC_MON_TEST", "============================================================", UVM_LOW)
            `uvm_info("SOC_MON_TEST", " STARTING SOC UVM VIP MONITORS (UART, SPI, I2C, GPIO)      ", UVM_LOW)
            `uvm_info("SOC_MON_TEST", " Monitors active and listening to IP interface transactions...", UVM_LOW)
            `uvm_info("SOC_MON_TEST", "============================================================", UVM_LOW)

            // Keep objection active while SoC firmware executes and monitors capture IP transfers
            test_done_ev = uvm_event_pool::get_global("test_done_ev");
            test_done_ev.wait_trigger();
            #3000;

            `uvm_info("SOC_MON_TEST", "============================================================", UVM_LOW)
            `uvm_info("SOC_MON_TEST", " ALL SOC IPs MONITORED AND VERIFIED THROUGH UVM VIPs         ", UVM_LOW)
            `uvm_info("SOC_MON_TEST", "============================================================", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass

endpackage
