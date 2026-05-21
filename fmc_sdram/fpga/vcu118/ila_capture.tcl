# Re-program top.bit, arm ILA on bist_state == DONE (6) by default,
# capture, and print summary. Supports tclargs for trigger override:
#
#   vivado -mode batch -source ila_capture.tcl -tclargs mismatch
#   vivado -mode batch -source ila_capture.tcl -tclargs done
#   vivado -mode batch -source ila_capture.tcl -tclargs pattern N    (0..3)
#
# Default: done. With auto_start_dly~10s and full-space sweep ~13s per
# pass, total wait is ~25s for the first DONE.

set trig_mode "done"
set trig_arg  ""
if {[llength $argv] >= 1} { set trig_mode [lindex $argv 0] }
if {[llength $argv] >= 2} { set trig_arg  [lindex $argv 1] }

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

set ila [lindex [get_hw_ilas] 0]
puts "==== ILA: $ila"
if {$ila eq ""} {
    puts "ERROR: no ILA visible"
    close_hw_target; close_hw_manager; quit
}

# Locate probes by name suffix.
proc P {ila pat} { return [lindex [get_hw_probes -of_objects $ila *$pat*] 0] }

set p_state    [P $ila dbg_bist_state]
set p_mismatch [P $ila dbg_mismatch]
set p_pattern  [P $ila dbg_pattern]
set p_phase    [P $ila dbg_phase_w]
set p_done     [P $ila dbg_bist_done]

switch -exact -- $trig_mode {
    mismatch {
        puts "==== trigger mode: dbg_mismatch == 1 (first failing read)"
        set_property TRIGGER_COMPARE_VALUE eq1'b1 $p_mismatch
        set_property CONTROL.TRIGGER_POSITION 4096 $ila
    }
    pattern {
        if {$trig_arg eq ""} { set trig_arg 2 }
        puts "==== trigger mode: dbg_pattern == $trig_arg (during pattern $trig_arg)"
        set_property TRIGGER_COMPARE_VALUE "eq2'h$trig_arg" $p_pattern
        set_property CONTROL.TRIGGER_POSITION 16384 $ila
    }
    alive {
        puts "==== trigger mode: dbg_bist_state == 4 (R_WAIT) — proves BIST is alive"
        set_property TRIGGER_COMPARE_VALUE eq3'h4 $p_state
        set_property CONTROL.TRIGGER_POSITION 1024 $ila
    }
    done {
        puts "==== trigger mode: dbg_bist_state == 6 (S_DONE) — after all 4 patterns"
        set_property TRIGGER_COMPARE_VALUE eq3'h6 $p_state
        set_property CONTROL.TRIGGER_POSITION 30000 $ila
    }
    default {
        puts "==== trigger mode: pattern==3 && state==5 (NEXT_PAT after pat 3)"
        set_property TRIGGER_COMPARE_VALUE eq2'h3 $p_pattern
        set_property TRIGGER_COMPARE_VALUE eq3'h5 $p_state
        set_property CONTROL.TRIGGER_POSITION 30000 $ila
    }
}

run_hw_ila $ila
puts "==== armed; waiting up to 60 s..."
if {[catch {wait_on_hw_ila -timeout 180 $ila} err]} {
    puts "==== wait_on_hw_ila: $err"
}

upload_hw_ila_data $ila
write_hw_ila_data -force ila_capture.csv -csv_file [current_hw_ila_data]
puts "==== wrote ila_capture.csv"

close_hw_target
close_hw_manager
quit
