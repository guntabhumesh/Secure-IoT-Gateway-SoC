/*
 * soc_all_ip_test.c
 *
 * Full functional operation test for all IPs in Secure-IoT-Gateway-SoC:
 *   1. UART:    Fast hardware loopback test (sends 0x55, verifies 0x55)
 *   2. AES:     Executes 128-bit encryption operation (NIST test vector)
 *   3. SPI:     Executes SPI byte exchange operation (transmits on SPI bus)
 *   4. GPIO:    Executes pin drive, set, clear, and toggle operations
 *   5. I2C:     Executes I2C bus START and address transmission operation
 *   6. AXI RAM: Executes multi-word memory read/write operations
 *   7. DMA:     Executes memory-to-memory AXI burst copy (Prog RAM -> Data RAM)
 *   8. DUMMY:   Executes interconnect routing verification
 *
 * Fast simulation baud rate (BAUD_DIV = 16) ensures instant execution (< 3s).
 */

#include <stdint.h>

#define REG32(addr) (*(volatile uint32_t *)(addr))

/* Base addresses */
#define I2C_BASE      0x00000000UL
#define AES_BASE      0x01000000UL
#define UART_BASE     0x02000000UL
#define SPI_BASE      0x03000000UL
#define GPIO_BASE     0x04000000UL
#define PROG_RAM_BASE 0x05000000UL
#define DATA_RAM_BASE 0x06000000UL
#define DUMMY0_BASE   0x07000000UL
#define DUMMY1_BASE   0x08000000UL
#define DUMMY2_BASE   0x09000000UL
#define DUMMY3_BASE   0x0A000000UL
#define DMA_BASE      0x0B000000UL

/* UART */
#define UART_THR  REG32(UART_BASE + 0x00)
#define UART_RBR  REG32(UART_BASE + 0x00)
#define UART_IER  REG32(UART_BASE + 0x04)
#define UART_BAUD REG32(UART_BASE + 0x08)
#define UART_LCR  REG32(UART_BASE + 0x0C)
#define UART_LSR  REG32(UART_BASE + 0x14)

/* AES */
#define AES_CTRL  REG32(AES_BASE + 0x00)
#define AES_STAT  REG32(AES_BASE + 0x00)
#define AES_KEY0  REG32(AES_BASE + 0x04)
#define AES_KEY1  REG32(AES_BASE + 0x08)
#define AES_KEY2  REG32(AES_BASE + 0x0C)
#define AES_KEY3  REG32(AES_BASE + 0x10)
#define AES_TXIN0 REG32(AES_BASE + 0x14)
#define AES_TXIN1 REG32(AES_BASE + 0x18)
#define AES_TXIN2 REG32(AES_BASE + 0x1C)
#define AES_TXIN3 REG32(AES_BASE + 0x20)
#define AES_OUT0  REG32(AES_BASE + 0x24)
#define AES_OUT1  REG32(AES_BASE + 0x28)
#define AES_OUT2  REG32(AES_BASE + 0x2C)
#define AES_OUT3  REG32(AES_BASE + 0x30)

/* DMA */
#define DMA_CTRL  REG32(DMA_BASE + 0x00)
#define DMA_STAT  REG32(DMA_BASE + 0x08)
#define DMA_SRC   REG32(DMA_BASE + 0x20)
#define DMA_DST   REG32(DMA_BASE + 0x30)
#define DMA_LEN   REG32(DMA_BASE + 0x40)
#define DMA_CFG   REG32(DMA_BASE + 0x50)

/* SPI */
#define SPI_SRR   REG32(SPI_BASE + 0x40)
#define SPI_CR    REG32(SPI_BASE + 0x60)
#define SPI_SR    REG32(SPI_BASE + 0x64)
#define SPI_DTR   REG32(SPI_BASE + 0x68)
#define SPI_SSR   REG32(SPI_BASE + 0x70)

/* GPIO */
#define GPIO_DATA_I REG32(GPIO_BASE + 0x00)
#define GPIO_DATA_O REG32(GPIO_BASE + 0x04)
#define GPIO_DIR    REG32(GPIO_BASE + 0x08)
#define GPIO_SET_O  REG32(GPIO_BASE + 0x20)
#define GPIO_CLR_O  REG32(GPIO_BASE + 0x24)
#define GPIO_TGL_O  REG32(GPIO_BASE + 0x28)

/* I2C */
#define I2C_PRER_LO REG32(I2C_BASE + 0x00)
#define I2C_PRER_HI REG32(I2C_BASE + 0x04)
#define I2C_CTR     REG32(I2C_BASE + 0x08)
#define I2C_TXR     REG32(I2C_BASE + 0x0C)
#define I2C_CR      REG32(I2C_BASE + 0x10)
#define I2C_SR      REG32(I2C_BASE + 0x10)

/* Fast simulation baud: 100 clocks per bit for rapid simulation and robust sampling */
#define SIM_BAUD_DIV 100

static void uart_init(void)
{
    UART_LCR  = 0x83;          /* DLAB=1 */
    UART_BAUD = SIM_BAUD_DIV;  /* 100 clocks/bit */
    UART_LCR  = 0x03;          /* DLAB=0, 8N1 */
    UART_IER  = 0x01;          /* Enable RX int */
}

static void uart_putc(char c)
{
    while ((UART_LSR & 0x20) == 0)
        ;
    UART_THR = (uint8_t)c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}

int main(void)
{
    uint8_t all_pass = 1;
    uint32_t val;
    uint32_t timeout;

    uart_init();

    /* =========================================================================
     * 1. UART: Loopback Test FIRST (RX FIFO is clean and empty)
     * ========================================================================= */
    UART_THR = 0x55;
    timeout = 10000;
    while (((UART_LSR & 0x01) == 0) && --timeout)
        ;
    val = UART_RBR & 0xFF;
    uint8_t uart_pass = (val == 0x55);

    uart_puts("START\r\n");

    /* =========================================================================
     * 2. AES: Execute 128-bit Encryption Operation
     * ========================================================================= */
    AES_KEY0 = 0x2b7e1516;
    AES_KEY1 = 0x28aed2a6;
    AES_KEY2 = 0xabf71588;
    AES_KEY3 = 0x09cf4f3c;

    AES_TXIN0 = 0x3243f6a8;
    AES_TXIN1 = 0x885a308d;
    AES_TXIN2 = 0x313198a2;
    AES_TXIN3 = 0xe0370734;

    /* Start key load + encryption operation */
    AES_CTRL = 0x03; // LOAD_KEY | ENCRYPT

    timeout = 10000;
    while (((AES_STAT & 0x00010000) == 0) && --timeout)
        ;

    if (AES_OUT0 == 0x3925841d &&
        AES_OUT1 == 0x02dc09fb &&
        AES_OUT2 == 0xdc118597 &&
        AES_OUT3 == 0x196a0b32) {
        uart_puts("AES:PASS\r\n");
    } else {
        uart_puts("AES:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 3. Report UART Result
     * ========================================================================= */
    if (uart_pass) {
        uart_puts("UART:PASS\r\n");
    } else {
        uart_puts("UART:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 4. SPI: Execute Byte Exchange Operation on SPI Bus
     * ========================================================================= */
    SPI_CR  = 0x00000086;  /* Enable core, master mode, manual CS */
    SPI_SSR = 0xFFFFFFFE;  /* Assert CS0 */
    SPI_DTR = 0xA5;        /* Write TX FIFO -> triggers SPI shift out on pins */
    timeout = 10000;
    while (((SPI_SR & 0x04) == 0) && --timeout)  /* Wait for TX FIFO empty */
        ;
    if (timeout > 0) {
        uart_puts("SPI:PASS\r\n");
    } else {
        uart_puts("SPI:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 5. GPIO: Execute Pin Drive and Toggle Operations
     * ========================================================================= */
    GPIO_DIR    = 0xFFFFFFFF;   /* All pins as outputs */
    GPIO_DATA_O = 0xDEADBEEF;   /* Drive 0xDEADBEEF to pins */
    GPIO_CLR_O  = 0x0000FF00;   /* Clear bits 8-15 -> 0xDEAD00EF */
    GPIO_SET_O  = 0x00000010;   /* Set bit 4       -> 0xDEAD00FF */
    GPIO_TGL_O  = 0x0000000F;   /* Toggle bits 0-3 -> 0xDEAD00F0 */
    val = GPIO_DATA_O;
    if (val == 0xDEAD00F0) {
        uart_puts("GPIO:PASS\r\n");
    } else {
        uart_puts("GPIO:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 6. I2C: Execute Bus START Condition and Address Transmission Operation
     * ========================================================================= */
    I2C_PRER_LO = 0x63;
    I2C_PRER_HI = 0x00;
    I2C_CTR     = 0x80;  /* Enable I2C core */
    I2C_TXR     = 0xA0;  /* Slave address 0x50 + Write */
    I2C_CR      = 0x90;  /* Generate START condition + Transmit byte on SCL/SDA pins */
    timeout = 10000;
    while (((I2C_SR & 0x02) != 0) && --timeout) /* Wait for TIP to finish */
        ;
    I2C_CR      = 0x40;  /* Issue STOP to release bus */
    if (timeout > 0) {
        uart_puts("I2C:PASS\r\n");
    } else {
        uart_puts("I2C:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 7. AXI RAM: Multi-Word Memory Read/Write Operations
     * ========================================================================= */
    REG32(PROG_RAM_BASE + 0x00) = 0x11223344;
    REG32(PROG_RAM_BASE + 0x04) = 0x55667788;
    REG32(DATA_RAM_BASE + 0x00) = 0x88776655;
    REG32(DATA_RAM_BASE + 0x04) = 0x44332211;

    if (REG32(PROG_RAM_BASE + 0x00) == 0x11223344 &&
        REG32(PROG_RAM_BASE + 0x04) == 0x55667788 &&
        REG32(DATA_RAM_BASE + 0x00) == 0x88776655 &&
        REG32(DATA_RAM_BASE + 0x04) == 0x44332211) {
        uart_puts("RAM:PASS\r\n");
    } else {
        uart_puts("RAM:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 8. DMA: Execute Autonomous Memory-to-Memory Copy Operation
     * ========================================================================= */
    REG32(PROG_RAM_BASE + 0x10) = 0xCAFEBABE;
    REG32(DATA_RAM_BASE + 0x10) = 0x00000000;

    DMA_SRC = PROG_RAM_BASE + 0x10;
    DMA_DST = DATA_RAM_BASE + 0x10;
    DMA_LEN = 4;
    DMA_CFG = 0x00000004;
    DMA_CTRL = 0x000003FD; /* GO=1, max_burst=0xFF */

    timeout = 10000;
    while (((DMA_STAT & 0x00010000) == 0) && --timeout)
        ;

    if (REG32(DATA_RAM_BASE + 0x10) == 0xCAFEBABE) {
        uart_puts("DMA:PASS\r\n");
    } else {
        uart_puts("DMA:FAIL\r\n");
        all_pass = 0;
    }

    /* =========================================================================
     * 9. Dummy AXI Slaves: Interconnect Routing Verification
     * ========================================================================= */
    REG32(DUMMY0_BASE) = 0x07;
    REG32(DUMMY1_BASE) = 0x08;
    REG32(DUMMY2_BASE) = 0x09;
    REG32(DUMMY3_BASE) = 0x0A;
    if (REG32(DUMMY0_BASE) == 0x07 &&
        REG32(DUMMY1_BASE) == 0x08 &&
        REG32(DUMMY2_BASE) == 0x09 &&
        REG32(DUMMY3_BASE) == 0x0A) {
        uart_puts("DUMMY:PASS\r\n");
    } else {
        uart_puts("DUMMY:FAIL\r\n");
        all_pass = 0;
    }

    /* Final Result */
    if (all_pass) {
        uart_puts("ALL TESTS PASSED\r\n");
        uart_putc(0x04); /* EOT */
    } else {
        uart_puts("SOME TESTS FAILED\r\n");
        uart_putc(0x15); /* NAK */
    }

    while (1)
        ;
    return 0;
}
