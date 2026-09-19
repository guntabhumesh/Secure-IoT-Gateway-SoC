simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/simv" \
           -args
debImport "-dbdir" \
          "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/simv.daidir"
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/dump_soc_uart.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/dump_soc_uart.fsdb
verdiSetActWin -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/dump_soc_uart.fsdb
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvGetSignalClose -win $_nWave2
wvScrollDown -win $_nWave2 0
verdiWindowResize -win $_Verdi_1 "799" "26" "800" "836"
wvSelectSignal -win $_nWave2 {( "G1" 14 )} 
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 16 17 )} 
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 18 19 )} 
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 18 19 )} 
wvSetPosition -win $_nWave2 {("G1" 19)}
wvGetSignalClose -win $_nWave2
wvZoomAll -win $_nWave2
wvSetCursor -win $_nWave2 27991308.333333 -snap {("G1" 19)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 20 21 22 23 24 25 26 27 28 )} 
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 20 21 22 23 24 25 26 27 28 )} 
wvSetPosition -win $_nWave2 {("G1" 28)}
wvGetSignalClose -win $_nWave2
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvSelectSignal -win $_nWave2 {( "G1" 20 )} 
wvSelectGroup -win $_nWave2 {G2}
wvZoom -win $_nWave2 0.000000 58862751.286174
wvSelectGroup -win $_nWave2 {G2}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvSetPosition -win $_nWave2 {("G1" 43)}
wvGetSignalClose -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 42 43 )} 
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSelectSignal -win $_nWave2 {( "G1" 30 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvSelectSignal -win $_nWave2 {( "G1" 28 29 30 31 )} 
wvSelectSignal -win $_nWave2 {( "G1" 28 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvSetPosition -win $_nWave2 {("G1" 31)}
wvSetPosition -win $_nWave2 {("G1" 32)}
wvSetPosition -win $_nWave2 {("G1" 33)}
wvSetPosition -win $_nWave2 {("G1" 34)}
wvSetPosition -win $_nWave2 {("G1" 35)}
wvSetPosition -win $_nWave2 {("G1" 34)}
wvSetPosition -win $_nWave2 {("G1" 33)}
wvSetPosition -win $_nWave2 {("G1" 32)}
wvSetPosition -win $_nWave2 {("G1" 31)}
wvSetPosition -win $_nWave2 {("G1" 30)}
wvSetPosition -win $_nWave2 {("G1" 29)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 29)}
wvSetPosition -win $_nWave2 {("G1" 30)}
wvSetPosition -win $_nWave2 {("G1" 31)}
wvSetPosition -win $_nWave2 {("G1" 32)}
wvSetPosition -win $_nWave2 {("G1" 33)}
wvSetPosition -win $_nWave2 {("G1" 34)}
wvSetPosition -win $_nWave2 {("G1" 35)}
wvSetPosition -win $_nWave2 {("G1" 36)}
wvSetPosition -win $_nWave2 {("G1" 37)}
wvSetPosition -win $_nWave2 {("G1" 38)}
wvSetPosition -win $_nWave2 {("G1" 39)}
wvSetPosition -win $_nWave2 {("G1" 40)}
wvSetPosition -win $_nWave2 {("G1" 41)}
wvSetPosition -win $_nWave2 {("G1" 42)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 42)}
wvSetPosition -win $_nWave2 {("G1" 41)}
wvSetPosition -win $_nWave2 {("G1" 40)}
wvSetPosition -win $_nWave2 {("G1" 39)}
wvSetPosition -win $_nWave2 {("G1" 38)}
wvSetPosition -win $_nWave2 {("G1" 37)}
wvSetPosition -win $_nWave2 {("G1" 36)}
wvSetPosition -win $_nWave2 {("G1" 35)}
wvSetPosition -win $_nWave2 {("G1" 34)}
wvSetPosition -win $_nWave2 {("G1" 33)}
wvSetPosition -win $_nWave2 {("G1" 32)}
wvSetPosition -win $_nWave2 {("G1" 31)}
wvSetPosition -win $_nWave2 {("G1" 30)}
wvSetPosition -win $_nWave2 {("G1" 29)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 43 )} 
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSelectSignal -win $_nWave2 {( "G1" 29 30 31 32 33 34 35 36 37 38 39 40 41 42 \
           43 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSelectGroup -win $_nWave2 {G2}
wvPaste -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSelectGroup -win $_nWave2 {G2}
wvPaste -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G2}
wvPaste -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSelectGroup -win $_nWave2 {G2}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 43 )} 
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes/u_enc"
wvSetPosition -win $_nWave2 {("G1" 48)}
wvSetPosition -win $_nWave2 {("G1" 48)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 44 45 46 47 48 )} 
wvSetPosition -win $_nWave2 {("G1" 48)}
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes/u_dec"
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSetPosition -win $_nWave2 {("G1" 54)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 49 50 51 52 53 54 )} 
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSetPosition -win $_nWave2 {("G1" 54)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 49 50 51 52 53 54 )} 
wvSetPosition -win $_nWave2 {("G1" 54)}
wvGetSignalClose -win $_nWave2
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G2}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes/u_dec"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_uart"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvSetPosition -win $_nWave2 {("G1" 69)}
wvSetPosition -win $_nWave2 {("G1" 69)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
{/tb_soc_top/u_soc/m02_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_arready} \
{/tb_soc_top/u_soc/m02_arvalid} \
{/tb_soc_top/u_soc/m02_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_awready} \
{/tb_soc_top/u_soc/m02_awvalid} \
{/tb_soc_top/u_soc/m02_bready} \
{/tb_soc_top/u_soc/m02_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m02_bvalid} \
{/tb_soc_top/u_soc/m02_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_rready} \
{/tb_soc_top/u_soc/m02_rvalid} \
{/tb_soc_top/u_soc/m02_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_wready} \
{/tb_soc_top/u_soc/m02_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 55 56 57 58 59 60 61 62 63 64 65 66 67 68 \
           69 )} 
wvSetPosition -win $_nWave2 {("G1" 69)}
wvSetPosition -win $_nWave2 {("G1" 69)}
wvSetPosition -win $_nWave2 {("G1" 69)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
{/tb_soc_top/u_soc/m02_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_arready} \
{/tb_soc_top/u_soc/m02_arvalid} \
{/tb_soc_top/u_soc/m02_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_awready} \
{/tb_soc_top/u_soc/m02_awvalid} \
{/tb_soc_top/u_soc/m02_bready} \
{/tb_soc_top/u_soc/m02_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m02_bvalid} \
{/tb_soc_top/u_soc/m02_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_rready} \
{/tb_soc_top/u_soc/m02_rvalid} \
{/tb_soc_top/u_soc/m02_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_wready} \
{/tb_soc_top/u_soc/m02_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 55 56 57 58 59 60 61 62 63 64 65 66 67 68 \
           69 )} 
wvSetPosition -win $_nWave2 {("G1" 69)}
wvGetSignalClose -win $_nWave2
wvScrollDown -win $_nWave2 0
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 69 )} 
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 55 )} 
wvSelectSignal -win $_nWave2 {( "G1" 55 69 )} 
wvSelectSignal -win $_nWave2 {( "G1" 64 )} 
wvSelectSignal -win $_nWave2 {( "G1" 55 )} 
wvSelectSignal -win $_nWave2 {( "G1" 55 56 57 58 59 60 61 62 63 64 65 66 67 68 \
           69 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSelectGroup -win $_nWave2 {G2}
wvPaste -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSetPosition -win $_nWave2 {("G1" 69)}
wvSelectGroup -win $_nWave2 {G2}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes/u_dec"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_uart"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_uart/u_uart"
wvSetPosition -win $_nWave2 {("G1" 77)}
wvSetPosition -win $_nWave2 {("G1" 77)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
{/tb_soc_top/u_soc/m02_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_arready} \
{/tb_soc_top/u_soc/m02_arvalid} \
{/tb_soc_top/u_soc/m02_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_awready} \
{/tb_soc_top/u_soc/m02_awvalid} \
{/tb_soc_top/u_soc/m02_bready} \
{/tb_soc_top/u_soc/m02_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m02_bvalid} \
{/tb_soc_top/u_soc/m02_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_rready} \
{/tb_soc_top/u_soc/m02_rvalid} \
{/tb_soc_top/u_soc/m02_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_wready} \
{/tb_soc_top/u_soc/m02_wvalid} \
{/tb_soc_top/u_soc/u_uart/u_uart/baudrate_divisor_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/read_state\[3:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/rx_fifo_data_out_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_data_in_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_push_int} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_baudrate_div_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_config_reg_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/write_state\[2:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 70 71 72 73 74 75 76 77 )} 
wvSetPosition -win $_nWave2 {("G1" 77)}
wvGetSignalSetScope -win $_nWave2 \
           "/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst"
wvSetPosition -win $_nWave2 {("G1" 81)}
wvSetPosition -win $_nWave2 {("G1" 81)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
{/tb_soc_top/u_soc/m02_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_arready} \
{/tb_soc_top/u_soc/m02_arvalid} \
{/tb_soc_top/u_soc/m02_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_awready} \
{/tb_soc_top/u_soc/m02_awvalid} \
{/tb_soc_top/u_soc/m02_bready} \
{/tb_soc_top/u_soc/m02_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m02_bvalid} \
{/tb_soc_top/u_soc/m02_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_rready} \
{/tb_soc_top/u_soc/m02_rvalid} \
{/tb_soc_top/u_soc/m02_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_wready} \
{/tb_soc_top/u_soc/m02_wvalid} \
{/tb_soc_top/u_soc/u_uart/u_uart/baudrate_divisor_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/read_state\[3:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/rx_fifo_data_out_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_data_in_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_push_int} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_baudrate_div_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_config_reg_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/write_state\[2:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/rx_data_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/tx_data_i\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/uart_rx_i} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/uart_tx_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 78 79 80 81 )} 
wvSetPosition -win $_nWave2 {("G1" 81)}
wvSetPosition -win $_nWave2 {("G1" 81)}
wvSetPosition -win $_nWave2 {("G1" 81)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_soc_top/u_soc/m00_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_arready} \
{/tb_soc_top/u_soc/m00_arvalid} \
{/tb_soc_top/u_soc/m00_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m00_awready} \
{/tb_soc_top/u_soc/m00_awvalid} \
{/tb_soc_top/u_soc/m00_bready} \
{/tb_soc_top/u_soc/m00_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m00_bvalid} \
{/tb_soc_top/u_soc/m00_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_rready} \
{/tb_soc_top/u_soc/m00_rvalid} \
{/tb_soc_top/u_soc/m00_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m00_wready} \
{/tb_soc_top/u_soc/m00_wvalid} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_i} \
{/tb_soc_top/u_soc/u_i2c/scl_pad_o} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_i} \
{/tb_soc_top/u_soc/u_i2c/sda_pad_o} \
{/tb_soc_top/u_soc/u_i2c/wb_ack_o} \
{/tb_soc_top/u_soc/u_i2c/wb_adr_i\[2:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_clk_i} \
{/tb_soc_top/u_soc/u_i2c/wb_cyc_i} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_i\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_dat_o\[7:0\]} \
{/tb_soc_top/u_soc/u_i2c/wb_rst_i} \
{/tb_soc_top/u_soc/u_i2c/wb_stb_i} \
{/tb_soc_top/u_soc/u_i2c/wb_we_i} \
{/tb_soc_top/u_soc/m01_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_arready} \
{/tb_soc_top/u_soc/m01_arvalid} \
{/tb_soc_top/u_soc/m01_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m01_awready} \
{/tb_soc_top/u_soc/m01_awvalid} \
{/tb_soc_top/u_soc/m01_bready} \
{/tb_soc_top/u_soc/m01_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m01_bvalid} \
{/tb_soc_top/u_soc/m01_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_rready} \
{/tb_soc_top/u_soc/m01_rvalid} \
{/tb_soc_top/u_soc/m01_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m01_wready} \
{/tb_soc_top/u_soc/m01_wvalid} \
{/tb_soc_top/u_soc/u_aes/u_enc/done} \
{/tb_soc_top/u_soc/u_aes/u_enc/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/ld} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_enc/text_out\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/done} \
{/tb_soc_top/u_soc/u_aes/u_dec/kdone} \
{/tb_soc_top/u_soc/u_aes/u_dec/key\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/kld} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_in\[127:0\]} \
{/tb_soc_top/u_soc/u_aes/u_dec/text_out\[127:0\]} \
{/tb_soc_top/u_soc/m02_araddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_arready} \
{/tb_soc_top/u_soc/m02_arvalid} \
{/tb_soc_top/u_soc/m02_awaddr\[31:0\]} \
{/tb_soc_top/u_soc/m02_awready} \
{/tb_soc_top/u_soc/m02_awvalid} \
{/tb_soc_top/u_soc/m02_bready} \
{/tb_soc_top/u_soc/m02_bresp\[1:0\]} \
{/tb_soc_top/u_soc/m02_bvalid} \
{/tb_soc_top/u_soc/m02_rdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_rready} \
{/tb_soc_top/u_soc/m02_rvalid} \
{/tb_soc_top/u_soc/m02_wdata\[31:0\]} \
{/tb_soc_top/u_soc/m02_wready} \
{/tb_soc_top/u_soc/m02_wvalid} \
{/tb_soc_top/u_soc/u_uart/u_uart/baudrate_divisor_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/read_state\[3:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/rx_fifo_data_out_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_data_in_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/tx_fifo_push_int} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_baudrate_div_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_config_reg_int\[31:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/write_state\[2:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/rx_data_int\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/tx_data_i\[7:0\]} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/uart_rx_i} \
{/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst/uart_tx_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvCollapseGroup -win $_nWave2 "G2"
wvSelectSignal -win $_nWave2 {( "G1" 78 79 80 81 )} 
wvSetPosition -win $_nWave2 {("G1" 81)}
wvGetSignalClose -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomAll -win $_nWave2
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvZoom -win $_nWave2 54137530.426045 167677837.379421
wvZoom -win $_nWave2 54411341.455670 65728864.013724
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 56476516.391906 -snap {("G1" 29)}
wvSelectSignal -win $_nWave2 {( "G1" 29 )} 
wvSetCursor -win $_nWave2 56585688.635232 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 56676665.504669 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 56813130.808826 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 56494711.765794 -snap {("G1" 29)}
verdiWindowResize -win $_Verdi_1 "799" "26" "800" "836"
wvZoom -win $_nWave2 56319039.112656 58524523.720977
wvSetCursor -win $_nWave2 56572371.804147 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 56651848.726969 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 56736292.957468 -snap {("G1" 29)}
wvSetCursor -win $_nWave2 57312500.647930 -snap {("G1" 45)}
wvSetCursor -win $_nWave2 56477992.958295 -snap {("G1" 32)}
wvSetCursor -win $_nWave2 56552502.573441 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 56641914.111616 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 56736292.957467 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 56830671.803319 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57019429.495022 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57103873.725521 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57188317.956020 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57277729.494195 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57382042.955399 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57456552.570545 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57382042.955399 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 57461519.878222 -snap {("G1" 41)}
wvZoom -win $_nWave2 56396738.276818 59203620.582403
wvSetCursor -win $_nWave2 57428880.715433 -snap {("G1" 47)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 57912203.432862 -snap {("G1" 44)}
wvSetCursor -win $_nWave2 58041920.679372 -snap {("G1" 49)}
wvSetCursor -win $_nWave2 58035131.756115 -snap {("G1" 49)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 56403527.200067 -snap {("G1" 49)}
wvSetCursor -win $_nWave2 57480703.023477 -snap {("G1" 45)}
wvSetCursor -win $_nWave2 57021319.216435 -snap {("G1" 41)}
wvZoomOut -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 41 )} 
wvSetCursor -win $_nWave2 59105518.656269 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59186985.735351 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59286556.609784 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59372549.637703 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59838722.368003 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59585269.233083 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59648632.516813 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59739151.493570 -snap {("G1" 41)}
wvSetCursor -win $_nWave2 59829670.470327 -snap {("G1" 41)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 59893033.754057 -snap {("G1" 46)}
wvSetCursor -win $_nWave2 60015234.372679 -snap {("G1" 44)}
wvSetCursor -win $_nWave2 60132909.042464 -snap {("G1" 49)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvZoomAll -win $_nWave2
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 0.000000 61691735.000000
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
verdiDockWidgetRestore -dock windowDock_nWave_2
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_soc_top" -win $_nTrace1
uniFindSearchString -widget <Inst._Tree> -pattern "m02" -next
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcSetScope "tb_soc_top.u_soc" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
uniFindSearchString -widget MTB_SOURCE_TAB_1 -pattern "m02" -next
uniFindSearchString -widget MTB_SOURCE_TAB_1 -pattern "m02" -next
uniFindSearchString -widget MTB_SOURCE_TAB_1 -pattern "m02" -next
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {179 179 25 26 1 1}
srcSelect -signal "m02_awaddr" -line 179 -pos 1 -win $_nTrace1
srcSelect -signal "m02_awready" -line 184 -pos 1 -win $_nTrace1
srcSelect -signal "m02_awvalid" -line 184 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 20)}
wvSetPosition -win $_nWave2 {("G1" 21)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 24)}
wvSetPosition -win $_nWave2 {("G1" 25)}
wvSetPosition -win $_nWave2 {("G1" 26)}
wvSetPosition -win $_nWave2 {("G1" 27)}
wvSetPosition -win $_nWave2 {("G1" 28)}
wvSetPosition -win $_nWave2 {("G1" 29)}
wvSetPosition -win $_nWave2 {("G1" 30)}
wvSetPosition -win $_nWave2 {("G1" 29)}
wvSetPosition -win $_nWave2 {("G1" 30)}
wvSetPosition -win $_nWave2 {("G1" 31)}
wvSetPosition -win $_nWave2 {("G1" 32)}
wvSetPosition -win $_nWave2 {("G1" 33)}
wvSetPosition -win $_nWave2 {("G1" 34)}
wvSetPosition -win $_nWave2 {("G1" 35)}
wvSetPosition -win $_nWave2 {("G1" 36)}
wvSetPosition -win $_nWave2 {("G1" 37)}
wvSetPosition -win $_nWave2 {("G1" 38)}
wvSetPosition -win $_nWave2 {("G1" 39)}
wvSetPosition -win $_nWave2 {("G1" 40)}
wvSetPosition -win $_nWave2 {("G1" 41)}
wvSetPosition -win $_nWave2 {("G1" 42)}
wvSetPosition -win $_nWave2 {("G1" 43)}
wvSetPosition -win $_nWave2 {("G1" 44)}
wvSetPosition -win $_nWave2 {("G1" 45)}
wvSetPosition -win $_nWave2 {("G1" 46)}
wvSetPosition -win $_nWave2 {("G1" 47)}
wvSetPosition -win $_nWave2 {("G1" 48)}
wvSetPosition -win $_nWave2 {("G1" 49)}
wvSetPosition -win $_nWave2 {("G1" 50)}
wvSetPosition -win $_nWave2 {("G1" 51)}
wvSetPosition -win $_nWave2 {("G1" 52)}
wvSetPosition -win $_nWave2 {("G1" 53)}
wvSetPosition -win $_nWave2 {("G1" 54)}
wvSetPosition -win $_nWave2 {("G1" 55)}
wvSetPosition -win $_nWave2 {("G1" 56)}
wvSetPosition -win $_nWave2 {("G1" 57)}
wvSetPosition -win $_nWave2 {("G1" 58)}
wvSetPosition -win $_nWave2 {("G1" 59)}
wvSetPosition -win $_nWave2 {("G1" 60)}
wvSetPosition -win $_nWave2 {("G1" 61)}
wvSetPosition -win $_nWave2 {("G1" 62)}
wvSetPosition -win $_nWave2 {("G1" 63)}
wvSetPosition -win $_nWave2 {("G1" 64)}
wvSetPosition -win $_nWave2 {("G1" 65)}
wvSetPosition -win $_nWave2 {("G1" 66)}
wvSetPosition -win $_nWave2 {("G1" 67)}
wvSetPosition -win $_nWave2 {("G1" 68)}
wvSetPosition -win $_nWave2 {("G1" 69)}
wvSetPosition -win $_nWave2 {("G1" 70)}
wvSetPosition -win $_nWave2 {("G1" 71)}
wvSetPosition -win $_nWave2 {("G1" 72)}
wvSetPosition -win $_nWave2 {("G1" 73)}
wvSetPosition -win $_nWave2 {("G1" 74)}
wvSetPosition -win $_nWave2 {("G1" 75)}
wvSetPosition -win $_nWave2 {("G1" 76)}
wvSetPosition -win $_nWave2 {("G1" 77)}
wvSetPosition -win $_nWave2 {("G1" 78)}
wvSetPosition -win $_nWave2 {("G1" 79)}
wvSetPosition -win $_nWave2 {("G1" 80)}
wvSetPosition -win $_nWave2 {("G1" 81)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvAddSignal -win $_nWave2 "/tb_soc_top/u_soc/m02_awaddr\[31:0\]" \
           "/tb_soc_top/u_soc/m02_awready" "/tb_soc_top/u_soc/m02_awvalid"
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetCursor -win $_nWave2 51049495.000000 -snap {("G2" 1)}
verdiSetActWin -win $_nWave2
wvSetCursor -win $_nWave2 57202040.000000 -snap {("G2" 1)}
wvSetCursor -win $_nWave2 55539190.000000 -snap {("G2" 1)}
wvSetCursor -win $_nWave2 60195170.000000 -snap {("G2" 2)}
wvSetCursor -win $_nWave2 54707765.000000 -snap {("G3" 0)}
wvSetCursor -win $_nWave2 59696315.000000 -snap {("G2" 2)}
wvSetCursor -win $_nWave2 58199750.000000 -snap {("G2" 1)}
wvSetCursor -win $_nWave2 52047205.000000 -snap {("G3" 0)}
wvSetCursor -win $_nWave2 47723795.000000 -snap {("G2" 3)}
wvSetCursor -win $_nWave2 30430155.000000 -snap {("G2" 3)}
wvSetCursor -win $_nWave2 44398095.000000 -snap {("G3" 0)}
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 246957.920792 -snap {("G2" 1)}
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 344712.097772 -snap {("G2" 1)}
wvSetCursor -win $_nWave2 329277.227723 -snap {("G2" 2)}
wvSetCursor -win $_nWave2 236668.007426 -snap {("G2" 3)}
wvPrevView -win $_nWave2
wvScrollUp -win $_nWave2 18
wvSelectSignal -win $_nWave2 {( "G1" 56 )} 
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 60 )} 
wvZoom -win $_nWave2 56204330.000000 63853440.000000
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_aes/u_dec"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_i2c"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_uart"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc/u_uart/u_uart"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_soc_top/u_soc/u_uart/u_uart/uart_controller_inst"
wvGetSignalSetScope -win $_nWave2 "/tb_soc_top/u_soc"
wvScrollDown -win $_nWave2 7
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 78 )} 
wvSelectSignal -win $_nWave2 {( "G1" 79 )} 
wvSelectSignal -win $_nWave2 {( "G1" 80 )} 
wvScrollDown -win $_nWave2 1
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvZoom -win $_nWave2 0.000000 61691735.000000
wvZoom -win $_nWave2 0.000000 56560937.237624
wvZoom -win $_nWave2 0.000000 6552108.571091
srcHBSelect "tb_soc_top.u_soc.u_i2c" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_soc_top.u_soc.u_ic" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_uart" -win $_nTrace1
verdiSetActWin -win $_nWave2
wvSaveSignal -win $_nWave2 \
           "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/signal.rc"
wvRestoreSignal -win $_nWave2 \
           "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvGoToGroup -win $_nWave2 "G2"
wvGoToGroup -win $_nWave2 "G3"
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvZoomAll -win $_nWave2
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 67
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G2" 6 )} 
wvScrollUp -win $_nWave2 56
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 82 83 84 85 86 87 88 89 90 91 92 93 94 95 \
           96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 \
           114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 \
           131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 \
           148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 )} {( \
           "G2" 1 2 3 4 5 6 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 81)}
wvScrollUp -win $_nWave2 54
wvScrollDown -win $_nWave2 23
wvZoomAll -win $_nWave2
wvZoomAll -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
verdiDockWidgetRestore -dock windowDock_nWave_2
srcHBSelect "tb_soc_top.u_soc.u_aes" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_soc_top.u_soc.u_i2c" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_ic" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_uart" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_ic.w_1" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_ic.axi_interconnect_inst" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_ic" -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcSetScope "tb_soc_top" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcSetScope "tb_soc_top.u_soc" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_aes" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc.u_ic" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcSetScope "tb_soc_top" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcSetScope "tb_soc_top" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcSetScope "tb_soc_top" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcSetScope "tb_soc_top" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
srcSetScope "tb_soc_top.u_soc" -delim "." -win $_nTrace1
srcHBSelect "tb_soc_top.u_soc" -win $_nTrace1
