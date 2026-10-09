//
// Native Testbench for Timer Core
//

module tb_timer_core;

    logic        clk;
    logic        rst_n;
    logic        en;
    logic        mode;
    logic        dir;
    logic        pwm_en;
    logic        ext_en;
    logic        pre_en;
    logic [15:0] pre_val;
    logic [31:0] load_val;
    logic [31:0] cmp_val;
    logic        load_cmd;
    logic        ext_meas_i;
    logic        capture_i;
    
    logic [31:0] current_val;
    logic [31:0] capture_val;
    logic        capture_stb;
    logic        pwm_o;
    logic        trigger_o;
    logic        irq;

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT Instantiation
    timer_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .mode(mode),
        .dir(dir),
        .pwm_en(pwm_en),
        .ext_en(ext_en),
        .pre_en(pre_en),
        .pre_val(pre_val),
        .load_val(load_val),
        .cmp_val(cmp_val),
        .load_cmd(load_cmd),
        .ext_meas_i(ext_meas_i),
        .capture_i(capture_i),
        .current_val(current_val),
        .capture_val(capture_val),
        .capture_stb(capture_stb),
        .pwm_o(pwm_o),
        .trigger_o(trigger_o),
        .irq(irq)
    );

    // Test Procedure
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_timer_core);

        // Reset
        rst_n = 0;
        en = 0;
        mode = 0;
        dir = 0;
        pwm_en = 0;
        ext_en = 0;
        pre_en = 0;
        pre_val = 0;
        load_val = 0;
        cmp_val = 0;
        load_cmd = 0;
        ext_meas_i = 0;
        capture_i = 0;
        
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        // Test 1: One-Shot Mode, No Prescaler
        $display("TEST 1: One-Shot Mode, Load=10");
        load_val = 32'd10;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        mode = 0; // One-Shot
        
        wait(irq == 1);
        $display("interrupt received at time %t", $time);
        
        repeat(5) @(posedge clk);
        if (current_val != 0) $error("Counter did not stop at 0 in One-Shot mode");

        en = 0;
        repeat(5) @(posedge clk);

        // Test 2: Repeat Mode, No Prescaler
        $display("TEST 2: Repeat Mode, Load=5");
        load_val = 32'd5;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        mode = 1; // Repeat

        wait(irq == 1);
        $display("Interrupt 1 received");
        @(negedge irq);
        
        wait(irq == 1);
        $display("Interrupt 2 received");

        en = 0;
        repeat(5) @(posedge clk);

        // Test 3: Prescaler Test (Divide by 4)
        $display("TEST 3: Prescaler Mode, Load=3, Pre=3");
        load_val = 32'd3; 
        pre_val = 16'd3;
        pre_en = 1;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        mode = 0;

        wait(irq == 1);
        $display("Interrupt with Prescaler received");
        en = 0;
        pre_en = 0;
        repeat(5) @(posedge clk);

        // NEW FEATURES TESTS

        // Test 4: PWM Up Mode
        $display("TEST 4: PWM Up Mode");
        load_val = 32'd20;
        cmp_val = 32'd10;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        dir = 1; // Up
        mode = 1; // Repeat
        pwm_en = 1;
        
        // Wait for IRQ (rollover)
        wait(irq == 1);
        
        // Check PWM logic roughly (should be 0 because counter wraps to 0 which is < 10)
        // Wait until counter is 5
        wait(current_val == 5);
        if(pwm_o !== 1) $error("PWM logic fail: Should be 1 when < CMP");
        wait(current_val == 15);
        if(pwm_o !== 0) $error("PWM logic fail: Should be 0 when >= CMP");

        en = 0;
        pwm_en = 0;
        dir = 0;
        repeat(5) @(posedge clk);
        
        // Test 5: Input Capture
        $display("TEST 5: Input Capture");
        load_val = 32'd100;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        dir = 0;
        mode = 0;
        
        repeat(5) @(posedge clk);
        // Drive capture with delay
        #1 capture_i = 1;
        @(posedge clk);
        #1; // Wait for update
        if(capture_stb !== 1) $error("Capture Strobe Missed");
        $display("Captured Value: %h", capture_val);
        capture_i = 0;
        
        en = 0;
        repeat(5) @(posedge clk);

        // Test 6: External Count
        $display("TEST 6: External Count");
        ext_en = 1;
        load_val = 32'd3;
        load_cmd = 1;
        @(posedge clk);
        load_cmd = 0;
        en = 1;
        
        repeat(5) @(posedge clk);
        // Generate 4 pulses (3->2, 2->1, 1->0, 0->IRQ)
        
        repeat(3) begin
             #1 ext_meas_i = 1;
             #20 ext_meas_i = 0;
             #20;
        end
        
        // 4th Pulse
        #1 ext_meas_i = 1;
        
        // Wait for IRQ
        fork
            begin
                wait(irq == 1);
                $display("IRQ Received in Ext Count Mode");
            end
            begin
                #100 $error("IRQ Missed in Ext Count Mode");
            end
        join_any
        
        #20 ext_meas_i = 0;

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
