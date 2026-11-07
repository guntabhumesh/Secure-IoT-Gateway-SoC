set proj_name "soc_test_sim_2"
set proj_dir "C:/Users/gunta/Documents/$proj_name"

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

set inc_dirs [list \
    "[file normalize "./rtl/inc"]" \
    "[file normalize "./rtl/dma/rtl/inc"]" \
    "[file normalize "./rtl/dma/rggen-verilog-rtl"]" \
    "[file normalize "./rtl/uart/src/include"]" \
    "[file normalize "./rtl/i2c"]" \
    "[file normalize "./rtl/spi/src/include"]" \
]

# Add source files
add_files ./rtl/interconnect/soc_top.v
add_files ./rtl/interconnect/axi_interconnect_wrap_3x12.v
add_files ./rtl/interconnect/axi_interconnect.v
add_files ./rtl/interconnect/arbiter.v
add_files ./rtl/interconnect/priority_encoder.v
add_files ./rtl/interconnect/axi_ram.sv
add_files ./tb/axi_to_wb_bridge.v
add_files ./tb/dummy_axi_slave.v
add_files ./tb/tb_soc_all_ips.sv

# DMA
add_files ./rtl/dma/bus_arch_sv_pkg/amba_axi_pkg.sv
add_files ./rtl/dma/rtl/inc/dma_utils_pkg.sv
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

# AES
add_files [glob -nocomplain ./rtl/aes/rtl/*.v]

# I2C
add_files [glob -nocomplain ./rtl/i2c/*.v]

# UART
add_files [glob -nocomplain ./rtl/uart/src/rtl/*.v]

# SPI
add_files [glob -nocomplain ./rtl/spi/src/rtl/*.v]

# GPIO
add_files [glob -nocomplain ./rtl/gpio/rtl/verilog/*.sv]
add_files ./rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv

set_property include_dirs $inc_dirs [current_fileset]
set_property top tb_soc_all_ips [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation

close_project
