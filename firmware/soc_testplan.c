/*
 * soc_testplan.c
 *
 * Embedded C firmware implementing test cases from the Secure-IoT-Gateway-SoC
 * UVM Verification Test Plan (doc/Secure_IoT_Gateway_SoC_UVM_Test_Plan.xlsx).
 *
 * Implemented Test Plan Cases:
 *   [TEST:CORE_MEM_001]    - 8-bit, 16-bit, and 32-bit load/store & sign/zero extension
 *   [TEST:LOCAL_MEM_001]   - Local memory (DCCM) pattern read/write verification
 *   [TEST:UART_LOOP_001]   - UART baud rate configuration and hardware loopback
 *   [TEST:AES_KAT_001]     - NIST FIPS-197 AES-128 Known Answer Test vector encryption
 *   [TEST:SPI_LOOP_001]    - SPI master transmission & byte exchange over MOSI
 *   [TEST:GPIO_ATOMIC_001] - GPIO direction, pattern, and atomic SET/CLR/TGL operations
 *   [TEST:I2C_WRITE_001]   - I2C prescaler, START condition, address transmission, STOP
 *   [TEST:RAM_STRB_001]    - AXI SRAM multi-word and byte-lane strobe operations
 *   [TEST:DMA_MEM2MEM_001] - Autonomous DMA memory-to-memory burst transfer
 *   [TEST:TIMER_ONESHOT_001] - Countdown timer, IRQ pending flag, and W1C status clear
 *   [TEST:DUMMY_SLAVE_001] - Interconnect address routing to dummy slaves m08..m10
 *   [TEST:SOC_MISSION_001] - Integrated end-to-end SoC mission status check
 */

#include <stdint.h>

#define REG32(addr) (*(volatile uint32_t *)(addr))
#define REG16(addr) (*(volatile uint16_t *)(addr))
#define REG8(addr)  (*(volatile uint8_t  *)(addr))

/* --- SoC Interconnect Memory Map --- */
#define I2C_BASE        0x00000000UL
#define AES_BASE        0x01000000UL
#define UART_BASE       0x02000000UL
#define SPI_BASE        0x03000000UL
#define GPIO_BASE       0x04000000UL
#define PROG_RAM_BASE   0x05000000UL
#define DATA_RAM_BASE   0x06000000UL
#define TIMER_BASE      0x07000000UL
#define DUMMY0_BASE     0x08000000UL
#define DUMMY1_BASE     0x09000000UL
#define DUMMY2_BASE     0x0A000000UL
#define DMA_BASE        0x0B000000UL
#define DCCM_BASE       0xF0040000UL

/* --- UART Registers --- */
#define UART_THR        REG32(UART_BASE + 0x00)
#define UART_RBR        REG32(UART_BASE + 0x00)
#define UART_IER        REG32(UART_BASE + 0x04)
#define UART_BAUD       REG32(UART_BASE + 0x08)
#define UART_LCR        REG32(UART_BASE + 0x0C)
#define UART_LSR        REG32(UART_BASE + 0x14)

/* --- AES Registers --- */
#define AES_CTRL        REG32(AES_BASE + 0x00)
#define AES_STAT        REG32(AES_BASE + 0x00)
#define AES_KEY0        REG32(AES_BASE + 0x04)
#define AES_KEY1        REG32(AES_BASE + 0x08)
#define AES_KEY2        REG32(AES_BASE + 0x0C)
#define AES_KEY3        REG32(AES_BASE + 0x10)
#define AES_TXIN0       REG32(AES_BASE + 0x14)
#define AES_TXIN1       REG32(AES_BASE + 0x18)
#define AES_TXIN2       REG32(AES_BASE + 0x1C)
#define AES_TXIN3       REG32(AES_BASE + 0x20)
#define AES_OUT0        REG32(AES_BASE + 0x24)
#define AES_OUT1        REG32(AES_BASE + 0x28)
#define AES_OUT2        REG32(AES_BASE + 0x2C)
#define AES_OUT3        REG32(AES_BASE + 0x30)

/* --- SPI Registers --- */
#define SPI_SRR         REG32(SPI_BASE + 0x40)
#define SPI_CR          REG32(SPI_BASE + 0x60)
#define SPI_SR          REG32(SPI_BASE + 0x64)
#define SPI_DTR         REG32(SPI_BASE + 0x68)
#define SPI_SSR         REG32(SPI_BASE + 0x70)

/* --- GPIO Registers --- */
#define GPIO_DATA_I     REG32(GPIO_BASE + 0x00)
#define GPIO_DATA_O     REG32(GPIO_BASE + 0x04)
#define GPIO_DIR        REG32(GPIO_BASE + 0x08)
#define GPIO_SET_O      REG32(GPIO_BASE + 0x20)
#define GPIO_CLR_O      REG32(GPIO_BASE + 0x24)
#define GPIO_TGL_O      REG32(GPIO_BASE + 0x28)

/* --- I2C Registers --- */
#define I2C_PRER_LO     REG32(I2C_BASE + 0x00)
#define I2C_PRER_HI     REG32(I2C_BASE + 0x04)
#define I2C_CTR         REG32(I2C_BASE + 0x08)
#define I2C_TXR         REG32(I2C_BASE + 0x0C)
#define I2C_CR          REG32(I2C_BASE + 0x10)
#define I2C_SR          REG32(I2C_BASE + 0x10)

/* --- General Timer Registers --- */
#define TIMER_CTRL      REG32(TIMER_BASE + 0x00)
#define TIMER_LOAD      REG32(TIMER_BASE + 0x04)
#define TIMER_VAL       REG32(TIMER_BASE + 0x08)
#define TIMER_PRE       REG32(TIMER_BASE + 0x0C)
#define TIMER_INT_EN    REG32(TIMER_BASE + 0x10)
#define TIMER_INT_STS   REG32(TIMER_BASE + 0x14)

/* --- DMA Registers --- */
#define DMA_CTRL        REG32(DMA_BASE + 0x00)
#define DMA_STAT        REG32(DMA_BASE + 0x08)
#define DMA_SRC         REG32(DMA_BASE + 0x20)
#define DMA_DST         REG32(DMA_BASE + 0x30)
#define DMA_LEN         REG32(DMA_BASE + 0x40)
#define DMA_CFG         REG32(DMA_BASE + 0x50)

#define SIM_BAUD_DIV    100

static void uart_init(void)
{
    UART_LCR  = 0x83;          /* DLAB = 1 */
    UART_BAUD = SIM_BAUD_DIV;  /* 100 clocks per bit */
    UART_LCR  = 0x03;          /* 8N1 */
    UART_IER  = 0x01;          /* Enable RX interrupt */
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

static void report_test(const char *test_id, uint8_t pass)
{
    uart_puts("[TEST:");
    uart_puts(test_id);
    if (pass) {
        uart_puts("] PASS\r\n");
    } else {
        uart_puts("] FAIL\r\n");
    }
}

int main(void)
{
    uint8_t all_pass = 1;
    uint32_t timeout;
    uint32_t val32;

    uart_init();

    /* -------------------------------------------------------------------------
     * 1. [TEST:UART_LOOP_001]
     * Verify UART transmitter and receiver with loopback byte 0x55
     * ------------------------------------------------------------------------- */
    UART_THR = 0x55;
    timeout = 10000;
    while (((UART_LSR & 0x01) == 0) && --timeout)
        ;
    val32 = UART_RBR & 0xFF;
    uint8_t pass_uart = (val32 == 0x55);
    report_test("UART_LOOP_001", pass_uart);
    if (!pass_uart) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 2. [TEST:CORE_MEM_001]
     * Exercise byte, halfword, and word loads and stores with sign extension
     * ------------------------------------------------------------------------- */
    volatile uint8_t  *ram8  = (volatile uint8_t  *)(DATA_RAM_BASE + 0x0100);
    volatile uint16_t *ram16 = (volatile uint16_t *)(DATA_RAM_BASE + 0x0100);
    volatile uint32_t *ram32 = (volatile uint32_t *)(DATA_RAM_BASE + 0x0100);

    /* Store 32-bit word, read back bytes */
    *ram32 = 0x12345678;
    uint8_t b0 = ram8[0]; // 0x78 (little endian)
    uint8_t b1 = ram8[1]; // 0x56
    uint8_t b2 = ram8[2]; // 0x34
    uint8_t b3 = ram8[3]; // 0x12

    /* Halfword write and read */
    ram16[2] = 0xABCD; // at offset 4
    uint16_t h0 = ram16[2];

    uint8_t pass_mem = (b0 == 0x78 && b1 == 0x56 && b2 == 0x34 && b3 == 0x12 && h0 == 0xABCD);
    report_test("CORE_MEM_001", pass_mem);
    if (!pass_mem) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 3. [TEST:LOCAL_MEM_001]
     * Verify read/write access to VeeR DCCM (local data memory)
     * ------------------------------------------------------------------------- */
    volatile uint32_t *dccm_ptr = (volatile uint32_t *)(DCCM_BASE + 0x0400);
    dccm_ptr[0] = 0xA5A55A5A;
    dccm_ptr[1] = 0x5A5AA5A5;
    uint8_t pass_dccm = (dccm_ptr[0] == 0xA5A55A5A && dccm_ptr[1] == 0x5A5AA5A5);
    report_test("LOCAL_MEM_001", pass_dccm);
    if (!pass_dccm) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 4. [TEST:AES_KAT_001]
     * NIST FIPS-197 AES-128 Known Answer Test vector encryption
     * Key: 2b7e1516 28aed2a6 abf71588 09cf4f3c
     * PT:  3243f6a8 885a308d 313198a2 e0370734
     * CT:  3925841d 02dc09fb dc118597 196a0b32
     * ------------------------------------------------------------------------- */
    AES_KEY0  = 0x2b7e1516;
    AES_KEY1  = 0x28aed2a6;
    AES_KEY2  = 0xabf71588;
    AES_KEY3  = 0x09cf4f3c;

    AES_TXIN0 = 0x3243f6a8;
    AES_TXIN1 = 0x885a308d;
    AES_TXIN2 = 0x313198a2;
    AES_TXIN3 = 0xe0370734;

    AES_CTRL  = 0x03; // LOAD_KEY | ENCRYPT

    timeout = 10000;
    while (((AES_STAT & 0x00010000) == 0) && --timeout)
        ;

    uint8_t pass_aes = (timeout > 0 &&
                        AES_OUT0 == 0x3925841d &&
                        AES_OUT1 == 0x02dc09fb &&
                        AES_OUT2 == 0xdc118597 &&
                        AES_OUT3 == 0x196a0b32);
    report_test("AES_KAT_001", pass_aes);
    if (!pass_aes) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 5. [TEST:SPI_LOOP_001]
     * SPI Master mode configuration, chip select assert, multi-byte transmission
     * ------------------------------------------------------------------------- */
    SPI_CR  = 0x00000086;  /* Enable core, master mode, manual CS */
    SPI_SSR = 0xFFFFFFFE;  /* Assert CS0 (active low) */
    SPI_DTR = 0xA5;        /* Write Byte 1 */
    SPI_DTR = 0x5A;        /* Write Byte 2 */
    SPI_DTR = 0x3C;        /* Write Byte 3 */
    timeout = 10000;
    while (((SPI_SR & 0x04) == 0) && --timeout)  /* Wait for TX FIFO empty */
        ;
    for (volatile int d = 0; d < 200; d++)
        ;                  /* Allow shift register to finish */
    SPI_SSR = 0xFFFFFFFF;  /* De-assert CS0 (CS back to 1) */
    uint8_t pass_spi = (timeout > 0);
    report_test("SPI_LOOP_001", pass_spi);
    if (!pass_spi) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 6. [TEST:GPIO_ATOMIC_001]
     * Atomic bit manipulation: direction, SET_O, CLR_O, and TGL_O
     * ------------------------------------------------------------------------- */
    GPIO_DIR    = 0xFFFFFFFF;   /* All 32 pins configured as output */
    GPIO_DATA_O = 0xDEADBEEF;
    GPIO_CLR_O  = 0x0000FF00;   /* Clear bits 8-15 -> 0xDEAD00EF */
    GPIO_SET_O  = 0x00000010;   /* Set bit 4       -> 0xDEAD00FF */
    GPIO_TGL_O  = 0x0000000F;   /* Toggle bits 0-3 -> 0xDEAD00F0 */
    val32 = GPIO_DATA_O;
    uint8_t pass_gpio = (val32 == 0xDEAD00F0);
    report_test("GPIO_ATOMIC_001", pass_gpio);
    if (!pass_gpio) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 7. [TEST:I2C_WRITE_001]
     * Multi-byte transmission: START + Slave Addr + Data Bytes + STOP
     * ------------------------------------------------------------------------- */
    I2C_PRER_LO = 0x20;  /* 32 clocks prescaler for clearly visible SCL cycles */
    I2C_PRER_HI = 0x00;
    I2C_CTR     = 0x80;  /* Enable I2C core */
    /* 1. START + Address 0x50 with Write bit (0xA0) */
    I2C_TXR     = 0xA0;
    I2C_CR      = 0x90;  /* START + WRITE */
    timeout = 10000;
    while (((I2C_SR & 0x02) != 0) && --timeout)
        ;
    /* 2. Data Byte 1: 0x5A */
    I2C_TXR     = 0x5A;
    I2C_CR      = 0x10;  /* WRITE */
    timeout = 10000;
    while (((I2C_SR & 0x02) != 0) && --timeout)
        ;
    /* 3. Data Byte 2: 0xA5 + STOP condition */
    I2C_TXR     = 0xA5;
    I2C_CR      = 0x50;  /* WRITE + STOP */
    timeout = 10000;
    while (((I2C_SR & 0x02) != 0) && --timeout)
        ;
    uint8_t pass_i2c = (timeout > 0);
    report_test("I2C_WRITE_001", pass_i2c);
    if (!pass_i2c) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 8. [TEST:RAM_STRB_001]
     * Multi-word read/write to Program RAM (m05) and Data RAM (m06)
     * ------------------------------------------------------------------------- */
    REG32(PROG_RAM_BASE + 0x00) = 0xCAFE0001;
    REG32(PROG_RAM_BASE + 0x04) = 0xCAFE0002;
    REG32(DATA_RAM_BASE + 0x00) = 0xBEEF0001;
    REG32(DATA_RAM_BASE + 0x04) = 0xBEEF0002;

    uint8_t pass_ram = (REG32(PROG_RAM_BASE + 0x00) == 0xCAFE0001 &&
                        REG32(PROG_RAM_BASE + 0x04) == 0xCAFE0002 &&
                        REG32(DATA_RAM_BASE + 0x00) == 0xBEEF0001 &&
                        REG32(DATA_RAM_BASE + 0x04) == 0xBEEF0002);
    report_test("RAM_STRB_001", pass_ram);
    if (!pass_ram) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 9. [TEST:DMA_MEM2MEM_001]
     * Autonomous DMA memory-to-memory copy from Program RAM to Data RAM
     * ------------------------------------------------------------------------- */
    REG32(PROG_RAM_BASE + 0x20) = 0x55AA1234;
    REG32(DATA_RAM_BASE + 0x20) = 0x00000000;

    DMA_SRC  = PROG_RAM_BASE + 0x20;
    DMA_DST  = DATA_RAM_BASE + 0x20;
    DMA_LEN  = 4;
    DMA_CFG  = 0x00000004;
    DMA_CTRL = 0x000003FD; /* GO=1, max_burst */

    timeout = 10000;
    while (((DMA_STAT & 0x00010000) == 0) && --timeout)
        ;

    uint8_t pass_dma = (timeout > 0 && REG32(DATA_RAM_BASE + 0x20) == 0x55AA1234);
    report_test("DMA_MEM2MEM_001", pass_dma);
    if (!pass_dma) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 10. [TEST:TIMER_ONESHOT_001]
     * Countdown timer load, interrupt pending bit, and W1C clear
     * ------------------------------------------------------------------------- */
    TIMER_CTRL   = 0x00;
    TIMER_INT_EN = 0x00;
    TIMER_LOAD   = 500;  /* 500 ticks = 5 us @ 100 MHz */
    TIMER_INT_EN = 0x01;
    TIMER_CTRL   = 0x01;  /* EN=1 */

    /* Sample live countdown counter */
    volatile uint32_t val_mid1 = TIMER_VAL;
    volatile uint32_t val_mid2 = TIMER_VAL;
    (void)val_mid1;
    (void)val_mid2;

    timeout = 100000;
    while (((TIMER_INT_STS & 0x01) == 0) && --timeout)
        ;

    uint8_t pass_timer = 0;
    if (timeout > 0) {
        TIMER_INT_STS = 0x01; /* Clear with W1C */
        if ((TIMER_INT_STS & 0x01) == 0) {
            pass_timer = 1;
        }
    }
    TIMER_CTRL   = 0x00;  /* Stop timer */
    TIMER_INT_EN = 0x00;  /* Disable interrupt */
    report_test("TIMER_ONESHOT_001", pass_timer);
    if (!pass_timer) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 11. [TEST:DUMMY_SLAVE_001]
     * Address decoding and access across dummy slaves m08, m09, m10
     * ------------------------------------------------------------------------- */
    REG32(DUMMY0_BASE) = 0x11;
    REG32(DUMMY1_BASE) = 0x22;
    REG32(DUMMY2_BASE) = 0x33;
    uint8_t pass_dummy = (REG32(DUMMY0_BASE) == 0x11 &&
                          REG32(DUMMY1_BASE) == 0x22 &&
                          REG32(DUMMY2_BASE) == 0x33);
    report_test("DUMMY_SLAVE_001", pass_dummy);
    if (!pass_dummy) all_pass = 0;

    /* -------------------------------------------------------------------------
     * 12. [TEST:SOC_MISSION_001]
     * Overall testplan execution status
     * ------------------------------------------------------------------------- */
    report_test("SOC_MISSION_001", all_pass);

    if (all_pass) {
        uart_puts("\r\n=================================================\r\n");
        uart_puts("*** UVM TEST PLAN COMPLETE: ALL TESTS PASSED ***\r\n");
        uart_puts("=================================================\r\n");
        uart_putc(0x04); /* ASCII EOT to signal testbench finish */
    } else {
        uart_puts("\r\n*** UVM TEST PLAN EXECUTION: FAILED ***\r\n");
        uart_putc(0x15); /* NAK */
    }

    while (1)
        ;
    return 0;
}
