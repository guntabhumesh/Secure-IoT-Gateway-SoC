/*
 * File: tb_top.sv
 * Description: UVM Top Testbench
 */

module tb_top;
    import uvm_pkg::*;
    import test_lib_pkg::*;

    logic clk;
    logic rst_n;

    // Clock Generation
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 0;
        #20ns;
        rst_n = 1;
    end

    // Interfaces
    // Interfaces
    apb_if  apb_vif(clk, rst_n);
    axi_if  axi_vif(clk, rst_n);
    wb_if   wb_vif(clk, rst_n);
    gpio_if gpio_vif(clk, rst_n);

    // DUT Instantiation
    wire [31:0] gpio_io;
    
`ifdef BUS_AXI
    // AXI Wrapper
    gpio_axi #(
        .NUM_BITS(32)
    ) dut (
        .s_axi_aclk(clk),
        .s_axi_aresetn(rst_n),
        // AXI Mapping
        .s_axi_awaddr(axi_vif.awaddr),
        .s_axi_awprot(axi_vif.awprot),
        .s_axi_awvalid(axi_vif.awvalid),
        .s_axi_awready(axi_vif.awready),
        .s_axi_wdata(axi_vif.wdata),
        .s_axi_wstrb(axi_vif.wstrb),
        .s_axi_wvalid(axi_vif.wvalid),
        .s_axi_wready(axi_vif.wready),
        .s_axi_bresp(axi_vif.bresp),
        .s_axi_bvalid(axi_vif.bvalid),
        .s_axi_bready(axi_vif.bready),
        .s_axi_araddr(axi_vif.araddr),
        .s_axi_arprot(axi_vif.arprot),
        .s_axi_arvalid(axi_vif.arvalid),
        .s_axi_arready(axi_vif.arready),
        .s_axi_rdata(axi_vif.rdata),
        .s_axi_rresp(axi_vif.rresp),
        .s_axi_rvalid(axi_vif.rvalid),
        .s_axi_rready(axi_vif.rready),
        // GPIO Mapping
        .io(gpio_io),
        .intr(gpio_vif.intr)
    );

    // GPIO IO Connection
    assign gpio_io = (dut.u_gpio_wrapper.oe == 0) ? gpio_vif.ipins : 32'hz;
    assign gpio_vif.opins = dut.u_gpio_wrapper.o;
    assign gpio_vif.oen   = dut.u_gpio_wrapper.oe;

    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", gpio_vif);
        run_test();
    end

`elsif BUS_WB
    // Wishbone Wrapper
    gpio_wb #(
        .NUM_BITS(32)
    ) dut (
        .wb_clk_i(clk),
        .wb_rst_i(~rst_n), // Wishbone RST is usually active high, verify this!
        // WB Mapping
        .wb_adr_i(wb_vif.adr),
        .wb_dat_i(wb_vif.dat_i),
        .wb_dat_o(wb_vif.dat_o),
        .wb_we_i(wb_vif.we),
        .wb_sel_i(wb_vif.sel),
        .wb_stb_i(wb_vif.stb),
        .wb_cyc_i(wb_vif.cyc),
        .wb_ack_o(wb_vif.ack),
        //.wb_err_o(wb_vif.err),
        //.wb_stall_o(wb_vif.stall),
        // GPIO Mapping
        .io(gpio_io),
        .intr(gpio_vif.intr)
    );
    
    // GPIO IO Connection
    assign gpio_io = (dut.u_gpio_wrapper.oe == 0) ? gpio_vif.ipins : 32'hz;
    assign gpio_vif.opins = dut.u_gpio_wrapper.o;
    assign gpio_vif.oen   = dut.u_gpio_wrapper.oe;

    initial begin
        uvm_config_db#(virtual wb_if)::set(null, "*", "vif", wb_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", gpio_vif);
        run_test();
    end

`else
    // APB Wrapper (Default)
    gpio_apb #(
        .NUM_BITS(32)
    ) dut (
        .pclk(clk),
        .presetn(rst_n),
        // APB Mapping
        .psel(apb_vif.psel),
        .penable(apb_vif.penable),
        .pwrite(apb_vif.pwrite),
        .paddr(apb_vif.paddr),
        .pwdata(apb_vif.pwdata),
        .pstrb(apb_vif.pstrb),
        .pprot(apb_vif.pprot),
        .prdata(apb_vif.prdata),
        .pready(apb_vif.pready),
        .pslverr(apb_vif.pslverr),
        // GPIO Mapping
        .io(gpio_io),
        .intr(gpio_vif.intr)
    );

    // GPIO IO Connection
    assign gpio_io = (dut.u_gpio_wrapper.oe == 0) ? gpio_vif.ipins : 32'hz;
    assign gpio_vif.opins = dut.u_gpio_wrapper.o;
    assign gpio_vif.oen   = dut.u_gpio_wrapper.oe;

    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", apb_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", gpio_vif);
        run_test();
    end
`endif

endmodule
