# =============================================================================
# run_soc_vips.f
#
# VCS filelist for compiling the Secure-IoT-Gateway-SoC with VeeR EL2
# and the Active UVM VIP Testbench (tb_soc_vips.sv).
# =============================================================================

+incdir+snapshots/default
+incdir+rtl/core/snapshots/default
+incdir+rtl/core/design/include
+incdir+rtl/core/design/lib

# ── VeeR EL2 Core RTL ──────────────────────────────────────────────────
rtl/core/design/lib/el2_assert.sv
rtl/core/design/include/el2_def.sv
rtl/core/design/el2_mubi_pkg.sv
rtl/core/design/el2_veer_wrapper.sv
rtl/core/design/el2_lockstep_pkg.sv
rtl/core/design/el2_veer_lockstep.sv
rtl/core/design/el2_mem.sv
rtl/core/design/el2_pic_ctrl.sv
rtl/core/design/el2_veer.sv
rtl/core/design/el2_dma_ctrl.sv
rtl/core/design/el2_pmp.sv

# VeeR IFU
rtl/core/design/ifu/el2_ifu_aln_ctl.sv
rtl/core/design/ifu/el2_ifu_compress_ctl.sv
rtl/core/design/ifu/el2_ifu_ifc_ctl.sv
rtl/core/design/ifu/el2_ifu_bp_ctl.sv
rtl/core/design/ifu/el2_ifu_ic_mem.sv
rtl/core/design/ifu/el2_ifu_mem_ctl.sv
rtl/core/design/ifu/el2_ifu_iccm_mem.sv
rtl/core/design/ifu/el2_ifu.sv

# VeeR DEC
rtl/core/design/dec/el2_dec_decode_ctl.sv
rtl/core/design/dec/el2_dec_gpr_ctl.sv
rtl/core/design/dec/el2_dec_ib_ctl.sv
rtl/core/design/dec/el2_dec_pmp_ctl.sv
rtl/core/design/dec/el2_dec_tlu_ctl.sv
rtl/core/design/dec/el2_dec_trigger.sv
rtl/core/design/dec/el2_dec.sv

# VeeR EXU
rtl/core/design/exu/el2_exu_alu_ctl.sv
rtl/core/design/exu/el2_exu_mul_ctl.sv
rtl/core/design/exu/el2_exu_div_ctl.sv
rtl/core/design/exu/el2_exu.sv

# VeeR LSU
rtl/core/design/lsu/el2_lsu.sv
rtl/core/design/lsu/el2_lsu_clkdomain.sv
rtl/core/design/lsu/el2_lsu_addrcheck.sv
rtl/core/design/lsu/el2_lsu_lsc_ctl.sv
rtl/core/design/lsu/el2_lsu_stbuf.sv
rtl/core/design/lsu/el2_lsu_bus_buffer.sv
rtl/core/design/lsu/el2_lsu_bus_intf.sv
rtl/core/design/lsu/el2_lsu_ecc.sv
rtl/core/design/lsu/el2_lsu_dccm_mem.sv
rtl/core/design/lsu/el2_lsu_dccm_ctl.sv
rtl/core/design/lsu/el2_lsu_trigger.sv

# VeeR Debug / DMI
rtl/core/design/dbg/el2_dbg.sv
rtl/core/design/dmi/dmi_mux.v
rtl/core/design/dmi/dmi_wrapper.v
rtl/core/design/dmi/dmi_jtag_to_core_sync.v
rtl/core/design/dmi/rvjtag_tap.v

# VeeR Lib
rtl/core/design/lib/el2_lib.sv
rtl/core/design/lib/el2_mem_if.sv
rtl/core/design/lib/el2_prim_generic_buf.sv
rtl/core/design/lib/el2_prim_buf.sv
rtl/core/design/lib/beh_lib.sv
rtl/core/design/lib/mem_lib.sv
rtl/core/design/lib/ahb_to_axi4.sv
rtl/core/design/lib/axi4_to_ahb.sv

# ── SoC Top with VeeR ───────────────────────────────────────────────────
rtl/top/soc_top_with_veer.v

# ── AXI 64-to-32 adapter ────────────────────────────────────────────────
rtl/top/axi_64to32_adapter.sv

# ── SoC subsystem (soc_top.v) ──────────────────────────────────────────
rtl/interconnect/soc_top.v

# ── AXI Interconnect 3x12 ──────────────────────────────────────────────
rtl/interconnect/axi_interconnect_wrap_3x12.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v

# ── AXI RAM ────────────────────────────────────────────────────────────
rtl/interconnect/axi_ram.sv

# ── AXI-to-Wishbone bridge (for I2C) ───────────────────────────────────
tb/axi_to_wb_bridge.v

# ── Dummy AXI slave ────────────────────────────────────────────────────
tb/dummy_axi_slave.v

# ── I2C master ─────────────────────────────────────────────────────────
+incdir+rtl/i2c
rtl/i2c/i2c_master_top.v
rtl/i2c/i2c_master_byte_ctrl.v
rtl/i2c/i2c_master_bit_ctrl.v

# ── AES ────────────────────────────────────────────────────────────────
+incdir+rtl/aes/rtl
rtl/aes/rtl/axi_aes_slave.v
rtl/aes/rtl/aes_cipher_top.v
rtl/aes/rtl/aes_inv_cipher_top.v
rtl/aes/rtl/aes_sbox.v
rtl/aes/rtl/aes_inv_sbox.v
rtl/aes/rtl/aes_key_expand_128.v
rtl/aes/rtl/aes_rcon.v

# ── UART ──────────────────────────────────────────────────────────────
+incdir+rtl/uart/src/include
rtl/uart/src/include/axi_uart.vh
rtl/uart/src/include/axi_uart_defines.vh
rtl/uart/src/rtl/axi_uart_top.v
rtl/uart/src/rtl/axi_uart_slave.v
rtl/uart/src/rtl/axi_internal_fifo.v
rtl/uart/src/rtl/uart_controller.v
rtl/uart/src/rtl/uart_transmitter.v
rtl/uart/src/rtl/uart_receiver.v
rtl/uart/src/rtl/uart_parity_bit_compute.v

# ── SPI ────────────────────────────────────────────────────────────────
+incdir+rtl/spi/src/include
rtl/spi/src/include/axi_spi.vh
rtl/spi/src/include/axi_spi_defines.vh
rtl/spi/src/rtl/axi_spi_top.v
rtl/spi/src/rtl/axi_spi_ctrl.v
rtl/spi/src/rtl/spi_ctrl.v
rtl/spi/src/rtl/spi_clk_gen.v
rtl/spi/src/rtl/spi_exch_byte.v
rtl/spi/src/rtl/spi_fifo.v
rtl/spi/src/rtl/spi_valid_logic.v
rtl/spi/src/rtl/ratio_clk.v

# ── GPIO ──────────────────────────────────────────────────────────────
+incdir+rtl/general_timer/lib/rtl
rtl/gpio/rtl/verilog/gpio_axi.sv
rtl/gpio/rtl/verilog/gpio_regs.sv
rtl/gpio/rtl/verilog/gpio_bit.sv
rtl/gpio/rtl/verilog/gpio_wb.sv
rtl/gpio/rtl/verilog/gpio_apb.sv
rtl/gpio/rtl/verilog/gpio_wrapper.sv
rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv

# ── General Timer ─────────────────────────────────────────────────────
rtl/general_timer/rtl/verilog/timer_core.sv
rtl/general_timer/rtl/verilog/timer_regs.sv
rtl/general_timer/rtl/verilog/timer_axi.sv

# ── DMA ───────────────────────────────────────────────────────────────
+incdir+rtl/dma/rtl/inc
+incdir+rtl/dma/rggen-verilog-rtl
rtl/dma/bus_arch_sv_pkg/amba_axi_pkg.sv
rtl/dma/rtl/inc/dma_pkg.svh
rtl/dma/rtl/inc/dma_utils_pkg.sv
rtl/dma/rtl/dma_axi_if.sv
rtl/dma/rtl/dma_axi_wrapper.sv
rtl/dma/rtl/dma_fifo.sv
rtl/dma/rtl/dma_fsm.sv
rtl/dma/rtl/dma_func_wrapper.sv
rtl/dma/rtl/dma_streamer.sv
rtl/dma/csr_out/csr_dma.v
rtl/dma/rggen-verilog-rtl/rggen_rtl_macros.vh
rtl/dma/rggen-verilog-rtl/rggen_adapter_common.v
rtl/dma/rggen-verilog-rtl/rggen_address_decoder.v
rtl/dma/rggen-verilog-rtl/rggen_axi4lite_adapter.v
rtl/dma/rggen-verilog-rtl/rggen_axi4lite_bridge.v
rtl/dma/rggen-verilog-rtl/rggen_axi4lite_skid_buffer.v
rtl/dma/rggen-verilog-rtl/rggen_bit_field.v
rtl/dma/rggen-verilog-rtl/rggen_bit_field_w01trg.v
rtl/dma/rggen-verilog-rtl/rggen_default_register.v
rtl/dma/rggen-verilog-rtl/rggen_external_register.v
rtl/dma/rggen-verilog-rtl/rggen_indirect_register.v
rtl/dma/rggen-verilog-rtl/rggen_mux.v
rtl/dma/rggen-verilog-rtl/rggen_or_reducer.v
rtl/dma/rggen-verilog-rtl/rggen_register_common.v
rtl/wrappers/dma_axi_wrapper_v.sv

# ── VIP Virtual Interfaces ─────────────────────────────────────────────
tb/uart_uvm_tb/uart_if.sv
tb/spi_uvm_tb/spi_if.sv
tb/i2c_uvm_tb/i2c_if.sv
tb/gpio_uvm_tb/gpio_if.sv

# ── VIP Package & Components ───────────────────────────────────────────
+incdir+tb/vips
tb/vips/soc_vip_pkg.sv

# ── Integrated VIP Testbench ───────────────────────────────────────────
tb/tb_soc_vips.sv

# ── VCS Top ────────────────────────────────────────────────────────────
-top tb_soc_vips
