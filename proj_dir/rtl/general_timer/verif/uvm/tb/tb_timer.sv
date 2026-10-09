/*
 * File: tb_timer.sv
 * Description: UVM Testbench Top for General Timer IP (SystemVerilog DUT)
 */

`include "uvm_macros.svh"

module tb_timer;
    import uvm_pkg::*;
    import timer_env_pkg::*;
    import timer_test_pkg::*;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // Interfaces
    axi_if axi_inst(clk, rst_n);
    apb_if apb_inst(clk, rst_n);
    wb_if  wb_inst(clk, rst_n);
    timer_if t_inst(clk, rst_n);

    // DUT Instantiation (Conditional based on BUS_TYPE)
    `ifdef BUS_AXI
    timer_axi dut (
        .aclk(clk),
        .aresetn(rst_n),
        .awaddr(axi_inst.awaddr),
        .awprot(axi_inst.awprot),
        .awvalid(axi_inst.awvalid),
        .awready(axi_inst.awready),
        .wdata(axi_inst.wdata),
        .wstrb(axi_inst.wstrb),
        .wvalid(axi_inst.wvalid),
        .wready(axi_inst.wready),
        .bresp(axi_inst.bresp),
        .bvalid(axi_inst.bvalid),
        .bready(axi_inst.bready),
        .araddr(axi_inst.araddr),
        .arprot(axi_inst.arprot),
        .arvalid(axi_inst.arvalid),
        .arready(axi_inst.arready),
        .rdata(axi_inst.rdata),
        .rresp(axi_inst.rresp),
        .rvalid(axi_inst.rvalid),
        .rready(axi_inst.rready),
        .ext_meas_i(t_inst.ext_meas_i),
        .capture_i(t_inst.capture_i),
        .pwm_o(t_inst.pwm_o),
        .trigger_o(t_inst.trigger_o),
        .irq(t_inst.irq)
    );
    `elsif BUS_APB
    timer_apb dut (
        .pclk(clk),
        .presetn(rst_n),
        .paddr(apb_inst.paddr),
        .psel(apb_inst.psel),
        .penable(apb_inst.penable),
        .pwrite(apb_inst.pwrite),
        .pwdata(apb_inst.pwdata),
        .pstrb(apb_inst.pstrb),
        .pprot(apb_inst.pprot),
        .pready(apb_inst.pready),
        .prdata(apb_inst.prdata),
        .pslverr(apb_inst.pslverr),
        .ext_meas_i(t_inst.ext_meas_i),
        .capture_i(t_inst.capture_i),
        .pwm_o(t_inst.pwm_o),
        .trigger_o(t_inst.trigger_o),
        .irq(t_inst.irq)
    );
    `elsif BUS_WB
    timer_wb dut (
        .wb_clk_i(clk),
        .wb_rst_i(!rst_n),
        .wb_adr_i(wb_inst.adr),
        .wb_dat_i(wb_inst.dat_i),
        .wb_dat_o(wb_inst.dat_o),
        .wb_we_i(wb_inst.we),
        .wb_sel_i(wb_inst.sel),
        .wb_stb_i(wb_inst.stb),
        .wb_cyc_i(wb_inst.cyc),
        .wb_ack_o(wb_inst.ack),
        .ext_meas_i(t_inst.ext_meas_i),
        .capture_i(t_inst.capture_i),
        .pwm_o(t_inst.pwm_o),
        .trigger_o(t_inst.trigger_o),
        .irq(t_inst.irq)
    );
    `endif

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 0;
        t_inst.ext_meas_i = 0;
        t_inst.capture_i = 0;
        #100 rst_n = 1;
    end

    // UVM Setup
    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*.axi_agt*", "vif", axi_inst);
        uvm_config_db#(virtual apb_if)::set(null, "*.apb_agt*", "vif", apb_inst);
        uvm_config_db#(virtual wb_if)::set(null, "*.wb_agt*", "vif", wb_inst);
        uvm_config_db#(virtual timer_if)::set(null, "*.t_agt*", "vif", t_inst);
        
        `ifdef BUS_AXI
            uvm_config_db#(string)::set(null, "uvm_test_top.env", "bus_type", "AXI");
        `elsif BUS_APB
            uvm_config_db#(string)::set(null, "uvm_test_top.env", "bus_type", "APB");
        `elsif BUS_WB
            uvm_config_db#(string)::set(null, "uvm_test_top.env", "bus_type", "WB");
        `endif

        run_test();
    end

endmodule
