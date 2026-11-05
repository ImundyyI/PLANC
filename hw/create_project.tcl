# hw/create_project.tcl
set hw_dir   [file dirname [file normalize [info script]]]
set proj_dir [file join $hw_dir build vivado]

catch {close_project -quiet}

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
set_property file_type {VHDL} [get_files -filter {FILE_TYPE == VHDL}]
add_files -fileset constrs_1 [find_files [file join $hw_dir vivado] *.xdc]

set vtb [find_files [file join $hw_dir tests vivado_tb] *.vhd]
if {[llength $vtb] > 0} { add_files -fileset sim_1 $vtb }

# import IP. from hw/ip/ directory.
set ip_src [file join $hw_dir ip]
set xci_files [find_files $ip_src *.xci]
puts "IP search dir : $ip_src"
puts "XCI found     : $xci_files"

# if there is any files to begin with.
if {[llength $xci_files] > 0} {
    # import them as ip.
    foreach xci $xci_files {
        import_ip $xci
    }
    # quietly upgrade them incase they were stale or for an older version of Vivado for whatevr reason.
    catch {upgrade_ip -quiet [get_ips]}
    generate_target all [get_ips]
    foreach ip [get_ips] {
        catch {create_ip_run [get_files -quiet "[get_property NAME $ip].xci"]}
    }
} else {
    puts "WARNING: no .xci files under $ip_src"
}

# Block design (skipped until bd.tcl has been exported)
set bd_script [file join $hw_dir bd bd.tcl]
if {[file exists $bd_script] && [file size $bd_script] > 0} {
    source $bd_script
    set bd_file [get_files *.bd]
    generate_target all $bd_file
    make_wrapper -files $bd_file -top -import -fileset sources_1
    set_property top [file rootname [file tail $bd_file]]_wrapper [current_fileset]
} else {
    puts "No block design script yet, skipping."
}
update_compile_order -fileset sources_1