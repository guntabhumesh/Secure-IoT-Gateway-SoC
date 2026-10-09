+incdir+../rtl
+incdir+../include

// ── UART RTL sources ───────────────────────────────────────────────────────

../rtl/uart_parity_bit_compute.v
../rtl/uart_transmitter.v
../rtl/uart_receiver.v
../rtl/uart_controller.v

// ── AXI UART sources ────────────────────────────────────────────────────────
../rtl/axi_internal_fifo.v
../rtl/axi_uart_top.v
../include/axi_uart.vh
../include/axi_uart_defines.vh

// ── Testbench top ───────────────────────────────────────────────────────────
../tb/tb_uart.v
