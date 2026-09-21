#include "stm32h723xx.h"
#include "watchdog.h"
#include "gpio.h"

void watchdog_init(uint32_t tim2_clock_hz) {
    // Init PE1 LED
    // Enable TIM2 peripheral clock
    // PSC
    // ARR
    // enable interrupt
    // enable TIM2 IRQ in NVIC
    // start TIM2

 // ---------------- Watchdog Timer TIM2 ---------------------

    watchdog_led_init();

    // Supply TIM2 a clock
    RCC->APB1LENR |= RCC_APB1LENR_TIM2EN;

    // TIM2 clock = 64 MHz
    // PSC = 63999
    // 64_000_000 / (PSC + 1) = 1000 Hz
    TIM2->PSC = ( tim2_clock_hz / 1000u ) - 1;

    // 1000 counts * 1ms = 1sec
    TIM2->ARR = 999;

    // TIM2 load new config
    TIM2->EGR |= TIM_EGR_UG;

    //  Allow TIM2 update events to request an interrupt
    TIM2->DIER |= TIM_DIER_UIE;

    //  Configure Cortex-M NVIC side
    NVIC_ClearPendingIRQ(TIM2_IRQn);
    NVIC_EnableIRQ(TIM2_IRQn);

    //  Start counting
    TIM2->CR1 |= TIM_CR1_CEN;

// -------------- End Watchdog Timer TIM2 -------------------
   
}

void watchdog_kick(void) {
    // Nothing for now
}


void TIM2_IRQHandler(void) {
    // Check interrupt flag
    // clear
    // toggle P1
    if (TIM2->SR & TIM_SR_UIF) {
        TIM2->SR &= ~(TIM_SR_UIF);
        watchdog_led_toggle();
    }
}
