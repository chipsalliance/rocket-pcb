# Trigger on the FIRST read (pattern 0, addr=0, phase_w=0).
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

set p_pattern [P $ila dbg_pattern]
set p_phase   [P $ila dbg_phase_w]
set p_addr    [P $ila dbg_req_addr]
set p_we      [P $ila dbg_req_we]
set p_vld     [P $ila dbg_req_valid]

# pattern==0, phase_w==0 (read), req_addr==0, req_we==0, req_valid==1
set_property TRIGGER_COMPARE_VALUE eq2'h0      $p_pattern
set_property TRIGGER_COMPARE_VALUE eq1'b0      $p_phase
set_property TRIGGER_COMPARE_VALUE eq24'h000000 $p_addr
set_property TRIGGER_COMPARE_VALUE eq1'b0      $p_we
set_property TRIGGER_COMPARE_VALUE eq1'b1      $p_vld

set_property CONTROL.TRIGGER_POSITION 4096 $ila

run_hw_ila $ila
puts "==== armed; waiting for FIRST read addr=0 in pattern 0..."
if {[catch {wait_on_hw_ila -timeout 60 $ila} err]} { puts "==== $err" }
upload_hw_ila_data $ila
write_hw_ila_data -force ila_capture.csv -csv_file [current_hw_ila_data]
puts "==== wrote"
close_hw_target; close_hw_manager; quit
