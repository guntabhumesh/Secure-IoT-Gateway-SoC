simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/rtl/aes_core-master/sim/rtl_sim/run/simv" \
           -args
debImport "-dbdir" \
          "/home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/rtl/aes_core-master/sim/rtl_sim/run/simv.daidir"
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/rtl/aes_core-master/sim/rtl_sim/run/dump3.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debLoadSimResult \
           /home/student/Documents/1602-23-735-311/secure_iot_gateway_SoC/proj_dir/rtl/aes_core-master/sim/rtl_sim/run/dump3.fsdb
verdiSetActWin -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/test/u0/u0"
debExit
