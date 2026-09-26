# Secure IoT Gateway SoC

[![Project](https://img.shields.io/badge/Project-Secure--IoT--Gateway--SoC-blue)](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC)
[![RTL](https://img.shields.io/badge/RTL-Verilog%2FSystemVerilog-green)](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl)
[![Core](https://img.shields.io/badge/CPU-RISC--V%20VeeR%20EL2%20(optional)-orange)](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/Cores-VeeR-EL2)
[![Sim](https://img.shields.io/badge/Simulation-VCS%20%7C%20Verdi-lightgrey)](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/run)

**Secure IoT Gateway SoC — AXI4 interconnect (2 masters × 11 slaves) integrating a Wishbone I2C master, an AXI AES-128 encrypt/decrypt engine, and an AXI-Lite UART, with an optional VeeR EL2 RISC‑V CPU top for firmware-driven simulation**

**Repository:** [github.com/guntabhumesh/Secure-IoT-Gateway-SoC](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC)

## Table of Contents
- [Project](#project)
- [Author](#author)
- [Highlights](#highlights)
- [Architecture (short)](#architecture-short)
- [Diagrams](#diagrams)
- [SoC Address Map](#soc-address-map)
- [1. Project overview and current goals](#1-project-overview-and-current-goals)
- [2. Implemented vs planned/stubbed blocks](#2-implemented-vs-plannedstubbed-blocks)
- [3. Detailed architecture and data/control flow](#3-detailed-architecture-and-datacontrol-flow)
- [4. Repository layout](#4-repository-layout-current)
- [5. Module/file responsibility table](#5-modulefile-responsibility-table)
- [6. Register maps](#6-register-maps)
- [7. Simulation prerequisites and exact flows](#7-simulation-prerequisites-and-exact-flows)
- [8. Verification strategy and covered scenarios](#8-verification-strategy-and-covered-scenarios)
- [9. Wrapper generator usage](#9-wrapper-generator-usage-scriptsaxi_interconnect_wrapy)
- [10. Imported IP — sources, references & licenses](#10-imported-ip-notes-i2c--aes--uart--veer-el2--sources-and-references)
- [11. Known limitations and current integration status](#11-known-limitations-and-current-integration-status)
- [12. Contribution/dev guidance and provenance notes](#12-contributiondev-guidance-and-provenance-notes)
- [13. Quick reference commands](#13-quick-reference-commands)
- [Documents Index](#documents-index)

---

## Project
**Secure IoT Gateway SoC** — an AXI4 interconnect-centric SoC that routes two AXI4 initiators to eleven memory-mapped targets: a Wishbone I2C master (via an AXI→Wishbone bridge), an AXI AES‑128 encrypt/decrypt accelerator, an AXI‑Lite UART, and eight dummy/reserved slaves — with an optional VeeR EL2 RISC‑V core wired on as `s00` for firmware-driven (rather than BFM-driven) simulation.

## Author
- **Name:** Bhumesh
- **GitHub:** [@guntabhumesh](https://github.com/guntabhumesh)

## Highlights
- **AXI4 interconnect** ([`axi_interconnect_wrap_2x11.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect_wrap_2x11.v)) — 2 slave-side masters (`s00`, `s01`) × 11 master-side targets (`m00`..`m10`), each on a 16 MB (`2^24`) window
- **Two integration tops** sharing the same interconnect and peripheral set:
  - [`soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/soc_top.v) — `s00`/`s01` exposed directly as external AXI4 ports (BFM-driven)
  - [`soc_top_with_veer.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/top/soc_top_with_veer.v) — a VeeR EL2 RISC‑V core drives `s00` through a 64→32-bit LSU width adapter; `s01` remains exposed as a spare master port
- **Peripheral integration:**
  - **m00 → I2C** — [`axi_to_wb_bridge.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/axi_to_wb_bridge.v) (AXI4-Lite → Wishbone B4, single outstanding transaction) → [`i2c_master_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/i2c-master/i2c_master_top.v)
  - **m01 → AES‑128** — [`axi_aes_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/axi_aes_slave.v) wrapping [`aes_cipher_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/aes_cipher_top.v) with [`aes_inv_cipher_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/aes_inv_cipher_top.v) auto-chained for round-trip decrypt
  - **m02 → UART** — [`axi_uart_slave.v`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/src/rtl/axi_uart_slave.v>) (AXI4-full → AXI4-Lite AW/W beat buffering) wrapping the `axi-lite_uart-ipcore`
  - **m03–m10 → dummy AXI slaves** ([`dummy_axi_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/dummy_axi_slave.v)) — reserved/placeholder targets that ACK writes and return a `0xDEAD_xxxx` read pattern encoding the slave index
- **Full-SoC integration testbench** ([`tb_soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_top.v)) — 12 directed tests covering I2C register access, AES‑128 encrypt against **two** NIST FIPS‑197 known-answer vectors plus an inverse-cipher round-trip, full UART init/TX/RX loopback, dummy-slave routing, and AES soft-reset
- **VeeR EL2 smoke test** ([`tb_soc_veer_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_veer_top.v)) — boots the core from a `$readmemh`-loaded ICCM image and watches UART TX for firmware activity
- **Standalone interconnect + I2C + AES testbench** ([`tb_axi_interconnect_2x11_aes.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_axi_interconnect_2x11_aes.v)) exercising the interconnect through lighter-weight AXI‑Lite bridges before full-SoC integration
- Simulation collateral centered on Synopsys VCS + Verdi; committed `simv_aes` and `simv_soc_veer` binaries show the AES-only and SoC+VeeR flows have each been compiled and run at least once

## Architecture (short)
Two integration tops share the same interconnect/peripheral core:

```text
                         ┌───────────────────────────────┐
  s00 (external AXI4) ──►│                                │──► m00  I2C   (0x0000_0000, via axi_to_wb_bridge)
  s01 (external AXI4) ──►│  axi_interconnect_wrap_2x11    │──► m01  AES   (0x0100_0000, axi_aes_slave)
                         │      (2 masters × 11 slaves)   │──► m02  UART  (0x0200_0000, axi_uart_slave)
                         │                                │──► m03..m10  dummy_axi_slave (0x0300_0000..0x0A00_0000)
                         └───────────────────────────────┘
```

With VeeR EL2 wired in ([`soc_top_with_veer.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/top/soc_top_with_veer.v)):

```text
   ┌─────────────────────┐
   │   el2_veer_wrapper   │  (VeeR EL2 RISC-V core)
   │                      │
   │  LSU AXI4 (64-bit)   │──[width-adapt 64→32]──►  s00 ─┐
   │  IFU AXI4            │──► ifu_axi_stub (ICCM mode)    │
   │  SB  AXI4            │──► tied off                     │
   │  DMA AXI4            │◄── tied off                     │
   └─────────────────────┘                                 │
                                                             ▼
                                        ┌────────────────────────────┐
                                        │ axi_interconnect_wrap_2x11 │
   s01 ◄──────────────────────────────►│   (2 masters, 11 slaves)   │
   (spare master, exposed at top)      └────────────┬────────────────┘
                                                      │ 11 slave ports
                              m00 0x0000_0000  I2C (Wishbone bridge)
                              m01 0x0100_0000  AES
                              m02 0x0200_0000  UART
                              m03-m10          dummy / reserved
```
The VeeR LSU AXI data bus is fixed at 64 bits by the core; the SoC bus is 32 bits, so a thin width adapter forwards only `wdata[31:0]`/`wstrb[3:0]` on writes and zero-extends `rdata[63:32]` on reads. The CPU must issue 32-bit (`awsize=2`) MMIO transfers only. With ICCM enabled (the default core config), the IFU never touches the external AXI bus, so its port is tied to a stub that never asserts `ready`/`valid`.

## Diagrams
<p align="center">
  <a href="https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/blockdiagram.png">
    <img src="https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/raw/main/proj_dir/doc/blockdiagram.png" alt="SOC block diagram" width="500"/>
  </a>
  <br/><sub>AXI‑Lite UART IP block diagram (see also the source <code>.vsdx</code> in <a href="https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/doc/uart">doc/uart/</a>)</sub>
</p>

There is currently no top-level SoC block diagram checked into the repo (unlike the UART IP's own diagram) — the ASCII sketches above are the closest thing until one is added under `proj_dir/doc/`. Verdi waveform captures from actual simulation runs are stored as screenshots in [`proj_dir/tb/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/tb) (`soc_i2c_uart_aes.png`, `aes_test*.png`, `i2c_test*.png`, `uart_tb.png`) — see [§8](#8-verification-strategy-and-covered-scenarios).

---

## SoC Address Map
Identical on both `soc_top` and `soc_top_with_veer` (each window is `2^24` = 16 MB):

| Slave | Base Address | Function |
|---|---|---|
| m00 | `0x0000_0000` | I2C — `axi_to_wb_bridge` → `i2c_master_top` (Wishbone) |
| m01 | `0x0100_0000` | AES‑128 — `axi_aes_slave` → `aes_cipher_top` + `aes_inv_cipher_top` |
| m02 | `0x0200_0000` | UART — `axi_uart_slave` → AXI4‑Lite `axi-lite_uart-ipcore` |
| m03–m10 | `0x0300_0000`..`0x0A00_0000` | `dummy_axi_slave` (reserved for future peripherals) |

---

## 1) Project overview and current goals
The repository centers on [`rtl/interconnect/axi_interconnect_wrap_2x11.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect_wrap_2x11.v), a generic 2×11 AXI4 crossbar, and two top-level integrations built on it:

1. AXI interconnect behavior (decode, arbitration, routing) shared by both tops
2. End-to-end I2C register access through an AXI‑Lite‑to‑Wishbone bridge
3. AES‑128 encryption **and** decryption — the inverse-cipher core auto-chains after the forward cipher, so a single `LD` pulse can be verified round-trip against NIST test vectors
4. End-to-end UART memory-mapped access (init sequence, TX, RX loopback) through an AXI4-to-AXI4‑Lite‑aware wrapper
5. Optional VeeR EL2 RISC‑V CPU integration as the `s00` master, with a firmware-loadable ICCM image, for CPU-driven (rather than BFM-driven) system simulation
6. Reproducible VCS/Verdi simulation flows per sub-block (I2C+AES via the interconnect, AES standalone, full SoC, SoC+VeeR)

## 2) Implemented vs planned/stubbed blocks

### Implemented/integrated in `soc_top.v` and `soc_top_with_veer.v`
- [`rtl/interconnect/axi_interconnect.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect.v), [`axi_interconnect_wrap_2x11.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect_wrap_2x11.v), [`arbiter.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/arbiter.v), [`priority_encoder.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/priority_encoder.v)
- [`rtl/interconnect/soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/soc_top.v) — BFM-facing top level
- [`rtl/top/soc_top_with_veer.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/top/soc_top_with_veer.v) (and its `.sv` counterpart) — VeeR EL2-facing top level
- I2C path: [`tb/axi_to_wb_bridge.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/axi_to_wb_bridge.v) → [`rtl/i2c-master/i2c_master_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/i2c-master/i2c_master_top.v) and its byte/bit controller sub-blocks
- AES path: [`rtl/aes_core-master/rtl/axi_aes_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/axi_aes_slave.v) → `aes_cipher_top.v` + `aes_inv_cipher_top.v` (S-box/inverse S-box/key-expand/rcon sub-blocks)
- UART path: [`rtl/uart file/src/rtl/axi_uart_slave.v`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/src/rtl/axi_uart_slave.v>) → `axi_uart_top.v` and its controller/FIFO/TX/RX sub-blocks
- `m03`–`m10`: [`tb/dummy_axi_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/dummy_axi_slave.v), parameterized per-slave-index, instantiated 8×

### Implemented in the lighter-weight standalone/bridge-level target (unchanged)
- [`tb/axi_to_aes_bridge.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/axi_to_aes_bridge.v) — an AXI4‑Lite wrapper around the AES cipher pair, used only by [`tb_axi_interconnect_2x11_aes.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_axi_interconnect_2x11_aes.v); this is *not* the same register-mapped slave as `axi_aes_slave.v` used inside the two SoC tops

### Known gaps in the integration
- `proj_dir/rtl/Cores-VeeR-EL2/` is present as an **empty directory** in a plain clone/download of this repo (tracked as a gitlink/submodule entry with no `.gitmodules` committed) — the VeeR EL2 source tree must be populated manually before `soc_top_with_veer` or `tb_soc_veer_top.v` can be compiled (see [§7](#7-simulation-prerequisites-and-exact-flows) and [§11](#11-known-limitations-and-current-integration-status))
- `proj_dir/rtl/uartfiles` is a symlink to an **absolute path on the original author's machine** (`/home/student/Documents/.../rtl/uart file`), so it will not resolve on a fresh clone — the real UART sources live at `proj_dir/rtl/uart file/` and can be used directly
- `proj_dir/run/run.f` references `../tb/tb_axi_interconnect_2x11.v`, and `proj_dir/run/run_aes.f` references `../tb/tb_aes_core.v` — **neither file exists** in the current tree (only the `_aes`-suffixed / SoC-level testbenches are present); these two filelists will not compile as-is
- `proj_dir/tb/soc_uart_tb.v` is a committed **empty file** (0 bytes)
- `proj_dir/run/run_spi.f` / `run_spi.sh` reference an SPI master block (`proj_dir/rtl/spi-master-master/...`) that is **not present** in the repository — SPI is planned/referenced but not yet imported

## 3) Detailed architecture and data/control flow

### `soc_top.v` (BFM-facing)
1. Two external AXI4 master ports, `s00` and `s01`, drive `axi_interconnect_wrap_2x11` directly
2. The interconnect decodes/arbitrates/routes to `m00` (I2C bridge), `m01` (AES), `m02` (UART), `m03`–`m10` (dummy)
3. `m00` passes through `axi_to_wb_bridge` (32-bit AXI4‑Lite ↔ 8‑bit/3‑bit Wishbone B4, single outstanding transaction) into `i2c_master_top`
4. `m01` and `m02` are full register-mapped AXI4 slaves (`axi_aes_slave`, `axi_uart_slave`) — no further bridging needed
5. I2C pads (`scl_pad_i/o/oen`, `sda_pad_i/o/oen`), the I2C interrupt (`i2c_irq`), and UART pads (`uart_tx_o`, `uart_rx_i`, `uart_irq`) are exposed at the SoC boundary

### `soc_top_with_veer.v` (VeeR EL2-facing)
1. `el2_veer_wrapper` (compiled with the VeeR-generated `common_defines.vh`/`el2_param.vh`) drives an LSU AXI4 master (64-bit data, 3-bit ID)
2. A width adapter pads the 3-bit VeeR ID to the interconnect's 8-bit `ID_WIDTH`, forwards only the lower 32 bits of `wdata`/`wstrb` on writes, and zero-extends reads back to 64 bits — the CPU is expected to use word-sized (`awsize=2`) MMIO accesses only
3. The adapted bus becomes `s00` into the same `axi_interconnect_wrap_2x11` / I2C / AES / UART / dummy-slave fabric as `soc_top.v`
4. `s01` remains exposed at the top level as a spare master port (e.g. for a second CPU or DMA engine)
5. The core's IFU AXI port is tied to a stub (ICCM mode — instruction fetch never leaves the core); its SB (debug) and DMA AXI ports are tied off entirely
6. JTAG (`jtag_tck/tms/tdi/tdo`), reset/NMI vectors, and a VeeR trace port (`trace_rv_i_*`) are exposed for debug and Verdi probing

## 4) Repository layout (current)
```text
Secure-IoT-Gateway-SoC/
├── README.md
├── .gitignore
├── main                                    # placeholder/build artifact at repo root
└── proj_dir/
    ├── doc/
    │   ├── Secure_IoT_Gateway_Abstract.pdf
    │   ├── Secure_IoT_Gateway_Architecture_Document-1.pdf
    │   ├── uart/
    │   │   ├── axi-uart.png
    │   │   └── axi-uart.vsdx
    │   ├── aes core/
    │   │   ├── aes.pdf
    │   │   └── regmapping
    │   ├── i2c master/
    │   │   ├── i2c_specs.pdf
    │   │   └── src/I2C_specs.doc
    │   └── RISCV-veer-El2 core/             # VeeR EL2 documentation sources (Sphinx/Markdown + PRM PDF)
    ├── rtl/
    │   ├── interconnect/
    │   │   ├── priority_encoder.v
    │   │   ├── arbiter.v
    │   │   ├── axi_interconnect.v
    │   │   ├── axi_interconnect_wrap_2x11.v
    │   │   └── soc_top.v                    # BFM-facing top
    │   ├── top/
    │   │   ├── soc_top_with_veer.v           # VeeR EL2-facing top (Verilog)
    │   │   └── soc_top_with_veer.sv          # VeeR EL2-facing top (SystemVerilog variant)
    │   ├── Cores-VeeR-EL2/                   # gitlink/submodule — EMPTY in a plain clone, see §11
    │   ├── i2c-master/
    │   │   ├── i2c_master_top.v
    │   │   ├── i2c_master_byte_ctrl.v
    │   │   ├── i2c_master_bit_ctrl.v
    │   │   └── i2c_master_defines.v
    │   ├── aes_core-master/
    │   │   ├── rtl/ (aes_cipher_top.v, aes_inv_cipher_top.v, aes_sbox.v, aes_inv_sbox.v,
    │   │   │         aes_key_expand_128.v, aes_rcon.v, axi_aes_slave.v, timescale.v)
    │   │   ├── bench/verilog/test_bench_top.v
    │   │   ├── sim/rtl_sim/                  # committed VCS/Verdi run artifacts
    │   │   ├── syn/bin/*.dc
    │   │   ├── data/sky130.tcl
    │   │   └── aes_core.core                 # FuseSoC core file
    │   ├── uart file/                        # AXI-Lite UART IP (real source — see §11 re: uartfiles symlink)
    │   │   ├── src/include/ (axi_uart.vh, axi_uart_defines.vh)
    │   │   ├── src/rtl/ (axi_uart_top.v, axi_uart_slave.v, axi_internal_fifo.v,
    │   │   │             uart_controller.v, uart_receiver.v, uart_transmitter.v,
    │   │   │             uart_parity_bit_compute.v)
    │   │   ├── src/tb/tb_uart.v
    │   │   ├── src/run/ (run_uart.f + committed VCS/Verdi run artifacts)
    │   │   ├── scripts/, .github/workflows/, LICENSE (MIT), README.md, Makefile, project.config
    │   └── uartfiles -> (broken absolute symlink, see §11)
    ├── tb/
    │   ├── axi_to_wb_bridge.v
    │   ├── axi_to_aes_bridge.v
    │   ├── dummy_axi_slave.v
    │   ├── tb_soc_top.v                      # full-SoC integration TB (12 directed tests)
    │   ├── tb_soc_veer_top.v                 # SoC + VeeR smoke test
    │   ├── tb_axi_interconnect_2x11_aes.v    # interconnect + I2C + AES bridge TB
    │   ├── soc_uart_tb.v                     # empty placeholder, see §11
    │   └── *.png                             # Verdi waveform screenshots (AES/I2C/UART/SoC)
    ├── run/
    │   ├── run.f, run_aes.f, run_integrated.f, run_soc.f     # VCS filelists (manual compile)
    │   ├── run_soc_veer.f / run_soc_veer.sh                  # VeeR SoC flow (scripted)
    │   ├── run_spi.f / run_spi.sh                            # SPI flow — RTL not yet present, see §11
    │   ├── snapshots/default/                                # generated VeeR headers (common_defines.vh, el2_param.vh, …)
    │   ├── simv_aes*, simv_soc_veer*                         # committed compiled simulation binaries
    │   └── novas.conf, novas.rc, verdi_config_file, *.rc     # Verdi session/session-signal config
    └── scripts/
        ├── axi_interconnect_wrap.py          # Jinja2 interconnect wrapper generator
        └── hello.c                           # minimal C sample (int add(a,b)), not yet wired into a build/boot flow
```
> Browse live: [`doc/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/doc) · [`rtl/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl) · [`tb/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/tb) · [`run/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/run) · [`scripts/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/scripts)

## 5) Module/file responsibility table
| File | Responsibility |
|---|---|
| [`rtl/interconnect/priority_encoder.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/priority_encoder.v) | Generic priority encoder used by the arbiter |
| [`rtl/interconnect/arbiter.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/arbiter.v) | Arbitration between the two slave-side masters |
| [`rtl/interconnect/axi_interconnect.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect.v) | Core AXI routing/decode/arbitration/response logic |
| [`rtl/interconnect/axi_interconnect_wrap_2x11.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/axi_interconnect_wrap_2x11.v) | Port-expanded wrapper: 2 slave-side + 11 master-side AXI4 ports, per-master base-address/window parameters |
| [`rtl/interconnect/soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/interconnect/soc_top.v) | BFM-facing SoC top: interconnect + I2C bridge + AES slave + UART slave + 8 dummy slaves |
| [`rtl/top/soc_top_with_veer.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/top/soc_top_with_veer.v) | VeeR EL2-facing SoC top: core + LSU width adapter + IFU/SB/DMA stubs + same interconnect/peripheral set |
| [`tb/axi_to_wb_bridge.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/axi_to_wb_bridge.v) | AXI4‑Lite slave → Wishbone B4 master bridge (32-bit AXI ↔ 8-bit/3-bit WB), single outstanding transaction |
| [`tb/axi_to_aes_bridge.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/axi_to_aes_bridge.v) | AXI4‑Lite wrapper around the AES cipher/inv-cipher pair, used by the standalone interconnect+AES TB only |
| [`tb/dummy_axi_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/dummy_axi_slave.v) | Single-beat AXI4 slave stub: ACKs writes, returns `0xDEAD_xxxx` reads keyed by `SLAVE_INDEX` |
| [`rtl/i2c-master/i2c_master_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/i2c-master/i2c_master_top.v) | WISHBONE rev B.2 I2C master core (OpenCores) |
| [`rtl/aes_core-master/rtl/axi_aes_slave.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/axi_aes_slave.v) | AXI4 register-mapped AES‑128 slave; auto-chains `aes_inv_cipher_top` after `aes_cipher_top` for round-trip decrypt |
| [`rtl/aes_core-master/rtl/aes_cipher_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/aes_cipher_top.v) / [`aes_inv_cipher_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/rtl/aes_inv_cipher_top.v) | AES‑128 forward/inverse cipher datapaths |
| [`rtl/uart file/src/rtl/axi_uart_slave.v`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/src/rtl/axi_uart_slave.v>) | AXI4-full slave wrapper around `axi_uart_top`; buffers the AW beat so it can present AW+W together to the UART core |
| [`rtl/uart file/src/rtl/axi_uart_top.v`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/src/rtl/axi_uart_top.v>) | AXI4‑Lite UART core: THR/RBR/IER/BAUD/LCR/LSR register file, TX/RX FIFOs |
| [`tb/tb_soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_top.v) | Full-SoC integration TB: 12 directed tests across I2C/AES/UART/dummy routing |
| [`tb/tb_soc_veer_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_veer_top.v) | SoC + VeeR EL2 smoke test: loads an ICCM `.hex` image, watches UART TX for firmware activity |
| [`tb/tb_axi_interconnect_2x11_aes.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_axi_interconnect_2x11_aes.v) | Interconnect + I2C (via `axi_to_wb_bridge`) + AES (via `axi_to_aes_bridge`) + dummy-slave routing test |
| [`run/run.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run.f) | Filelist for the bare interconnect+I2C TB — **references a missing TB file**, see [§11](#11-known-limitations-and-current-integration-status) |
| [`run/run_aes.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_aes.f) | Filelist for a standalone AES-core TB — **references a missing TB file**, see §11 |
| [`run/run_integrated.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_integrated.f) | Filelist for `tb_axi_interconnect_2x11_aes.v` |
| [`run/run_soc.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_soc.f) | Filelist for `tb_soc_top.v` against `soc_top.v` |
| [`run/run_soc_veer.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_soc_veer.f), [`run/run_soc_veer.sh`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_soc_veer.sh) | Filelist + compile/sim/wave launcher for the VeeR-integrated SoC |
| [`run/run_spi.f`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_spi.f), [`run/run_spi.sh`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/run/run_spi.sh) | Filelist + launcher for a planned SPI master block — RTL not yet imported, see §11 |
| [`scripts/axi_interconnect_wrap.py`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/scripts/axi_interconnect_wrap.py) | Jinja2 generator for `axi_interconnect_wrap_MxN.v` (`-p`, `-n`, `-o`) |
| [`scripts/hello.c`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/scripts/hello.c) | Minimal C snippet (`add(a,b)`); not yet wired into any build/boot flow |

## 6) Register maps

### AES‑128 (`axi_aes_slave.v`, offsets relative to `AES_BASE = 0x0100_0000`)
*(from the module header and [`doc/aes core/regmapping`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/aes%20core/regmapping>))*

| Offset | Register | Access | Contents |
|---|---|---|---|
| `0x00` | `CTRL_STATUS` | R/W | `[17]=KDONE` `[16]=DONE` `[2]=RST` `[1]=KLD` `[0]=LD` |
| `0x04`–`0x10` | `KEY0`..`KEY3` | R/W | Key `[127:96]` .. `[31:0]` (MSB word first) |
| `0x14`–`0x20` | `TEXT0`..`TEXT3` | R/W | Plaintext `[127:96]` .. `[31:0]` |
| `0x24`–`0x30` | `OUT0`..`OUT3` | RO | Ciphertext (or, after the inverse-cipher auto-chain, recovered plaintext) `[127:96]` .. `[31:0]` |

Encrypt: pulse `LD` (`aes_inv_cipher_top.KLD` pre-loads its key schedule in the same cycle) → ~11 cycles later `DONE` fires and the inverse cipher's `LD` fires automatically, feeding the ciphertext back in for a round-trip check → ~11 more cycles later `KDONE`-gated decrypt completes. `tb_soc_top.v` verifies both forward encryption and the round-trip against:
- NIST FIPS‑197 Appendix B: key `2B7E1516…09CF4F3C`, plaintext `3243F6A8…E0370734`, ciphertext `3925841D…196A0B32`
- NIST FIPS‑197 Appendix C.1: key `000102030405060708090A0B0C0D0E0F`, plaintext `00112233…CCDDEEFF`, ciphertext `69C4E0D8…B570EFAD`

### UART (`axi_uart_top.v`, offsets relative to `UART_BASE = 0x0200_0000`, `reg[4:2]` decode)
| Offset | reg[4:2] | Register | DLAB gate |
|---|---|---|---|
| `0x00` | 0 | THR (write) / RBR (read) | `LCR[7]` (DLAB) = 0 |
| `0x04` | 1 | IER | DLAB = 0 |
| `0x08` | 2 | BAUD_DIVISOR | DLAB = 1 |
| `0x0C` | 3 | LCR | always |
| `0x14` | 5 | LSR (read-only) | always |

Init sequence used by `tb_soc_top.v`: `LCR=0x83` (DLAB=1, 8N1) → `BAUD=divisor` (e.g. 868 for 115200 baud @ 100 MHz) → `LCR=0x03` (DLAB=0, locks baud) → `IER=0x01` (enable RX interrupt, needed for LSR `DATA_READY`) → write `THR` to transmit.

### I2C (Wishbone, via `axi_to_wb_bridge`, 3-bit WB address / 8-bit WB data)
`tb_soc_top.v` and `tb_axi_interconnect_2x11_aes.v` exercise the I2C prescaler and control registers through the bridge (register layout follows the standard OpenCores I2C-master WISHBONE map: `PRER_LO`/`PRER_HI`/`CTR`/`TXR`/`RXR`/`CR`/`SR`).

---

## 7) Simulation prerequisites and exact flows

### Prerequisites
- Synopsys VCS + Verdi
- `run/run_soc_veer.sh` hardcodes `VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03`, `VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1`, and a license server address — edit these for any other environment
- **For the VeeR-integrated flow:** `proj_dir/rtl/Cores-VeeR-EL2/` must first be populated with the [chipsalliance/Cores-VeeR-EL2](https://github.com/chipsalliance/Cores-VeeR-EL2) source tree (it ships empty in this repo — see [§11](#11-known-limitations-and-current-integration-status)), and the generated headers `common_defines.vh`/`el2_param.vh`/`el2_pdef.vh` (already checked in under [`run/snapshots/default/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/run/snapshots/default)) must be reachable via `+incdir+./snapshots/default`

### I2C + AES via the interconnect (`run_integrated.f`)
```bash
cd proj_dir/run
vcs -sverilog -full64 -f run_integrated.f -o simv_integrated \
    +define+FSDB \
    -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
    2>&1 | tee compile_integrated.log
./simv_integrated | tee sim_integrated.log
```

### Full SoC — `soc_top.v` + `tb_soc_top.v` (`run_soc.f`)
```bash
cd proj_dir/run
vcs -sverilog -full64 -f run_soc.f -o simv_soc \
    2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log

# With Verdi FSDB:
vcs -sverilog -full64 -f run_soc.f -o simv_soc \
    -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
       ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
    2>&1 | tee compile_soc.log && ./simv_soc | tee sim_soc.log
verdi -f run_soc.f -ssf dump_soc_uart.fsdb &
```
> `run_soc.f` expects UART sources at `../rtl/uartfiles/src/include` — since that symlink is broken on a fresh clone (see §11), point `+incdir` at `../rtl/uart file/src/include` instead, or recreate the `uartfiles` symlink locally.

### SoC + VeeR EL2 (`run_soc_veer.f` / `run_soc_veer.sh`)
```bash
cd proj_dir/run
chmod +x run_soc_veer.sh
./run_soc_veer.sh compile   # compile only
./run_soc_veer.sh sim       # simulate (needs prior compile)
./run_soc_veer.sh wave      # open Verdi on the existing FSDB
./run_soc_veer.sh clean     # remove generated artifacts
./run_soc_veer.sh           # compile → simulate → open Verdi
```
Firmware loading for `tb_soc_veer_top.v`: a `$readmemh`-format `.hex` file is loaded directly into the VeeR ICCM array via a hierarchical path (`el2_veer_wrapper → el2_mem → iccm`); pass it with `+hex_file+/path/to/firmware.hex` or edit the `HEX_PATH` localparam in the testbench. Reset vector is `0x8000_0000`; ICCM base is `0xEE00_0000`.

### AES standalone (`run_aes.f`) and bare interconnect (`run.f`)
Both filelists compile the relevant RTL correctly but point at testbench files (`tb_aes_core.v`, `tb_axi_interconnect_2x11.v`) that are not present in this snapshot of the repo (see §11) — add the missing TB or repoint the filelist at `tb_axi_interconnect_2x11_aes.v` / `bench/verilog/test_bench_top.v` before running.

### SPI (`run_spi.f` / `run_spi.sh`)
References a `spi-master-master` block that has not been imported yet — see §11.

---

## 8) Verification strategy and covered scenarios

### Full-SoC TB ([`tb_soc_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_top.v))
Twelve directed tests against `soc_top.v`, with pass/fail counters and a global timeout watchdog:
- **[01]** I2C prescaler & control register read/write, plus a configuration + START/WRITE sequence
- **[02]** AES key-only load (`CTRL.KLD`) → poll `KDONE`
- **[03]** AES encrypt vs. NIST FIPS‑197 Appendix B
- **[04]** AES round-trip via the inverse-cipher auto-chain
- **[05]** AES encrypt vs. NIST FIPS‑197 Appendix C.1
- **[06]** AES key readback
- **[07]** UART init: `LCR` DLAB=1 → baud divisor → `LCR` DLAB=0 → `IER=1`
- **[08]** UART transmit `0x55` via an AXI write to `THR`
- **[09]** UART TX: poll `LSR.THRE` (TX holding register empty)
- **[10]** UART RX loopback: after a baud-rate wait, check `LSR.DATA_READY` and read `RBR` back (`uart_rx` is physically tied to `uart_tx` in the TB)
- **[11]** Dummy-slave `m03` routing (`0x0300_0000` → `0xDEAD_0003`)
- **[12]** AES soft-reset (`CTRL.RST`)

FSDB signals captured include the `s00` AXI master channel, the `m02` (UART) interconnect channel, `axi_uart_slave` internal AW-buffering state, and `axi_uart_top` internals (write/read FSM state, config register, baud divisor, TX FIFO push/data, LSR register).

### VeeR smoke test ([`tb_soc_veer_top.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_soc_veer_top.v))
Asserts reset for 10 cycles, releases it so VeeR fetches from its ICCM, then monitors UART TX for output (with `uart_rx_i` looped back to `uart_tx_o`) — a 200 µs timeout flags no-activity. This validates that a CPU-fetched program can actually drive the SoC's peripherals through the full AXI path, rather than the BFM-injected stimulus used elsewhere.

### Interconnect + I2C + AES TB ([`tb_axi_interconnect_2x11_aes.v`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/tb/tb_axi_interconnect_2x11_aes.v))
1. Configure the I2C prescaler and enable the core via `m00`
2. Read back I2C registers via `m00`
3. Program the AES key/plaintext, trigger encrypt, poll `DONE`, read the result — all via `m01`
4. Feed the ciphertext back in, trigger decrypt, poll `DONE`, confirm the plaintext is recovered
5. Read `m02` (dummy slave) to verify routing

### Evidence of runs already performed
Verdi waveform screenshots are committed under [`proj_dir/tb/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/tb) (`soc_i2c_uart_aes.png`, `aes_test.png`, `aes_test22.png`, `i2c_test.png`, `i2c_test22.png`, `i2c_test_integrated.png`, `uart_tb.png`), and compiled `simv_aes` / `simv_soc_veer` binaries are committed under `proj_dir/run/`, indicating the AES-standalone and SoC+VeeR flows have each been built and simulated at least once in the original environment.

## 9) Wrapper generator usage (`scripts/axi_interconnect_wrap.py`)
Dependency: Python package `jinja2`.
```bash
python proj_dir/scripts/axi_interconnect_wrap.py -p 2 11 -n axi_interconnect_wrap_2x11 -o axi_interconnect_wrap_2x11.v
```
`-p` accepts one value (equal master/slave count) or two values (`m n`) — this is how `axi_interconnect_wrap_2x11.v` itself was generated.

## 10) Imported IP notes (I2C / AES / UART / VeeR EL2) — sources and references

### I2C master — [`rtl/i2c-master/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/i2c-master)
| | |
|---|---|
| **Upstream source** | [OpenCores I2C-Master Core](https://opencores.org/projects/i2c) — WISHBONE rev B.2 compliant I2C master, by Richard Herveille |
| **Datasheet** | [`doc/i2c master/i2c_specs.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/i2c%20master/i2c_specs.pdf>) |
| **Status in this repo** | `i2c_master_top.v`, `i2c_master_byte_ctrl.v`, `i2c_master_bit_ctrl.v`, `i2c_master_defines.v` imported; bridged onto the AXI‑Lite side via `axi_to_wb_bridge.v` at `m00` |

### AES‑128 core — [`rtl/aes_core-master/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/aes_core-master)
| | |
|---|---|
| **Upstream source** | `asics.ws::aes:1.1` per the committed [`aes_core.core`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/aes_core-master/aes_core.core) FuseSoC file (Secworks-style hardware AES core), extended here with an AXI slave wrapper (`axi_aes_slave.v`) |
| **Datasheet** | [`doc/aes core/aes.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/aes%20core/aes.pdf>), [`doc/aes core/regmapping`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/aes%20core/regmapping>) |
| **Reference vectors** | NIST FIPS‑197, Appendices B and C.1 |
| **Status in this repo** | RTL, AXI slave wrapper, bench, FuseSoC core file, sky130 synthesis TCL, and RTL-sim run collateral included; integrated at `m01` in both SoC tops |

### AXI‑Lite UART IP — [`rtl/uart file/`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/uart%20file>)
| | |
|---|---|
| **Upstream source** | [`axi-lite_uart-ipcore`](https://github.com/m4j0rt0m/axi-lite_uart-ipcore) by Abraham J. Ruiz R. (`m4j0rt0m`) |
| **License** | MIT — [`rtl/uart file/LICENSE`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/LICENSE>) |
| **Diagram** | [`doc/uart/axi-uart.png`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/uart/axi-uart.png), [`doc/uart/axi-uart.vsdx`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/uart/axi-uart.vsdx) |
| **Status in this repo** | RTL, headers, TB, Makefile-based build, CI workflow configs (lint-verilator, synth-quartus, synth-yosys), and license included; extended here with `axi_uart_slave.v` (AXI4-full wrapper) and integrated at `m02` |

### VeeR EL2 RISC‑V core — [`rtl/Cores-VeeR-EL2/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/Cores-VeeR-EL2)
| | |
|---|---|
| **Upstream source** | [chipsalliance/Cores-VeeR-EL2](https://github.com/chipsalliance/Cores-VeeR-EL2) (originally Western Digital's SweRV EL2, now maintained under CHIPS Alliance), Apache‑2.0 |
| **Reference manual (PRM)** | [`doc/RISCV-veer-El2 core/RISC-V_VeeR_EL2_PRM.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/RISCV-veer-El2%20core/RISC-V_VeeR_EL2_PRM.pdf>); Sphinx/Markdown doc sources also under the same `doc/RISCV-veer-El2 core/source/` tree |
| **Status in this repo** | Tracked as a gitlink/submodule entry — **the source tree is not populated** in a plain clone/tarball of this repo (see §11); generated config headers (`common_defines.vh`, `el2_param.vh`, `el2_pdef.vh`, `whisper.json`, `link.ld`, …) for the `default` snapshot are checked in under [`run/snapshots/default/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/run/snapshots/default), and `soc_top_with_veer.v` wires the core in via `el2_veer_wrapper` with a 64→32-bit LSU width adapter |

### SPI master — referenced, not yet imported
`run_spi.f`/`run_spi.sh` expect a `spi-master-master` block (`SPI_Master.v`, `SPI_Master_With_Single_CS.v`, `SPI_Master_With_Single_CS_TB.sv`) under `proj_dir/rtl/spi-master-master/` that is not present in this snapshot — see §11.

### Interconnect / bridge / top-level RTL — [`rtl/interconnect/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/interconnect), [`rtl/top/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/rtl/top)
Original/authored for this project: `axi_interconnect.v`, `axi_interconnect_wrap_2x11.v`, `arbiter.v`, `priority_encoder.v`, `soc_top.v`, `soc_top_with_veer.v`/`.sv`, `axi_to_wb_bridge.v`, `axi_to_aes_bridge.v`, `dummy_axi_slave.v`, `axi_uart_slave.v`, `axi_aes_slave.v`.

---

## 11) Known limitations and current integration status
- `proj_dir/rtl/Cores-VeeR-EL2/` ships as an **empty directory** — it is a gitlink/submodule reference with no `.gitmodules` committed, so `soc_top_with_veer.v` and `tb_soc_veer_top.v` cannot be compiled until the VeeR EL2 source tree is populated manually from [chipsalliance/Cores-VeeR-EL2](https://github.com/chipsalliance/Cores-VeeR-EL2)
- `proj_dir/rtl/uartfiles` is an **absolute symlink** pointing into the original author's local filesystem (`/home/student/Documents/1602-23-735-311/...`) and will not resolve elsewhere; use `proj_dir/rtl/uart file/` directly instead
- `run/run.f` and `run/run_aes.f` each reference a testbench file (`tb_axi_interconnect_2x11.v`, `tb_aes_core.v`) that is **not present** in the repository — only the `_aes`-suffixed interconnect TB and the AES bench under `aes_core-master/bench/` exist
- `proj_dir/tb/soc_uart_tb.v` is a committed **empty placeholder** file
- `run/run_spi.f` / `run_spi.sh` reference an SPI master block whose RTL/TB has **not yet been added** to `proj_dir/rtl/`
- No top-level SoC block diagram is currently checked into `proj_dir/doc/` (only the UART IP's own diagram is present) — see [§ Diagrams](#diagrams)
- `run/run_soc_veer.sh` hardcodes tool paths and a license-server address specific to the original build environment and needs local edits to run elsewhere
- The repository's GitHub "About" field currently has no description or topics set
- Generated simulation artifacts (`AN.DB/`, `simv*`, `*.daidir/`, `csrc/`, Verdi session logs) are present in the committed tree under `proj_dir/run/` and various `sim/`/`run/` subfolders

## 12) Contribution/dev guidance and provenance notes
- Prefer modifying source under `proj_dir/rtl/interconnect/`, `proj_dir/rtl/top/`, `proj_dir/tb/`, `proj_dir/run/`, and root-level docs, while treating imported third-party IP trees (`i2c-master/`, `aes_core-master/`, `uart file/`, `Cores-VeeR-EL2/`) as vendored unless intentionally updating them
- License/provenance signals in-tree:
  - MIT license file in the UART IP subtree ([`rtl/uart file/LICENSE`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/rtl/uart%20file/LICENSE>))
  - OpenCores/Richard Herveille copyright header in `i2c_master_top.v` ("may be used and distributed without restriction provided that this copyright statement is not removed")
  - FuseSoC core metadata (`aes_core.core`) for the AES core
  - Apache‑2.0 license on the upstream VeeR EL2 project (not yet vendored into this repo's tree — see §11)
- No top-level `LICENSE` file is currently present at the repository root — consider adding one compatible with all vendored licenses (MIT, OpenCores' permissive notice, Apache‑2.0) if the repo will be distributed
- Before adding a real SPI master, either finish importing `spi-master-master` under `proj_dir/rtl/` to match `run_spi.f`, or update the filelist to point at wherever it actually lands
- `proj_dir/.gitignore` exists but generated VCS/Verdi artifacts are already committed in several places (`run/AN.DB/`, `run/simv_*`, `aes_core-master/sim/rtl_sim/run/csrc/`, `uart file/src/run/csrc/`, Verdi logs) — cleaning these out of history would shrink the repo substantially

## 13) Quick reference commands
```bash
# Interconnect + I2C + AES (via bridges)
cd proj_dir/run
vcs -sverilog -full64 -f run_integrated.f -o simv_integrated && ./simv_integrated

# Full SoC (BFM-driven)
cd proj_dir/run
vcs -sverilog -full64 -f run_soc.f -o simv_soc && ./simv_soc

# Full SoC + VeeR EL2 (requires Cores-VeeR-EL2 populated first — see §11)
cd proj_dir/run
./run_soc_veer.sh compile
./run_soc_veer.sh sim
./run_soc_veer.sh wave

# Wrapper generation (requires jinja2)
python proj_dir/scripts/axi_interconnect_wrap.py -p 2 11 -n axi_interconnect_wrap_2x11 -o axi_interconnect_wrap_2x11.v
```

---

## Documents Index
| File | Type | Description |
|---|---|---|
| [`doc/Secure_IoT_Gateway_Abstract.pdf`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/Secure_IoT_Gateway_Abstract.pdf) | PDF | Project abstract |
| [`doc/Secure_IoT_Gateway_Architecture_Document-1.pdf`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/Secure_IoT_Gateway_Architecture_Document-1.pdf) | PDF | Full architecture document |
| [`doc/uart/axi-uart.png`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/uart/axi-uart.png) | Image | AXI-Lite UART IP block diagram (embedded above) |
| [`doc/uart/axi-uart.vsdx`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/uart/axi-uart.vsdx) | Visio | Editable source diagram for the UART block diagram |
| [`doc/aes core/aes.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/aes%20core/aes.pdf>) | PDF | AES core datasheet/design documentation |
| [`doc/aes core/regmapping`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/aes%20core/regmapping>) | Text | AES register map source (see [§6](#6-register-maps)) |
| [`doc/i2c master/i2c_specs.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/i2c%20master/i2c_specs.pdf>) | PDF | I2C master core specification |
| [`doc/i2c master/src/I2C_specs.doc`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/i2c%20master/src/I2C_specs.doc>) | Word doc | I2C specification source |
| [`doc/RISCV-veer-El2 core/RISC-V_VeeR_EL2_PRM.pdf`](<https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/blob/main/proj_dir/doc/RISCV-veer-El2%20core/RISC-V_VeeR_EL2_PRM.pdf>) | PDF | VeeR EL2 core Programmer's Reference Manual |

Verdi waveform/verification screenshots (referenced in [§8](#8-verification-strategy-and-covered-scenarios)) live under [`tb/`](https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/tree/main/proj_dir/tb) — `soc_i2c_uart_aes.png`, `aes_test*.png`, `i2c_test*.png`, `uart_tb.png`.

---

<p align="center"><sub>Secure IoT Gateway SoC — AXI4 interconnect with I2C / AES-128 / UART, optional VeeR EL2 integration · Bhumesh</sub></p>
