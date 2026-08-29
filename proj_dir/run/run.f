// run.f  –  VCS file list for axi_interconnect_wrap_2x11 testbench
//
// Compile command (run from proj_dir/run/):
//
//   vcs -sverilog -full64 \
//       -f run.f \
//       -o simv \
//       +define+FSDB \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       && ./simv
//
// Or without FSDB (VCD only):
//   vcs -sverilog -full64 -f run.f -o simv && ./simv

// ── Include paths ──────────────────────────────────────────────────────────
+incdir+../rtl/i2c-master

// ── RTL: AXI Interconnect ──────────────────────────────────────────────────
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x11.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// ── RTL: I2C Master (Wishbone) ─────────────────────────────────────────────
../rtl/i2c-master/i2c_master_top.v
../rtl/i2c-master/i2c_master_byte_ctrl.v
../rtl/i2c-master/i2c_master_bit_ctrl.v

// ── TB support modules ──────────────────────────────────────────────────────
../tb/axi_to_wb_bridge.v
../tb/dummy_axi_slave.v

// ── Testbench top ───────────────────────────────────────────────────────────
../tb/tb_axi_interconnect_2x11.v
