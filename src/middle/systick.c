#include "systick.h"
#include "gd32c10x.h"

static volatile uint32_t g_tick = 0;

void systick_init(void)
{
    SysTick_Config(SystemCoreClock / 1000U);
}

void systick_tick(void)
{
    g_tick++;
}

uint32_t systick_get_tick(void)
{
    return g_tick;
}

void systick_delay_ms(uint32_t ms)
{
    uint32_t start = g_tick;
    while ((g_tick - start) < ms) {}
}

void systick_delay_us(uint32_t us)
{
    uint32_t ticks = us * (SystemCoreClock / 1000000U);
    SysTick->LOAD = ticks - 1U;
    SysTick->VAL  = 0U;
    SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_ENABLE_Msk;
    while (!(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {}
    SysTick->CTRL = 0U;
}
