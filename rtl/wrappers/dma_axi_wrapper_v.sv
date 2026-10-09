
`timescale 1ns/1ps
module dma_axi_wrapper_v #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,

    // AXI-Lite CSR Slave Interface
    input  wire [ID_WIDTH-1:0]    csr_awid,
    input  wire [ADDR_WIDTH-1:0]  csr_awaddr,
    input  wire [2:0]             csr_awprot,
    input  wire                   csr_awvalid,
    output wire                   csr_awready,
    input  wire [DATA_WIDTH-1:0]  csr_wdata,
    input  wire [DATA_WIDTH/8-1:0] csr_wstrb,
    input  wire                   csr_wvalid,
    output wire                   csr_wready,
    output wire [ID_WIDTH-1:0]    csr_bid,
    output wire [1:0]             csr_bresp,
    output wire                   csr_bvalid,
    input  wire                   csr_bready,
    input  wire [ID_WIDTH-1:0]    csr_arid,
    input  wire [ADDR_WIDTH-1:0]  csr_araddr,
    input  wire [2:0]             csr_arprot,
    input  wire                   csr_arvalid,
    output wire                   csr_arready,
    output wire [ID_WIDTH-1:0]    csr_rid,
    output wire [DATA_WIDTH-1:0]  csr_rdata,
    output wire [1:0]             csr_rresp,
    output wire                   csr_rlast,
    output wire                   csr_rvalid,
    input  wire                   csr_rready,

    // AXI Master Interface
    output wire [ID_WIDTH-1:0]    m_awid,
    output wire [ADDR_WIDTH-1:0]  m_awaddr,
    output wire [7:0]             m_awlen,
    output wire [2:0]             m_awsize,
    output wire [1:0]             m_awburst,
    output wire                   m_awlock,
    output wire [3:0]             m_awcache,
    output wire [2:0]             m_awprot,
    output wire [3:0]             m_awqos,
    output wire [3:0]             m_awregion,
    output wire [0:0]             m_awuser,
    output wire                   m_awvalid,
    input  wire                   m_awready,
    output wire [DATA_WIDTH-1:0]  m_wdata,
    output wire [DATA_WIDTH/8-1:0] m_wstrb,
    output wire                   m_wlast,
    output wire [0:0]             m_wuser,
    output wire                   m_wvalid,
    input  wire                   m_wready,
    input  wire [ID_WIDTH-1:0]    m_bid,
    input  wire [1:0]             m_bresp,
    input  wire [0:0]             m_buser,
    input  wire                   m_bvalid,
    output wire                   m_bready,
    output wire [ID_WIDTH-1:0]    m_arid,
    output wire [ADDR_WIDTH-1:0]  m_araddr,
    output wire [7:0]             m_arlen,
    output wire [2:0]             m_arsize,
    output wire [1:0]             m_arburst,
    output wire                   m_arlock,
    output wire [3:0]             m_arcache,
    output wire [2:0]             m_arprot,
    output wire [3:0]             m_arqos,
    output wire [3:0]             m_arregion,
    output wire [0:0]             m_aruser,
    output wire                   m_arvalid,
    input  wire                   m_arready,
    input  wire [ID_WIDTH-1:0]    m_rid,
    input  wire [DATA_WIDTH-1:0]  m_rdata,
    input  wire [1:0]             m_rresp,
    input  wire                   m_rlast,
    input  wire [0:0]             m_ruser,
    input  wire                   m_rvalid,
    output wire                   m_rready,

    output wire dma_done,
    output wire dma_error
);

    import amba_axi_pkg::*;

    s_axil_mosi_t dma_csr_mosi;
    s_axil_miso_t dma_csr_miso;
    s_axi_mosi_t  dma_m_mosi;
    s_axi_miso_t  dma_m_miso;

    // Address latching for write and read steering
    logic w_steer;
    logic r_steer;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            w_steer <= 1'b0;
            r_steer <= 1'b0;
        end else begin
            if (csr_awvalid)
                w_steer <= csr_awaddr[2];
            
            if (csr_arvalid)
                r_steer <= csr_araddr[2];
        end
    end

    logic current_w_steer;
    logic current_r_steer;
    assign current_w_steer = csr_awvalid ? csr_awaddr[2] : w_steer;
    assign current_r_steer = csr_arvalid ? csr_araddr[2] : r_steer;

    // Connect CSR MOSI
    assign dma_csr_mosi.awid    = csr_awid;
    assign dma_csr_mosi.awaddr  = csr_awaddr;
    assign dma_csr_mosi.awprot  = axi_prot_t'(csr_awprot);
    assign dma_csr_mosi.awvalid = csr_awvalid;
    // Duplicate 32-bit data to both halves of 64-bit bus
    assign dma_csr_mosi.wdata   = {csr_wdata, csr_wdata};
    // Steer the 4-bit strobe to the upper or lower half based on awaddr[2]
    assign dma_csr_mosi.wstrb   = current_w_steer ? {csr_wstrb, 4'h0} : {4'h0, csr_wstrb};
    assign dma_csr_mosi.wvalid  = csr_wvalid;
    assign dma_csr_mosi.bready  = csr_bready;
    assign dma_csr_mosi.arid    = csr_arid;
    assign dma_csr_mosi.araddr  = csr_araddr;
    assign dma_csr_mosi.arprot  = axi_prot_t'(csr_arprot);
    assign dma_csr_mosi.arvalid = csr_arvalid;
    assign dma_csr_mosi.rready  = csr_rready;

    // Connect CSR MISO
    assign csr_awready = dma_csr_miso.awready;
    assign csr_wready  = dma_csr_miso.wready;
    assign csr_bid     = dma_csr_miso.bid;
    assign csr_bresp   = dma_csr_miso.bresp;
    assign csr_bvalid  = dma_csr_miso.bvalid;
    assign csr_arready = dma_csr_miso.arready;
    assign csr_rid     = dma_csr_miso.rid;
    // Select the correct 32-bit half from the 64-bit read data based on araddr[2]
    assign csr_rdata   = current_r_steer ? dma_csr_miso.rdata[63:32] : dma_csr_miso.rdata[31:0];
    assign csr_rresp   = dma_csr_miso.rresp;
    assign csr_rlast   = 1'b1; // AXI4-Lite has no bursts
    assign csr_rvalid  = dma_csr_miso.rvalid;

    // Connect Master MOSI
    assign m_awid    = dma_m_mosi.awid;
    assign m_awaddr  = dma_m_mosi.awaddr;
    assign m_awlen   = dma_m_mosi.awlen;
    assign m_awsize  = dma_m_mosi.awsize;
    assign m_awburst = dma_m_mosi.awburst;
    assign m_awlock  = dma_m_mosi.awlock;
    assign m_awcache = dma_m_mosi.awcache;
    assign m_awprot  = dma_m_mosi.awprot;
    assign m_awqos   = dma_m_mosi.awqos;
    assign m_awregion= dma_m_mosi.awregion;
    assign m_awuser  = dma_m_mosi.awuser;
    assign m_awvalid = dma_m_mosi.awvalid;
    assign m_wdata   = dma_m_mosi.wdata;
    assign m_wstrb   = dma_m_mosi.wstrb;
    assign m_wlast   = dma_m_mosi.wlast;
    assign m_wuser   = dma_m_mosi.wuser; // Might not exist in all AXI structs, will check
    assign m_wvalid  = dma_m_mosi.wvalid;
    assign m_bready  = dma_m_mosi.bready;
    assign m_arid    = dma_m_mosi.arid;
    assign m_araddr  = dma_m_mosi.araddr;
    assign m_arlen   = dma_m_mosi.arlen;
    assign m_arsize  = dma_m_mosi.arsize;
    assign m_arburst = dma_m_mosi.arburst;
    assign m_arlock  = dma_m_mosi.arlock;
    assign m_arcache = dma_m_mosi.arcache;
    assign m_arprot  = dma_m_mosi.arprot;
    assign m_arqos   = dma_m_mosi.arqos;
    assign m_arregion= dma_m_mosi.arregion;
    assign m_aruser  = dma_m_mosi.aruser;
    assign m_arvalid = dma_m_mosi.arvalid;
    assign m_rready  = dma_m_mosi.rready;

    // Connect Master MISO
    assign dma_m_miso.awready = m_awready;
    assign dma_m_miso.wready  = m_wready;
    assign dma_m_miso.bid     = m_bid;
    assign dma_m_miso.bresp   = axi_resp_t'(m_bresp);
    assign dma_m_miso.buser   = m_buser;
    assign dma_m_miso.bvalid  = m_bvalid;
    assign dma_m_miso.arready = m_arready;
    assign dma_m_miso.rid     = m_rid;
    assign dma_m_miso.rdata   = m_rdata;
    assign dma_m_miso.rresp   = axi_resp_t'(m_rresp);
    assign dma_m_miso.ruser   = m_ruser;
    assign dma_m_miso.rlast   = m_rlast;
    assign dma_m_miso.rvalid  = m_rvalid;

    dma_axi_wrapper #(
        .DMA_ID_VAL(0)
    ) u_dma_wrapper (
        .clk(clk),
        .rst(rst),
        .dma_csr_mosi_i(dma_csr_mosi),
        .dma_csr_miso_o(dma_csr_miso),
        .dma_m_mosi_o(dma_m_mosi),
        .dma_m_miso_i(dma_m_miso),
        .dma_done_o(dma_done),
        .dma_error_o(dma_error)
    );

endmodule
