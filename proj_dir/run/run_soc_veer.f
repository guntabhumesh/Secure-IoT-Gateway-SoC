// =============================================================================
// run_soc_veer.f  -  VCS filelist for Secure IoT Gateway SoC + VeeR EL2
//
// Run from:  proj_dir/run/
//
// Quick compile+sim:
//   vcs -sverilog -full64 -f run_soc_veer.f -o simv_soc_veer \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//          ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       2>&1 | tee compile_soc_veer.log
//   ./simv_soc_veer | tee sim_soc_veer.log
//
// Open waveform:
//   verdi -f run_soc_veer.f -ssf dump_soc_veer.fsdb &
// =============================================================================

// ── 1. Generated VeeR config headers (from veer.config -snapshot=default) ──
//    common_defines.vh  : `defines for bus type, tag widths, memory sizes
//    el2_pdef.vh        : parameter struct typedef (el2_param_t)
//    el2_param.vh       : parameter block instantiated in el2_veer_wrapper
+incdir+./snapshots/default

// ── 2. VeeR EL2 design include directory (SVH files) ────────────────────────
+incdir+../rtl/Cores-VeeR-EL2/design/include

// ── 3. VeeR EL2 design source files  (order matches Cores-VeeR-EL2/design/flist)

// Assertion macros (must come before packages that use them)
../rtl/Cores-VeeR-EL2/design/lib/el2_assert.sv

// Package / defines (must come first)
../rtl/Cores-VeeR-EL2/design/include/el2_def.sv
../rtl/Cores-VeeR-EL2/design/el2_mubi_pkg.sv
../rtl/Cores-VeeR-EL2/design/el2_lockstep_pkg.sv

// Library primitives
../rtl/Cores-VeeR-EL2/design/lib/el2_lib.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_mem_if.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_regfile_if.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_prim_buf.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_prim_generic_buf.sv
-v ../rtl/Cores-VeeR-EL2/design/lib/beh_lib.sv
-v ../rtl/Cores-VeeR-EL2/design/lib/mem_lib.sv
../rtl/Cores-VeeR-EL2/design/lib/ahb_to_axi4.sv
../rtl/Cores-VeeR-EL2/design/lib/axi4_to_ahb.sv

// IFU (instruction fetch unit)
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_aln_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_compress_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ifc_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_bp_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ic_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_mem_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_iccm_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu.sv

// DEC (decode)
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_decode_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_gpr_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_ib_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_pmp_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_tlu_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_trigger.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec.sv

// EXU (execute unit)
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_alu_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_mul_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_div_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu.sv

// LSU (load-store unit)
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_clkdomain.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_addrcheck.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_lsc_ctl.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_stbuf.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_buffer.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_intf.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_ecc.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_mem.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_ctl.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_trigger.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu.sv

// DBG / DMI (debug)
../rtl/Cores-VeeR-EL2/design/dbg/el2_dbg.sv
../rtl/Cores-VeeR-EL2/design/dmi/dmi_mux.v
../rtl/Cores-VeeR-EL2/design/dmi/dmi_wrapper.v
../rtl/Cores-VeeR-EL2/design/dmi/dmi_jtag_to_core_sync.v
../rtl/Cores-VeeR-EL2/design/dmi/rvjtag_tap.v

// PIC / PMP / DMA / MEM
../rtl/Cores-VeeR-EL2/design/el2_pic_ctrl.sv
../rtl/Cores-VeeR-EL2/design/el2_pmp.sv
../rtl/Cores-VeeR-EL2/design/el2_dma_ctrl.sv
../rtl/Cores-VeeR-EL2/design/el2_mem.sv

// Core top  and  lockstep wrapper
../rtl/Cores-VeeR-EL2/design/el2_veer.sv
../rtl/Cores-VeeR-EL2/design/el2_veer_lockstep.sv

// VeeR top wrapper  (includes el2_param.vh via `include)
../rtl/Cores-VeeR-EL2/design/el2_veer_wrapper.sv

// ── 4. AXI Interconnect ──────────────────────────────────────────────────────
+incdir+../rtl/interconnect
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x11.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// ── 5. Peripheral IP includes ────────────────────────────────────────────────
+incdir+../rtl/i2c-master
+incdir+../rtl/aes_core-master/rtl/verilog
+incdir+../rtl/uartfiles/src/include

// ── 6. I2C master (Wishbone) ─────────────────────────────────────────────────
../rtl/i2c-master/i2c_master_top.v
../rtl/i2c-master/i2c_master_byte_ctrl.v
../rtl/i2c-master/i2c_master_bit_ctrl.v

// ── 7. AES core ──────────────────────────────────────────────────────────────
../rtl/aes_core-master/rtl/verilog/timescale.v
../rtl/aes_core-master/rtl/verilog/aes_rcon.v
../rtl/aes_core-master/rtl/verilog/aes_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_inv_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_key_expand_128.v
../rtl/aes_core-master/rtl/verilog/aes_cipher_top.v
../rtl/aes_core-master/rtl/verilog/aes_inv_cipher_top.v

// ── 8. UART  (via symlink uartfiles → "uart file") ───────────────────────────
../rtl/uartfiles/src/rtl/uart_parity_bit_compute.v
../rtl/uartfiles/src/rtl/uart_controller.v
../rtl/uartfiles/src/rtl/uart_transmitter.v
../rtl/uartfiles/src/rtl/uart_receiver.v
../rtl/uartfiles/src/rtl/axi_internal_fifo.v
../rtl/uartfiles/src/rtl/axi_uart_top.v

// ── 9. SoC peripheral slaves ─────────────────────────────────────────────────
../rtl/axi_aes_slave.v
../rtl/axi_uart_slave.v

// ── 10. Original SoC top (instantiated inside soc_top_with_veer) ─────────────
../rtl/soc_top.v

// ── 11. Integrated SoC + VeeR top  (SystemVerilog — needs import el2_pkg::*) ─
../rtl/soc_top_with_veer.sv

// ── 12. TB support files ─────────────────────────────────────────────────────
../tb/axi_to_wb_bridge.v
../tb/dummy_axi_slave.v

// ── 13. Testbench top ────────────────────────────────────────────────────────
// tb_soc_veer_top: loads firmware into ICCM, monitors VeeR trace + UART output
../tb/tb_soc_veer_top.v
