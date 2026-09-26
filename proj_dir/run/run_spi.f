// run_spi.f  -  VCS filelist for SPI Master verification
//
// Project  : Secure IoT Gateway SoC
// Block    : SPI Master (spi-master-master)
// Testbench: SPI_Master_With_Single_CS_TB.sv  (top-level TB)
//
// Directory layout (relative to proj_dir/run/):
//   ../rtl/spi-master-master/Verilog/source/SPI_Master.v
//   ../rtl/spi-master-master/Verilog/source/SPI_Master_With_Single_CS.v
//   ../rtl/spi-master-master/Verilog/sim/SPI_Master_With_Single_CS_TB.sv
//
// NOTE: SPI_Master_With_Single_CS_TB.sv contains:
//         `include "SPI_Master.v"
//       VCS resolves `include paths via +incdir. We therefore:
//         1. Add +incdir pointing at the Verilog/source directory so the
//            `include "SPI_Master.v" inside the TB resolves correctly.
//         2. Do NOT list SPI_Master.v as a separate source file to avoid a
//            duplicate-module error (it is pulled in via the `include).
//
// ── Quick Compile + Simulate (run from proj_dir/run/) ──────────────────────
//
//  No waveforms (fastest):
//    vcs -sverilog -full64 -f run_spi.f -o simv_spi \
//        2>&1 | tee compile_spi.log && ./simv_spi | tee sim_spi.log
//
//  With Verdi FSDB dump:
//    vcs -sverilog -full64 -f run_spi.f -o simv_spi \
//        -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
//        ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
//        2>&1 | tee compile_spi.log && ./simv_spi | tee sim_spi.log
//
//  Open waveform in Verdi:
//    verdi -f run_spi.f -ssf dump_spi.fsdb -rc spi_signals.rc &
//
// ──────────────────────────────────────────────────────────────────────────

// ── Include-directory search path ─────────────────────────────────────────
// Required so that `include "SPI_Master.v" inside the TB resolves to
// ../rtl/spi-master-master/Verilog/source/SPI_Master.v
+incdir+../rtl/spi-master-master/Verilog/source

// ── RTL Sources ────────────────────────────────────────────────────────────

// SPI Master with single Chip-Select wrapper (DUT top-level).
// This module instantiates SPI_Master internally.
// SPI_Master.v is NOT listed here because it is pulled in via
// `include "SPI_Master.v" inside SPI_Master_With_Single_CS_TB.sv.
../rtl/spi-master-master/Verilog/source/SPI_Master_With_Single_CS.v

// ── Testbench ──────────────────────────────────────────────────────────────

// Top-level SystemVerilog testbench.
// Contains `include "SPI_Master.v" at the top (resolved via +incdir above).
../rtl/spi-master-master/Verilog/sim/SPI_Master_With_Single_CS_TB.sv
