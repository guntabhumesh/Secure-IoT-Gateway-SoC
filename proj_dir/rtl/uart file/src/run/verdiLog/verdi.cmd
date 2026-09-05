simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/1602-23-735-311/axi-lite_uart-ipcore-develop/src/run/simv" \
           -args
debImport "-dbdir" \
          "/home/student/Documents/1602-23-735-311/axi-lite_uart-ipcore-develop/src/run/simv.daidir"
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/axi-lite_uart-ipcore-develop/src/run/uart_sim.fsdb
wvCreateWindow
verdiWindowResize -win $_Verdi_1 "340" "92" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/axi-lite_uart-ipcore-develop/src/run/uart_sim.fsdb
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_axi_uart"
verdiSetActWin -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_axi_uart/dut/axi_internal_fifo_rx_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst"
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/busy} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_data_i\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_ready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/busy} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_data_i\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_ready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvGetSignalClose -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_axi_uart"
wvGetSignalSetScope -win $_nWave2 "/tb_axi_uart/dut"
wvGetSignalSetScope -win $_nWave2 "/tb_axi_uart/dut/uart_controller_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst"
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/busy} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_data_i\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_ready} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx_data\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx_valid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 6 7 8 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/busy} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_data_i\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_transmitter_inst/tx_ready} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/counter_int\[31:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx_data\[7:0\]} \
{/tb_axi_uart/dut/uart_controller_inst/uart_receiver_inst/rx_valid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 6 7 8 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvGetSignalClose -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvSetCursor -win $_nWave2 225392.446342 -snap {("G2" 0)}
wvSetCursor -win $_nWave2 295292.635398 -snap {("G1" 6)}
wvZoom -win $_nWave2 171293.721706 570979.072354
wvSetCursor -win $_nWave2 260645.735579 -snap {("G1" 2)}
wvSetCursor -win $_nWave2 257647.345852 -snap {("G1" 2)}
wvSetCursor -win $_nWave2 358992.918635 -snap {("G1" 5)}
wvPrevView -win $_nWave2
wvZoom -win $_nWave2 294054.222262 665190.619293
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvZoomAll -win $_nWave2
wvSetCursor -win $_nWave2 10000077.014218 -snap {("G1" 8)}
wvSetCursor -win $_nWave2 492734.004739 -snap {("G1" 3)}
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 153474.526066 2051712.085308
wvZoom -win $_nWave2 180463.685676 676764.342950
wvSetCursor -win $_nWave2 1254213.685893 -snap {("G1" 2)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSetRadix -win $_nWave2 -format UDec
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSetRadix -win $_nWave2 -format UDec
wvSetCursor -win $_nWave2 1784620.312505 -snap {("G1" 6)}
wvZoomAll -win $_nWave2
debExit
