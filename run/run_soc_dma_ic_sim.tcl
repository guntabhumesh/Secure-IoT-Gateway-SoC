# run_soc_dma_ic_sim.tcl
set proj_name "soc_dma_ic_proj"
set proj_dir "C:/Users/gunta/Documents/$proj_name"
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# Define include directories
set inc_dirs [list \
    "[file normalize "./rtl/inc"]" \
    "[file normalize "./rtl/dma/rtl/inc"]" \
    "[file normalize "./rtl/dma/rggen-verilog-rtl"]" \
    "[file normalize "./rtl/uart/src/include"]" \
    "[file normalize "./rtl/i2c"]" \
    "[file normalize "./rtl/spi/src/include"]" \
]

# AXI and Utils packages
add_files ./rtl/dma/bus_arch_sv_pkg/amba_axi_pkg.sv
add_files ./rtl/dma/rtl/inc/dma_utils_pkg.sv

# DMA components
add_files [glob -nocomplain ./rtl/dma/rggen-verilog-rtl/*.v]
add_files ./rtl/dma/rggen-verilog-rtl/rggen_rtl_macros.vh
add_files [glob -nocomplain ./rtl/dma/csr_out/*.v]
add_files ./rtl/dma/rtl/inc/dma_pkg.svh
add_files ./rtl/dma/rtl/dma_axi_if.sv
add_files ./rtl/dma/rtl/dma_axi_wrapper.sv
add_files ./rtl/wrappers/dma_axi_wrapper_v.sv
add_files ./rtl/dma/rtl/dma_fifo.sv
add_files ./rtl/dma/rtl/dma_fsm.sv
add_files ./rtl/dma/rtl/dma_func_wrapper.sv
add_files ./rtl/dma/rtl/dma_streamer.sv

# The actual SoC Top and Interconnect (and its dummies/bridges)
add_files ./rtl/interconnect/soc_top.v
add_files ./rtl/interconnect/axi_interconnect_wrap_3x12.v
add_files ./rtl/interconnect/axi_interconnect.v
add_files ./rtl/interconnect/arbiter.v
add_files ./rtl/interconnect/priority_encoder.v
add_files ./tb/axi_to_wb_bridge.v
add_files ./rtl/aes/rtl/axi_aes_slave.v

add_files ./tb/dummy_axi_slave.v

# Stub out I2C, UART and AES for simulation if we don't need them directly for this test
# Wait, soc_top instantiates i2c_master_top. We need to provide dummy or the real i2c_master_top.
add_files ./rtl/i2c/i2c_master_top.v
add_files ./rtl/i2c/i2c_master_byte_ctrl.v
add_files ./rtl/i2c/i2c_master_bit_ctrl.v
add_files ./rtl/i2c/i2c_master_defines.v

# soc_top instantiates axi_aes_slave which instantiates aes_cipher_top and aes_inv_cipher_top
add_files ./rtl/aes/rtl/aes_cipher_top.v
add_files ./rtl/aes/rtl/aes_key_expand_128.v
add_files ./rtl/aes/rtl/aes_sbox.v
add_files ./rtl/aes/rtl/aes_rcon.v
add_files ./rtl/aes/rtl/aes_inv_cipher_top.v
add_files ./rtl/aes/rtl/aes_inv_sbox.v

# soc_top instantiates axi_uart_slave which instantiates uart_top
add_files [glob -nocomplain "./rtl/uart/src/rtl/*.v"]
add_files "./rtl/uart/src/include/axi_uart_defines.vh"
add_files "./rtl/uart/src/include/axi_uart.vh"

# RAM
add_files ./rtl/interconnect/axi_ram.sv

# SPI
add_files [glob -nocomplain "./rtl/spi/src/rtl/*.v"]
add_files "./rtl/spi/src/include/axi_spi_defines.vh"
add_files "./rtl/spi/src/include/axi_spi.vh"

# GPIO
add_files [glob -nocomplain "./rtl/gpio/rtl/verilog/*.sv"]
add_files ./rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv

# Add the testbench
add_files -fileset sim_1 ./tb/tb_soc_dma_interconnect.sv

# Ensure headers are treated as Verilog Headers
set_property file_type "Verilog Header" [get_files "./rtl/dma/rggen-verilog-rtl/rggen_rtl_macros.vh"]
set_property file_type "Verilog Header" [get_files "./rtl/dma/rtl/inc/dma_pkg.svh"]
set_property file_type "Verilog Header" [get_files "./rtl/i2c/i2c_master_defines.v"]
set_property file_type "Verilog Header" [get_files "./rtl/uart/src/include/axi_uart_defines.vh"]
set_property file_type "Verilog Header" [get_files "./rtl/uart/src/include/axi_uart.vh"]
set_property file_type "Verilog Header" [get_files "./rtl/spi/src/include/axi_spi_defines.vh"]
set_property file_type "Verilog Header" [get_files "./rtl/spi/src/include/axi_spi.vh"]

# Include directories
set_property include_dirs $inc_dirs [get_filesets sources_1]
set_property include_dirs $inc_dirs [get_filesets sim_1]

# Set top module
set_property top tb_soc_dma_interconnect [get_filesets sim_1]

puts "Vivado project $proj_name created successfully!"
update_compile_order -fileset sources_1
launch_simulation
run all
