#include "gd32c10x.h"
#include "systick_delay.h"

int main(void)
{
    rcu_periph_clock_enable(RCU_GPIOB);
    gpio_init(GPIOB, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_12);

    while (1) {
        gpio_bit_set(GPIOB, GPIO_PIN_12);
        systick_delay_ms(1000);
        gpio_bit_reset(GPIOB, GPIO_PIN_12);
        systick_delay_ms(1000);
    }
}
