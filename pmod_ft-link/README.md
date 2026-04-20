# FT-LINK

The FT-LINK is a generic in-circuit debugger and programmer based on the FT2232H chip. It supports both Joint Test Action Group (JTAG) and Universal Asynchronous Receiver/Transmitter (UART) interfaces. The FT-LINK connects to the host computer through a USB Type-C port, enabling seamless communication with any rocket-chip based FPGA designs.


## Overview

### PMOD Connector

This design complies with [Digilent Pmod™ Interface Specification 1.2.0](https://digilent.com/reference/_media/reference/pmod/pmod-interface-specification-1_2_0.pdf).

| PMOD Pin # | Digital Pin # | Pin Name |
| ---------- | ------------- | -------- |
| 1          | 0             | TDO      |
| 2          | 1             | nTRST    |
| 3          | 2             | TCK      |
| 4          | 3             | TXD      |
| 5          | NA            | GND      |
| 6          | NA            | 3V3      |
| 7          | 4             | TDI      |
| 8          | 5             | TMS      |
| 9          | 6             | nSRST    |
| 10         | 7             | RXD      |
| 11         | NA            | GND      |
| 12         | NA            | 3V3      |

### LED

| LED | Color | Description      |
| --- | ----- | ---------------- |
| 1   | Red   | Power            |
| 2   | White | UART TX Activity |
| 3   | White | UART RX Activity |
| 4   | Blue  | JTAG Status      |

## 3D View

### Top View

![](image/3d_top.png)

### Bottom View

![](image/3d_bottom.png)

The project can also be accessed with the Altium [online viewer](https://ucb-bar.365.altium.com/designs/60758C9D-BF62-41B4-A112-BCE5FF2BFA60)


## Reference Ordering Instruction

> Note: 
> This is a example order with [JLCPCB](https://cart.jlcpcb.com/quote) for reference. The design can be manufactured with any PCB house with similar capabilities.

### Specifications

| Entry               | Value         |
| ------------------- | ------------- |
| Base Material       | FR-4          |
| Layers              | 2             |
| Dimension           | 36 mm x 20 mm |
| PCB Thickness       | 1.6 mm        |
| PCB Color           | Black         |
| Silkscreen          | White         |
| Surface Finish      | ENIG          |
| Outer Copper Weight | 1 oz          |
| Via Covering        | Tented        |

Cost for reference is $2 for 5 PCBs, and $15 for 5 with assembly.

