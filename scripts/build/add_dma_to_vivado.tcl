# add_dma_to_vivado.tcl
# Automatically sets up the correct paths regardless of where Vivado is launched from

# Project root (two levels up from scripts/build)
set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize "$script_dir/../.."]

# The project file path
set proj_name "secure_iot_soc"
set proj_dir "C:/Users/gunta/Documents/$proj_name"
set xpr_file "${proj_dir}/${proj_name}.xpr"

# Open the project
open_project $xpr_file

# Add the new 3x12 interconnect
add_files -norecurse "${root_dir}/rtl/interconnect/axi_interconnect_wrap_3x12.v"

# Add packages (must be added as SystemVerilog)
set sv_packages [list \
    "${root_dir}/rtl/dma/bus_arch_sv_pkg/amba_axi_pkg.sv" \
    "${root_dir}/rtl/dma/rtl/inc/dma_pkg.svh" \
    "${root_dir}/rtl/dma/rtl/inc/dma_utils_pkg.sv" \
    "${root_dir}/rtl/dma/csr_out/csr_dma_ral_pkg.sv" \
]
add_files -norecurse $sv_packages
set_property file_type SystemVerilog [get_files $sv_packages]

# Set include directories for the DMA package
set_property include_dirs "${root_dir}/rtl/dma/rtl/inc" [current_fileset]

# Add DMA core files
set dma_core [list \
    "${root_dir}/rtl/dma/rtl/dma_axi_if.sv" \
    "${root_dir}/rtl/dma/rtl/dma_axi_wrapper.sv" \
    "${root_dir}/rtl/wrappers/dma_axi_wrapper_v.sv" \
    "${root_dir}/rtl/dma/rtl/dma_fifo.sv" \
    "${root_dir}/rtl/dma/rtl/dma_fsm.sv" \
    "${root_dir}/rtl/dma/rtl/dma_func_wrapper.sv" \
    "${root_dir}/rtl/dma/rtl/dma_streamer.sv" \
]
add_files -norecurse $dma_core
set_property file_type SystemVerilog [get_files $dma_core]

# Add DMA CSR files
set dma_csr [list \
    "${root_dir}/rtl/dma/csr_out/csr_dma.v" \
    "${root_dir}/rtl/dma/csr_out/csr_dma.sv" \
]
add_files -norecurse $dma_csr

# Add rggen dependencies (for the CSRs)
add_files -norecurse [glob ${root_dir}/rtl/dma/rggen-verilog-rtl/*.v]

# Let Vivado figure out the compile order
update_compile_order -fileset sources_1

puts "Successfully added DMA and new interconnect files to the Vivado project!"
close_project
