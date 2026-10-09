/* Linker script for VeeR EL2 bare-metal simulation
 * Code  -> ICCM : 0xEE000000 (64 KB)
 * Data  -> DCCM : 0xF0040000 (64 KB)
 * Stack at top of DCCM region
 */
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    ICCM (rx)  : ORIGIN = 0xEE000000, LENGTH = 64K
    DCCM (rwx) : ORIGIN = 0xF0040000, LENGTH = 64K
}

SECTIONS {
    . = 0xEE000000;

    .text : {
        *(.text.init)
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > ICCM

    . = 0xF0040000;

    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > DCCM

    .bss (NOLOAD) : {
        _bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        _bss_end = .;
    } > DCCM

    /* Stack: 4 KB at end of DCCM */
    _stack_top = ORIGIN(DCCM) + LENGTH(DCCM);
}
