// run_integrated.f  –  VCS filelist for the integrated AXI interconnect TB
//
// Topology:
//   s00 (stimulus) → axi_interconnect_wrap_2x11
//     m00 → axi_to_wb_bridge  → i2c_master_top
//     m01 → axi_to_aes_bridge → aes_cipher_top + aes_inv_cipher_top
//     m02–m10 → dummy_axi_slave
//
// ──────────────────────────────────────────────────────────────────────────
// Compile + simulate commands (run from proj_dir/run/):
//
// With Verdi/FSDB waveform dump:
//   vcs -sverilog -full64 \
//       -f run_integrated.f \
//       -o simv_integrated \
//       +define+FSDB \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       2>&1 | tee compile_integrated.log \
//       && ./simv_integrated | tee sim_integrated.log
//
// With VCD waveform dump:
//   vcs -sverilog -full64 \
//       -f run_integrated.f \
//       -o simv_integrated \
//       +define+VCD \
//       2>&1 | tee compile_integrated.log \
//       && ./simv_integrated | tee sim_integrated.log
//
// Without waveform dump (fastest):
//   vcs -sverilog -full64 \
//       -f run_integrated.f \
//       -o simv_integrated \
//       2>&1 | tee compile_integrated.log \
//       && ./simv_integrated | tee sim_integrated.log
//
// View FSDB in Verdi:
//   verdi -f run_integrated.f -ssf tb_axi_interconnect_2x11_aes.fsdb &
//
// View VCD in DVE:
//   dve -vpd tb_axi_interconnect_2x11_aes.vcd &
// ──────────────────────────────────────────────────────────────────────────

// ── Include paths ──────────────────────────────────────────────────────────
+incdir+../rtl/i2c-master
+incdir+../rtl/aes_core-master/rtl/verilog

// ── RTL: AXI Interconnect ──────────────────────────────────────────────────
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x11.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// ── RTL: I2C Master (Wishbone) ─────────────────────────────────────────────
../rtl/i2c-master/i2c_master_top.v
../rtl/i2c-master/i2c_master_byte_ctrl.v
../rtl/i2c-master/i2c_master_bit_ctrl.v

// ── RTL: AES Core ─────────────────────────────────────────────────────────
// Timescale header (included by AES RTL via `include "timescale.v")
../rtl/aes_core-master/rtl/verilog/timescale.v

// Sub-modules first
../rtl/aes_core-master/rtl/verilog/aes_rcon.v
../rtl/aes_core-master/rtl/verilog/aes_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_inv_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_key_expand_128.v

// Cipher top levels
../rtl/aes_core-master/rtl/verilog/aes_cipher_top.v
../rtl/aes_core-master/rtl/verilog/aes_inv_cipher_top.v

// ── TB support modules ──────────────────────────────────────────────────────
../tb/axi_to_wb_bridge.v
../tb/axi_to_aes_bridge.v
../tb/dummy_axi_slave.v

// ── Testbench top ───────────────────────────────────────────────────────────
../tb/tb_axi_interconnect_2x11_aes.v
