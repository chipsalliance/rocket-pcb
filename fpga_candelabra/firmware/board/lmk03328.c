#include <stdio.h>
#include "board/board.h"
#include "board/lmk03328.h"

#include "pico/stdlib.h"
#include "hardware/i2c.h"

#define LOG_TAG "LMK03328"
#include "log.h"

int lmk03328_read_reg(uint8_t reg, uint8_t *data) {
    // write register address
    uint8_t buf[1];
    buf[0] = reg;
    int ret = mgmt_i2c_write_blocking(MGMT_I2C_ADDR_LMK03328_PLL, buf, 1, true);
    if (ret < 0) {
        LOG("Failed to write register address, return code: %d\n", ret);
        return ret;
    }

    // read data
    ret = mgmt_i2c_read_blocking(MGMT_I2C_ADDR_LMK03328_PLL, buf, 1, false);
    if (ret < 0) {
        LOG("Failed to read data, return code: %d\n", ret);
        return ret;
    }
    *data = buf[0];

    return 0;
}

int lmk03328_write_reg(uint8_t reg, uint8_t data) {
    uint8_t buf[2];
    buf[0] = reg;
    buf[1] = data;
    int ret = mgmt_i2c_write_blocking(MGMT_I2C_ADDR_LMK03328_PLL, buf, 2, false);
    if (ret < 0) {
        LOG("Failed to write data, return code: %d\n", ret);
        return ret;
    }
    return 0;
}

int lmk03328_dump_regs(void) {
    uint8_t data;
    int ret;
    
    for (int i = 0; i <= 144; i++) {
        ret = lmk03328_read_reg(i, &data);
        if (ret != 0) return ret;

        if (i % 16 == 0) LOG(" REG [%03d - %03d]: ", i, i + 15);
        printf("0x%02x ", data);

        if (i % 16 == 15) printf("\n");
    }

    printf("\n");

    return 0;
}

int lmk03328_write_config(void) {
    int entries = sizeof(lmk03328_config_data) / sizeof(lmk03328_config_data[0]);
    LOG("Writing %d registers\n", entries);
    
    for (int i = 0; i < entries; i++) {
        int ret = lmk03328_write_reg(lmk03328_config_data[i][0], lmk03328_config_data[i][1]);
        if (ret != 0) return ret;
    }
    return 0;
}
