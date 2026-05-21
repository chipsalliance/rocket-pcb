# Capture the moment pattern 3 issues a WRITE to addr 0x0000B9.
# Multi-probe AND trigger: req_addr==0xB9 && req_we==1 && pattern==3 &&
# req_valid==1.

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

proc P {ila pat} { return [lindex [get_hw_probes -of_objects $ila *$pat*] 0] }

# Default compare for everything is "don't care" (X). We override only the
# probes that need to match.
set p_addr  [P $ila dbg_req_addr]
set p_we    [P $ila dbg_req_we]
set p_pat   [P $ila dbg_pattern]
set p_vld   [P $ila dbg_req_valid]

set_property TRIGGER_COMPARE_VALUE eq24'h0000B9 $p_addr
set_property TRIGGER_COMPARE_VALUE eq1'b1       $p_we
set_property TRIGGER_COMPARE_VALUE eq2'b11      $p_pat
set_property TRIGGER_COMPARE_VALUE eq1'b1       $p_vld

set_property CONTROL.TRIGGER_POSITION 16384 $ila

run_hw_ila $ila
puts "==== armed; waiting for write(addr=0xB9, pat=3)..."
if {[catch {wait_on_hw_ila -timeout 60 $ila} err]} { puts "==== $err" }

upload_hw_ila_data $ila
write_hw_ila_data -force ila_capture.csv -csv_file [current_hw_ila_data]
puts "==== wrote ila_capture.csv"

close_hw_target; close_hw_manager; quit
