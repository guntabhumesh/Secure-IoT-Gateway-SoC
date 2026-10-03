/* startup.S — minimal VeeR EL2 bare-metal startup
 * Sets up stack pointer, configures MRAC, and calls main().
 * Must be placed in .text.init so the linker script puts it first.
 *
 * MRAC (CSR 0x7c0) — Memory Region Attribute Control.
 * Each pair of bits [2*i+1 : 2*i] controls region i (addr[31:28] == i):
 *   bit[2i+1] = sideeffect  (1 = preserve exact address on AXI, no coalescing)
 *   bit[2i+0] = cacheable   (0 = non-cacheable for MMIO)
 *
 * UART is at 0x02000000 → region 0 (addr[31:28]=0x0) → bits [1:0].
 * Set bit 1 (sideeffect=1) for region 0 so VeeR preserves araddr[2]
 * when reading UART registers at odd-word offsets (e.g. LSR at 0x14).
 *
 * Also set sideeffect for all lower MMIO regions (0-3) to be safe:
 *   MRAC = 0x000000AA = bits [7:0] = 0b10101010
 *   (sideeffect=1, cacheable=0 for regions 0,1,2,3)
 */
    .section .text.init, "ax", @progbits
    .global  _start
    .type    _start, @function

_start:
    /* Configure MRAC: set sideeffect for regions 0-3 (MMIO range 0x00-0x3FFFFFFF) */
    li   t0, 0xAAAAAAAA        /* sideeffect=1, cacheable=0 for all 16 regions */
    csrw 0x7c0, t0

    /* Set stack pointer to top of DCCM */
    la   sp, _stack_top

    /* Zero-initialise .bss */
    la   t0, _bss_start
    la   t1, _bss_end
bss_loop:
    bge  t0, t1, bss_done
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    bss_loop
bss_done:

    /* Call main */
    call main

    /* Spin forever if main returns */
spin:
    j    spin
