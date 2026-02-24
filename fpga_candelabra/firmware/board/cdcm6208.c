#include <stdio.h>
#include "board/board.h"
#include "board/cdcm6208.h"

#include "pico/stdlib.h"
#include "hardware/i2c.h"

#define LOG_TAG "CDCM6208"
#include "log.h"

int cdcm6208_read_reg(uint8_t reg, uint16_t *data) {
    // write register address twice
    uint8_t buf[2];
    buf[0] = 0x00; // reg;
    buf[1] = reg;
    int ret = mgmt_i2c_write_blocking(MGMT_I2C_ADDR_CDCM6208_PLL, buf, 2, false);
    if (ret < 0) {
        LOG("Failed to write register address, return code: %d\n", ret);
        return ret;
    }

    sleep_us(100);

    // read data
    ret = mgmt_i2c_read_blocking(MGMT_I2C_ADDR_CDCM6208_PLL, buf, 2, false);
    if (ret < 0) {
        LOG("Failed to read data, return code: %d\n", ret);
        return ret;
    }
    *data = (buf[0] << 8) | buf[1];

    sleep_ms(1);

    return 0;
}

int cdcm6208_write_reg(uint8_t reg, uint16_t data) {
    uint8_t buf[4];
    buf[0] = 0x00; //reg;
    buf[1] = reg;
    buf[2] = data >> 8;
    buf[3] = data & 0xff;
    int ret = mgmt_i2c_write_blocking(MGMT_I2C_ADDR_CDCM6208_PLL, buf, 4, false);
    if (ret < 0) {
        LOG("Failed to write data, return code: %d\n", ret);
        return ret;
    }
    sleep_ms(1);
    
    return 0;
}

int cdcm6208_read_reg_with_retry(uint8_t reg, uint16_t *data, int retry) {
    for (int i = 0; i < retry; i++) {
        int ret = cdcm6208_read_reg(reg, data);
        if (ret == 0) return 0;
    }
    return -1;
}

int cdcm6208_write_reg_with_retry(uint8_t reg, uint16_t data, int retry) {
    for (int i = 0; i < retry; i++) {
        int ret = cdcm6208_write_reg(reg, data);
        if (ret == 0) return 0;
    }
    return -1;
}

int cdcm6208_dump_regs(void) {
    uint16_t data;
    int ret;
    
    for (int i = 0; i <= 20; i++) {
        ret = cdcm6208_read_reg_with_retry(i, &data, 3);
        if (ret != 0) return ret;
        LOG("Register %d: 0x%04x\n", i, data);
    }

    // Register 21 & 40 are read only
    ret = cdcm6208_read_reg_with_retry(21, &data, 3);
    if (ret != 0) return ret;
    LOG("Register 21: 0x%04x\n", data);
    
    ret = cdcm6208_read_reg_with_retry(40, &data, 3);
    if (ret != 0) return ret;
    LOG("Register 40: 0x%04x\n", data);

    // uint8_t buf[256];
    // buf[0] = 0x00;
    // buf[1] = 0x00;  // start dump from register 0

    // ret = mgmt_i2c_write_blocking(MGMT_I2C_ADDR_CDCM6208_PLL, buf, 2, true);
    // if (ret < 0) {
    //     LOG("Failed to write data, return code: %d\n", ret);
    //     return ret;
    // }
    // sleep_ms(1);
 
    // ret = mgmt_i2c_read_blocking(MGMT_I2C_ADDR_CDCM6208_PLL, buf, 82, false);
    // if (ret < 0) {
    //     LOG("Failed to read data, return code: %d\n", ret);
    //     return ret;
    // }

    // for (int i = 0; i <= 40; i++) {
    //     if (i > 20 && i < 40) continue;
    //     LOG("Register %d: 0x%04x\n", i, (buf[i * 2] << 8) | buf[i * 2 + 1]);
    // }

    return 0;
}

int cdcm6208_write_config(void) {
    int entries = sizeof(cdcm6208_config_data) / sizeof(cdcm6208_config_data[0]);
    for (int i = 0; i < entries; i++) {
        int ret = cdcm6208_write_reg_with_retry(cdcm6208_config_data[i][0], cdcm6208_config_data[i][1], 3);
        if (ret != 0) return ret;
    }
    return 0;
}