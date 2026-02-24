#ifndef _BOARD_CDCM6208_H
#define _BOARD_CDCM6208_H

#include "pico/stdlib.h"

/* BEGIN CDCM6208 Generated Config */
static const uint16_t cdcm6208_config_data[][2] = {
    {0, 0x01B1},
    {1, 0x0000},
    {2, 0x0018},
    {3, 0x00F0},
    {4, 0x30E8},
    {5, 0x0182},
    {6, 0x0003},
    {7, 0x0182},
    {8, 0x0003},
    {9, 0x0202},
    {10, 0x0022},
    {11, 0x0000},
    {12, 0x0202},
    {13, 0x0022},
    {14, 0x0000},
    {15, 0x0202},
    {16, 0x0022},
    {17, 0x0900},
    {18, 0x0018},
    {19, 0x0000},
    {20, 0x0000},
    {21, 0x0000},
    {40, 0x0000}
};

/* END CDCM6208 Generated Config */

/* BEGIN function prototypes */
int cdcm6208_dump_regs(void);
int cdcm6208_write_config(void);

#endif // _BOARD_CDCM6208_H