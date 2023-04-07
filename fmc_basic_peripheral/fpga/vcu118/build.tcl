read_verilog {tap.v top.v}
read_xdc top.xdc
synth_design -top top -part xcvu9p-flga2104-2L-e
place_design
route_design
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force top.bit
quit
