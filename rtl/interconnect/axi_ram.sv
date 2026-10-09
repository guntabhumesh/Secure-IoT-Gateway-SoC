module axi_ram #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 32,
    parameter integer ID_WIDTH = 8,
    parameter integer MEM_SIZE_BYTES = 32768
) (
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,

    output wire [ID_WIDTH-1:0]    s_axi_bid,
    output wire [1:0]             s_axi_bresp,
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,

    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,

    output wire [ID_WIDTH-1:0]    s_axi_rid,
    output wire [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rlast,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready
);

    localparam ADDR_LSB = $clog2(DATA_WIDTH/8);
    localparam MEM_DEPTH = MEM_SIZE_BYTES / (DATA_WIDTH/8);
    localparam ADDR_MASK = MEM_SIZE_BYTES - 1;

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    
    // Simple state machine for AXI
    reg [ID_WIDTH-1:0] awid_reg;
    reg aw_en;

    assign s_axi_awready = aw_en;
    assign s_axi_wready  = aw_en;

    always @(posedge clk) begin
        if (~rst_n) begin
            aw_en <= 1'b1;
            awid_reg <= 0;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && aw_en) begin
                aw_en <= 1'b0;
                awid_reg <= s_axi_awid;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end
        end
    end

    // Write operation
    wire [ADDR_WIDTH-1:0] mem_addr = (s_axi_awaddr & ADDR_MASK) >> ADDR_LSB;
    integer byte_index;
    always @(posedge clk) begin
        if (s_axi_awvalid && s_axi_wvalid && aw_en) begin
            if (mem_addr < MEM_DEPTH) begin
                for (byte_index = 0; byte_index <= (DATA_WIDTH/8)-1; byte_index = byte_index+1)
                    if (s_axi_wstrb[byte_index] == 1) begin
                        mem[mem_addr][(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                    end
            end
        end
    end

    // Write response
    reg bvalid_reg;
    reg [ID_WIDTH-1:0] bid_reg;
    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_bid = bid_reg;
    assign s_axi_bresp = 2'b00;

    always @(posedge clk) begin
        if (~rst_n) begin
            bvalid_reg <= 1'b0;
            bid_reg <= 0;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && aw_en) begin
                bvalid_reg <= 1'b1;
                bid_reg <= s_axi_awid;
            end else if (s_axi_bready && bvalid_reg) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read operation
    reg ar_ready;
    assign s_axi_arready = ar_ready;
    reg [ID_WIDTH-1:0] rid_reg;
    reg rvalid_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg rlast_reg;

    wire [ADDR_WIDTH-1:0] mem_raddr = (s_axi_araddr & ADDR_MASK) >> ADDR_LSB;

    always @(posedge clk) begin
        if (~rst_n) begin
            ar_ready <= 1'b1;
            rvalid_reg <= 1'b0;
            rlast_reg <= 1'b0;
            rdata_reg <= 0;
            rid_reg <= 0;
        end else begin
            if (ar_ready && s_axi_arvalid) begin
                ar_ready <= 1'b0;
                rid_reg <= s_axi_arid;
                rvalid_reg <= 1'b1;
                rlast_reg <= 1'b1; // Simplified: ignoring burst lengths > 1
                if (mem_raddr < MEM_DEPTH)
                    rdata_reg <= mem[mem_raddr];
                else
                    rdata_reg <= 0;
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
                rlast_reg <= 1'b0;
                ar_ready <= 1'b1;
            end
        end
    end

    assign s_axi_rid = rid_reg;
    assign s_axi_rdata = rdata_reg;
    assign s_axi_rresp = 2'b00;
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rlast = rlast_reg;

endmodule
