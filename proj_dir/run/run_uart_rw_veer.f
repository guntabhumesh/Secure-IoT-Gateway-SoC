// =============================================================================
// run_uart_rw_veer.f  -  VCS filelist for UART R/W verification
//
// DUT      : soc_top_with_veer  (VeeR EL2 + AXI interconnect + I2C/AES/UART)
// Testbench: tb_uart_rw_veer
// Firmware : ../scripts/uart_rw_iccm_words.hex  (uart_rw.c linked at 0xEE000000)
//
// Run from:  proj_dir/run/
//
// Quick compile + simulate:
//   vcs -sverilog -full64 -f run_uart_rw_veer.f -o simv_uart_rw \
//       +define+RV_BUILD_AXI4                    \
//       +define+RV_BUILD_AXI_NATIVE              \
//       +define+ICCM_HIER_LOAD                   \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//          ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       2>&1 | tee compile_uart_rw.log
//   ./simv_uart_rw +hex_file+../scripts/uart_rw.hex 2>&1 | tee sim_uart_rw.log
//
// Open waveform:
//   verdi -f run_uart_rw_veer.f -ssf dump_uart_rw.fsdb &
//
// Notes:
//   +define+ICCM_HIER_LOAD  : enables direct $readmemh into ICCM RAM arrays
//                             inside el2_ifu_iccm_mem via hierarchical path.
//                             Remove if your ICCM is not a plain reg array.
//   +define+ICCM_HEX_FILE=\"../scripts/uart_rw.hex\"
//                           : alternative — pre-load via RTL `initial block
//                             inside el2_ifu_iccm_mem (requires RTL support).
//   snapshots/default       : generated VeeR config headers (see veer.config).
//                             Must be regenerated if VeeR parameters change.
// =============================================================================

// ── 1. Generated VeeR config headers ────────────────────────────────────────
//    common_defines.vh  : bus-type, tag-width, ICCM/DCCM size defines
//    el2_pdef.vh        : el2_param_t struct typedef
//    el2_param.vh       : parameter block (included by el2_veer_wrapper)
+incdir+./snapshots/default

// ── 2. VeeR EL2 design include directory (SVH / VH files) ───────────────────
+incdir+../rtl/Cores-VeeR-EL2/design/include

// ── 3. VeeR EL2 design source files  (order matches design/flist) ───────────

// Assertion macros (must come before packages)
../rtl/Cores-VeeR-EL2/design/lib/el2_assert.sv

// Packages / defines (must come first)
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

// IFU (instruction fetch unit) — includes ICCM memory
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_aln_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_compress_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ifc_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_bp_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ic_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_mem_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_iccm_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu.sv

// DEC (decode unit)
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

// DBG / DMI (debug interface)
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

// Core top and lockstep wrapper
../rtl/Cores-VeeR-EL2/design/el2_veer.sv
../rtl/Cores-VeeR-EL2/design/el2_veer_lockstep.sv

// VeeR top-level wrapper  (includes el2_param.vh via `include directive)
../rtl/Cores-VeeR-EL2/design/el2_veer_wrapper.sv

// ── 4. AXI Interconnect ──────────────────────────────────────────────────────
+incdir+../rtl/interconnect
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x11.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

// ── 5. Peripheral IP includes ────────────────────────────────────────────────
+incdir+../rtl/i2c-master
+incdir+../rtl/aes_core-master/rtl
+incdir+../rtl/uartfiles/src/include

// ── 6. I2C master (Wishbone interface) ──────────────────────────────────────
../rtl/i2c-master/i2c_master_top.v
../rtl/i2c-master/i2c_master_byte_ctrl.v
../rtl/i2c-master/i2c_master_bit_ctrl.v

// ── 7. AES core ──────────────────────────────────────────────────────────────
../rtl/aes_core-master/rtl/timescale.v
../rtl/aes_core-master/rtl/aes_rcon.v
../rtl/aes_core-master/rtl/aes_sbox.v
../rtl/aes_core-master/rtl/aes_inv_sbox.v
../rtl/aes_core-master/rtl/aes_key_expand_128.v
../rtl/aes_core-master/rtl/aes_cipher_top.v
../rtl/aes_core-master/rtl/aes_inv_cipher_top.v

// ── 8. UART  (via symlink: uartfiles → "uart file") ─────────────────────────
../rtl/uartfiles/src/rtl/uart_parity_bit_compute.v
../rtl/uartfiles/src/rtl/uart_controller.v
../rtl/uartfiles/src/rtl/uart_transmitter.v
../rtl/uartfiles/src/rtl/uart_receiver.v
../rtl/uartfiles/src/rtl/axi_internal_fifo.v
../rtl/uartfiles/src/rtl/axi_uart_top.v

// ── 9. SoC peripheral slaves (AXI wrappers) ─────────────────────────────────
../rtl/aes_core-master/rtl/axi_aes_slave.v
../rtl/uartfiles/src/rtl/axi_uart_slave.v

// ── 10. SoC interconnect top (instantiates I2C/AES/UART slaves) ─────────────
../rtl/interconnect/soc_top.v

// ── 11. Integrated SoC + VeeR top-level ─────────────────────────────────────
../rtl/top/soc_top_with_veer.v

// ── 12. TB support files ─────────────────────────────────────────────────────
../tb/axi_to_wb_bridge.v
../tb/dummy_axi_slave.v

// ── 13. Testbench top ────────────────────────────────────────────────────────
//    tb_uart_rw_veer: UART loopback test with uart_rw.hex
../tb/tb_uart_rw_veer.v
