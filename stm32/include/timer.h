#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

void event_timer_init(void);
void TIM3_IRQHandler(void);
void start_event_timer(void);

void watchdog_timer_init(uint32_t tim2_clock_hz);
void TIM2_IRQHandler(void);

#endif
