// run_soc.f  –  VCS filelist for Secure IoT Gateway SoC testbench
//
// Address map:
//   m00  0x0000_0000  I2C (Wishbone)
//   m01  0x0100_0000  AES encrypt/decrypt
//   m02  0x0200_0000  UART (AXI4-Lite)
//   m03..m10          dummy slaves
//
// ── Compile + simulate (run from proj_dir/run/) ───────────────────────────
//
// No waveforms (fastest):
//   vcs -sverilog -full64 -f run_soc.f -o simv_soc \
//       2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
//
// With Verdi FSDB:
//   vcs -sverilog -full64 -f run_soc.f -o simv_soc \
//       -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//       2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
//
// Open in Verdi:
//   verdi -f run_soc.f -ssf dump_soc_uart.fsdb &
//
// NOTE: ../rtl/uartfiles is a symlink to ../rtl/uart file
//       (created to avoid spaces in path which VCS filelists do not support)
// ──────────────────────────────────────────────────────────────────────────

+incdir+../rtl/i2c-master
+incdir+../rtl/aes_core-master/rtl/verilog
+incdir+../rtl/uartfiles/src/include

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

// UART RTL  (via uartfiles symlink → rtl/uart file)
../rtl/uartfiles/src/rtl/uart_parity_bit_compute.v
../rtl/uartfiles/src/rtl/uart_controller.v
../rtl/uartfiles/src/rtl/uart_transmitter.v
../rtl/uartfiles/src/rtl/uart_receiver.v
../rtl/uartfiles/src/rtl/axi_internal_fifo.v
../rtl/uartfiles/src/rtl/axi_uart_top.v

// SoC RTL
../rtl/axi_aes_slave.v
../rtl/axi_uart_slave.v
../rtl/soc_top.v

// TB support
../tb/axi_to_wb_bridge.v
../tb/dummy_axi_slave.v

// Testbench top
../tb/tb_soc_top.v
