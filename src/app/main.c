#include "gd32c10x.h"
#include "SEGGER_RTT.h"
#include "systick.h"

uint32_t data;

int main(void)
{
    systick_init();
    static uint8_t rtt_1_buf[1024] = {0};
    SEGGER_RTT_ConfigUpBuffer(1, "JScope_u4", rtt_1_buf, sizeof(rtt_1_buf), SEGGER_RTT_MODE_NO_BLOCK_SKIP);

    while(1)
    {
        SEGGER_RTT_printf(0, "[%d]Hello\r\n", data);
        SEGGER_RTT_Write(1, &data, 4);
        data++;
        systick_delay_ms(1);
    }
}
