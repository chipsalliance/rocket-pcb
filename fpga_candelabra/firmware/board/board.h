#ifndef _BOARD_BOARD_H
#define _BOARD_BOARD_H

#define DEBUG 1

/* BEGIN Board definitions */

// MGMT I2C Bus:
//  - 0b0011001 DDR4 SPD Temp
//  - 0b0110001 DDR4 SPD Utility
//  - 0b1010001 DDR4 SPD R/W
//  - 0b1010000 FMC0 I2C EEPROM
//  - 0bxxxxx00 FMC0 I2C Optional
//  - 0b1010101 CDCM6208 PLL
//  - 0b1100111 TPS53667 PMBus
//  - 0b1100001 FMC_VADJ DAC
#define MGMT_I2C_PORT i2c0
#define MGMT_I2C_SDA 0
#define MGMT_I2C_SCL 1

#define MGMT_I2C_ADDR_SPD_TEMP          0b0011001
#define MGMT_I2C_ADDR_SPD_UTIL          0b0110001
#define MGMT_I2C_ADDR_SPD_RW            0b1010001
#define MGMT_I2C_ADDR_FMC_EEPROM        0b1010000
#define MGMT_I2C_ADDR_CDCM6208_PLL      0b1010101
#define MGMT_I2C_ADDR_TPS53667_PMBUS    0b1100111
#define MGMT_I2C_ADDR_FMC_VADJ_DAC      0b1100001

// SYSMON I2C Bus
#define SYSMON_I2C_PORT i2c1
#define SYSMON_I2C_SDA 26
#define SYSMON_I2C_SCL 27

// PMBus external signals
#define PMBUS_ALERT_PIN 3

// VCCINT
#define VCCINT_EN_PIN 2
#define VCCINT_PG_PIN 7

// VCCAUX
#define VCCAUX_EN_PIN 6
#define VCCAUX_PG_PIN 4

// 5V Main
#define V5V_MAIN_PG_PIN 5

// FMC VADJ
#define FMC_VADJ_EN_PIN 8
#define FMC_VADJ_PG_PIN 9

#define FMC_VADJ_DCDC_VREF 0.8f
#define FMC_VADJ_FB_R1 33000.0f
#define FMC_VADJ_FB_R2 33000.0f
#define FMC_VADJ_FB_R3 100000.0f

// FMC 3P3V
#define FMC_3P3V_EN_PIN 11
#define FMC_3P3V_PG_PIN 10

// MGTVCCAUX
#define MGTVCCAUX_EN_PIN 13
#define MGTVCCAUX_PG_PIN 12

// MGTAVCC
#define MGTAVCC_EN_PIN 15
#define MGTAVCC_PG_PIN 14

// MGTAVTT
#define MGTAVTT_EN_PIN 18
#define MGTAVTT_PG_PIN 17

// DDR4
#define DDR4_VDDQ_EN_PIN 20
#define DDR4_VPP_EN_PIN 20  /* Shared with VDDQ */
#define DDR4_VDDQ_PG_PIN 22
#define DDR4_VPP_PG_PIN 21

// FMC MISC
#define FMC_PRSNT_PIN 24
#define FMC_PG_C2M_PIN 25

// External watchdog
#define WDT_PIN 16

// SYSRST output
#define SYSRST_N_PIN 19

// Debug UART
#define DEBUG_UART_PORT uart0
#define DEBUG_UART_BAUDRATE 115200
#define DEBUG_UART_TX_PIN 28
#define DEBUG_UART_RX_PIN 29

// system reset macros
#define system_reset_pin_init() \
    do { \
        gpio_init(SYSRST_N_PIN); \
        gpio_put(SYSRST_N_PIN, 0); \
        gpio_set_dir(SYSRST_N_PIN, GPIO_OUT); \
    } while(0)

#define hold_system_reset() gpio_put(SYSRST_N_PIN, 0)
#define release_system_reset() gpio_put(SYSRST_N_PIN, 1)

/* BEGIN function prototypes */
void external_wdt_feed(void);
void board_init(void);

#endif // _BOARD_BOARD_H
