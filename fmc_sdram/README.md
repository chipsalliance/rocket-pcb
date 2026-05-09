# FMC_SDRAM

FMC mezannine card with dual MT48LC16M16A2 SDRAM, organized as 16Mx32bit, with level shifters for VADJ.
Also includes USB to UART bridge, JTAG level shifter with ARM 20-pin JTAG header.

![3D VIEW TOP](./image/fmc_sdram_3d_top.png)

![3D VIEW BOTTOM](./image/fmc_sdram_3d_bot.png)

## Preparation

Install kicad 8, cmake, ninja, frugy.

## Precautions

When using it for the first time, it is necessary to program the IPMI FRU data
for the EEPROM so that the development board can identify the power supply
of the FMC.

## Build

```bash
cmake -G Ninja -B build
cmake --build build
```

If you only need to build the eeprom binary,

```bash
cmake --build build --target eeprom
```

If you only need to generate a pdf of the schematic or pcb,

```bash
cmake --build build --target pdf
```

If you need to generate complete production data,

```bash
cmake --build build --target production
```

## Program the FRU EEPROM

Use a CH341A USB-to-I2C adapter (PID `1a86:5512`, EPP/MEM/I2C mode) with
[ch341eeprom](https://github.com/commandtab/ch341eeprom). Wire `SDA`, `SCL`,
`VCC` (3.3V) and `GND` to the on-board M24C02, and pull `WP` to GND.

```bash
ch341eeprom -v -s 24c02 -w build/fmc_fru_eeprom.bin
ch341eeprom -v -s 24c02 -V build/fmc_fru_eeprom.bin
```

The verifier reports a mismatch at offset 238 because the FRU image is 238
bytes while the EEPROM is padded to 256 — the FRU data itself is correct.
