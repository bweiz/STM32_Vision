// main.c

#include <watchdog.h>
#include "gpio.h"
#include "timer.h"
#include "event.h"

int main(void) {
    watchdog_init(64000000u);
    event_init();    
    event_trigger();
    
    while(1) {
    }
}
