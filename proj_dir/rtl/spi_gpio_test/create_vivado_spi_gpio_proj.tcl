# create_vivado_spi_gpio_proj.tcl
# Tcl script to create a Vivado project for testing SPI and GPIO

set proj_name "spi_gpio_proj"
# Set project directory outside the SoC repo to keep it out of git tracking
set proj_dir "C:/Users/gunta/Documents/$proj_name"

# Get the directory where this script is located
set script_dir [file dirname [info script]]

# Create project
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

# --- Add SPI Files ---
set spi_inc_dir [file normalize "$script_dir/../axi-lite_spi-ipcore-develop/src/include"]
add_files [glob -nocomplain "$script_dir/../axi-lite_spi-ipcore-develop/src/rtl/*.v"]
add_files [glob -nocomplain "$script_dir/../axi-lite_spi-ipcore-develop/src/include/*.vh"]

# --- Add GPIO Files ---
# Note: The PULP GPIO repository relies on 'register_interface', 'common_cells', and 'axi' 
# packages which are missing from the current repository. We add the available SV files anyway.
add_files [glob -nocomplain "$script_dir/../gpio/src/*.sv"]

# Set include properties for all filesets
set inc_dirs [list $spi_inc_dir]
set_property include_dirs $inc_dirs [get_filesets sources_1]

# Set Verilog Header property for SPI macro files
set_property file_type "Verilog Header" [get_files "[file normalize "$script_dir/../axi-lite_spi-ipcore-develop/src/include/axi_spi_defines.vh"]"]
set_property file_type "Verilog Header" [get_files "[file normalize "$script_dir/../axi-lite_spi-ipcore-develop/src/include/axi_spi.vh"]"]

# Add Testbench to simulation fileset
add_files -fileset sim_1 [file normalize "$script_dir/tb_spi_gpio_vcs.sv"]
set_property include_dirs $inc_dirs [get_filesets sim_1]

# Set the top module for sources and simulation
# Note: We set the TB as top for simulation. For synth, you might choose axi_spi_top.
set_property top tb_spi_gpio_vcs [get_filesets sim_1]

puts "Vivado project $proj_name created successfully at $proj_dir!"
puts "WARNING: The GPIO module from PULP platform requires 'common_cells' and 'register_interface'."
puts "If elaboration fails on GPIO, you must fetch those submodules or remove GPIO from the project."

# Start GUI so the project opens automatically
start_gui
