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
    ##################################################################
    # sequence through debug nets and organize them by clock in the
    # clock_list array. Also create max and min array for bus indices
    set dbgs [get_nets -hierarchical -filter {MARK_DEBUG}]
    if {[llength $dbgs] == 0} {
        puts "No nets have the MARK_DEBUG attribute.  No ILA cores created"
        return
    } else {
    #process list of nets to find and reject nets that are attached to VIO cores.  This has a side effect that VIO nets can't be monitored with an ILA
    # This can be overridden by using the attribute "mark_debug_valid" = "true" on a net like this.
    set net_list {}
        foreach net $dbgs {
            if { [get_property -quiet MARK_DEBUG_VALID $net] != "true" } { 
                set pin_list [get_pins -of_objects [get_nets -segments $net]]
                set not_vio_net 1
                foreach pin $pin_list {
                    if { [get_property IS_DEBUG_CORE [get_cells -of_object $pin]] == 1 } {
                        # It seems this net is attached to a debug core (i.e. VIO core) already, so we should skip adding it to the netlist
                        set not_vio_net 0
                        break
                        }
                    }
                if { $not_vio_net == 1 } { lappend net_list $net; }
            } else { 
                lappend net_list $net
            }
        }
    }
    # check again to see if we have any nets left now
    if {[llength $net_list] == 0} {
        puts "All nets with MARK_DEBUG are already connected to VIO cores.  No ILA cores created"
        return
    }
    # Now that the netlist has been filtered,  determine bus names and clock domains
    foreach d $net_list {
        # name is root name of a bus, index is the bit index in the
        # bus
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
        # Now we search for the local clock net associated with the target net.  There may be ambiguities or no answer in some cases
        if {![info exists clocks($name)]} {
            # does MARK_DEBUG_CLOCK decorate this net?   If not, then search backwards to the driver cell
            set clk_name [get_property -quiet MARK_DEBUG_CLOCK $d]
            if {  [llength $clk_name] == 0 } {
                # trace to the clock net, tracing backwards via the driver pin.
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
                    # our driver cell is a LUT or LUTMEM in combinatorial mode, we need to trace further.
                    set paths [get_timing_paths -quiet -through $driver_pin ]
                    if { [llength $paths] > 0 } {
                        # note that here we arbitrarily select the start point of the FIRST timing path... there might be multiple clocks with timing paths for this net.
                        # use MARK_DEBUG_CLOCK to specify another clock in this case.
                        set cell_clock_pin [get_pins [get_property STARTPOINT_PIN [lindex $paths 0]]]  
                    } else { 
                        # Can't find any timing path, so skip the net, and warn the user.                    
                        puts "Critical Warning: from batch_insert_ila.tcl    Can't trace any clock domain on driver of net $d"
                        puts "Please attach the attribute MARK_DEBUG_CLOCK with a string containing the net name of the desired sampling clock, .i.e."
                        puts "attribute mark_debug_clock of $d : signal is \"inst_bufg/clk\";"
                        continue
                    }
                }   
                # clk_net will usually be a list of net segments, which needs filtering to determine the net connected to the driver pin
                set clk_net [get_nets -segments -of_objects $cell_clock_pin]
            } else {
                set clk_net [get_nets -segments $clk_name]
                if { [llength $clk_net] == 0 } { puts "MARK_DEBUG_CLOCK attribute on net $d does not match any known net.  Please fix."; continue; }
            }    
            # trace forward to net actually connected to clock buffer output, not any of the lower level segment names
            set clocks($name) [get_nets -of_objects [get_pins -filter {DIRECTION == "OUT" && IS_LEAF == TRUE } -of_objects $clk_net]]
            if {![info exists clock_list($clocks($name))]} {
              # found a new clock
              puts "New clock found is $clocks($name)"
              set clock_list($clocks($name)) [list $name]
              set ila_depth($clocks($name)) $depth
              set ila_adv_trigger($clocks($name)) false
            } else {
              lappend clock_list($clocks($name)) $name
            }
            # Does this net have a "MARK_DEBUG_DEPTH" attribute attached?
            set clk_depth [get_property -quiet MARK_DEBUG_DEPTH $d]
            if { [llength $clk_depth] != 0 } {
                set ila_depth($clocks($name)) $clk_depth
            }
            # Does this net have a "MARK_DEBUG_ADV_TRIGGER" attribute attached?
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
        # Now build and connect an ILA core for each clock domain
        [incr ila_count ]
        set ila_inst "ila_$ila_count"
        ##################################################################
        # first verify if depth is a member of the set, 1024, 2048, 4096, 8192, ... 131072
        if { $ila_depth($c) < 1024 || [expr $ila_depth($c) & ($ila_depth($c) - 1)] || $ila_depth($c) > 131072 } {
            # Depth is not right...  lets fix it, and continue
            if { $ila_depth($c) < 1024 } {
                set new_depth 1024
            } elseif { $ila_depth($c) > 131072 } {
                set new_depth 131072
            } else { 
                # round value to next highest power of 2, (in log space)
                set new_depth [expr 1 << int( log($ila_depth($c))/log(2) + .9999 )]
            }
            puts "Can't create ILA core $ila_inst with depth of $ila_depth($c)!  Changed capture depth to $new_depth"
            set ila_depth($c) $new_depth
        }    
        # create ILA and connect its clock
        puts "Creating ILA $ila_inst with capture depth $ila_depth($c) and advanced trigger = $ila_adv_trigger($c)"
        if { [expr [string range [version -short] 0 3] < 2014] } {
            create_debug_core  $ila_inst        labtools_ila_v3
        } else {
            create_debug_core  $ila_inst        ila
        }
        if { $ila_adv_trigger($c) } { set mu_cnt 4; } else { set mu_cnt 2; }
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
        # hookup trigger ports in a circle if more than one ILA is created
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
        ##################################################################
        # add probes
        set nprobes 0
        foreach n [lsort $clock_list($c)] {
            set nets {}
            if {$max($n) < 0} {
                lappend nets [get_nets $n]
            } else {
                # n is a bus name
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
    # at this point, we need to complete the circular connection of trigger outputs and acks
    if { $enable_trigger == true } {
        connect_debug_port ila_1/trig_in [get_nets $trig_out]
        connect_debug_port ila_1/trig_in_ack [get_nets $trig_out_ack]
    } 
    set project_found [get_projects -quiet] 
    if { $project_found != "New Project" } {
        puts "Saving constraints now in project [current_project -quiet]"
        save_constraints_as debug_constraints.xdc
    }    
    ##################################################################
    implement_debug_core
    ##################################################################
    # write out probe info file
    write_debug_probes -force debug_nets.ltx
}

set VERILOG_FILES [get_file_list top.fl "utf-8" "lf"]

read_verilog $VERILOG_FILES

if {[file exist "ip"]} {
    foreach {entry} [glob -directory ip *] {
        catch { file delete -force $entry }
    }
}

if {![file exist "ip"]} {
    file mkdir ip
}

create_ip -vendor xilinx.com -library ip -version 6.0 -name clk_wiz -module_name mmcm -dir ip -force
set_property -dict [list CONFIG.Component_Name {mmcm} CONFIG.PRIM_IN_FREQ 250.0 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {48.0} CONFIG.RESET_TYPE {ACTIVE_LOW}] [get_ips mmcm]
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

# Xilinx bug workaround
# scrape IP tree for directories containing .vh files
# [get_property include_dirs] misses all IP core subdirectory includes if user has specified -dir flag in create_ip
set IP_INCLUDE_DIRS {}
## Helper function that recursively includes files given a directory and a pattern/suffix extensions
proc recglob { basedir pattern } {
    set dirlist [glob -nocomplain -directory $basedir -type d *]
    set findlist [glob -nocomplain -directory $basedir $pattern]
    foreach dir $dirlist {
        set reclist [recglob $dir $pattern]
        set findlist [concat $findlist $reclist]
    }
    return $findlist
}
## Helper function to find all subdirectories containing ".vh" files
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

set usb_clk_period [expr 1000.0 / 48.0]
set usb_clk_edge_list "0.0 [expr $usb_clk_period/2.0]"
set_property DONT_TOUCH true [get_cells mmcm_inst/inst]
create_clock -name usb_clk -waveform $usb_clk_edge_list -period $usb_clk_period [get_pins mmcm_inst/inst/clk_out1]

batch_insert_ila 1048576
place_design
route_design
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force top.bit
quit
