#include "board/board.h"
#include "board/power_sequence.h"
#include "board/vadj.h"

#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/gpio.h"
#include "hardware/i2c.h"

/*
 * Initialise debug UART
*/
void debug_uart_init(void) {
    uart_init(DEBUG_UART_PORT, DEBUG_UART_BAUDRATE);
    gpio_set_function(DEBUG_UART_TX_PIN, GPIO_FUNC_UART);
    gpio_set_function(DEBUG_UART_RX_PIN, GPIO_FUNC_UART);
}

/*
 * Put string to debug UART
*/
void debug_uart_puts(const char *str) {
    uart_puts(DEBUG_UART_PORT, str);
}

/*
 * Initialise the external watchdog pin
*/
void external_wdt_init(void) {
    gpio_init(WDT_PIN);
    gpio_set_dir(WDT_PIN, GPIO_OUT);
    gpio_put(WDT_PIN, 0);
}

/*
 * Toggle the external watchdog pin
 * This function needs to be called at least once every 610ms
*/
void external_wdt_feed(void) {
    gpio_put(WDT_PIN, !gpio_get(WDT_PIN));
}

/*
 * Management I2C initialization
*/
void mgmt_i2c_init(void) {
    // Initialise the I2C bus at 400kHz
    i2c_init(MGMT_I2C_PORT, 400 * 1000);
    gpio_set_function(MGMT_I2C_SDA, GPIO_FUNC_I2C);
    gpio_set_function(MGMT_I2C_SCL, GPIO_FUNC_I2C);
    gpio_pull_up(MGMT_I2C_SDA);
    gpio_pull_up(MGMT_I2C_SCL);

    // Make the I2C pins available to picotool via binary info
    bi_decl(bi_2pins_with_func(MGMT_I2C_SDA, MGMT_I2C_SCL, GPIO_FUNC_I2C));
}

/*
 * Management I2C write
*/
int mgmt_i2c_write_blocking(uint8_t addr, const uint8_t *src, size_t len, bool nostop) {
    // return i2c_write_blocking(MGMT_I2C_PORT, addr, src, len, nostop);
    return i2c_write_timeout_per_char_us(MGMT_I2C_PORT, addr, src, len, nostop, 200);
}

/*
 * Management I2C read
*/
int mgmt_i2c_read_blocking(uint8_t addr, uint8_t *dst, size_t len, bool nostop) {
    return i2c_read_timeout_per_char_us(MGMT_I2C_PORT, addr, dst, len, nostop, 200);
}

/*
 * Board overall initialization
*/
void board_init(void) {
    debug_uart_init();
    external_wdt_init();
    mgmt_i2c_init();
    power_up_sequence_init();
}
