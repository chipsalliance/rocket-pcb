# VCU118 SDRAM bring-up

FPGA test bitstream for the `fmc_sdram` mezzanine plugged into VCU118
**J2** (FMC HPC1, LPC functional subset). It brings up the dual
`MT48LC16M16A2P` SDRAM (x32, 64 MB) at 50 MHz CL=2, runs a multi-pattern
built-in self test, and counts read mismatches.

Status (50 MHz, 1 Mword sweep, 4 patterns, `T_WR_CYC = 3`):
**0 / 4,194,304 read errors**.

## Files

- `top.v`: clocking, reset sync, controller wiring, IOBUFs, ODDR clock
  forwarding, BIST instance, LED status, ILA probes.
- `sdram_ctrl.v`: minimal SDRAM controller (BL=1, CL=2, x32, single
  outstanding request). Honours `tRDL = 2 tCK` (last data in to PRECHARGE).
- `sdram_bist.v`: sweep-write then sweep-read BIST over 4 patterns
  (`addr XOR {a,~a}`, `AAAA5555 XOR addr`, `5555AAAA XOR addr`, `~base`),
  with per-pattern and total error counters and first-error capture.
- `top.fl`: Verilog filelist consumed by `build.tcl`.
- `top.xdc`: pin and IO standards. 250 MHz diff clock, on-board
  LEDs/buttons/switches, full SDRAM x32 on J2.
- `build.tcl`: Vivado batch flow with `batch_insert_ila`. MMCM is
  generated for 50 MHz. The debug hub is told the matching clock frequency.
- `load.tcl`: program `top.bit` over the VCU118 USB-JTAG.
- `ila_capture.tcl`: main ILA capture with selectable trigger modes
  (`done` / `mismatch` / `pattern N` / `alive`).
- `ila_capture_r0.tcl`, `ila_capture_w0.tcl`, `ila_capture_w.tcl`:
  targeted captures that trigger on the first read at addr 0, the first
  write at addr 0 in pattern 0, and the first write at addr 0xB9 in
  pattern 3. Useful for diagnosing specific transactions.
- `ila_dump.tcl`: connect, program, and dump every probe name without
  arming. Quick dbg_hub sanity check.

## Build

```bash
source /opt/Xilinx/Vivado/2021.1/.settings64-Vivado.sh
vivado -mode batch -source build.tcl 2>&1 | tee vivado_build.log
grep -i "error\|critical warning" vivado_build.log
```

## Load + run BIST

```bash
vivado -mode batch -source ila_capture.tcl
```

This programs the device, arms the ILA on `dbg_bist_state == 6 (S_DONE)`,
waits for the full 4-pattern 1 Mword sweep (about 22 s on the first
iteration including auto-start delay), and writes the captured buffer to
`ila_capture.csv`.

## Run / observe (on-board)

LED layout after the bitstream loads:

| LED  | Meaning                                       |
| ---- | --------------------------------------------- |
| `7`  | error_count_total != 0 (red flag)             |
| `6`  | bist_done                                     |
| `5`  | bist_busy                                     |
| `4`  | mmcm_locked                                   |
| `3:0`| heartbeat / pattern_idx+phase / err_count nibble |

`btn[0]` (BTNU) restarts the BIST. `sw[0]` selects loop mode. Set to 1 it
auto-restarts after one full pass. It reads HIGH by default on VCU118, so
the BIST cycles forever.

## ILA probes

`debug_nets.ltx` is generated next to `top.bit`. Useful trigger conditions:

| Trigger                      | Catches                          |
| ---------------------------- | -------------------------------- |
| `dbg_bist_state == 6`        | BIST finished all 4 patterns     |
| `dbg_bist_state == 5`        | between patterns (NEXT_PAT)      |
| `dbg_bist_state == 4`        | read in progress, BIST is alive  |
| `dbg_mismatch == 1`          | first failing read               |
| `dbg_pattern == N`           | a specific pattern               |
| `dbg_ctrl_state == 0xa`      | refresh firing (S_AREF)          |

The ILA core captures 32 k samples per arm on the 50 MHz logic clock.

## PCB rework: DQM-DIR

The DQM lines pass through bidirectional SN74AVCH2T45 level shifters
whose DIR pins were tied to `SDRAM_DQ_DIR`. On a READ the shifters flip
to B-to-A, so the SDRAM DQM input floats, which is illegal for a CMOS
input. Both DIR pins (U13.5 and U14.5) are reworked to VADJ so DQM
always drives FPGA to SDRAM.
