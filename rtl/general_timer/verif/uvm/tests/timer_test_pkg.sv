/*
 * File: timer_test_pkg.sv
 * Description: UVM Package for Timer tests
 */
package timer_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_agent_pkg::*;
    import apb_agent_pkg::*;
    import wb_agent_pkg::*;
    import timer_agent_pkg::*;
    import timer_env_pkg::*;

    `include "timer_sequences.sv"
    
    // Base Test
    class timer_base_test extends uvm_test;
        `uvm_component_utils(timer_base_test)

        timer_env env;
        string bus_type = "AXI";

        function new(string name = "timer_base_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = timer_env::type_id::create("env", this);
            
            // Pass bus type to env
            if ($value$plusargs("BUS_TYPE=%s", bus_type)) begin
                 uvm_config_db#(string)::set(this, "env", "bus_type", bus_type);
            end
        endfunction

        virtual task run_phase(uvm_phase phase);
            `uvm_info("TEST", "Base test running", UVM_LOW)
        endtask

    endclass

    // Simple Register Test
    class timer_reg_test extends timer_base_test;
        `uvm_component_utils(timer_reg_test)
        function new(string name = "timer_reg_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_axi_reg_seq axi_seq;
            timer_apb_reg_seq apb_seq;
            timer_wb_reg_seq  wb_seq;
            phase.raise_objection(this);
            
            if (bus_type == "AXI") begin
                axi_seq = timer_axi_reg_seq::type_id::create("axi_seq");
                axi_seq.start(env.axi_agt.sequencer);
                axi_seq.write_reg(32'h04, 32'h12345678); // LOAD
                axi_seq.read_reg(32'h04);
                axi_seq.write_reg(32'h0C, 32'h0000000A); // PRE
                axi_seq.read_reg(32'h0C);
            end else if (bus_type == "APB") begin
                apb_seq = timer_apb_reg_seq::type_id::create("apb_seq");
                apb_seq.start(env.apb_agt.sequencer);
                apb_seq.write_reg(32'h04, 32'h12345678);
                apb_seq.read_reg(32'h04);
            end else if (bus_type == "WB") begin
                wb_seq = timer_wb_reg_seq::type_id::create("wb_seq");
                wb_seq.start(env.wb_agt.sequencer);
                wb_seq.write_reg(32'h04, 32'h12345678);
                wb_seq.read_reg(32'h04);
            end
            
            #1000;
            phase.drop_objection(this);
        endtask
    endclass

    // Functional Count Test
    class timer_count_test extends timer_base_test;
        `uvm_component_utils(timer_count_test)
        function new(string name = "timer_count_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_axi_reg_seq axi_seq;
            phase.raise_objection(this);
            
            if (bus_type == "AXI") begin
                axi_seq = timer_axi_reg_seq::type_id::create("axi_seq");
                axi_seq.start(env.axi_agt.sequencer);
                
                `uvm_info("TEST", "Starting Timer counting test...", UVM_LOW)
                axi_seq.write_reg(32'h04, 32'h00000020); // LOAD = 32
                axi_seq.write_reg(32'h00, 32'h00000001); // CTRL: EN=1, MODE=0 (Pulse), DIR=0 (Down)
                
                // Wait for some time to see it counting
                #1000;
                
                axi_seq.read_reg(32'h08); // VAL
                axi_seq.read_reg(32'h14); // INT_STS (Should have expired by now)
            end
            
            phase.drop_objection(this);
        endtask
    endclass

    // Specialized PWM Test
    class timer_pwm_perf_test extends timer_base_test;
        `uvm_component_utils(timer_pwm_perf_test)
        function new(string name = "timer_pwm_perf_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_pwm_seq seq = timer_pwm_seq::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(env.axi_agt.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // Specialized Capture Stress Test
    class timer_capture_stress_test extends timer_base_test;
        `uvm_component_utils(timer_capture_stress_test)
        function new(string name = "timer_capture_stress_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_axi_reg_seq reg_seq = timer_axi_reg_seq::type_id::create("reg_seq");
            timer_capture_trigger_seq trig_seq = timer_capture_trigger_seq::type_id::create("trig_seq");
            phase.raise_objection(this);
            
            // Enable capture via registers
            reg_seq.start(env.axi_agt.sequencer);
            reg_seq.write_reg(32'h00, 32'h0000_0041); // EN=1, CAP_EN=1
            
            // Start triggers
            trig_seq.start(env.t_agt.sequencer);
            
            phase.drop_objection(this);
        endtask
    endclass

    // Specialized Prescaler Sweep Test
    class timer_prescaler_sweep_test extends timer_base_test;
        `uvm_component_utils(timer_prescaler_sweep_test)
        function new(string name = "timer_prescaler_sweep_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_prescaler_seq seq = timer_prescaler_seq::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(env.axi_agt.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // Full Mode Verification Test (Maximizing Code Coverage)
    class timer_full_mode_test extends timer_base_test;
        `uvm_component_utils(timer_full_mode_test)
        function new(string name = "timer_full_mode_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
            timer_axi_reg_seq seq;
            phase.raise_objection(this);
            seq = timer_axi_reg_seq::type_id::create("seq");
            seq.start(env.axi_agt.sequencer);

            `uvm_info("TEST", "Starting Full Mode Coverage Test...", UVM_LOW)

            // 1. One-Shot Down Counting (Default)
            seq.write_reg(32'h04, 32'h0000_0020); // LOAD = 32
            seq.write_reg(32'h00, 32'h0000_0001); // EN=1, MODE=0, DIR=0
            #1000;
            seq.read_reg(32'h14); // Clear IRQ
            seq.write_reg(32'h00, 32'h0000_0000); // Disable

            // 2. Repeat Down Counting
            `uvm_info("TEST", "Testing Repeat Down Mode...", UVM_LOW)
            seq.write_reg(32'h04, 32'h0000_0010); // LOAD = 16
            seq.write_reg(32'h00, 32'h0000_0003); // EN=1, MODE=1, DIR=0
            #1000; // Should expire multiple times
            seq.read_reg(32'h14); // Read IRQ (Sticky)
            seq.write_reg(32'h14, 32'h0000_0001); // Clear IRQ
            seq.write_reg(32'h00, 32'h0000_0000); // Disable

            // 3. One-Shot Up Counting
            `uvm_info("TEST", "Testing One-Shot Up Mode...", UVM_LOW)
            seq.write_reg(32'h04, 32'h0000_0020); // LOAD = 32
            seq.write_reg(32'h0C, 32'h0000_0000); // PRE = 0
            seq.write_reg(32'h18, 32'h0000_0010); // CMP = 16 (for PWM trigger coverage)
            seq.write_reg(32'h00, 32'h0000_0019); // EN=1, DIR=1 (Up), PWM_EN=1
            #1000;
            seq.read_reg(32'h14);
            seq.write_reg(32'h14, 32'h0000_0001);
            seq.write_reg(32'h00, 32'h0000_0000);

            // 4. Repeat Up Counting with Prescaler
            `uvm_info("TEST", "Testing Repeat Up Mode with Prescaler...", UVM_LOW)
            seq.write_reg(32'h04, 32'h0000_0010); // LOAD = 16
            seq.write_reg(32'h0C, 32'h0000_0001); // PRE = 1 (Divide by 2)
            seq.write_reg(32'h00, 32'h0000_001F); // EN=1, MODE=1, DIR=1, PWM_EN=1, PRE_EN=1
            #2000; 
            seq.read_reg(32'h14);
            seq.write_reg(32'h00, 32'h0000_0000);

            phase.drop_objection(this);
        endtask
    endclass

endpackage
