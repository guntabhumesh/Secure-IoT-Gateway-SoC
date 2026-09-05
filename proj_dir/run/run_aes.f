
+incdir+../rtl/aes_core-master/rtl/verilog

// ── AES RTL sources ────────────────────────────────────────────────────────
// Timescale header (included by the RTL files via `include "timescale.v")
../rtl/aes_core-master/rtl/verilog/timescale.v

// Sub-modules (must precede the top-level files that instantiate them)
../rtl/aes_core-master/rtl/verilog/aes_rcon.v
../rtl/aes_core-master/rtl/verilog/aes_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_inv_sbox.v
../rtl/aes_core-master/rtl/verilog/aes_key_expand_128.v

// Cipher and inverse-cipher top levels
../rtl/aes_core-master/rtl/verilog/aes_cipher_top.v
../rtl/aes_core-master/rtl/verilog/aes_inv_cipher_top.v

// ── Testbench top ───────────────────────────────────────────────────────────
../tb/tb_aes_core.v
