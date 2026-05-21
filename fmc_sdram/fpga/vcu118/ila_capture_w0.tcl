# Capture the FIRST write of pattern 0 (addr 0) and its surroundings.
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
proc P {ila pat} { return [lindex [get_hw_probes -of_objects $ila *$pat*] 0] }

# Trigger when ctrl drives ACTIVE command in pattern 0 — easier than
# matching exact req_addr bus state.
set p_cmd     [P $ila dbg_cmd]
set p_pattern [P $ila dbg_pattern]
set p_phase   [P $ila dbg_phase_w]

# cmd 4'b0011 = 3 = ACTIVE, pattern == 0, phase_write == 1
set_property TRIGGER_COMPARE_VALUE eq4'h3   $p_cmd
set_property TRIGGER_COMPARE_VALUE eq2'h0   $p_pattern
set_property TRIGGER_COMPARE_VALUE eq1'b1   $p_phase

set_property CONTROL.TRIGGER_POSITION 4096 $ila

run_hw_ila $ila
puts "==== armed; waiting for first ACT in pattern 0 write..."
if {[catch {wait_on_hw_ila -timeout 60 $ila} err]} { puts "==== $err" }
upload_hw_ila_data $ila
write_hw_ila_data -force ila_capture.csv -csv_file [current_hw_ila_data]
puts "==== wrote ila_capture.csv"
close_hw_target; close_hw_manager; quit
