# create_vivado_spi_gpio_proj.tcl
# Tcl script to create a Vivado project for testing SPI and GPIO

set proj_name "spi_gpio_proj"
# Set project directory outside the SoC repo to keep it out of git tracking
set proj_dir "C:/Users/gunta/Documents/$proj_name"

# Project root (two levels up from scripts/build)
set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize "$script_dir/../.."]

# Create project
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# --- Add SPI Files ---
set spi_inc_dir [file normalize "$root_dir/rtl/spi/src/include"]
add_files [glob -nocomplain "$root_dir/rtl/spi/src/rtl/*.v"]
add_files [glob -nocomplain "$root_dir/rtl/spi/src/include/*.vh"]

# --- Add GPIO Files ---
add_files [glob -nocomplain "$root_dir/rtl/gpio/rtl/verilog/*.sv"]
add_files "$root_dir/rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv"

# Set include properties for all filesets
set inc_dirs [list $spi_inc_dir]
set_property include_dirs $inc_dirs [get_filesets sources_1]

# Set Verilog Header property for SPI macro files
set_property file_type "Verilog Header" [get_files "[file normalize "$root_dir/rtl/spi/src/include/axi_spi_defines.vh"]"]
set_property file_type "Verilog Header" [get_files "[file normalize "$root_dir/rtl/spi/src/include/axi_spi.vh"]"]

# Add Testbench to simulation fileset
add_files -fileset sim_1 [file normalize "$root_dir/tb/tb_spi_gpio_vcs.sv"]
set_property include_dirs $inc_dirs [get_filesets sim_1]

# Set the top module for sources and simulation
# Note: We set the TB as top for simulation. For synth, you might choose axi_spi_top.
set_property top tb_spi_gpio_vcs [get_filesets sim_1]

puts "Vivado project $proj_name created successfully at $proj_dir!"
