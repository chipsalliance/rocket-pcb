proc get_file_list {fname encode eofile} {
    if { [file readable $fname]} {
        set fileid [open $fname "r"]
        fconfigure $fileid -encoding $encode -translation $eofile
        set contents [read $fileid]
        close $fileid
        return $contents
    }
}

# Automatically inserts ILA instances
# By J. McCluskey, https://github.com/cambridgehackers/fpgamake/blob/master/tcl/batch_insert_ila.tcl
proc batch_insert_ila { depth } {
    set dbgs [get_nets -hierarchical -filter {MARK_DEBUG}]
    if {[llength $dbgs] == 0} {
        puts "No nets have the MARK_DEBUG attribute.  No ILA cores created"
        return
    } else {
        set net_list {}
        foreach net $dbgs {
            if { [get_property -quiet MARK_DEBUG_VALID $net] != "true" } {
                set pin_list [get_pins -of_objects [get_nets -segments $net]]
                set not_vio_net 1
                foreach pin $pin_list {
                    if { [get_property IS_DEBUG_CORE [get_cells -of_object $pin]] == 1 } {
                        set not_vio_net 0
                        break
                    }
                }
                if { $not_vio_net == 1 } { lappend net_list $net }
            } else {
                lappend net_list $net
            }
        }
    }
    if {[llength $net_list] == 0} {
        puts "All nets with MARK_DEBUG are already connected to VIO cores.  No ILA cores created"
        return
    }
    foreach d $net_list {
        set name [regsub {\[[[:digit:]]+\]$} $d {}]
        set index [regsub {^.*\[([[:digit:]]+)\]$} $d {\1}]
        if {[string is integer -strict $index]} {
            if {![info exists max($name)]} {
                set max($name) $index
                set min($name) $index
            } elseif {$index > $max($name)} {
                set max($name) $index
            } elseif {$index < $min($name)} {
                set min($name) $index
            }
        } else {
            set max($name) -1
        }
        if {![info exists clocks($name)]} {
            set clk_name [get_property -quiet MARK_DEBUG_CLOCK $d]
            if {  [llength $clk_name] == 0 } {
                set driver_pin [get_pins -filter {DIRECTION == "OUT" && IS_LEAF == TRUE } -of_objects [ get_nets -segments $d ]]
                set driver_cell [get_cells -of_objects $driver_pin]
                if { [get_property IS_SEQUENTIAL $driver_cell] == 1 } {
                    set timing_arc [get_timing_arcs -to $driver_pin]
                    set cell_clock_pin [get_pins -filter {IS_CLOCK} [get_property FROM_PIN $timing_arc]]
                    if { [llength $cell_clock_pin] > 1 } {
                        puts "Error: in batch_insert_ila. Found more than 1 clock pin in driver cell $driver_cell with timing arc $timing_arc for net $d"
                        continue
                    }
                } else {
                    set paths [get_timing_paths -quiet -through $driver_pin ]
                    if { [llength $paths] > 0 } {
                        set cell_clock_pin [get_pins [get_property STARTPOINT_PIN [lindex $paths 0]]]
                    } else {
                        puts "Critical Warning: from batch_insert_ila.tcl    Can't trace any clock domain on driver of net $d"
                        continue
                    }
                }
                set clk_net [get_nets -segments -of_objects $cell_clock_pin]
            } else {
                set clk_net [get_nets -segments $clk_name]
                if { [llength $clk_net] == 0 } { puts "MARK_DEBUG_CLOCK attribute on net $d does not match any known net.  Please fix."; continue }
            }
            set clocks($name) [get_nets -of_objects [get_pins -filter {DIRECTION == "OUT" && IS_LEAF == TRUE } -of_objects $clk_net]]
            if {![info exists clock_list($clocks($name))]} {
                puts "New clock found is $clocks($name)"
                set clock_list($clocks($name)) [list $name]
                set ila_depth($clocks($name)) $depth
                set ila_adv_trigger($clocks($name)) false
            } else {
                lappend clock_list($clocks($name)) $name
            }
            set clk_depth [get_property -quiet MARK_DEBUG_DEPTH $d]
            if { [llength $clk_depth] != 0 } {
                set ila_depth($clocks($name)) $clk_depth
            }
            set trigger [get_property -quiet MARK_DEBUG_ADV_TRIGGER $d]
            if { $trigger == "true" } {
                set ila_adv_trigger($clocks($name)) true
            }
        }
    }
    set ila_count 0
    set trig_out ""
    set trig_out_ack ""
    if { [llength [array names clock_list]] > 1 } {
        set enable_trigger true
    } else {
        set enable_trigger false
    }
    foreach c [array names clock_list] {
        [incr ila_count]
        set ila_inst "ila_$ila_count"
        if { $ila_depth($c) < 1024 || [expr $ila_depth($c) & ($ila_depth($c) - 1)] || $ila_depth($c) > 131072 } {
            if { $ila_depth($c) < 1024 } {
                set new_depth 1024
            } elseif { $ila_depth($c) > 131072 } {
                set new_depth 131072
            } else {
                set new_depth [expr 1 << int( log($ila_depth($c))/log(2) + .9999 )]
            }
            puts "Can't create ILA core $ila_inst with depth of $ila_depth($c)!  Changed capture depth to $new_depth"
            set ila_depth($c) $new_depth
        }
        puts "Creating ILA $ila_inst with capture depth $ila_depth($c) and advanced trigger = $ila_adv_trigger($c)"
        if { [expr [string range [version -short] 0 3] < 2014] } {
            create_debug_core  $ila_inst        labtools_ila_v3
        } else {
            create_debug_core  $ila_inst        ila
        }
        if { $ila_adv_trigger($c) } { set mu_cnt 4 } else { set mu_cnt 2 }
        set_property    C_DATA_DEPTH   $ila_depth($c) [get_debug_cores $ila_inst]
        set_property    C_TRIGIN_EN    $enable_trigger [get_debug_cores $ila_inst]
        set_property    C_TRIGOUT_EN   $enable_trigger [get_debug_cores $ila_inst]
        set_property    C_ADV_TRIGGER  $ila_adv_trigger($c) [get_debug_cores $ila_inst]
        set_property    C_INPUT_PIPE_STAGES 1 [get_debug_cores $ila_inst]
        set_property    C_EN_STRG_QUAL true [get_debug_cores $ila_inst]
        set_property    ALL_PROBE_SAME_MU true [get_debug_cores $ila_inst]
        set_property    ALL_PROBE_SAME_MU_CNT $mu_cnt [get_debug_cores $ila_inst]
        set_property    port_width 1     [get_debug_ports $ila_inst/clk]
        connect_debug_port $ila_inst/clk    $c
        if { $enable_trigger == true } {
            create_debug_port $ila_inst trig_in
            create_debug_port $ila_inst trig_in_ack
            create_debug_port $ila_inst trig_out
            create_debug_port $ila_inst trig_out_ack
            if { $trig_out != "" } {
                connect_debug_port $ila_inst/trig_in [get_nets $trig_out]
            }
            if { $trig_out_ack != "" } {
                connect_debug_port $ila_inst/trig_in_ack [get_nets $trig_out_ack]
            }
            set trig_out ${ila_inst}_trig_out_$ila_count
            create_net $trig_out
            connect_debug_port  $ila_inst/trig_out [get_nets $trig_out]
            set trig_out_ack ${ila_inst}_trig_out_ack_$ila_count
            create_net $trig_out_ack
            connect_debug_port  $ila_inst/trig_out_ack [get_nets $trig_out_ack]
        }
        set nprobes 0
        foreach n [lsort $clock_list($c)] {
            set nets {}
            if {$max($n) < 0} {
                lappend nets [get_nets $n]
            } else {
                for {set i $min($n)} {$i <= $max($n)} {incr i} {
                    lappend nets [get_nets $n[$i]]
                }
            }
            set prb probe$nprobes
            if {$nprobes > 0} {
                create_debug_port $ila_inst probe
            }
            set_property port_width [llength $nets] [get_debug_ports $ila_inst/$prb]
            connect_debug_port $ila_inst/$prb $nets
            incr nprobes
        }
    }
    if { $enable_trigger == true } {
        connect_debug_port ila_1/trig_in [get_nets $trig_out]
        connect_debug_port ila_1/trig_in_ack [get_nets $trig_out_ack]
    }
    set project_found [get_projects -quiet]
    if { $project_found != "New Project" } {
        puts "Saving constraints now in project [current_project -quiet]"
        save_constraints_as debug_constraints.xdc
    }
    implement_debug_core
    write_debug_probes -force debug_nets.ltx
}

set VERILOG_FILES [get_file_list top.fl "utf-8" "lf"]

read_verilog $VERILOG_FILES

if {[file exist "ip"]} {
    foreach {entry} [glob -nocomplain -directory ip *] {
        catch { file delete -force $entry }
    }
}

if {![file exist "ip"]} {
    file mkdir ip
}

# MMCM: 250 MHz diff in (DIFF_SSTL12) -> 100 MHz out for SDRAM and logic.
create_ip -vendor xilinx.com -library ip -version 6.0 -name clk_wiz -module_name mmcm -dir ip -force
set_property -dict [list \
    CONFIG.Component_Name {mmcm} \
    CONFIG.PRIM_IN_FREQ {250.0} \
    CONFIG.CLKIN1_JITTER_PS {40.0} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.0} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_SAFE_CLOCK_STARTUP {true}] [get_ips mmcm]
generate_target all [get_files mmcm.xci]


set IP_DIRS [glob -nocomplain -directory "ip" -type d *]

set_property -dict [list \
    TARGET_LANGUAGE {Verilog} \
    SIMULATOR_LANGUAGE {Mixed} \
    TARGET_SIMULATOR {XSim} \
    DEFAULT_LIB {xil_defaultlib} \
    IP_REPO_PATHS $IP_DIRS \
    ] [current_project]

set_property GENERATE_SYNTH_CHECKPOINT {false} [get_files -all {*.xci}]
set IPS [get_ips]
generate_target all $IPS
export_ip_user_files -of_objects $IPS -no_script -force

# Xilinx bug workaround: gather IP include dirs.
set IP_INCLUDE_DIRS {}
proc recglob { basedir pattern } {
    set dirlist [glob -nocomplain -directory $basedir -type d *]
    set findlist [glob -nocomplain -directory $basedir $pattern]
    foreach dir $dirlist {
        set reclist [recglob $dir $pattern]
        set findlist [concat $findlist $reclist]
    }
    return $findlist
}
proc findincludedir { basedir pattern } {
    set vhfiles [recglob $basedir $pattern]
    set vhdirs {}
    foreach match $vhfiles {
        lappend vhdirs [file dir $match]
    }
    set uniquevhdirs [lsort -unique $vhdirs]
    return $uniquevhdirs
}
foreach DIR $IP_DIRS {
    set IP_INCLUDE_DIRS [concat $IP_INCLUDE_DIRS [findincludedir $DIR "*.vh"]]
    set IP_INCLUDE_DIRS [concat $IP_INCLUDE_DIRS [findincludedir $DIR "*.h"]]
}

read_xdc top.xdc

synth_design -top top -part xcvu9p-flga2104-2L-e -include_dirs {$IP_INCLUDE_DIRS}

# Generated SDRAM/logic clock constraint (post-synth so the MMCM hierarchy exists).
set sys_clk_period [expr 1000.0 / 50.0]
set sys_clk_edge_list "0.0 [expr $sys_clk_period/2.0]"
set_property DONT_TOUCH true [get_cells u_mmcm/inst]
create_clock -name sys_clk -waveform $sys_clk_edge_list -period $sys_clk_period [get_pins u_mmcm/inst/clk_out1]

# Forwarded SDRAM clock at the FPGA pad: same period as sys_clk.
create_generated_clock -name sdram_clk -source [get_pins u_mmcm/inst/clk_out1] \
    -divide_by 1 [get_ports sdram_clk_pad]

# 32k-deep ILA per clock domain (one domain in this design).
batch_insert_ila 32768

# Explicitly tell dbg_hub the ILA clock frequency. Without this the BSCAN
# bridge times out at probe time and HW Manager reports "debug hub core
# was not detected".
if {[llength [get_debug_cores -quiet dbg_hub]] > 0} {
    set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
    set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
    puts "dbg_hub configured for 50 MHz ILA clock"
    implement_debug_core
}

place_design
route_design
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force top.bit
quit
