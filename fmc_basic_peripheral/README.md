# FMC_BASIC_PERI

The basic peripherals of the FPGA mezzanine card, including JTAG, UART, GPIO,
USB, I3C, etc., can be used for prototype verification of the basic peripherals
of the SoC.

## Preparation

Install kicad7, cmake, ninja, frugy.

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
