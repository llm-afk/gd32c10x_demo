#ifndef SYSTICK_H
#define SYSTICK_H

#include <stdint.h>

void systick_init(void);
uint32_t systick_get_tick(void);
void systick_tick(void);
void systick_delay_ms(uint32_t ms);
void systick_delay_us(uint32_t us);

#endif
