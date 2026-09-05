// run_soc.f  –  VCS filelist for Secure IoT Gateway SoC testbench
//
// ── Compile + simulate (run from proj_dir/run/) ───────────────────────────
//
// No waveforms (fastest):
//   vcs -sverilog -full64 -f run_soc.f -o simv_soc \
//       2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
//
// With Verdi FSDB:
//   vcs -sverilog -full64 -f run_soc.f -o simv_soc +define+FSDB \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
//
// With VCD:
//   vcs -sverilog -full64 -f run_soc.f -o simv_soc +define+VCD \
//       2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
//
// Open in Verdi:
//   verdi -f run_soc.f -ssf tb_soc_top.fsdb &
// ──────────────────────────────────────────────────────────────────────────

+incdir+../rtl/i2c-master
+incdir+../rtl/aes_core-master/rtl/verilog

// AXI Interconnect
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x11.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// I2C master (Wishbone)
../rtl/i2c-master/i2c_master_top.v
../rtl/i2c-master/i2c_master_byte_ctrl.v
../rtl/i2c-master/i2c_master_bit_ctrl.v

// AES core RTL (primitives before top-levels)
../rtl/aes_core-master/rtl/verilog/timescale.v
../rtl/aes_core-master/rtl/verilog/aes_rcon.v
../rtl/aes_core-master/rtl/verilog/aes_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_inv_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_key_expand_128.v
../rtl/aes_core-master/rtl/verilog/aes_cipher_top.v
../rtl/aes_core-master/rtl/verilog/aes_inv_cipher_top.v

// SoC RTL
../rtl/axi_aes_slave.v
../rtl/soc_top.v

// TB support
../tb/axi_to_wb_bridge.v
../tb/dummy_axi_slave.v

// Testbench top
../tb/tb_soc_top.v
