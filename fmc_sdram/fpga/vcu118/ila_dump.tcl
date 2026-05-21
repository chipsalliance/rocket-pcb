# Connect, list all probes by NAME so we know how the dbg_* signals are
# represented inside hw_ila_1. Used once to debug ila_capture.tcl.

open_hw_manager
connect_hw_server
current_hw_target [lindex [get_hw_targets] 0]
open_hw_target

set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
set_property PROGRAM.FILE {top.bit} $dev
program_hw_devices $dev
set_property PROBES.FILE     {debug_nets.ltx} $dev
set_property FULL_PROBES.FILE {debug_nets.ltx} $dev
refresh_hw_device $dev

set ilas [get_hw_ilas]
puts "==== ILA cores: $ilas"

foreach ila $ilas {
    puts "---- $ila"
    foreach p [get_hw_probes -of_objects $ila] {
        set nm [get_property NAME.SHORT $p]
        set fn [get_property NAME $p]
        puts [format "  %-30s -> %s" $nm $fn]
    }
}

close_hw_target
close_hw_manager
quit
