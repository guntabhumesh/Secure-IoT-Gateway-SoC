//------------------------------------------------------------------------------
// File: tb_gpio_apb.sv
// Description: SystemVerilog testbench for native verification of GPIO IP (APB).
//
// Author: Gemini-3 AI
// License: MIT
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_gpio_apb;

    parameter int NUM_BITS = 8;
    parameter real CLK_PERIOD = 10.0;

    // Signals
    logic pclk = 0;
    logic rst_n = 0;
    
    // APB4 Interface
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

    // GPIO Signals
    wire [NUM_BITS-1:0] io;
    logic intr;

    // Clock Generation
    always #(CLK_PERIOD/2) pclk = ~pclk;

    // DUT Instantiation
    gpio_apb #(
        .NUM_BITS(NUM_BITS)
    ) dut (
        .pclk(pclk),
        .presetn(rst_n),
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
        .io(io),
        .intr(intr)
    );

    // Register Offsets
    localparam bit [31:0] REG_DATA_I  = 32'h00;
    localparam bit [31:0] REG_DATA_O  = 32'h04;
    localparam bit [31:0] REG_DIR     = 32'h08;
    localparam bit [31:0] REG_INT_EN  = 32'h0C;
    localparam bit [31:0] REG_INT_STS = 32'h1C;
    localparam bit [31:0] REG_SET_O   = 32'h20;
    localparam bit [31:0] REG_CLR_O   = 32'h24;
    localparam bit [31:0] REG_TGL_O   = 32'h28;

    // Shared BFM Tasks
    `include "apb_bfm_tasks.sv"

    // Main Test Sequence
    initial begin
        logic [31:0] rdata;
        int errors = 0;
        
        // Reset
        rst_n = 0;
        psel = 0;
        penable = 0;
        repeat(5) @(posedge pclk);
        rst_n = 1;
        repeat(2) @(posedge pclk);

        $display("[%t] Starting APB Native Directed Test...", $time);

        // Test 1: Basic R/W and DIR
        $display("[%t] Test 1: Basic R/W and DIR", $time);
        apb_write(REG_DIR, 32'hFF);
        apb_write(REG_DATA_O, 32'hAA);
        repeat(10) @(posedge pclk); // Wait for synchronization/debouncing
        apb_read(REG_DATA_O, rdata);
        if (rdata[7:0] !== 8'hAA) begin
            $error("Test 1 Failed: DATA_O mismatch, got %h expected AA", rdata[7:0]);
            errors++;
        end
        apb_read(REG_DATA_I, rdata);
        if (rdata[7:0] !== 8'hAA) begin
            $error("Test 1 Failed: DATA_I mismatch, got %h expected AA", rdata[7:0]);
            errors++;
        end

        // Test 2: Atomic Operations
        $display("[%t] Test 2: Atomic Operations", $time);
        apb_write(REG_DATA_O, 32'h00);
        apb_write(REG_SET_O,  32'h55);
        apb_read(REG_DATA_O, rdata);
        if (rdata[7:0] !== 8'h55) begin
            $error("Test 2 Failed: SET failed, got %h expected 55", rdata[7:0]);
            errors++;
        end
        
        apb_write(REG_TGL_O,  32'h33);
        apb_read(REG_DATA_O, rdata);
        if (rdata[7:0] !== 8'h66) begin
            $error("Test 2 Failed: TGL failed, got %h expected 66", rdata[7:0]);
            errors++;
        end

        apb_write(REG_CLR_O,  32'h44);
        apb_read(REG_DATA_O, rdata);
        if (rdata[7:0] !== 8'h22) begin
            $error("Test 2 Failed: CLR failed, got %h expected 22", rdata[7:0]);
            errors++;
        end

        // Test 3: Interrupts (Basic)
        $display("[%t] Test 3: Interrupts (Basic)", $time);
        apb_write(REG_DIR,    32'hFF); // Outputs
        apb_write(REG_INT_EN, 32'h01); // Enable Bit 1
        apb_write(REG_DATA_O, 32'h01); // Bit 1 High
        repeat(5) @(posedge pclk);
        apb_write(REG_INT_STS, 32'h01); // Clear Status
        repeat(2) @(posedge pclk);
        
        apb_write(REG_DATA_O, 32'h00); // Falling Edge on Bit 1
        repeat(10) @(posedge pclk);
        
        apb_read(REG_INT_STS, rdata);
        if (!(rdata & 32'h01)) begin
             $error("Test 3 Failed: Interrupt status not set");
             errors++;
        end
        if (!intr) begin
             $error("Test 3 Failed: Global interrupt not asserted");
             errors++;
        end
        apb_write(REG_INT_STS, 32'h01); // Clear

        $display("[%t] APB Native Directed Test Completion.", $time);
        $display("--------------------------------------------------");
        if (errors == 0) begin
            $display("APB TEST PASSED");
        end else begin
            $display("APB TEST FAILED with %0d errors", errors);
        end
        $display("--------------------------------------------------");
        #100 $finish;
    end

    // Timeout Watchdog
    initial begin
        #1000000; // 1 ms timeout
        $display("TIMEOUT - Testbench hung");
        $finish;
    end

endmodule
