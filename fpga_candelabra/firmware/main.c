#include <stdio.h>
#include "board/board.h"
#include "board/lmk03328.h"
#include "board/power_sequence.h"
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

int main()
{
    int ret;

    stdio_init_all();

    system_reset_pin_init();

#ifdef DEBUG
    // Wait for usb cdc connection
    while (!tud_cdc_connected()) {
        external_wdt_feed();
        sleep_ms(100);
    }
#endif

    sleep_ms(1000);

    // Initialise board
    board_init();

    // Power up sequence
    ret = power_up_sequence();
    if (ret != 0) {
        LOG("Power up sequence failed, return code: %d\n", ret);
        hang();
    }

    // Release SYSRST_N_PIN
    release_system_reset();

    LOG("System reset done\n");

    while (true) {
        external_wdt_feed();
        sleep_ms(100);
    }
}
