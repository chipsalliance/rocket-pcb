# IO constraints
# 250 MHZ clock
set_property PACKAGE_PIN AW27            [get_ports "clk_n"               ] ;# Bank  41 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_41
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "clk_n"               ] ;# Bank  41 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_41
set_property PACKAGE_PIN AW26            [get_ports "clk_p"               ] ;# Bank  41 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_41
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "clk_p"               ] ;# Bank  41 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_41

# JTAG
set_property PACKAGE_PIN AL35            [get_ports "tdi"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_43 - FMCP_HSPC_LA00_CC_P - GPIO0
set_property IOSTANDARD  LVCMOS18        [get_ports "tdi"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_43 - FMCP_HSPC_LA00_CC_P - GPIO0
set_property PACKAGE_PIN AL36            [get_ports "tms"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_43 - FMCP_HSPC_LA00_CC_N - GPIO1
set_property IOSTANDARD  LVCMOS18        [get_ports "tms"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_43 - FMCP_HSPC_LA00_CC_N - GPIO1
set_property PACKAGE_PIN AT39            [get_ports "tck"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_43 - FMCP_HSPC_LA03_P - GPIO2
set_property IOSTANDARD  LVCMOS18        [get_ports "tck"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_43 - FMCP_HSPC_LA03_P - GPIO2
set_property PACKAGE_PIN AT40            [get_ports "tdo"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_43 - FMCP_HSPC_LA03_N - GPIO3
set_property IOSTANDARD  LVCMOS18        [get_ports "tdo"                 ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_43 - FMCP_HSPC_LA03_N - GPIO3

# UART
set_property PACKAGE_PIN AL30            [get_ports "uart_rx"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_43 - FMCP_HSPC_LA01_CC_P - UART_TXD
set_property IOSTANDARD  LVCMOS18        [get_ports "uart_rx"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_43 - FMCP_HSPC_LA01_CC_P - UART_TXD
set_property PACKAGE_PIN AL31            [get_ports "uart_tx"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_43 - FMCP_HSPC_LA01_CC_N - UART_RXD
set_property IOSTANDARD  LVCMOS18        [get_ports "uart_tx"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_43 - FMCP_HSPC_LA01_CC_N - UART_RXD

# TODO
# set_property PACKAGE_PIN AK30            [get_ports "FMCP_HSPC_LA08_N"    ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_43 - FMCP_HSPC_LA08_N - GPIO4
# set_property IOSTANDARD  LVCMOS18        [get_ports "FMCP_HSPC_LA08_N"    ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_43 - FMCP_HSPC_LA08_N - GPIO4
# set_property PACKAGE_PIN AK29            [get_ports "FMCP_HSPC_LA08_P"    ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_43 - FMCP_HSPC_LA08_P - GPIO5
# set_property IOSTANDARD  LVCMOS18        [get_ports "FMCP_HSPC_LA08_P"    ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_43 - FMCP_HSPC_LA08_P - GPIO5

# LED
set_property PACKAGE_PIN L34             [get_ports "led[0]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_45 - FMCP_HSPC_LA33_P - GPIO20
set_property IOSTANDARD  LVCMOS18        [get_ports "led[0]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_45 - FMCP_HSPC_LA33_P - GPIO20
set_property PACKAGE_PIN K34             [get_ports "led[1]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_45 - FMCP_HSPC_LA33_N - GPIO21
set_property IOSTANDARD  LVCMOS18        [get_ports "led[1]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_45 - FMCP_HSPC_LA33_N - GPIO21
set_property PACKAGE_PIN AJ32            [get_ports "led[2]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_43 - FMCP_HSPC_LA02_P - GPIO22
set_property IOSTANDARD  LVCMOS18        [get_ports "led[2]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_43 - FMCP_HSPC_LA02_P - GPIO22
set_property PACKAGE_PIN AK32            [get_ports "led[3]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_43 - FMCP_HSPC_LA02_N - GPIO23
set_property IOSTANDARD  LVCMOS18        [get_ports "led[3]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_43 - FMCP_HSPC_LA02_N - GPIO23
set_property PACKAGE_PIN AR37            [get_ports "led[4]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_43 - FMCP_HSPC_LA04_P - GPIO24
set_property IOSTANDARD  LVCMOS18        [get_ports "led[4]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_43 - FMCP_HSPC_LA04_P - GPIO24
set_property PACKAGE_PIN AT37            [get_ports "led[5]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_43 - FMCP_HSPC_LA04_N - GPIO25
set_property IOSTANDARD  LVCMOS18        [get_ports "led[5]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_43 - FMCP_HSPC_LA04_N - GPIO25
set_property PACKAGE_PIN AP36            [get_ports "led[6]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_43 - FMCP_HSPC_LA07_P - GPIO26
set_property IOSTANDARD  LVCMOS18        [get_ports "led[6]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_43 - FMCP_HSPC_LA07_P - GPIO26
set_property PACKAGE_PIN AP37            [get_ports "led[7]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_43 - FMCP_HSPC_LA07_N - GPIO27
set_property IOSTANDARD  LVCMOS18        [get_ports "led[7]"              ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_43 - FMCP_HSPC_LA07_N - GPIO27

# Switch
set_property PACKAGE_PIN AJ30            [get_ports "switch[0]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_43 - FMCP_HSPC_LA11_P - GPIO28
set_property IOSTANDARD  LVCMOS18        [get_ports "switch[0]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_43 - FMCP_HSPC_LA11_P - GPIO28
set_property PACKAGE_PIN AJ31            [get_ports "switch[1]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_43 - FMCP_HSPC_LA11_N - GPIO29
set_property IOSTANDARD  LVCMOS18        [get_ports "switch[1]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_43 - FMCP_HSPC_LA11_N - GPIO29
set_property PACKAGE_PIN AG32            [get_ports "switch[2]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_43 - FMCP_HSPC_LA15_P - GPIO30
set_property IOSTANDARD  LVCMOS18        [get_ports "switch[2]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_43 - FMCP_HSPC_LA15_P - GPIO30
set_property PACKAGE_PIN AG33            [get_ports "switch[3]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_43 - FMCP_HSPC_LA15_N - GPIO31
set_property IOSTANDARD  LVCMOS18        [get_ports "switch[3]"           ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_43 - FMCP_HSPC_LA15_N - GPIO31

# Key
set_property PACKAGE_PIN U35             [get_ports "key[0]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_45 - FMCP_HSPC_LA29_P - GPIO16
set_property IOSTANDARD  LVCMOS18        [get_ports "key[0]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_45 - FMCP_HSPC_LA29_P - GPIO16
set_property PACKAGE_PIN T36             [get_ports "key[1]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_45 - FMCP_HSPC_LA29_N - GPIO17
set_property IOSTANDARD  LVCMOS18        [get_ports "key[1]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_45 - FMCP_HSPC_LA29_N - GPIO17
set_property PACKAGE_PIN P37             [get_ports "key[2]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_45 - FMCP_HSPC_LA31_P - GPIO18
set_property IOSTANDARD  LVCMOS18        [get_ports "key[2]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_45 - FMCP_HSPC_LA31_P - GPIO18
set_property PACKAGE_PIN N37             [get_ports "key[3]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_45 - FMCP_HSPC_LA31_N - GPIO19
set_property IOSTANDARD  LVCMOS18        [get_ports "key[3]"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_45 - FMCP_HSPC_LA31_N - GPIO19

# USB
set_property PACKAGE_PIN AP35            [get_ports "usb_det"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_43 - FMCP_HSPC_LA10_P - USB_DET
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_det"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_43 - FMCP_HSPC_LA10_P - USB_DET
set_property PACKAGE_PIN AR35            [get_ports "usb_con"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_43 - FMCP_HSPC_LA10_N - USB_CON
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_con"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_43 - FMCP_HSPC_LA10_N - USB_CON
set_property PACKAGE_PIN AG31            [get_ports "usb_oen"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_43 - FMCP_HSPC_LA14_P - USB_OEN
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_oen"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_43 - FMCP_HSPC_LA14_P - USB_OEN
set_property PACKAGE_PIN AH31            [get_ports "usb_rcv"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_43 - FMCP_HSPC_LA14_N - USB_RCV
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_rcv"             ] ;# Bank  43 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_43 - FMCP_HSPC_LA14_N - USB_RCV
set_property PACKAGE_PIN R31             [get_ports "usb_vp"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_45 - FMCP_HSPC_LA18_CC_P - USB_VP
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_vp"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_45 - FMCP_HSPC_LA18_CC_P - USB_VP
set_property PACKAGE_PIN P31             [get_ports "usb_vm"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_45 - FMCP_HSPC_LA18_CC_N - USB_VM
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_vm"              ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_45 - FMCP_HSPC_LA18_CC_N - USB_VM
set_property PACKAGE_PIN V33             [get_ports "usb_spd"             ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_45 - FMCP_HSPC_LA27_P - USB_SPD
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_spd"             ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_45 - FMCP_HSPC_LA27_P - USB_SPD
set_property PACKAGE_PIN V34             [get_ports "usb_sus"             ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_45 - FMCP_HSPC_LA27_N - USB_SUS
set_property IOSTANDARD  LVCMOS18        [get_ports "usb_sus"             ] ;# Bank  45 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_45 - FMCP_HSPC_LA27_N - USB_SUS

# Not recommended settings, it's just a dirty fix
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_IBUF_inst/O]
