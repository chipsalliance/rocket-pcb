#include <stdio.h>
#include "board/board.h"
#include "board/sysmon.h"

#include "pico/stdlib.h"
#include "hardware/i2c.h"

#define LOG_TAG "SYSMON"
#include "log.h"

float sysmon_adc_to_temp(uint16_t adc) {
    return (float)adc * 509.3140064f / 65536.0f - 280.23087870f;
}

float sysmon_adc_to_voltage(uint16_t adc) {
    return (float)adc / 65536.0f * 3.0f;
}

int sysmon_read_reg(uint16_t daddr, uint16_t *data) {
    uint32_t drp_cmd = DRP_CMD_READ(daddr);
    int ret;

    ret = sysmon_i2c_write_blocking(SYSMON_I2C_ADDR_SLR0, (uint8_t *)&drp_cmd, sizeof(drp_cmd), true);
    if (ret < 0) {
        LOG("Failed to write DRP command, return code: %d\n", ret);
        return ret;
    }

    ret = sysmon_i2c_read_blocking(SYSMON_I2C_ADDR_SLR0, (uint8_t *)data, sizeof(*data), false);
    if (ret < 0) {
        LOG("Failed to read DRP data, return code: %d\n", ret);
        return ret;
    }

    return 0;
}

int sysmon_read_temperature(uint16_t addr, float *temp) {
    uint16_t data;
    int ret;

    ret = sysmon_read_reg(addr, &data);
    if (ret < 0) {
        return ret;
    }

    *temp = sysmon_adc_to_temp(data);

    return 0;
}

int sysmon_read_voltage(uint16_t addr, float *voltage) {
    uint16_t data;
    int ret;

    ret = sysmon_read_reg(addr, &data);
    if (ret < 0) {
        return ret;
    }

    *voltage = sysmon_adc_to_voltage(data);

    return 0;
}

int sysmon_dump_status(void) {
    float temp;
    float voltage;

    // temperature
    sysmon_read_temperature(DRP_ADDR_TEMPERATURE, &temp);
    LOG("Temperature: %.2f C\n", temp);

    sysmon_read_temperature(DRP_ADDR_TEMPERATURE_MAX, &temp);
    LOG("Temperature Max: %.2f C\n", temp);

    // voltages
    sysmon_read_voltage(DRP_ADDR_VCCINT, &voltage);
    LOG("VCCINT: %.2f V\n", voltage);

    sysmon_read_voltage(DRP_ADDR_VCCAUX, &voltage);
    LOG("VCCAUX: %.2f V\n", voltage);

    sysmon_read_voltage(DRP_ADDR_VP_VN, &voltage);
    LOG("VP_VN: %.2f V\n", voltage);

    sysmon_read_voltage(DRP_ADDR_VREFP, &voltage);
    LOG("VREFP: %.2f V\n", voltage);

    sysmon_read_voltage(DRP_ADDR_VREFN, &voltage);
    LOG("VREFN: %.2f V\n", voltage);

    return 0;
}