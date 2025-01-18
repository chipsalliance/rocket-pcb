#include <stdio.h>
#include "board/power_sequence.h"
#include "board/vadj.h"
#include "pico/stdlib.h"

#define LOG_TAG "PSEQ"
#include "log.h"

// NOTE: power up sequence is as follows:
// 1. Wait on V5V_MAIN power good
// 2. Power on and wait VCCINT
// 3. Power on and wait MGTAVCC & MGTVCCAUX
// 4. Power on and wait MGTAVTT
// 5. Power on and wait VCCAUX
// 6. Power on and wait DDR4_VDDQ & DDR4_VPP
// 7. Power on and wait FMC_3P3V
// 8. Set DAC voltage of FMC_VADJ
// 9. Power on and wait FMC_VADJ
// 10. Release SYSRST_N_PIN

/*
 * Initialise board power up sequence with all rail GPIOs
*/
void power_up_sequence_init(void) {
    init_rail_pgood_pin(V5V_MAIN);

    init_rail_enable_pin(VCCINT);
    init_rail_pgood_pin(VCCINT);
    gpio_init(PMBUS_ALERT_PIN);
    gpio_set_dir(PMBUS_ALERT_PIN, GPIO_IN);

    init_rail_enable_pin(MGTAVCC);
    init_rail_enable_pin(MGTVCCAUX);
    init_rail_pgood_pin(MGTAVCC);
    init_rail_pgood_pin(MGTVCCAUX);

    init_rail_enable_pin(MGTAVTT);
    init_rail_pgood_pin(MGTAVTT);

    init_rail_enable_pin(VCCAUX);
    init_rail_pgood_pin(VCCAUX);

    init_rail_enable_pin(DDR4_VDDQ);
    init_rail_enable_pin(DDR4_VPP);
    init_rail_pgood_pin(DDR4_VDDQ);
    init_rail_pgood_pin(DDR4_VPP);

    init_rail_enable_pin(FMC_3P3V);
    init_rail_pgood_pin(FMC_3P3V);

    init_rail_enable_pin(FMC_VADJ);
    init_rail_pgood_pin(FMC_VADJ);
}

/*
 * Start board power up sequence
 * Return: 0 on success, -1 on failure
*/
int power_up_sequence(void) {
    int ret = 0;

    // Step 1: Wait on V5V_MAIN power good
    wait_rail_pgood(V5V_MAIN, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 1:\n");
        LOG("  Failed to wait on V5V_MAIN power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 2: Power on and wait VCCINT
    power_rail_enable(VCCINT);
    wait_rail_pgood(VCCINT, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 2:\n");
        LOG("  Failed to wait on VCCINT power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 3: Power on and wait MGTAVCC & MGTVCCAUX
    power_rail_enable(MGTAVCC);
    power_rail_enable(MGTVCCAUX);
    wait_rail_pgood(MGTAVCC, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 3:\n");
        LOG("  Failed to wait on MGTAVCC power good\n");
        return -1;
    }
    wait_rail_pgood(MGTVCCAUX, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 3:\n");
        LOG("  Failed to wait on MGTVCCAUX power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 4: Power on and wait MGTAVTT
    power_rail_enable(MGTAVTT);
    wait_rail_pgood(MGTAVTT, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 4:\n");
        LOG("  Failed to wait on MGTAVTT power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 5: Power on and wait VCCAUX
    power_rail_enable(VCCAUX);
    wait_rail_pgood(VCCAUX, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 5:\n");
        LOG("  Failed to wait on VCCAUX power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 6: Power on and wait DDR4_VDDQ & DDR4_VPP
    power_rail_enable(DDR4_VDDQ);
    power_rail_enable(DDR4_VPP);
    wait_rail_pgood(DDR4_VDDQ, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 6:\n");
        LOG("  Failed to wait on DDR4_VDDQ power good\n");
        return -1;
    }
    wait_rail_pgood(DDR4_VPP, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 6:\n");
        LOG("  Failed to wait on DDR4_VPP power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 7: Power on and wait FMC_3P3V
    power_rail_enable(FMC_3P3V);
    wait_rail_pgood(FMC_3P3V, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 7:\n");
        LOG("  Failed to wait on FMC_3P3V power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    // Step 8: Set DAC voltage of FMC_VADJ
    // TODO: read voltage from IPMI records
    ret = vadj_set_voltage(1.8);
    if (ret != 0) {
        LOG("Power up sequence failed at step 8:\n");
        LOG("  Failed to set FMC_VADJ voltage\n");
        return -1;
    }
    sleep_ms(10);   // Wait for DAC to settle

    // Step 9: Power on and wait FMC_VADJ
    power_rail_enable(FMC_VADJ);
    wait_rail_pgood(FMC_VADJ, ret);
    if (ret != 0) {
        LOG("Power up sequence failed at step 9:\n");
        LOG("  Failed to wait on FMC_VADJ power good\n");
        return -1;
    }
    sleep_ms(POWERUP_SEQUENCE_DELAY);

    return 0;
}