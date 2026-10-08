# add_dma_to_vivado.tcl
# Automatically sets up the correct paths regardless of where Vivado is launched from

# Get the directory where this script is located (proj_dir)
set script_dir [file dirname [file normalize [info script]]]

# The project file path
set proj_name "secure_iot_soc"
set proj_dir "run/vivado_proj"
set xpr_file "${script_dir}/${proj_dir}/${proj_name}.xpr"

# Open the project
open_project $xpr_file

# Add the new 3x12 interconnect
add_files -norecurse "${script_dir}/rtl/interconnect/axi_interconnect_wrap_3x12.v"

# Add packages (must be added as SystemVerilog)
set sv_packages [list \
    "${script_dir}/rtl/axi_dma/bus_arch_sv_pkg/amba_axi_pkg.sv" \
    "${script_dir}/rtl/axi_dma/rtl/inc/dma_pkg.svh" \
    "${script_dir}/rtl/axi_dma/rtl/inc/dma_utils_pkg.sv" \
    "${script_dir}/rtl/axi_dma/csr_out/csr_dma_ral_pkg.sv" \
]
add_files -norecurse $sv_packages
set_property file_type SystemVerilog [get_files $sv_packages]

# Set include directories for the DMA package
set_property include_dirs "${script_dir}/rtl/axi_dma/rtl/inc" [current_fileset]

# Add DMA core files
set dma_core [list \
    "${script_dir}/rtl/axi_dma/rtl/dma_axi_if.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_axi_wrapper.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_axi_wrapper_v.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_fifo.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_fsm.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_func_wrapper.sv" \
    "${script_dir}/rtl/axi_dma/rtl/dma_streamer.sv" \
]
add_files -norecurse $dma_core
set_property file_type SystemVerilog [get_files $dma_core]

# Add DMA CSR files
set dma_csr [list \
    "${script_dir}/rtl/axi_dma/csr_out/csr_dma.v" \
    "${script_dir}/rtl/axi_dma/csr_out/csr_dma.sv" \
]
add_files -norecurse $dma_csr

# Add rggen dependencies (for the CSRs)
add_files -norecurse [glob ${script_dir}/rtl/axi_dma/rggen-verilog-rtl/*.v]

# Let Vivado figure out the compile order
update_compile_order -fileset sources_1

puts "Successfully added DMA and new interconnect files to the Vivado project!"
close_project
