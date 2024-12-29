#ifndef _BOARD_VADJ_H
#define _BOARD_VADJ_H

/* BEGIN MCP4725 ADC definitions */
#define MCP4725_CMD_WRITE_FAST 0x00
#define MCP4725_CMD_WRITE_REG 0x40
#define MCP4725_CMD_WRITE_REG_EEPROM 0x60

#define MCP4725_PD_NORMAL 0x00

/* BEGIN function prototypes */
int vadj_set_voltage(float voltage);

#endif // _BOARD_VADJ_H
