#ifndef WATCHDOG_H
#define WATCHDOG_H

#include <stdint.h>

void watchdog_init(uint32_t core_clock_hz);
void watchdog_kick(void);

#endif
