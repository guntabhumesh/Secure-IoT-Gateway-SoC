set proj_name "spi_gpio_proj_2"
set proj_dir "C:/Users/gunta/Documents/$proj_name"
set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize "$script_dir/../.."]

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

set spi_inc_dir [file normalize "$root_dir/rtl/spi/src/include"]
set spi_files [glob -nocomplain "$root_dir/rtl/spi/src/rtl/*.v"]
if {[llength $spi_files] > 0} { add_files $spi_files }

set spi_vh [glob -nocomplain "$root_dir/rtl/spi/src/include/*.vh"]
if {[llength $spi_vh] > 0} { add_files $spi_vh }

set gpio_files [glob -nocomplain "$root_dir/rtl/gpio/rtl/verilog/*.sv"]
if {[llength $gpio_files] > 0} { add_files $gpio_files }
add_files "$root_dir/rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv"

set inc_dirs [list $spi_inc_dir]
set_property include_dirs $inc_dirs [get_filesets sources_1]

set_property file_type "Verilog Header" [get_files "[file normalize "$root_dir/rtl/spi/src/include/axi_spi_defines.vh"]"]
set_property file_type "Verilog Header" [get_files "[file normalize "$root_dir/rtl/spi/src/include/axi_spi.vh"]"]

add_files -fileset sim_1 [file normalize "$root_dir/tb/tb_spi_gpio_vcs.sv"]
set_property include_dirs $inc_dirs [get_filesets sim_1]
set_property top tb_spi_gpio_vcs [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]

launch_simulation
run all
