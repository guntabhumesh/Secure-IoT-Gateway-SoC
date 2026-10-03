
+incdir+../rtl/aes_core-master/rtl

// ── AES RTL sources ────────────────────────────────────────────────────────
// Timescale header (included by the RTL files via `include "timescale.v")
../rtl/aes_core-master/rtl/timescale.v

// Sub-modules (must precede the top-level files that instantiate them)
../rtl/aes_core-master/rtl/aes_rcon.v
../rtl/aes_core-master/rtl/aes_sbox.v
../rtl/aes_core-master/rtl/aes_inv_sbox.v
../rtl/aes_core-master/rtl/aes_key_expand_128.v

// Cipher and inverse-cipher top levels
../rtl/aes_core-master/rtl/aes_cipher_top.v
../rtl/aes_core-master/rtl/aes_inv_cipher_top.v

// ── Testbench top ───────────────────────────────────────────────────────────
../rtl/aes_core-master/bench/verilog/test_bench_top.v
