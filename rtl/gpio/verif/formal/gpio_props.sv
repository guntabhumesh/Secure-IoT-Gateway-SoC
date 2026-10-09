/*
 * File: gpio_props.sv
 * Description: SystemVerilog Properties for GPIO IP Formal Verification
 * Note: Using immediate assertions for robust Yosys support.
 */

// -----------------------------------------------------------------------------
// Register Block Properties (Bind to gpio_regs)
// -----------------------------------------------------------------------------
module gpio_regs_props #(
    parameter int NUM_BITS = 32
) (
    input logic clk,
    input logic reset_n,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic [31:0] rdata,
    input logic we,
    input logic re,
    input logic ack,
    input logic [NUM_BITS-1:0] reg_data_o,
    input logic [NUM_BITS-1:0] reg_dir
);

    always @(posedge clk) begin
        if (reset_n) begin
            // 1. DATA_O Write Check
            // (we && addr == 0x04) |=> (reg_data_o == wdata)
            if ($past(we && addr[6:0] == 7'h04)) begin
                assert(reg_data_o == $past(wdata[NUM_BITS-1:0]));
            end

            // 2. DIR Write Check
            // (we && addr == 0x08) |=> (reg_dir == wdata)
            if ($past(we && addr[6:0] == 7'h08)) begin
                assert(reg_dir == $past(wdata[NUM_BITS-1:0]));
            end

            // 3. ACK Generation
            // (we || re) |=> ack
            if ($past(we || re)) begin
                assert(ack);
            end

            // 4. Stable Read (Combinational/Same Cycle check)
            // (re && addr == 0x04) |-> (rdata == reg_data_o)
            if (re && addr[6:0] == 7'h04) begin
                assert(rdata[NUM_BITS-1:0] == reg_data_o);
            end
        end
    end

endmodule


// -----------------------------------------------------------------------------
// APB Protocol Properties (Bind to gpio_apb)
// -----------------------------------------------------------------------------
module apb_props (
    input logic pclk,
    input logic presetn,
    input logic psel,
    input logic penable,
    input logic pwrite,
    input logic pready
);
    
    always @(posedge pclk) begin
        if (presetn) begin
            // 1. PREADY Stability
            // (psel && penable) |-> pready
            if (psel && penable) begin
                assert(pready);
            end

            // 2. PREADY Constant
            assert(pready == 1'b1);
        end
    end

endmodule


// -----------------------------------------------------------------------------
// AXI Protocol Properties (Bind to gpio_axi)
// -----------------------------------------------------------------------------
module axi_props (
    input logic s_axi_aclk,
    input logic s_axi_aresetn,
    input logic s_axi_awvalid,
    input logic s_axi_awready,
    input logic s_axi_wvalid,
    input logic s_axi_wready,
    input logic s_axi_bvalid,
    input logic s_axi_bready,
    input logic s_axi_arvalid,
    input logic s_axi_arready,
    input logic s_axi_rvalid,
    input logic s_axi_rready
);

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn) begin
            // 1. Handshake Stability (Inputs assumptions)
            // AWVALID && !AWREADY |=> AWVALID
            if ($past(s_axi_awvalid && !s_axi_awready)) begin
                assume(s_axi_awvalid);
            end

            // WVALID && !WREADY |=> WVALID
            if ($past(s_axi_wvalid && !s_axi_wready)) begin
                assume(s_axi_wvalid);
            end
        end
    end

endmodule


// -----------------------------------------------------------------------------
// Wishbone Protocol Properties (Bind to gpio_wb)
// -----------------------------------------------------------------------------
module wb_props (
    input logic wb_clk_i,
    input logic wb_rst_i,
    input logic wb_cyc_i,
    input logic wb_stb_i,
    input logic wb_ack_o
);

    always @(posedge wb_clk_i) begin
        // Reset check
        if (wb_rst_i) begin
            assert(!wb_ack_o);
        end else begin
            // 1. Response Generation
            // (cyc && stb && !ack) |=> (ack || ##1 ack)
            // If request started last cycle and wasn't acked, it should be acked now or soon?
            // RTL is: ack <= (we || re); where we/re derived from cyc&&stb.
            // So latency is exactly 1 cycle.
            
            // If we had a valid strobe last cycle, we MUST have ack this cycle.
            // Because RTL registers the ack signal.
            if ($past(wb_cyc_i && wb_stb_i && !wb_ack_o)) begin
                 assert(wb_ack_o);
            end
        end
    end

endmodule
