module timer_axi_vhdl_binds;
    bind timer_axi axi_props props_axi (
        .s_axi_aclk(aclk),
        .s_axi_aresetn(aresetn),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );
endmodule
