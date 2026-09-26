# Secure IoT Gateway SoC

A SystemVerilog/Verilog SoC integration project centered on an AXI interconnect with I2C, AES, and UART peripherals, with optional VeeR EL2 RISC-V top integration for firmware-driven simulation.

## Highlights

- AXI4 interconnect wrapper (`2 masters x 11 slaves`)
- Peripheral integration:
  - I2C master (Wishbone IP behind AXI→Wishbone bridge)
  - AES accelerator (AXI slave + AES cipher/inv-cipher chain)
  - UART (AXI wrapper around AXI-lite UART core)
- Optional VeeR EL2 integration with LSU width adaptation (`64-bit LSU -> 32-bit SoC bus`)
- Multiple integration testbenches and VCS/Verdi run flows

## Repository Structure

- `proj_dir/rtl/interconnect/` — AXI interconnect and SoC integration
- `proj_dir/rtl/i2c-master/` — I2C master RTL
- `proj_dir/rtl/aes_core-master/rtl/` — AES core + AXI AES slave wrapper
- `proj_dir/rtl/uart file/src/rtl/` — UART core + AXI UART slave wrapper
- `proj_dir/rtl/top/` — `soc_top_with_veer` integration top
- `proj_dir/tb/` — testbenches and bridge/dummy support modules
- `proj_dir/run/` — VCS/Verdi filelists and run scripts
- `proj_dir/doc/` — architecture/reference docs and diagrams

## SoC Address Map

| Slave | Base Address  | Function |
|------:|---------------|----------|
| m00   | `0x0000_0000` | I2C (AXI→Wishbone bridge → `i2c_master_top`) |
| m01   | `0x0100_0000` | AES AXI slave |
| m02   | `0x0200_0000` | UART AXI slave |
| m03–m10 | `0x0300_0000`..`0x0A00_0000` | Dummy AXI slaves |

## Key RTL Entry Points

- `proj_dir/rtl/interconnect/soc_top.v`
- `proj_dir/rtl/top/soc_top_with_veer.v`
- `proj_dir/rtl/interconnect/axi_interconnect_wrap_2x11.v`
- `proj_dir/rtl/aes_core-master/rtl/axi_aes_slave.v`
- `proj_dir/rtl/uart file/src/rtl/axi_uart_slave.v`
- `proj_dir/tb/axi_to_wb_bridge.v`

## Testbenches

- `proj_dir/tb/tb_soc_top.v`  
  Full integration test (I2C + AES + UART + dummy routing), including NIST AES vectors and UART loopback checks.
- `proj_dir/tb/tb_axi_interconnect_2x11_aes.v`  
  Interconnect + I2C + AES bridge integration.
- `proj_dir/tb/tb_soc_veer_top.v`  
  SoC + VeeR smoke test with trace/UART activity checks.

## Run Flows

Primary run assets are under `proj_dir/run/`:

- `run_soc.f`
- `run_integrated.f`
- `run_soc_veer.f`
- `run_soc_veer.sh`
- `run_spi.f`
- `run_spi.sh`

## Documentation

- Main docs directory: `proj_dir/doc/`
- VeeR EL2 documentation sources: `proj_dir/doc/RISCV-veer-El2 core/source/`
- Project PDFs:
  - `proj_dir/doc/Secure_IoT_Gateway_Abstract.pdf`
  - `proj_dir/doc/Secure_IoT_Gateway_Architecture_Document-1.pdf`

## Current Caveats

- `proj_dir/rtl/Cores-VeeR-EL2` is tracked as a gitlink/submodule entry and may require explicit population in fresh clones.
- `proj_dir/rtl/uartfiles` is an absolute symlink target from the original author environment.
- Some run filelists reference paths that may require cleanup for fully portable out-of-the-box simulation.
- Generated simulation artifacts are present in repository history.

## Suggested Figures

- `proj_dir/tb/soc_i2c_uart_aes.png`
- `proj_dir/doc/uart/axi-uart.png`
- `proj_dir/doc/RISCV-veer-El2 core/source/img/core_complex.png`

## Contributors

- [@guntabhumesh](https://github.com/guntabhumesh)

## Commit History

- https://github.com/guntabhumesh/Secure-IoT-Gateway-SoC/commits/main
