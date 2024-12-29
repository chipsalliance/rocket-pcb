#ifndef _LOG_H
#define _LOG_H

#include <stdio.h>

#ifndef LOG_TAG
#define LOG_TAG "NO_TAG"
#endif

#ifdef NO_LOGGING
#define LOG(fmt, ...) \
    do { } while (0)
#else
#define LOG(fmt, ...) \
    do { \
        printf("[%s] " fmt "", LOG_TAG, ##__VA_ARGS__); \
    } while (0)
#endif

#endif