# --------------------------------------------------------------------
# fmc_sdram FPGA test, target VCU118 (xcvu9p-flga2104-2L-e).
#
# The mezzanine card has a 160-pin LPC FMC connector (J1 = ASP-134604-01)
# and is plugged into VCU118 J2 (FMC HPC1, LA[0..33] subset populated).
# All SDRAM signals are routed via J2; status / control I/O uses
# VCU118 on-board LEDs, push buttons and DIP switches.
#
# Pin mapping derived from:
#   - fmc_sdram/fmc.kicad_sch (J1 SDRAM nets)
#   - VITA 57.1 standard FMC LA pinout
#   - Xilinx VCU118 master XDC (FMC_HPC1_LA<n>_<P/N> -> package pin)
# --------------------------------------------------------------------

# ---- 250 MHz on-board differential clock (bank 41) ------------------
set_property PACKAGE_PIN AW27            [get_ports "clk_n"]
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "clk_n"]
set_property PACKAGE_PIN AW26            [get_ports "clk_p"]
set_property IOSTANDARD  DIFF_SSTL12     [get_ports "clk_p"]

# ---- VCU118 on-board CPU_RESET button (active HIGH, pulldown idle) ---
set_property PACKAGE_PIN L19             [get_ports "cpu_reset"]
set_property IOSTANDARD  LVCMOS12        [get_ports "cpu_reset"]
set_property PULLDOWN    true            [get_ports "cpu_reset"]

# ---- VCU118 on-board push buttons U/L/D/R (LVCMOS18) ----------------
set_property PACKAGE_PIN BB24            [get_ports "btn[0]"] ;# BTNU
set_property IOSTANDARD  LVCMOS18        [get_ports "btn[0]"]
set_property PACKAGE_PIN BF22            [get_ports "btn[1]"] ;# BTNL
set_property IOSTANDARD  LVCMOS18        [get_ports "btn[1]"]
set_property PACKAGE_PIN BE22            [get_ports "btn[2]"] ;# BTND
set_property IOSTANDARD  LVCMOS18        [get_ports "btn[2]"]
set_property PACKAGE_PIN BE23            [get_ports "btn[3]"] ;# BTNR
set_property IOSTANDARD  LVCMOS18        [get_ports "btn[3]"]

# ---- VCU118 on-board DIP switches (LVCMOS12) ------------------------
set_property PACKAGE_PIN B17             [get_ports "sw[0]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "sw[0]"]
set_property PACKAGE_PIN G16             [get_ports "sw[1]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "sw[1]"]
set_property PACKAGE_PIN J16             [get_ports "sw[2]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "sw[2]"]
set_property PACKAGE_PIN D21             [get_ports "sw[3]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "sw[3]"]

# ---- VCU118 on-board user LEDs (LVCMOS12) ---------------------------
set_property PACKAGE_PIN AT32            [get_ports "led[0]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[0]"]
set_property PACKAGE_PIN AV34            [get_ports "led[1]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[1]"]
set_property PACKAGE_PIN AY30            [get_ports "led[2]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[2]"]
set_property PACKAGE_PIN BB32            [get_ports "led[3]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[3]"]
set_property PACKAGE_PIN BF32            [get_ports "led[4]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[4]"]
set_property PACKAGE_PIN AU37            [get_ports "led[5]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[5]"]
set_property PACKAGE_PIN AV36            [get_ports "led[6]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[6]"]
set_property PACKAGE_PIN BA37            [get_ports "led[7]"]
set_property IOSTANDARD  LVCMOS12        [get_ports "led[7]"]
set_property DRIVE 8 [get_ports "led[*]"]
set_property SLEW SLOW [get_ports "led[*]"]
set_false_path -to   [get_ports "led[*]"]
set_false_path -from [get_ports "btn[*] sw[*] cpu_reset"]

# --------------------------------------------------------------------
# SDRAM signals on VCU118 J2 (FMC HPC1 LA pins).
# IO standard 1.8 V LVCMOS through SN74AVCH16T245 level shifters on the
# mezzanine. DRIVE 8, SLEW FAST.
# --------------------------------------------------------------------
# ---- SDRAM control ---------------------------------------------------
set_property PACKAGE_PIN AL15  [get_ports "sdram_clk_pad"]    ;# J2.D27 LA26_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_clk_pad"]
set_property PACKAGE_PIN AM14  [get_ports "sdram_cke_pad"]    ;# J2.C27 LA27_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_cke_pad"]
set_property PACKAGE_PIN BF14  [get_ports "sdram_cs_n_pad"]   ;# J2.D12 LA05_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_cs_n_pad"]
set_property PACKAGE_PIN BE13  [get_ports "sdram_ras_n_pad"]  ;# J2.C11 LA06_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_ras_n_pad"]
set_property PACKAGE_PIN BD13  [get_ports "sdram_cas_n_pad"]  ;# J2.C10 LA06_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_cas_n_pad"]
set_property PACKAGE_PIN BE14  [get_ports "sdram_we_n_pad"]   ;# J2.D11 LA05_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_we_n_pad"]

# ---- SDRAM bank ------------------------------------------------------
set_property PACKAGE_PIN BA14  [get_ports "sdram_ba_pad[0]"]  ;# J2.D14 LA09_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_ba_pad[0]"]
set_property PACKAGE_PIN BB13  [get_ports "sdram_ba_pad[1]"]  ;# J2.C14 LA10_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_ba_pad[1]"]

# ---- SDRAM address ---------------------------------------------------
set_property PACKAGE_PIN BB12  [get_ports "sdram_a_pad[0]"]   ;# J2.C15 LA10_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[0]"]
set_property PACKAGE_PIN AY8   [get_ports "sdram_a_pad[1]"]   ;# J2.D17 LA13_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[1]"]
set_property PACKAGE_PIN AY7   [get_ports "sdram_a_pad[2]"]   ;# J2.D18 LA13_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[2]"]
set_property PACKAGE_PIN AW8   [get_ports "sdram_a_pad[3]"]   ;# J2.C18 LA14_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[3]"]
set_property PACKAGE_PIN AR14  [get_ports "sdram_a_pad[4]"]   ;# J2.D20 LA17_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[4]"]
set_property PACKAGE_PIN AT14  [get_ports "sdram_a_pad[5]"]   ;# J2.D21 LA17_CC_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[5]"]
set_property PACKAGE_PIN AP12  [get_ports "sdram_a_pad[6]"]   ;# J2.C22 LA18_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[6]"]
set_property PACKAGE_PIN AN16  [get_ports "sdram_a_pad[7]"]   ;# J2.D23 LA23_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[7]"]
set_property PACKAGE_PIN AR12  [get_ports "sdram_a_pad[8]"]   ;# J2.C23 LA18_CC_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[8]"]
set_property PACKAGE_PIN AP16  [get_ports "sdram_a_pad[9]"]   ;# J2.D24 LA23_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[9]"]
set_property PACKAGE_PIN BB14  [get_ports "sdram_a_pad[10]"]  ;# J2.D15 LA09_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[10]"]
set_property PACKAGE_PIN AK15  [get_ports "sdram_a_pad[11]"]  ;# J2.D26 LA26_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[11]"]
set_property PACKAGE_PIN AL14  [get_ports "sdram_a_pad[12]"]  ;# J2.C26 LA27_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_a_pad[12]"]

# ---- SDRAM DQM (active high mask) -----------------------------------
set_property PACKAGE_PIN AV9   [get_ports "sdram_dqm_pad[0]"] ;# J2.G18 LA16_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dqm_pad[0]"]
set_property PACKAGE_PIN BB16  [get_ports "sdram_dqm_pad[1]"] ;# J2.H19 LA15_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dqm_pad[1]"]
set_property PACKAGE_PIN AV8   [get_ports "sdram_dqm_pad[2]"] ;# J2.G19 LA16_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dqm_pad[2]"]
set_property PACKAGE_PIN BC16  [get_ports "sdram_dqm_pad[3]"] ;# J2.H20 LA15_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dqm_pad[3]"]

# ---- SDRAM DQ low byte (DQ0..15, lower MT48LC chip) -----------------
set_property PACKAGE_PIN BE12  [get_ports "sdram_dq_pad[0]"]  ;# J2.G10 LA03_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[0]"]
set_property PACKAGE_PIN BD12  [get_ports "sdram_dq_pad[1]"]  ;# J2.G9  LA03_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[1]"]
set_property PACKAGE_PIN BA9   [get_ports "sdram_dq_pad[2]"]  ;# J2.G7  LA00_CC_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[2]"]
set_property PACKAGE_PIN AY9   [get_ports "sdram_dq_pad[3]"]  ;# J2.G6  LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[3]"]
set_property PACKAGE_PIN BC15  [get_ports "sdram_dq_pad[4]"]  ;# J2.H13 LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[4]"]
set_property PACKAGE_PIN BD15  [get_ports "sdram_dq_pad[5]"]  ;# J2.H14 LA07_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[5]"]
set_property PACKAGE_PIN BA16  [get_ports "sdram_dq_pad[6]"]  ;# J2.H16 LA11_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[6]"]
set_property PACKAGE_PIN BA15  [get_ports "sdram_dq_pad[7]"]  ;# J2.H17 LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[7]"]
set_property PACKAGE_PIN BC13  [get_ports "sdram_dq_pad[8]"]  ;# J2.G16 LA12_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[8]"]
set_property PACKAGE_PIN BC14  [get_ports "sdram_dq_pad[9]"]  ;# J2.G15 LA12_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[9]"]
set_property PACKAGE_PIN BF15  [get_ports "sdram_dq_pad[10]"] ;# J2.G13 LA08_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[10]"]
set_property PACKAGE_PIN BE15  [get_ports "sdram_dq_pad[11]"] ;# J2.G12 LA08_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[11]"]
set_property PACKAGE_PIN BC11  [get_ports "sdram_dq_pad[12]"] ;# J2.H7  LA02_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[12]"]
set_property PACKAGE_PIN BD11  [get_ports "sdram_dq_pad[13]"] ;# J2.H8  LA02_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[13]"]
set_property PACKAGE_PIN BF12  [get_ports "sdram_dq_pad[14]"] ;# J2.H10 LA04_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[14]"]
set_property PACKAGE_PIN BF11  [get_ports "sdram_dq_pad[15]"] ;# J2.H11 LA04_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[15]"]

# ---- SDRAM DQ high byte (DQ16..31, upper MT48LC chip) ---------------
set_property PACKAGE_PIN AP13  [get_ports "sdram_dq_pad[16]"] ;# J2.H28 LA24_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[16]"]
set_property PACKAGE_PIN AR13  [get_ports "sdram_dq_pad[17]"] ;# J2.H29 LA24_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[17]"]
set_property PACKAGE_PIN AV10  [get_ports "sdram_dq_pad[18]"] ;# J2.H31 LA28_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[18]"]
set_property PACKAGE_PIN AW10  [get_ports "sdram_dq_pad[19]"] ;# J2.H32 LA28_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[19]"]
set_property PACKAGE_PIN AY13  [get_ports "sdram_dq_pad[20]"] ;# J2.G25 LA22_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[20]"]
set_property PACKAGE_PIN AW13  [get_ports "sdram_dq_pad[21]"] ;# J2.G24 LA22_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[21]"]
set_property PACKAGE_PIN AY10  [get_ports "sdram_dq_pad[22]"] ;# J2.G22 LA20_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[22]"]
set_property PACKAGE_PIN AW11  [get_ports "sdram_dq_pad[23]"] ;# J2.G21 LA20_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[23]"]
set_property PACKAGE_PIN AW12  [get_ports "sdram_dq_pad[24]"] ;# J2.H22 LA19_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[24]"]
set_property PACKAGE_PIN AY12  [get_ports "sdram_dq_pad[25]"] ;# J2.H23 LA19_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[25]"]
set_property PACKAGE_PIN AU11  [get_ports "sdram_dq_pad[26]"] ;# J2.H25 LA21_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[26]"]
set_property PACKAGE_PIN AV11  [get_ports "sdram_dq_pad[27]"] ;# J2.H26 LA21_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[27]"]
set_property PACKAGE_PIN AP15  [get_ports "sdram_dq_pad[28]"] ;# J2.G31 LA29_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[28]"]
set_property PACKAGE_PIN AN15  [get_ports "sdram_dq_pad[29]"] ;# J2.G30 LA29_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[29]"]
set_property PACKAGE_PIN AU12  [get_ports "sdram_dq_pad[30]"] ;# J2.G28 LA25_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[30]"]
set_property PACKAGE_PIN AT12  [get_ports "sdram_dq_pad[31]"] ;# J2.G27 LA25_P
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_pad[31]"]

# ---- Level shifter direction control (FPGA-only output) -------------
set_property PACKAGE_PIN AW7   [get_ports "sdram_dq_dir_pad"] ;# J2.C19 LA14_N
set_property IOSTANDARD LVCMOS18 [get_ports "sdram_dq_dir_pad"]

# ---- DRIVE / SLEW for the whole SDRAM bus ---------------------------
set_property DRIVE 8   [get_ports {sdram_clk_pad sdram_cke_pad sdram_cs_n_pad
                                   sdram_ras_n_pad sdram_cas_n_pad sdram_we_n_pad
                                   sdram_a_pad[*] sdram_ba_pad[*] sdram_dqm_pad[*]
                                   sdram_dq_pad[*] sdram_dq_dir_pad}]
set_property SLEW FAST [get_ports {sdram_clk_pad sdram_cke_pad sdram_cs_n_pad
                                   sdram_ras_n_pad sdram_cas_n_pad sdram_we_n_pad
                                   sdram_a_pad[*] sdram_ba_pad[*] sdram_dqm_pad[*]
                                   sdram_dq_pad[*] sdram_dq_dir_pad}]
