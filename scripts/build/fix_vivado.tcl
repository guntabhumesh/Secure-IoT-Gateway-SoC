# fix_vivado.tcl
set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize "$script_dir/../.."]
set proj_name "secure_iot_soc"
set proj_dir "C:/Users/gunta/Documents/$proj_name"
set xpr_file "${proj_dir}/${proj_name}.xpr"

open_project $xpr_file

# Add all the necessary include directories back (including the ones for VeeR, UART, DMA, and rggen)
set all_includes [list \
    "${root_dir}/rtl/Cores-VeeR-EL2/design/include" \
    "${root_dir}/rtl/interconnect" \
    "${root_dir}/rtl/i2c" \
    "${root_dir}/rtl/uart/src/include" \
    "${root_dir}/rtl/dma/rtl/inc" \
    "${root_dir}/rtl/dma/rggen-verilog-rtl" \
]

# Set for synthesis and simulation filesets
set_property include_dirs $all_includes [get_filesets sources_1]
set_property include_dirs $all_includes [get_filesets sim_1]

# Make sure the rggen macro file itself is added and set as a global include just in case
add_files -norecurse "${root_dir}/rtl/dma/rggen-verilog-rtl/rggen_rtl_macros.vh"
set_property is_global_include true [get_files "${root_dir}/rtl/dma/rggen-verilog-rtl/rggen_rtl_macros.vh"]

# Update compile order to ensure Vivado sees everything
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Successfully restored missing include directories and macros!"
close_project
