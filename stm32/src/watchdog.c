#include "stm32h723xx.h"
#include "watchdog.h"
#include "gpio.h"
#include "timer.h"
void watchdog_init(uint32_t tim2_clock_hz)
{
    watchdog_timer_init(tim2_clock_hz);
}
void watchdog_kick(void) 
{
    // Nothing for now
}


