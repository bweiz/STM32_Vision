// main.c

#include <watchdog.h>

int main(void) {
    volatile unsigned int x = 0;

    while(1) {
        x++;
    }
}
