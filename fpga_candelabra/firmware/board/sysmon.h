#ifndef _BOARD_SYSMON_H
#define _BOARD_SYSMON_H

/* BEGIN SYSMON definitions */
// DRP command
#define DRP_CMD_CMD_OFFSET  26
#define DRP_CMD_CMD_MASK    0xf
#define DRP_CMD_ADDR_OFFSET 16
#define DRP_CMD_ADDR_MASK   0x3ff
#define DRP_CMD_DATA_OFFSET 0
#define DRP_CMD_DATA_MASK   0xffff

#define DRP_CMD_CMD_NOP     0
#define DRP_CMD_CMD_READ    1
#define DRP_CMD_CMD_WRITE   2

#define DRP_CMD(cmd, addr, data) ( \
    (((cmd) & DRP_CMD_CMD_MASK) << DRP_CMD_CMD_OFFSET) | \
    (((addr) & DRP_CMD_ADDR_MASK) << DRP_CMD_ADDR_OFFSET) | \
    ((data) & DRP_CMD_DATA_MASK) )

#define DRP_CMD_READ(addr)  DRP_CMD(DRP_CMD_CMD_READ, addr, 0)
#define DRP_CMD_WRITE(addr, data)  DRP_CMD(DRP_CMD_CMD_WRITE, addr, data)

// DRP status registers
#define DRP_ADDR_TEMPERATURE 0x0
#define DRP_ADDR_TEMPERATURE_MAX 0x20
#define DRP_ADDR_TEMPERATURE_MIN 0x24

#define DRP_ADDR_VCCINT      0x1
#define DRP_ADDR_VCCINT_MAX  0x21
#define DRP_ADDR_VCCINT_MIN  0x25
#define DRP_ADDR_VCCAUX      0x2
#define DRP_ADDR_VCCAUX_MAX  0x22
#define DRP_ADDR_VCCAUX_MIN  0x26
#define DRP_ADDR_VP_VN       0x3
#define DRP_ADDR_VREFP       0x4
#define DRP_ADDR_VREFN       0x5
#define DRP_ADDR_VCCBRAM     0x6
#define DRP_ADDR_VCCBRAM_MAX 0x23
#define DRP_ADDR_VCCBRAM_MIN 0x27

// I2C operations
#define sysmon_i2c_read_blocking mgmt_i2c_read_blocking
#define sysmon_i2c_write_blocking mgmt_i2c_write_blocking

/* BEGIN function prototypes */
int sysmon_read_reg(uint16_t daddr, uint16_t *data);
int sysmon_read_temperature(uint16_t addr, float *temp);
int sysmon_read_voltage(uint16_t addr, float *voltage);
int sysmon_dump_status(void);

#endif // _BOARD_SYSMON_H