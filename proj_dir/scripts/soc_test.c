#include <stdint.h>

/* --- UART Registers --- */
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

/* --- I2C Registers --- */
#define I2C_BASE    0x00000000UL
#define I2C_PRER_LO (*(volatile uint32_t *)(I2C_BASE + 0x00))
#define I2C_PRER_HI (*(volatile uint32_t *)(I2C_BASE + 0x04))
#define I2C_CTR     (*(volatile uint32_t *)(I2C_BASE + 0x08))
#define I2C_TXR     (*(volatile uint32_t *)(I2C_BASE + 0x0C))
#define I2C_RXR     (*(volatile uint32_t *)(I2C_BASE + 0x0C))
#define I2C_CR      (*(volatile uint32_t *)(I2C_BASE + 0x10))
#define I2C_SR      (*(volatile uint32_t *)(I2C_BASE + 0x10))

/* --- AES Registers --- */
#define AES_BASE    0x01000000UL
#define AES_CTRL    (*(volatile uint32_t *)(AES_BASE + 0x00))
#define AES_STATUS  (*(volatile uint32_t *)(AES_BASE + 0x04))
#define AES_KEY0    (*(volatile uint32_t *)(AES_BASE + 0x08))
#define AES_KEY1    (*(volatile uint32_t *)(AES_BASE + 0x0C))
#define AES_KEY2    (*(volatile uint32_t *)(AES_BASE + 0x10))
#define AES_KEY3    (*(volatile uint32_t *)(AES_BASE + 0x14))
#define AES_TXIN0   (*(volatile uint32_t *)(AES_BASE + 0x18))
#define AES_TXIN1   (*(volatile uint32_t *)(AES_BASE + 0x1C))
#define AES_TXIN2   (*(volatile uint32_t *)(AES_BASE + 0x20))
#define AES_TXIN3   (*(volatile uint32_t *)(AES_BASE + 0x24))
#define AES_TXOUT0  (*(volatile uint32_t *)(AES_BASE + 0x28))
#define AES_TXOUT1  (*(volatile uint32_t *)(AES_BASE + 0x2C))
#define AES_TXOUT2  (*(volatile uint32_t *)(AES_BASE + 0x30))
#define AES_TXOUT3  (*(volatile uint32_t *)(AES_BASE + 0x34))


static void uart_init(void)
{
    UART_LCR = 0x83;
    UART_BAUD = BAUD_DIV;
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
    uint8_t tx_data, rx_data;
    uint8_t all_pass = 1;

    /* 1. UART Initialization */
    uart_init();

    /* 2. I2C Test: Write and Readback Registers */
    I2C_PRER_LO = 0x63;
    I2C_PRER_HI = 0x00;
    I2C_CTR     = 0x80; /* Enable I2C core */

    /* Masking with 0xFF because underlying registers are 8-bit */
    if ((I2C_PRER_LO & 0xFF) != 0x63 || (I2C_CTR & 0xFF) != 0x80) {
        all_pass = 0;
    }

    /* 3. AES Test: Encrypt NIST Test Vector */
    AES_KEY0 = 0x2b7e1516;
    AES_KEY1 = 0x28aed2a6;
    AES_KEY2 = 0xabf71588;
    AES_KEY3 = 0x09cf4f3c;

    AES_TXIN0 = 0x3243f6a8;
    AES_TXIN1 = 0x885a308d;
    AES_TXIN2 = 0x313198a2;
    AES_TXIN3 = 0xe0370734;

    /* Trigger Encryption (bit 0 of CTRL) */
    AES_CTRL = 0x01;

    /* Wait for Encryption to Complete (bit 0 of STATUS) */
    while ((AES_STATUS & 0x01) == 0)
        ;

    /* Verify Ciphertext Output */
    if (AES_TXOUT0 != 0x3925841d ||
        AES_TXOUT1 != 0x02dc09fb ||
        AES_TXOUT2 != 0xdc118597 ||
        AES_TXOUT3 != 0x196a0b32) {
        all_pass = 0;
    }

    /* 4. UART Loopback Test */
    tx_data = 0x41; /* 'A' */
    uart_putc(tx_data);
    rx_data = uart_getc();

    if (rx_data != tx_data) {
        all_pass = 0;
    }

    /* 5. Result Reporting */
    if (all_pass) {
        uart_putc('P'); /* PASS */
    } else {
        uart_putc('F'); /* FAIL */
    }

    /* Spin Forever */
    while (1)
        ;

    return 0;
}
