# hw/create_project.tcl
set hw_dir   [file dirname [file normalize [info script]]]
set proj_dir [file join $hw_dir build vivado]

proc find_files {dir pattern} {
    set found [glob -nocomplain -directory $dir -types f $pattern]
    foreach sub [glob -nocomplain -directory $dir -types d *] {
        set found [concat $found [find_files $sub $pattern]]
    }
    return $found
}

create_project anc $proj_dir -part xck26-sfvc784-2LV-c -force
set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]

add_files [find_files [file join $hw_dir modules] *.vhd]
set_property file_type {VHDL 2008} [get_files -filter {FILE_TYPE == VHDL}]
add_files -fileset constrs_1 [find_files [file join $hw_dir vivado] *.xdc]

set vtb [find_files [file join $hw_dir tests vivado_tb] *.vhd]
if {[llength $vtb] > 0} { add_files -fileset sim_1 $vtb }

source [file join $hw_dir bd bd.tcl]
set bd_file [get_files *.bd]
generate_target all $bd_file
make_wrapper -files $bd_file -top -import -fileset sources_1
set_property top [file rootname [file tail $bd_file]]_wrapper [current_fileset]
update_compile_order -fileset sources_1