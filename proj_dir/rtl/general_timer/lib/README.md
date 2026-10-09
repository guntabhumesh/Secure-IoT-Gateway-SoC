# Shared IP Library

This directory contains shared RTL and Verification components used across multiple IP blocks (e.g., GPIO, General Timer) to ensure consistency and reduce code duplication.

## Directory Structure

- `rtl/`: Synthesizable Bus Adapters (SystemVerilog and VHDL).
- `verif/`: Verification Bus Functional Models (BFMs) and Tasks.

## RTL Adapters (`rtl/`)

These modules adapt standard bus protocols (AXI4-Lite, APB4, AHB-Lite, Wishbone B4) to a simple, generic "Native Register Interface" used by the IP cores.

### SystemVerilog (`*.sv`)
- **`axi4lite_slave_adapter.sv`**: Connects an AXI4-Lite master to the native register interface. Handles the AXI handshake state machine.
- **`apb_slave_adapter.sv`**: Connects an APB4 master to the native register interface. Zero-wait state implementation.
- **`ahb_slave_adapter.sv`**: Connects an AHB-Lite master to the native register interface. Implements 0-wait state transactions for both read and write during the data phase.
- **`wb_slave_adapter.sv`**: Connects a Wishbone B4 master to the native register interface.
    - *Note*: Implements a 1-cycle wait state for ack generation.
    - *Critical*: Gates `reg_we` with `!reg_ack` to prevent atomic double-writes. Does *not* gate `reg_re` to ensure read data validity during the ack cycle.

### VHDL (`*.vhd`)
- **`axi4lite_slave_adapter.vhd`**: VHDL equivalent of the AXI4-Lite adapter.
- **`apb_slave_adapter.vhd`**: VHDL equivalent of the APB4 adapter.
- **`ahb_slave_adapter.vhd`**: VHDL equivalent of the AHB-Lite adapter.
- **`wb_slave_adapter.vhd`**: VHDL equivalent of the Wishbone B4 adapter. Implements the same atomic write projection logic as the SV version.

### Native Register Interface
All adapters output a standardized interface to the IP core:
- `reg_addr` (Output): Register address.
- `reg_wdata` (Output): Write data.
- `reg_rdata` (Input): Read data from IP core.
- `reg_we` (Output): Write Enable strobe (1 cycle).
- `reg_re` (Output): Read Enable strobe (1 cycle).
- `reg_be` (Output): Byte Enable strobes.

---

## Verification Library (`verif/`)

These files provide standardized tasks and procedures for simulating bus transactions in testbenches.

### SystemVerilog (`*.sv`)
Intended to be included (`include`) inside a testbench module/program.
- **`axi_bfm_tasks.sv`**: Provides `axi_write` and `axi_read` tasks.
- **`apb_bfm_tasks.sv`**: Provides `apb_write` and `apb_read` tasks.
- **`wb_bfm_tasks.sv`**: Provides `wb_write` and `wb_read` tasks.

### VHDL (`*.vhd`)
Implemented as Packages. Testbenches should add `use work.<package_name>.all;`.
- **`axi_bfm_pkg.vhd`**: Package containing `axi_write` and `axi_read` procedures.
- **`apb_bfm_pkg.vhd`**: Package containing `apb_write` and `apb_read` procedures.
- **`wb_bfm_pkg.vhd`**: Package containing `wb_write` and `wb_read` procedures.
