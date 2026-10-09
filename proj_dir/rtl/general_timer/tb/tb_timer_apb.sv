//
// Native Testbench for Timer APB Wrapper
//

module tb_timer_apb;

    logic        pclk;
    logic        presetn;
    logic [31:0] paddr;
    logic [2:0]  pprot;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] pwdata;
    logic [3:0]  pstrb;
    logic        pready;
    logic [31:0] prdata;
    logic        pslverr;
    logic        irq;

    logic        ext_meas_i;
    logic        capture_i;
    logic        pwm_o;
    logic        trigger_o;

    // Clock Generation
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    // DUT Instantiation
    timer_apb dut (
        .pclk(pclk),
        .presetn(presetn),
        .paddr(paddr),
        .pprot(pprot),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pstrb(pstrb),
        .pready(pready),
        .prdata(prdata),
        .pslverr(pslverr),
        .ext_meas_i(ext_meas_i),
        .capture_i(capture_i),
        .pwm_o(pwm_o),
        .trigger_o(trigger_o),
        .irq(irq)
    );

    // Shared BFM Tasks
    `include "apb_bfm_tasks.sv"

    // Register Map Offsets
    localparam ADDR_CTRL    = 32'h00;
    localparam ADDR_LOAD    = 32'h04;
    localparam ADDR_VAL     = 32'h08;
    localparam ADDR_INT_EN  = 32'h10;
    localparam ADDR_INT_STS = 32'h14;
    localparam ADDR_CMP     = 32'h18;
    localparam ADDR_CAP     = 32'h1C;

    logic [31:0] rdata;

    logic [31:0] timeout;

    initial begin
        $dumpfile("dump_apb.vcd");
        $dumpvars(0, tb_timer_apb);

        // Reset
        presetn = 0;
        psel    = 0;
        penable = 0;
        pwrite  = 0;
        paddr   = 0;
        pwdata  = 0;
        pprot   = 0;
        pstrb   = 0;
        timeout = 0;
        ext_meas_i = 0;
        capture_i = 0;
        
        repeat(10) @(posedge pclk);
        presetn = 1;
        repeat(10) @(posedge pclk);

        $display("TEST 1: APB Register R/W");
        // Write Load
        apb_write(ADDR_LOAD, 32'hDEADBEEF);
        
        // Read Load
        apb_read(ADDR_LOAD, rdata);
        if (rdata !== 32'hDEADBEEF) $error("APB Read Mismatch: Expected DEADBEEF, Got %h", rdata);
        else $display("APB Read LOAD: PASS");

        // Write CMP
        apb_write(ADDR_CMP, 32'hCAFEBABE);
        apb_read(ADDR_CMP, rdata);
        if (rdata !== 32'hCAFEBABE) $error("APB Read CMP Mismatch: Expected CAFEBABE, Got %h", rdata);
        else $display("APB Read CMP: PASS");

        $display("TEST 2: Timer Functionality via APB");
        // Load = 10
        apb_write(ADDR_LOAD, 32'd10);
        
        // Enable Interrupt (Bit 0 = Wrap, Bit 1 = Capture)
        apb_write(ADDR_INT_EN, 32'd1);
        apb_read(ADDR_INT_EN, rdata);
        $display("INT_EN Readback: %h", rdata); 

        // Enable Timer (Bit 0 = En)
        apb_write(ADDR_CTRL, 32'd1);
        $display("Timer Enabled. Waiting for IRQ...");

        // Wait loop with timeout
        timeout = 0;
        while (irq == 0 && timeout < 1000) begin
            @(posedge pclk);
            timeout++;
            if (timeout % 100 == 0) begin    
                apb_read(ADDR_VAL, rdata); // Read VAL
                $display("Time: %t, Count: %d, IRQ: %b", $time, rdata, irq);
                apb_read(ADDR_INT_EN, rdata);
                if (rdata != 1) $display("WARNING: INT_EN lost!");
            end
        end
        
        if (irq) $display("APB Interrupt Received");
        else begin
            $display("TIMEOUT waiting for IRQ");
            apb_read(ADDR_INT_STS, rdata); // Read INT_STS
            $display("Final INT_STS: %h", rdata);
            $error("Test Failed: Timeout");
        end
        
        $display("APB TESTS PASSED");
        $finish;
    end

endmodule
