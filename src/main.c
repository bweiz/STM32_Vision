// main.c

#include <watchdog.h>
#include "gpio.h"

int main(void) {
    watchdog_init(64000000u);

    while(1) {
    }
}
