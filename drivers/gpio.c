#include "stm32h723xx.h"
#include "gpio.h"

/*
 *   Peripheral: GPIOE
 *   Pin:        1
 *
 *   Register       Field               Desired
 *   ------------------------------------------------
 *   MODER          MODER1 [3:2]        01 output
 *   OTYPER         OT1    [1]          0 push-pull
 *   OSPEEDR        OSPEED1 [3:2]       00 low
 *   PUPDR          PUPD1  [3:2]        00 none
 *   BSRR           BS1    [1]          write 1 = high
 *   BSRR           BR1    [17]         write 1 = low
 */

void watchdog_led_init(void) {

// ----------------------- LED ------------------------------
    // Give a clock to PE1
    RCC->AHB4ENR |= RCC_AHB4ENR_GPIOEEN;
    (void)RCC->AHB4ENR;
    // Mode Register: clear and set to 01
    GPIOE->MODER &= ~(3u << 2);
    GPIOE->MODER |= (1u << 2);          // Output

    // Output Type Register
    GPIOE->OTYPER &= ~(1u << 1);        // Push-Pull
    
    // Output speed
    GPIOE->OSPEEDR &= ~(0x3u << 2);    // Low-speed

    // PullUp PullDown
    GPIOE->PUPDR &= ~(0x3u << 2);      // No pull

    // Start with LED off 
    GPIOE->BSRR = (1u << 17);

// --------------------- End LED ----------------------------

}

void watchdog_led_on(void) {
    GPIOE->BSRR = (1u << 1);
}

void watchdog_led_off(void) {
    GPIOE->BSRR = (1u << 17);
}

void watchdog_led_toggle(void) {
    if (GPIOE->ODR & (1u << 1))
    {
        watchdog_led_off();
    }
    else
    {
        watchdog_led_on();
    }
}
