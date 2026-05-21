# VCU118 SDRAM bring-up

FPGA test bitstream for the `fmc_sdram` mezzanine plugged into VCU118
**J2** (FMC HPC1, LPC functional subset). Brings up the dual
`MT48LC16M16A2P` SDRAM (organized x32, 64 MB) at 50 MHz CL=2 and runs a
multi-pattern built-in self test across the SDRAM, then verifies the
data and counts mismatches.

Current bring-up status (50 MHz, 1 Mword sweep, 4 patterns,
`T_WR_CYC = 3`): **0 / 4,194,304 read errors**.

## Files

- `top.v` — top-level: clocking, reset sync, controller wiring, IOBUFs,
  ODDR clock forwarding, BIST instantiation, LED status, ILA probes.
- `sdram_ctrl.v` — minimal SDRAM controller (BL=1, CL=2, x32, single
  outstanding request). Honours datasheet tCK-spec constraints, notably
  `tRDL = 2 tCK` (last-data-in to PRECHARGE).
- `sdram_bist.v` — sweep-write / sweep-read BIST cycling 4 patterns
  (`addr XOR {a,~a}`, `AAAA5555 XOR addr`, `5555AAAA XOR addr`, `~base`),
  with per-pattern and total error counters and first-error capture.
- `top.fl` — Verilog filelist consumed by `build.tcl`.
- `top.xdc` — pin / IO standards: 250 MHz diff clock, on-board
  LEDs/buttons/switches, full SDRAM x32 on J2.
- `build.tcl` — Vivado batch flow with `batch_insert_ila`. MMCM is
  generated for 50 MHz; debug hub is told the matching clock frequency.
- `load.tcl` — program `top.bit` over the VCU118 USB-JTAG.
- `ila_capture.tcl` — main ILA capture script with selectable trigger
  modes (`done` / `mismatch` / `pattern N` / `alive`).
- `ila_capture_r0.tcl`, `ila_capture_w0.tcl`, `ila_capture_w.tcl` —
  targeted capture scripts that trigger on the first read at addr 0, the
  first write at addr 0 in pattern 0, and the first write at addr 0xB9
  in pattern 3 respectively. Useful for diagnosing specific transactions.
- `ila_dump.tcl` — connect, program and dump every probe name without
  arming. Quick sanity check for the dbg_hub.

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
waits for the BIST to complete its full 4-pattern × 1 Mword sweep
(~ 22 s on first iteration including the auto-start delay), and writes
the captured buffer to `ila_capture.csv`.

## Run / observe (on-board)

LED layout after the bitstream loads:

| LED  | Meaning                                       |
| ---- | --------------------------------------------- |
| `7`  | error_count_total != 0 (red flag)             |
| `6`  | bist_done                                     |
| `5`  | bist_busy                                     |
| `4`  | mmcm_locked                                   |
| `3:0`| heartbeat / pattern_idx+phase / err_count nibble |

`btn[0]` (BTNU) restarts the BIST. `sw[0]` selects loop mode (1 = auto
restart after one full pass; the default reads HIGH on VCU118 so the
BIST cycles forever).

## ILA probes

`debug_nets.ltx` is generated next to `top.bit`. Useful trigger conditions:

- `dbg_bist_state == 6` — BIST finished all 4 patterns
- `dbg_bist_state == 5` — between patterns (NEXT_PAT)
- `dbg_bist_state == 4` — read in progress (proves BIST is alive)
- `dbg_mismatch == 1` — first failing read
- `dbg_pattern == N` — capture during a specific pattern
- `dbg_ctrl_state == 0xa` (S_AREF) — verify refresh is firing

The ILA core captures 32 k samples per arm on the 50 MHz logic clock.

## Bring-up history (notable bugs found)

1. **CPU_RESET polarity** — VCU118 `cpu_reset` (pin L19) is active-HIGH
   with a pulldown, not active-low. Wired `cpu_reset` then inverted in
   RTL to drive MMCM's active-low `resetn`.
2. **Debug hub clock not configured** — `dbg_hub` needs an explicit
   `C_CLK_INPUT_FREQ_HZ` matching the ILA capture clock, otherwise HW
   Manager reports "debug hub core was not detected".
3. **CL_CYC** — at 50 MHz CL=2, FPGA must sample DQ four FPGA clocks
   after issuing READ (= 1 cmd-register cycle + CL=2 SDRAM cycles +
   round-trip propagation through the level shifter).
4. **BIST ready/valid handshake** — the master must hold `req_valid`
   until it observes `req_valid && req_ready` in the SAME cycle.
   Otherwise a refresh that fires between asserting valid and the slave
   latching the request eats the request and the BIST hangs.
5. **tRDL violation** — `T_WR_CYC` must be ≥ 2 because the datasheet
   specifies `tRDL = 2 tCK`. This is a cycle count, not a nanosecond
   count, so it holds at any clock frequency.
6. **PCB DQM-DIR rework** — on this mezzanine the DQM signals are
   routed through bidirectional SN74AVCH2T45 level shifters whose DIR
   pins are tied to `SDRAM_DQ_DIR`. During READ the level shifters flip
   to B→A, leaving the SDRAM-side DQM input floating (illegal for a
   CMOS input). The PCB has been reworked to tie both DIR pins (U13.5
   and U14.5) to VADJ so the DQM lanes are always FPGA→SDRAM.
