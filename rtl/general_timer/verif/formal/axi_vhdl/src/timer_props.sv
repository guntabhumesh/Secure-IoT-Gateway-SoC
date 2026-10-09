//-------------------------------------------------------------------------------
// File: timer_props.sv
// Description: SVA Properties for General Purpose Timer IP
// Note: Using immediate assertions within always blocks for robust Yosys support.
//-------------------------------------------------------------------------------

module timer_core_props (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    input  logic        mode,
    input  logic        dir,
    input  logic        pre_en,
    input  logic [15:0] pre_val,
    input  logic [31:0] load_val,
    input  logic        load_cmd,
    input  logic [31:0] counter,
    input  logic        tick,
    input  logic        irq,
    input  logic        trigger_o,
    input  logic        capture_re,
    input  logic        capture_stb,
    input  logic [31:0] capture_val,
    input  logic        pwm_en,
    input  logic [31:0] cmp_val,
    input  logic        pwm_o
);

    always @(posedge clk) begin
        if (rst_n) begin
            // 1. Load Command
            if ($past(load_cmd)) begin
                assert(counter == $past(load_val));
            end

            // 2. Counting Logic (Down)
            if ($past(en && tick && !dir && !load_cmd && counter > 0)) begin
                assert(counter == $past(counter) - 1);
            end

            // 3. Counting Logic (Up)
            if ($past(en && tick && dir && !load_cmd && counter < load_val)) begin
                assert(counter == $past(counter) + 1);
            end

            // 4. Timer Expiry (Down)
            if ($past(en && tick && !dir && !load_cmd && counter == 0)) begin
                assert(irq && trigger_o);
            end

            // 5. Timer Expiry (Up)
            if ($past(en && tick && dir && !load_cmd && counter == load_val)) begin
                assert(irq && trigger_o);
            end

            // 6. Reload Logic (Continuous Mode, Down)
            if ($past(en && tick && !dir && !load_cmd && mode && counter == 0)) begin
                assert(counter == $past(load_val));
            end
            
            // 7. Capture Logic
            if ($past(capture_re)) begin
                assert(capture_stb);
                assert(capture_val == $past(counter));
            end
            
            // 8. PWM Correctness (Immediate combinational check)
            if (pwm_en) begin
                if (!dir) begin // Down
                    if (counter <= cmp_val) assert(pwm_o);
                    else assert(!pwm_o);
                end else begin // Up
                    if (counter < cmp_val) assert(pwm_o);
                    else assert(!pwm_o);
                end
            end
        end
    end

endmodule

module timer_regs_props (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs,
    input  logic        we,
    input  logic [5:0]  addr,
    input  logic [31:0] wdata,
    input  logic [31:0] rdata,
    input  logic [31:0] reg_ctrl,
    input  logic [31:0] reg_load,
    input  logic [31:0] current_val
);
    // Address offsets
    localparam ADDR_CTRL    = 6'h00;
    localparam ADDR_LOAD    = 6'h04;
    localparam ADDR_VAL     = 6'h08;

    always @(posedge clk) begin
        if (rst_n) begin
            // 1. Control Register Write
            if ($past(cs && we && (addr == ADDR_CTRL))) begin
                assert(reg_ctrl == $past(wdata));
            end

            // 2. Load Register Write
            if ($past(cs && we && (addr == ADDR_LOAD))) begin
                assert(reg_load == $past(wdata));
            end

            // 3. Current Value Read
            if (cs && !we && (addr == ADDR_VAL)) begin
                assert(rdata == current_val);
            end
        end
    end

endmodule

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
            // Handshake Stability (Assume inputs stay high until ready)
            if ($past(s_axi_awvalid && !s_axi_awready)) assume(s_axi_awvalid);
            if ($past(s_axi_wvalid && !s_axi_wready))   assume(s_axi_wvalid);
            if ($past(s_axi_arvalid && !s_axi_arready)) assume(s_axi_arvalid);
            
            // Output stability (Assert outputs stay high until ready)
            if ($past(s_axi_bvalid && !s_axi_bready))   assert(s_axi_bvalid);
            if ($past(s_axi_rvalid && !s_axi_rready))   assert(s_axi_rvalid);
        end
    end
endmodule

module apb_props (
    input logic pclk,
    input logic presetn,
    input logic psel,
    input logic penable,
    input logic pready
);
    always @(posedge pclk) begin
        if (presetn) begin
            // APB Protocol compliance
            if ($past(psel && !penable)) assert(penable);
            if ($past(psel && !pready))  assert(psel);
        end
    end
endmodule

module wb_props (
    input logic clk,
    input logic rst,
    input logic stb,
    input logic cyc,
    input logic ack
);
    always @(posedge clk) begin
        if (!rst) begin
            // Wishbone Protocol compliance
            if ($past(stb && cyc && !ack)) begin
                assert(stb && cyc);
            end
            if (ack) assert(cyc);
        end
    end
endmodule
