# fix_vivado.tcl
set script_dir [file dirname [file normalize [info script]]]
set proj_name "secure_iot_soc"
set proj_dir "run/vivado_proj"
set xpr_file "${script_dir}/${proj_dir}/${proj_name}.xpr"

open_project $xpr_file

# Add all the necessary include directories back (including the ones for VeeR, UART, DMA, and rggen)
set all_includes [list \
    "${script_dir}/rtl/Cores-VeeR-EL2/design/include" \
    "${script_dir}/rtl/interconnect" \
    "${script_dir}/rtl/i2c-master" \
    "${script_dir}/rtl/uartfiles/src/include" \
    "${script_dir}/rtl/axi_dma/rtl/inc" \
    "${script_dir}/rtl/axi_dma/rggen-verilog-rtl" \
]

# Set for synthesis and simulation filesets
set_property include_dirs $all_includes [get_filesets sources_1]
set_property include_dirs $all_includes [get_filesets sim_1]

# Make sure the rggen macro file itself is added and set as a global include just in case
add_files -norecurse "${script_dir}/rtl/axi_dma/rggen-verilog-rtl/rggen_rtl_macros.vh"
set_property is_global_include true [get_files "${script_dir}/rtl/axi_dma/rggen-verilog-rtl/rggen_rtl_macros.vh"]

# Update compile order to ensure Vivado sees everything
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Successfully restored missing include directories and macros!"
close_project
