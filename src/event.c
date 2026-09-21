#include "event.h"
#include "gpio.h"
#include "timer.h"

void event_init(void)
{
    event_gpio_init();
    event_timer_init();
}
void event_trigger(void)
{
    event_gpio_high();
    start_event_timer();
    
}
