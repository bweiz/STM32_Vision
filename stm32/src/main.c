// main.c

#include <watchdog.h>
#include "gpio.h"
#include "timer.h"
#include "event.h"

int main(void) {
    watchdog_init(64000000u);
    event_init();       

    while(1)
    {
        event_trigger();
        for(int i = 0; i < 1000000u; i++){};
    }
}
