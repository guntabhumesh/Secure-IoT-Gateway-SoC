# run_soc_dma_ic_sim.tcl
set proj_name "soc_dma_ic_proj"
set proj_dir "C:/Users/gunta/Documents/$proj_name"
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# Define include directories
set inc_dirs [list \
    "[file normalize "./proj_dir/rtl/inc"]" \
    "[file normalize "./proj_dir/rtl/axi_dma/rtl/inc"]" \
    "[file normalize "./proj_dir/rtl/axi_dma/rggen-verilog-rtl"]" \
    "[file normalize "./proj_dir/rtl/uart_file/src/include"]" \
    "[file normalize "./proj_dir/rtl/i2c-master"]" \
]

# AXI and Utils packages
add_files ./proj_dir/rtl/axi_dma/bus_arch_sv_pkg/amba_axi_pkg.sv
add_files ./proj_dir/rtl/axi_dma/rtl/inc/dma_utils_pkg.sv

# DMA components
add_files [glob -nocomplain ./proj_dir/rtl/axi_dma/rggen-verilog-rtl/*.v]
add_files ./proj_dir/rtl/axi_dma/rggen-verilog-rtl/rggen_rtl_macros.vh
add_files [glob -nocomplain ./proj_dir/rtl/axi_dma/csr_out/*.v]
add_files ./proj_dir/rtl/axi_dma/rtl/inc/dma_pkg.svh
add_files ./proj_dir/rtl/axi_dma/rtl/dma_axi_if.sv
add_files ./proj_dir/rtl/axi_dma/rtl/dma_axi_wrapper.sv
add_files ./proj_dir/rtl/wrappers/dma_axi_wrapper_v.sv
add_files ./proj_dir/rtl/axi_dma/rtl/dma_fifo.sv
add_files ./proj_dir/rtl/axi_dma/rtl/dma_fsm.sv
add_files ./proj_dir/rtl/axi_dma/rtl/dma_func_wrapper.sv
add_files ./proj_dir/rtl/axi_dma/rtl/dma_streamer.sv

# The actual SoC Top and Interconnect (and its dummies/bridges)
add_files ./proj_dir/rtl/interconnect/soc_top.v
add_files ./proj_dir/rtl/interconnect/axi_interconnect_wrap_3x12.v
add_files ./proj_dir/rtl/interconnect/axi_interconnect.v
add_files ./proj_dir/rtl/interconnect/arbiter.v
add_files ./proj_dir/rtl/interconnect/priority_encoder.v
add_files ./proj_dir/tb/axi_to_wb_bridge.v
add_files ./proj_dir/rtl/aes_core-master/rtl/axi_aes_slave.v

add_files ./proj_dir/tb/dummy_axi_slave.v

# Stub out I2C, UART and AES for simulation if we don't need them directly for this test
# Wait, soc_top instantiates i2c_master_top. We need to provide dummy or the real i2c_master_top.
add_files ./proj_dir/rtl/i2c-master/i2c_master_top.v
add_files ./proj_dir/rtl/i2c-master/i2c_master_byte_ctrl.v
add_files ./proj_dir/rtl/i2c-master/i2c_master_bit_ctrl.v
add_files ./proj_dir/rtl/i2c-master/i2c_master_defines.v

# soc_top instantiates axi_aes_slave which instantiates aes_cipher_top and aes_inv_cipher_top
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_cipher_top.v
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_key_expand_128.v
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_sbox.v
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_rcon.v
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_inv_cipher_top.v
add_files ./proj_dir/rtl/aes_core-master/rtl/aes_inv_sbox.v

# soc_top instantiates axi_uart_slave which instantiates uart_top
add_files [glob -nocomplain "./proj_dir/rtl/uart_file/src/rtl/*.v"]
add_files "./proj_dir/rtl/uart_file/src/include/axi_uart_defines.vh"
add_files "./proj_dir/rtl/uart_file/src/include/axi_uart.vh"

# Add the testbench
add_files -fileset sim_1 ./proj_dir/tb/tb_soc_dma_interconnect.sv

# Ensure headers are treated as Verilog Headers
set_property file_type "Verilog Header" [get_files "./proj_dir/rtl/axi_dma/rggen-verilog-rtl/rggen_rtl_macros.vh"]
set_property file_type "Verilog Header" [get_files "./proj_dir/rtl/axi_dma/rtl/inc/dma_pkg.svh"]
set_property file_type "Verilog Header" [get_files "./proj_dir/rtl/i2c-master/i2c_master_defines.v"]
set_property file_type "Verilog Header" [get_files "./proj_dir/rtl/uart_file/src/include/axi_uart_defines.vh"]
set_property file_type "Verilog Header" [get_files "./proj_dir/rtl/uart_file/src/include/axi_uart.vh"]

# Include directories
set_property include_dirs $inc_dirs [get_filesets sources_1]
set_property include_dirs $inc_dirs [get_filesets sim_1]

# Set top module
set_property top tb_soc_dma_interconnect [get_filesets sim_1]

puts "Vivado project $proj_name created successfully!"
update_compile_order -fileset sources_1
launch_simulation
run all
