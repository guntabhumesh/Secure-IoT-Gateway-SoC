#include <stdint.h>


#define UART_BASE   0x02000000UL

#define UART_THR    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_RBR    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_IER    (*(volatile uint32_t *)(UART_BASE + 0x04))
#define UART_BAUD   (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_LCR    (*(volatile uint32_t *)(UART_BASE + 0x0C))
#define UART_LSR    (*(volatile uint32_t *)(UART_BASE + 0x14))

#define LSR_DATA_READY   (1U << 0)
#define LSR_THRE         (1U << 5)
#define LSR_TEMT         (1U << 6)

#define BAUD_DIV         868U


static void uart_init(void)
{
        UART_LCR = 0x83;
    UART_LCR = 0x03;

    /* Enable RX interrupt */
    UART_IER = 0x01;
}


static void uart_putc(uint8_t data)
{
      while ((UART_LSR & LSR_THRE) == 0)
           ;

    UART_THR = data;
}


static uint8_t uart_getc(void)
{
    while ((UART_LSR & LSR_DATA_READY) == 0)
        ;

    return (uint8_t)(UART_RBR & 0xFF);
}


int main(void)
{
    uint8_t tx_data;
    uint8_t rx_data;

    uart_init();

    /* Send character 'A' = 0x41 */
    tx_data = 0x41;

    uart_putc(tx_data);

    /* Receive it back through UART loopback */
    rx_data = uart_getc();
    if (rx_data == tx_data)
    {
        /* Send 'P' to indicate PASS */
        uart_putc('P');
    }
    else
    {
        /* Send 'F' to indicate FAIL */
        uart_putc('F');
    }

    while (1)
        ;

    return 0;
}
