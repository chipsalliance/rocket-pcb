#include <stdio.h>
#include "board/board.h"
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
    stdio_init_all();

#ifdef DEBUG
    // Wait for usb cdc connection
    while (!tud_cdc_connected()) {
        sleep_ms(100);
    }
#endif

    // Initialise board
    board_init();

    // Power up sequence
    int ret = power_up_sequence();
    if (ret != 0) {
        LOG("Power up sequence failed, return code: %d\n", ret);
        hang();
    }

    while (true) {
        LOG("Hello, world!\n");
        sleep_ms(1000);
    }
}
