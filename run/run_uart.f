+incdir+rtl/dma/rtl/inc
+incdir+rtl/dma/rggen-verilog-rtl
+incdir+rtl/uart/src/include
+incdir+rtl/spi/src/include
+incdir+rtl/i2c
+incdir+rtl/aes/rtl
+incdir+rtl/general_timer/lib/rtl

# SoC Top & Interconnect
rtl/interconnect/soc_top.v
rtl/interconnect/axi_interconnect_wrap_3x12.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v
rtl/interconnect/axi_ram.sv
tb/axi_to_wb_bridge.v
tb/dummy_axi_slave.v

# I2C
rtl/i2c/i2c_master_top.v
rtl/i2c/i2c_master_byte_ctrl.v
rtl/i2c/i2c_master_bit_ctrl.v

# AES
rtl/aes/rtl/axi_aes_slave.v
rtl/aes/rtl/aes_cipher_top.v
rtl/aes/rtl/aes_inv_cipher_top.v
rtl/aes/rtl/aes_sbox.v
rtl/aes/rtl/aes_inv_sbox.v
rtl/aes/rtl/aes_key_expand_128.v
rtl/aes/rtl/aes_rcon.v

# UART
rtl/uart/src/include/axi_uart.vh
rtl/uart/src/include/axi_uart_defines.vh
rtl/uart/src/rtl/axi_uart_top.v
rtl/uart/src/rtl/axi_uart_slave.v
rtl/uart/src/rtl/axi_internal_fifo.v
rtl/uart/src/rtl/uart_controller.v
rtl/uart/src/rtl/uart_transmitter.v
rtl/uart/src/rtl/uart_receiver.v
rtl/uart/src/rtl/uart_parity_bit_compute.v

# SPI
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

# GPIO
rtl/gpio/rtl/verilog/gpio_axi.sv
rtl/gpio/rtl/verilog/gpio_regs.sv
rtl/gpio/rtl/verilog/gpio_bit.sv
rtl/gpio/rtl/verilog/gpio_wb.sv
rtl/gpio/rtl/verilog/gpio_apb.sv
rtl/gpio/rtl/verilog/gpio_wrapper.sv
rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv

# General Timer
rtl/general_timer/rtl/verilog/timer_core.sv
rtl/general_timer/rtl/verilog/timer_regs.sv
rtl/general_timer/rtl/verilog/timer_axi.sv

# DMA
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

# Testbench
tb/soc_uart_tb.v

-top soc_uart_tb
