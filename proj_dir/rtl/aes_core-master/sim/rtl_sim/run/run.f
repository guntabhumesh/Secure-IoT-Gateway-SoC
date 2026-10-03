// =============================================================================
// run.f - VCS Filelist for AES Core RTL Simulation
//
// Project : 1602-23-735-127 Aegis-V-SoC
// Module  : AES Rijndael IP Core (aes_core-master)
// Author  : Rudolf Usselmann (rudi@asics.ws)
// Tool    : Synopsys VCS U-2023.03
//
// Compile order follows hierarchy from doc/aes.pdf:
//
//   aes_cipher_top.v
//     |- aes_key_expand_128.v
//     |    |- aes_sbox.v
//     |    |- aes_rcon.v
//     |- aes_sbox.v
//
//   aes_inv_cipher_top.v
//     |- aes_key_expand_128.v
//     |    |- aes_sbox.v
//     |    |- aes_rcon.v
//     |- aes_inv_sbox.v
//     |- aes_sbox.v
//
// Usage:
//   vcs -full64 +v2k +define+RUDIS_TB -f run.f -top test -o simv
// =============================================================================

// -----------------------------------------------------------------------------
// Verilog standard
// -----------------------------------------------------------------------------
+v2k

// -----------------------------------------------------------------------------
// Defines
// -----------------------------------------------------------------------------
+define+RUDIS_TB

// -----------------------------------------------------------------------------
// Include directories
// -----------------------------------------------------------------------------
+incdir+../../../rtl
+incdir+../../../bench/verilog

// -----------------------------------------------------------------------------
// RTL Sources - bottom-up compile order
// -----------------------------------------------------------------------------

// Timescale
../../../rtl/timescale.v

// Primitives
../../../rtl/aes_rcon.v
../../../rtl/aes_sbox.v
../../../rtl/aes_inv_sbox.v

// Sub-modules
../../../rtl/aes_key_expand_128.v

// Top-level DUT modules
../../../rtl/aes_cipher_top.v
../../../rtl/aes_inv_cipher_top.v

// -----------------------------------------------------------------------------
// Testbench
// -----------------------------------------------------------------------------
../../../bench/verilog/test_bench_top.v
