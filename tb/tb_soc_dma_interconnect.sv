// =============================================================================
// tb_soc_dma_interconnect.sv
//
// Testbench to verify DMA through the AXI interconnect.
// Instantiates soc_top.
// Uses s00 to configure DMA at 0x0B00_0000.
// DMA transfers 1 word from m03 (0x0300_0000) to m04 (0x0400_0000).
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import amba_axi_pkg::*;
import dma_utils_pkg::*;

module tb_soc_dma_interconnect;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = DATA_WIDTH/8;
    localparam ID_WIDTH   = 8;

    localparam CLK_PERIOD = 10;

    reg clk = 1'b0;
    reg rst_n = 1'b0;

    always #(CLK_PERIOD/2) clk = ~clk;

    // s00 AXI master stimulus signals
    reg  [ID_WIDTH-1:0]   s00_axi_awid    = 0;
    reg  [ADDR_WIDTH-1:0] s00_axi_awaddr  = 0;
    reg  [7:0]            s00_axi_awlen   = 0;
    reg  [2:0]            s00_axi_awsize  = 3'b010;
    reg  [1:0]            s00_axi_awburst = 2'b01;
    reg                   s00_axi_awlock  = 0;
    reg  [3:0]            s00_axi_awcache = 0;
    reg  [2:0]            s00_axi_awprot  = 0;
    reg  [3:0]            s00_axi_awqos   = 0;
    reg                   s00_axi_awvalid = 0;
    wire                  s00_axi_awready;

    reg  [DATA_WIDTH-1:0] s00_axi_wdata  = 0;
    reg  [STRB_WIDTH-1:0] s00_axi_wstrb  = 4'hf;
    reg                   s00_axi_wlast  = 1;
    reg                   s00_axi_wvalid = 0;
    wire                  s00_axi_wready;

    wire [ID_WIDTH-1:0]   s00_axi_bid;
    wire [1:0]            s00_axi_bresp;
    wire                  s00_axi_bvalid;
    reg                   s00_axi_bready = 1;

    reg  [ID_WIDTH-1:0]   s00_axi_arid    = 0;
    reg  [ADDR_WIDTH-1:0] s00_axi_araddr  = 0;
    reg  [7:0]            s00_axi_arlen   = 0;
    reg  [2:0]            s00_axi_arsize  = 3'b010;
    reg  [1:0]            s00_axi_arburst = 2'b01;
    reg                   s00_axi_arlock  = 0;
    reg  [3:0]            s00_axi_arcache = 0;
    reg  [2:0]            s00_axi_arprot  = 0;
    reg  [3:0]            s00_axi_arqos   = 0;
    reg                   s00_axi_arvalid = 0;
    wire                  s00_axi_arready;

    wire [ID_WIDTH-1:0]   s00_axi_rid;
    wire [DATA_WIDTH-1:0] s00_axi_rdata;
    wire [1:0]            s00_axi_rresp;
    wire                  s00_axi_rlast;
    wire                  s00_axi_rvalid;
    reg                   s00_axi_rready = 1;

    // s01 tied off
    wire s01_axi_awready;
    wire s01_axi_wready;
    wire [ID_WIDTH-1:0] s01_axi_bid;
    wire [1:0] s01_axi_bresp;
    wire s01_axi_bvalid;
    wire s01_axi_arready;
    wire [ID_WIDTH-1:0] s01_axi_rid;
    wire [DATA_WIDTH-1:0] s01_axi_rdata;
    wire [1:0] s01_axi_rresp;
    wire s01_axi_rlast;
    wire s01_axi_rvalid;

    // external signals
    wire scl_pad_i = 1'b1;
    wire scl_pad_o;
    wire scl_padoen_o;
    wire sda_pad_i = 1'b1;
    wire sda_pad_o;
    wire sda_padoen_o;
    wire i2c_irq;
    wire uart_tx_o;
    wire uart_rx_i = 1'b1;
    wire uart_irq;

    soc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos), .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready), .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos), .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready), .s00_axi_rid(s00_axi_rid),
        .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast), .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),

        .s01_axi_awid(8'b0), .s01_axi_awaddr(32'b0), .s01_axi_awlen(8'b0),
        .s01_axi_awsize(3'b010), .s01_axi_awburst(2'b01), .s01_axi_awlock(1'b0),
        .s01_axi_awcache(4'b0), .s01_axi_awprot(3'b0), .s01_axi_awqos(4'b0),
        .s01_axi_awvalid(1'b0), .s01_axi_awready(s01_axi_awready),
        .s01_axi_wdata(32'b0), .s01_axi_wstrb(4'b0), .s01_axi_wlast(1'b0),
        .s01_axi_wvalid(1'b0), .s01_axi_wready(s01_axi_wready),
        .s01_axi_bid(s01_axi_bid), .s01_axi_bresp(s01_axi_bresp),
        .s01_axi_bvalid(s01_axi_bvalid), .s01_axi_bready(1'b1),
        .s01_axi_arid(8'b0), .s01_axi_araddr(32'b0), .s01_axi_arlen(8'b0),
        .s01_axi_arsize(3'b010), .s01_axi_arburst(2'b01), .s01_axi_arlock(1'b0),
        .s01_axi_arcache(4'b0), .s01_axi_arprot(3'b0), .s01_axi_arqos(4'b0),
        .s01_axi_arvalid(1'b0), .s01_axi_arready(s01_axi_arready),
        .s01_axi_rid(s01_axi_rid), .s01_axi_rdata(s01_axi_rdata),
        .s01_axi_rresp(s01_axi_rresp), .s01_axi_rlast(s01_axi_rlast),
        .s01_axi_rvalid(s01_axi_rvalid), .s01_axi_rready(1'b1),

        .scl_pad_i(scl_pad_i), .scl_pad_o(scl_pad_o), .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda_pad_i), .sda_pad_o(sda_pad_o), .sda_padoen_o(sda_padoen_o),
        .i2c_irq(i2c_irq), .uart_tx_o(uart_tx_o), .uart_rx_i(uart_rx_i), .uart_irq(uart_irq)
    );

    // AXI Write Task
    // AXI Write Task
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        reg aw_done;
        reg w_done;
    begin
        @(posedge clk); #1;
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= 4'hf;
        s00_axi_wlast   <= 1'b1;
        s00_axi_wvalid  <= 1'b1;

        aw_done = 0;
        w_done = 0;
        $display("[%0t] Starting AXI Write to %h, data %h", $time, addr, data);

        while (!aw_done || !w_done) begin
            @(posedge clk);
            if (!aw_done && s00_axi_awready && s00_axi_awvalid) begin
                aw_done = 1;
                $display("[%0t] AXI Write AW_DONE", $time);
                s00_axi_awvalid <= 1'b0;
            end
            if (!w_done && s00_axi_wready && s00_axi_wvalid) begin
                w_done = 1;
                $display("[%0t] AXI Write W_DONE", $time);
                s00_axi_wvalid <= 1'b0;
            end
        end

        s00_axi_bready <= 1'b1;
        while (!s00_axi_bvalid) begin
            @(posedge clk);
        end
        $display("[%0t] AXI Write BVALID received", $time);
        s00_axi_bready <= 1'b0;
    end
    endtask

    // AXI Read Task
    reg [DATA_WIDTH-1:0] rd_data;
    task axi_read;
        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;
    begin
        @(posedge clk); #1;
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        $display("[%0t] Starting AXI Read from %h", $time, addr);

        while (1) begin
            @(posedge clk);
            if (s00_axi_arready) begin
                $display("[%0t] AXI Read AR_DONE", $time);
                s00_axi_arvalid <= 1'b0;
                break;
            end
        end

        s00_axi_rready <= 1'b1;
        while (1) begin
            @(posedge clk);
            if (s00_axi_rvalid) begin
                data = s00_axi_rdata;
                $display("[%0t] AXI Read R_DONE, data %h", $time, data);
                break;
            end
        end
        s00_axi_rready <= 1'b0;
    end
    endtask

    localparam [ADDR_WIDTH-1:0] DMA_BASE = 32'h0B00_0000;
    localparam [ADDR_WIDTH-1:0] DMA_CTRL = DMA_BASE + 32'h00;
    localparam [ADDR_WIDTH-1:0] DMA_STAT = DMA_BASE + 32'h08;
    localparam [ADDR_WIDTH-1:0] DMA_SRC  = DMA_BASE + 32'h20;
    localparam [ADDR_WIDTH-1:0] DMA_DST  = DMA_BASE + 32'h30;
    localparam [ADDR_WIDTH-1:0] DMA_LEN  = DMA_BASE + 32'h40;
    localparam [ADDR_WIDTH-1:0] DMA_CFG  = DMA_BASE + 32'h50;

    localparam [ADDR_WIDTH-1:0] M03_ADDR = 32'h0300_0000;
    localparam [ADDR_WIDTH-1:0] M04_ADDR = 32'h0400_0000;

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    initial begin
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(10) @(posedge clk);

        $display("\n--- Step 1: Write test pattern to Source (M03) ---");
        axi_write(M03_ADDR, 32'hCAFEBABE);
        axi_read(M03_ADDR, rd_data);
        if (rd_data === 32'hCAFEBABE) begin
            $display("  [PASS] M03 correctly written with CAFEBABE");
        end else begin
            $display("  [FAIL] M03 readback = 0x%08h, expected 0xCAFEBABE", rd_data);
        end

        $display("\n--- Step 2: Write test pattern to Destination (M04) to clear it ---");
        axi_write(M04_ADDR, 32'h00000000);
        axi_read(M04_ADDR, rd_data);
        if (rd_data === 32'h00000000) begin
            $display("  [PASS] M04 correctly cleared to 0");
        end else begin
            $display("  [FAIL] M04 readback = 0x%08h", rd_data);
        end

        $display("\n--- Step 3: Configure DMA via AXI ---");
        axi_write(DMA_SRC, M03_ADDR);
        axi_write(DMA_DST, M04_ADDR);
        axi_write(DMA_LEN, 32'd4); // 4 bytes (1 word) to avoid burst issues with dummy_axi_slave
        axi_write(DMA_CFG, 32'h4); // Enable descriptor 0 (bit 2)

        axi_read(DMA_SRC, rd_data);
        if (rd_data === M03_ADDR) $display("  [PASS] DMA SRC configured correctly");
        else $display("  [FAIL] DMA SRC readback = 0x%08h", rd_data);

        axi_read(DMA_DST, rd_data);
        $display("  [INFO] DMA DST readback = 0x%08h", rd_data);

        axi_read(DMA_LEN, rd_data);
        $display("  [INFO] DMA LEN readback = 0x%08h", rd_data);

        axi_read(DMA_CFG, rd_data);
        $display("  [INFO] DMA CFG readback = 0x%08h", rd_data);

        $display("\n--- Step 4: Trigger DMA ---");
        axi_write(DMA_CTRL, 32'h0000_03FD); // Set go bit (bit 0) and max_burst=0xFF (bits 9:2)

        axi_read(DMA_CTRL, rd_data);
        $display("  [INFO] DMA CTRL readback = 0x%08h", rd_data);

        $display("\n--- Step 5: Poll DMA Done ---");
        begin : poll
            integer i;
            for (i=0; i<100; i=i+1) begin
                axi_read(DMA_STAT, rd_data);
                if (rd_data[16] === 1'b1) begin
                    $display("  [PASS] DMA Done bit is set.");
                    disable poll;
                end
            end
            $display("  [FAIL] DMA timed out.");
            fail_cnt = fail_cnt + 1;
        end

        $display("\n--- Step 6: Verify Destination Data (M04) ---");
        axi_read(M04_ADDR, rd_data);
        if (rd_data === 32'hCAFEBABE) begin
            $display("  [PASS] DMA successfully transferred data: 0x%08h", rd_data);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] M04 data mismatch: got 0x%08h, expected 0xCAFEBABE", rd_data);
            fail_cnt = fail_cnt + 1;
        end

        $display("\n=====================================================");
        $display(" SUMMARY: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        if (fail_cnt == 0 && pass_cnt > 0)
            $display(" ** ALL TESTS PASSED **");
        else
            $display(" ** SOME TESTS FAILED **");
        $display("=====================================================\n");

        repeat(20) @(posedge clk);
        $finish;
    end

    initial begin
        #10000;
        $display("ERROR: Simulation timeout");
        $finish;
    end
endmodule
