//------------------------------------------------------------------------------
// File: ahb_slave_adapter.sv
// Description: Generic AHB-Lite Slave Adapter.
// Converts AHB-Lite transactions into a simple native register bus.
//
// Author: Gemini-3 AI
// License: MIT
//------------------------------------------------------------------------------

module ahb_slave_adapter #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic hclk,
    input logic hresetn,

    // AHB-Lite Interface
    input  logic                  hsel,
    input  logic [ADDR_WIDTH-1:0] haddr,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [           1:0] htrans,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                  hwrite,
    input  logic [           2:0] hsize,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [           2:0] hburst,
    input  logic [           3:0] hprot,
    // verilator lint_on UNUSEDSIGNAL
    input  logic [DATA_WIDTH-1:0] hwdata,
    input  logic                  hready_i,
    output logic                  hready_o,
    output logic [           1:0] hresp,
    output logic [DATA_WIDTH-1:0] hrdata,

    // Native Register Bus
    output logic [    ADDR_WIDTH-1:0] reg_addr,
    output logic [    DATA_WIDTH-1:0] reg_wdata,
    input  logic [    DATA_WIDTH-1:0] reg_rdata,
    output logic                      reg_we,
    output logic                      reg_re,
    output logic [(DATA_WIDTH/8)-1:0] reg_be
);

  // Address Phase Registers
  logic [ADDR_WIDTH-1:0] addr_reg;
  logic                  write_reg;
  logic [           2:0] size_reg;
  logic                  active_req;

  // Capture Address Phase
  always_ff @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      addr_reg   <= '0;
      write_reg  <= '0;
      size_reg   <= '0;
      active_req <= 1'b0;
    end else begin
      if (hsel && hready_i && htrans[1]) begin
        addr_reg   <= haddr;
        write_reg  <= hwrite;
        size_reg   <= hsize;
        active_req <= 1'b1;
      end else if (hready_i) begin
        active_req <= 1'b0;
      end
    end
  end

  // Data Phase (Native Bus Outputs)
  assign reg_addr  = addr_reg;
  assign reg_wdata = hwdata;
  assign reg_we    = active_req && write_reg;
  assign reg_re    = active_req && !write_reg;

  // Byte Enable Logic based on hsize and addr_reg
  always_comb begin
    reg_be = '0;
    if (active_req) begin
      case (size_reg)
        3'b000:  reg_be = 4'b0001 << addr_reg[1:0];  // Byte
        3'b001:  reg_be = 4'b0011 << addr_reg[1:0];  // Halfword
        3'b010:  reg_be = 4'b1111;  // Word
        default: reg_be = 4'b1111;
      endcase
    end
  end

  // AHB Responses
  assign hready_o = 1'b1; // Zero-wait state for now
  assign hresp    = 2'b00; // OKAY
  assign hrdata   = reg_rdata;

endmodule
