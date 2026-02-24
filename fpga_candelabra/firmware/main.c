#include <stdio.h>
#include "board/board.h"
#include "board/lmk03328.h"
#include "board/power_sequence.h"
#include "board/sysmon.h"
#include "pico/stdlib.h"
#include "hardware/i2c.h"
#include "hardware/watchdog.h"
#include "hardware/uart.h"

#ifdef DEBUG
#include <tusb.h>
#endif

#define LOG_TAG "MAIN"
#include "log.h"

void hang(void) {
    LOG("!!! HANGING !!!\n");
    while (true) {
        sleep_ms(100);
        external_wdt_feed();
    }
}

// I2C reserves some addresses for special purposes. We exclude these from the scan.
// These are any addresses of the form 000 0xxx or 111 1xxx
bool reserved_addr(uint8_t addr) {
    return (addr & 0x78) == 0 || (addr & 0x78) == 0x78;
}

int main()
{
    int ret;

    stdio_init_all();

    system_reset_pin_init();

// #ifdef DEBUG
//     // Wait for usb cdc connection
//     while (!tud_cdc_connected()) {
//         external_wdt_feed();
//         sleep_ms(100);
//     }
// #endif

    // Initialise board
    board_init();

    LOG("Hello, world!\n");
    sleep_ms(1000);

    // Power up sequence
    ret = power_up_sequence();
    if (ret != 0) {
        LOG("Power up sequence failed, return code: %d\n", ret);
        hang();
    }

    // Initialise LMK03328
    ret = lmk03328_init();
    if (ret != 0) {
        LOG("LMK03328 init failed, return code: %d\n", ret);
        hang();
    }

    // Release SYSRST_N_PIN
    release_system_reset();
    LOG("System reset done\n");

    // Main loop
    uint32_t counter = 0;
    while (true) {
        external_wdt_feed();
        counter++;
        sleep_ms(100);

        if (counter % 50 == 0) {
            uint8_t int_live;
            lmk03328_read_reg(13, &int_live);
            LOG("INT_LIVE: 0x%02x\n", int_live);
            sysmon_dump_status();
        }
    }
}
