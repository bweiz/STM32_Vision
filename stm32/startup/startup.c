#include <stdint.h>

/* Symbols supplied by linker/stm32h723.ld */
extern uint32_t _estack;

extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;

extern uint32_t _sbss;
extern uint32_t _ebss;

int main(void);

void Reset_Handler(void);
void Default_Handler(void);


/*
 * Any weak handler will resolve to Default_Handler unless
 * you provide a real function with the same name elsewhere.
 */
#define WEAK_DEFAULT_HANDLER(name) \
    void name(void) __attribute__((weak, alias("Default_Handler")))


/* Cortex-M7 exceptions */
WEAK_DEFAULT_HANDLER(NMI_Handler);
WEAK_DEFAULT_HANDLER(HardFault_Handler);
WEAK_DEFAULT_HANDLER(MemManage_Handler);
WEAK_DEFAULT_HANDLER(BusFault_Handler);
WEAK_DEFAULT_HANDLER(UsageFault_Handler);
WEAK_DEFAULT_HANDLER(SVC_Handler);
WEAK_DEFAULT_HANDLER(DebugMon_Handler);
WEAK_DEFAULT_HANDLER(PendSV_Handler);
WEAK_DEFAULT_HANDLER(SysTick_Handler);


/* STM32H723 external interrupts: IRQ 0 through IRQ 28 */
WEAK_DEFAULT_HANDLER(WWDG_IRQHandler);          // IRQ 0
WEAK_DEFAULT_HANDLER(PVD_AVD_IRQHandler);       // IRQ 1
WEAK_DEFAULT_HANDLER(TAMP_STAMP_IRQHandler);    // IRQ 2
WEAK_DEFAULT_HANDLER(RTC_WKUP_IRQHandler);      // IRQ 3
WEAK_DEFAULT_HANDLER(FLASH_IRQHandler);         // IRQ 4
WEAK_DEFAULT_HANDLER(RCC_IRQHandler);           // IRQ 5
WEAK_DEFAULT_HANDLER(EXTI0_IRQHandler);         // IRQ 6
WEAK_DEFAULT_HANDLER(EXTI1_IRQHandler);         // IRQ 7
WEAK_DEFAULT_HANDLER(EXTI2_IRQHandler);         // IRQ 8
WEAK_DEFAULT_HANDLER(EXTI3_IRQHandler);         // IRQ 9
WEAK_DEFAULT_HANDLER(EXTI4_IRQHandler);         // IRQ 10
WEAK_DEFAULT_HANDLER(DMA1_Stream0_IRQHandler);  // IRQ 11
WEAK_DEFAULT_HANDLER(DMA1_Stream1_IRQHandler);  // IRQ 12
WEAK_DEFAULT_HANDLER(DMA1_Stream2_IRQHandler);  // IRQ 13
WEAK_DEFAULT_HANDLER(DMA1_Stream3_IRQHandler);  // IRQ 14
WEAK_DEFAULT_HANDLER(DMA1_Stream4_IRQHandler);  // IRQ 15
WEAK_DEFAULT_HANDLER(DMA1_Stream5_IRQHandler);  // IRQ 16
WEAK_DEFAULT_HANDLER(DMA1_Stream6_IRQHandler);  // IRQ 17
WEAK_DEFAULT_HANDLER(ADC_IRQHandler);           // IRQ 18
WEAK_DEFAULT_HANDLER(FDCAN1_IT0_IRQHandler);    // IRQ 19
WEAK_DEFAULT_HANDLER(FDCAN2_IT0_IRQHandler);    // IRQ 20
WEAK_DEFAULT_HANDLER(FDCAN1_IT1_IRQHandler);    // IRQ 21
WEAK_DEFAULT_HANDLER(FDCAN2_IT1_IRQHandler);    // IRQ 22
WEAK_DEFAULT_HANDLER(EXTI9_5_IRQHandler);       // IRQ 23
WEAK_DEFAULT_HANDLER(TIM1_BRK_IRQHandler);      // IRQ 24
WEAK_DEFAULT_HANDLER(TIM1_UP_IRQHandler);       // IRQ 25
WEAK_DEFAULT_HANDLER(TIM1_TRG_COM_IRQHandler);  // IRQ 26
WEAK_DEFAULT_HANDLER(TIM1_CC_IRQHandler);       // IRQ 27
WEAK_DEFAULT_HANDLER(TIM2_IRQHandler);          // IRQ 28
WEAK_DEFAULT_HANDLER(TIM3_IRQHandler);          // IRQ 29

/*
 * Vector table.
 *
 * Entries 0-15 are fixed Cortex-M entries.
 * External STM32 IRQs begin at entry 16.
 *
 * Therefore:
 *
 * TIM2_IRQn = 28
 * vector index = 16 + 28 = 44
 */
__attribute__((used, section(".isr_vector")))
const uintptr_t vector_table[] = {

    /* Cortex-M7 core vectors */

    (uintptr_t)&_estack,              // 0  Initial stack pointer
    (uintptr_t)Reset_Handler,         // 1  Reset
    (uintptr_t)NMI_Handler,           // 2  NMI
    (uintptr_t)HardFault_Handler,     // 3  HardFault
    (uintptr_t)MemManage_Handler,     // 4  MemManage
    (uintptr_t)BusFault_Handler,      // 5  BusFault
    (uintptr_t)UsageFault_Handler,    // 6  UsageFault

    0,                                // 7  Reserved
    0,                                // 8  Reserved
    0,                                // 9  Reserved
    0,                                // 10 Reserved

    (uintptr_t)SVC_Handler,           // 11 SVCall
    (uintptr_t)DebugMon_Handler,      // 12 Debug monitor
    0,                                // 13 Reserved
    (uintptr_t)PendSV_Handler,        // 14 PendSV
    (uintptr_t)SysTick_Handler,       // 15 SysTick


    /* STM32 external interrupts */

    (uintptr_t)WWDG_IRQHandler,          // 16 + IRQ 0
    (uintptr_t)PVD_AVD_IRQHandler,       // 16 + IRQ 1
    (uintptr_t)TAMP_STAMP_IRQHandler,    // 16 + IRQ 2
    (uintptr_t)RTC_WKUP_IRQHandler,      // 16 + IRQ 3
    (uintptr_t)FLASH_IRQHandler,         // 16 + IRQ 4
    (uintptr_t)RCC_IRQHandler,           // 16 + IRQ 5
    (uintptr_t)EXTI0_IRQHandler,         // 16 + IRQ 6
    (uintptr_t)EXTI1_IRQHandler,         // 16 + IRQ 7
    (uintptr_t)EXTI2_IRQHandler,         // 16 + IRQ 8
    (uintptr_t)EXTI3_IRQHandler,         // 16 + IRQ 9
    (uintptr_t)EXTI4_IRQHandler,         // 16 + IRQ 10
    (uintptr_t)DMA1_Stream0_IRQHandler,  // 16 + IRQ 11
    (uintptr_t)DMA1_Stream1_IRQHandler,  // 16 + IRQ 12
    (uintptr_t)DMA1_Stream2_IRQHandler,  // 16 + IRQ 13
    (uintptr_t)DMA1_Stream3_IRQHandler,  // 16 + IRQ 14
    (uintptr_t)DMA1_Stream4_IRQHandler,  // 16 + IRQ 15
    (uintptr_t)DMA1_Stream5_IRQHandler,  // 16 + IRQ 16
    (uintptr_t)DMA1_Stream6_IRQHandler,  // 16 + IRQ 17
    (uintptr_t)ADC_IRQHandler,           // 16 + IRQ 18
    (uintptr_t)FDCAN1_IT0_IRQHandler,    // 16 + IRQ 19
    (uintptr_t)FDCAN2_IT0_IRQHandler,    // 16 + IRQ 20
    (uintptr_t)FDCAN1_IT1_IRQHandler,    // 16 + IRQ 21
    (uintptr_t)FDCAN2_IT1_IRQHandler,    // 16 + IRQ 22
    (uintptr_t)EXTI9_5_IRQHandler,       // 16 + IRQ 23
    (uintptr_t)TIM1_BRK_IRQHandler,      // 16 + IRQ 24
    (uintptr_t)TIM1_UP_IRQHandler,       // 16 + IRQ 25
    (uintptr_t)TIM1_TRG_COM_IRQHandler,  // 16 + IRQ 26
    (uintptr_t)TIM1_CC_IRQHandler,       // 16 + IRQ 27
    (uintptr_t)TIM2_IRQHandler,          // 16 + IRQ 28 = entry 44
    (uintptr_t)TIM3_IRQHandler           // 16 + IRQ 29
};


/*
 * Runs immediately after reset.
 */
void Reset_Handler(void)
{
    /* Copy initialized .data from Flash to RAM */
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;

    while (dst < &_edata)
    {
        *dst++ = *src++;
    }

    /* Zero-initialize .bss */
    dst = &_sbss;

    while (dst < &_ebss)
    {
        *dst++ = 0;
    }

    main();

    /* main() should never return */
    while (1)
    {
    }
}


/*
 * Any unexpected exception/interrupt ends up here.
 *
 * This is deliberately an infinite loop because it gives
 * you somewhere useful to stop and inspect with GDB.
 */
void Default_Handler(void)
{
    while (1)
    {
    }
}
