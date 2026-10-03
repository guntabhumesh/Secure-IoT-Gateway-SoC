verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/simv" \
           -args
debImport "-dbdir" \
          "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/simv.daidir"
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/dump_uart_rw.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/run/dump_uart_rw.fsdb
verdiSetActWin -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_uart_rw_veer"
wvGetSignalSetScope -win $_nWave2 "/tb_uart_rw_veer/dut/u_veer/mem/iccm"
wvGetSignalSetScope -win $_nWave2 "/tb_uart_rw_veer/dut/u_veer/mem/iccm/iccm"
wvGetSignalOpen -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_uart_rw_veer/dut/u_veer/mem/iccm/iccm/iccm_rw_addr\[15:1\]} \
{/tb_uart_rw_veer/dut/u_veer/mem/iccm/iccm/iccm_wr_data\[77:0\]} \
{/tb_uart_rw_veer/dut/u_veer/mem/iccm/iccm/iccm_wr_size\[2:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
