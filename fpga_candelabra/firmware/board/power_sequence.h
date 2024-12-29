#ifndef _BOARD_POWER_SEQUENCE_H
#define _BOARD_POWER_SEQUENCE_H

#include "board/board.h"

// Rail pins
#define RAIL_ENABLE_PIN(RAIL) (RAIL ## _EN_PIN)
#define RAIL_PGOOD_PIN(RAIL) (RAIL ## _PG_PIN)

#define init_rail_enable_pin(RAIL) \
    do { \
        gpio_init(RAIL_ENABLE_PIN(RAIL)); \
        gpio_put(RAIL_ENABLE_PIN(RAIL), 0); \
        gpio_set_dir(RAIL_ENABLE_PIN(RAIL), GPIO_OUT); \
    } while(0)

#define init_rail_pgood_pin(RAIL) \
    do { \
        gpio_init(RAIL_PGOOD_PIN(RAIL)); \
        gpio_pull_down(RAIL_PGOOD_PIN(RAIL)); \
        gpio_set_dir(RAIL_PGOOD_PIN(RAIL), GPIO_IN); \
    } while(0)

// Utility macros
#define POWERUP_TIMEOUT 200
#define POWERUP_CHECK_DELAY 5
#define POWERUP_SEQUENCE_DELAY 50

#define power_rail_enable(RAIL) \
    do { \
        gpio_put(RAIL_ENABLE_PIN(RAIL), 1); \
    } while(0)

#define wait_rail_pgood(RAIL, result) \
    do { \
        result = -1; \
        for (int wait = 0; wait < POWERUP_TIMEOUT; wait += POWERUP_CHECK_DELAY) { \
            if (gpio_get(RAIL_PGOOD_PIN(RAIL))) { \
                result = 0; \
                break; \
            } \
            sleep_ms(POWERUP_CHECK_DELAY); \
            external_wdt_feed(); \
        } \
    } while(0)

/* BEGIN function prototypes */
void power_up_sequence_init(void);
int power_up_sequence(void);

#endif // _BOARD_POWER_SEQUENCE_H
