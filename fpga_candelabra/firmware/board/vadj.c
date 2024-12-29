#include <stdio.h>
#include <math.h>
#include "board/vadj.h"
#include "board/board.h"
#include "pico/stdlib.h"
#include "hardware/i2c.h"

#define LOG_TAG "VADJ"
#include "log.h"

/*
 * Write DAC value to MCP4725
*/
int mcp4725_dac_write(uint16_t value) {
    uint8_t data[3];
    if (value > 4095) {
        value = 4095;
    }

    data[0] = MCP4725_CMD_WRITE_REG;
    data[1] = (value >> 4) & 0xff;
    data[2] = (value & 0x0f) << 4;

    LOG("Writing DAC value: %d\n", value);

    int ret = i2c_write_blocking(MGMT_I2C_PORT, MGMT_I2C_ADDR_FMC_VADJ_DAC, data, 3, false);
    if (ret < 0) {
        LOG("Failed to write DAC value, return code: %d\n", ret);
        return ret;
    }

    return 0;
}

/*
 * Convert voltage to DAC value
 * Reference: 
 * https://www.analog.com/en/resources/technical-articles/digital-adjustment-of-dcdc-converter-output-voltage-in-portable-applications.html
*/
uint16_t voltage_to_dac_value(float voltage) {
    // Vout = Vref*(1+R1/R2+R1/R3) - Vdac*(R1/R3)
    // Vdac = (Vref*(1+R1/R2+R1/R3) - Vout)*(R3/R1)

    float step1 = FMC_VADJ_DCDC_VREF * (1 + FMC_VADJ_FB_R1 / FMC_VADJ_FB_R2 + FMC_VADJ_FB_R1 / FMC_VADJ_FB_R3);
    float step2 = (step1 - voltage) * (FMC_VADJ_FB_R3 / FMC_VADJ_FB_R1);
    float step3 = step2 / (3.3f / 4096.0f);

    // sanity check
    if ((uint16_t)step3 > 4095 || (uint16_t)step3 < 0) {
        LOG("Invalid target voltage: %.3fV, calculated DAC value: %.1f\n", voltage, step3);
        return 4095; // max DAC value for lowest voltage
    }

    return (uint16_t)roundf(step3);
}

/*
 * Set VADJ DAC voltage
*/
int vadj_set_voltage(float voltage) {
    LOG("Setting voltage to %.3fV\n", voltage);
    return mcp4725_dac_write(voltage_to_dac_value(voltage));
}
