# FMC_BASIC_PERI

The basic peripherals of the FPGA mezzanine card, including JTAG, UART, GPIO,
USB, I3C, etc., can be used for prototype verification of the basic peripherals
of the SoC.

![3D VIEW](./image/fmc_basic_peri_3d.jpg)

## Preparation

Install kicad 10, cmake, ninja, frugy.

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
ch341eeprom -s 24c02 -e
ch341eeprom -s 24c02 -w build/fmc_fru_eeprom.bin
ch341eeprom -s 24c02 -V build/fmc_fru_eeprom.bin
```

`ch341eeprom` truncates the 2 KiB bin to the 256-byte chip on write, and the
verifier passes end-to-end. To inspect the FRU contents semantically,
`ch341eeprom -s 24c02 -r /tmp/dump.bin && frugy -r -d /tmp/dump.bin`.
