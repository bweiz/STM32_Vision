#ifndef GPIO_H
#define GPIO_H

void watchdog_led_init(void);
void watchdog_led_on(void);
void watchdog_led_off(void);
void watchdog_led_toggle(void);

void event_gpio_init(void);
void event_gpio_high(void);
void event_gpio_low(void);

#endif
