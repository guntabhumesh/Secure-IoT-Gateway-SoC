
//------------------------------------------------------------------------------
// File: axi4lite_slave_adapter.sv
// Description: Generic AXI4-Lite Slave Adapter.
// Converts AXI4-Lite transactions into a simple native register bus.
//
// Author: Gemini-3 AI
// License: MIT
//------------------------------------------------------------------------------



module axi4lite_slave_adapter #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    // AXI4-Lite Interface
    input logic aclk,
    input logic aresetn,

    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [           2:0] s_axi_awprot,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                  s_axi_awvalid,
    output logic                  s_axi_awready,

    // Write Data Channel
    input  logic [    DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic                      s_axi_wvalid,
    output logic                      s_axi_wready,

    // Write Response Channel
    output logic [1:0] s_axi_bresp,
    output logic       s_axi_bvalid,
    input  logic       s_axi_bready,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
    // verilator lint_off UNUSEDSIGNAL
    input  logic [           2:0] s_axi_arprot,
    // verilator lint_on UNUSEDSIGNAL
    input  logic                  s_axi_arvalid,
    output logic                  s_axi_arready,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0] s_axi_rdata,
    output logic [           1:0] s_axi_rresp,
    output logic                  s_axi_rvalid,
    input  logic                  s_axi_rready,

    // Native Register Bus
    output logic [    ADDR_WIDTH-1:0] reg_addr,
    output logic [    DATA_WIDTH-1:0] reg_wdata,
    input  logic [    DATA_WIDTH-1:0] reg_rdata,
    output logic                      reg_we,
    output logic                      reg_re,
    output logic [(DATA_WIDTH/8)-1:0] reg_be
);

  // Internal State
  logic aw_en;

  // Write Address & Data Handshake
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end else begin
      if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
        s_axi_awready <= 1'b1;
        aw_en <= 1'b0;
      end else if (s_axi_bready && s_axi_bvalid) begin
        aw_en <= 1'b1;
        s_axi_awready <= 1'b0;
      end else begin
        s_axi_awready <= 1'b0;
      end
    end
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_wready <= 1'b0;
    end else begin
      if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
        s_axi_wready <= 1'b1;
      end else begin
        s_axi_wready <= 1'b0;
      end
    end
  end

  // Write Response
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= 2'b0;
    end else begin
      if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= 2'b0;
      end else if (s_axi_bready && s_axi_bvalid) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  // Read Address Handshake
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_arready <= 1'b0;
    end else begin
      if (~s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
        s_axi_arready <= 1'b1;
      end else begin
        s_axi_arready <= 1'b0;
      end
    end
  end

  // Read Data & Response
  logic [DATA_WIDTH-1:0] rdata_reg;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rresp  <= 2'b0;
      rdata_reg    <= '0;
    end else begin
      if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rresp  <= 2'b0;
        rdata_reg    <= reg_rdata; // Capture data from slave
      end else if (s_axi_rready && s_axi_rvalid) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  // Output Assignments (Native Bus)
  assign reg_we    = s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid;
  assign reg_addr  = reg_we ? s_axi_awaddr : s_axi_araddr;
  assign reg_wdata = s_axi_wdata;
  assign reg_be    = s_axi_wstrb;
  assign reg_re    = s_axi_arready && s_axi_arvalid;

  // Read Data Output
  assign s_axi_rdata = rdata_reg;

endmodule
