module tb_soc_top;

localparam DW  = 32;
localparam AW  = 32;
localparam IDW = 8;
localparam SW  = DW/8;
localparam CLK_HALF = 5;

localparam [AW-1:0] I2C_BASE = 32'h0000_0000;
localparam [AW-1:0] AES_BASE = 32'h0100_0000;
localparam [AW-1:0] DUM_BASE = 32'h0200_0000;

localparam [AW-1:0] I2C_PRER_LO = I2C_BASE + 32'h00;
localparam [AW-1:0] I2C_PRER_HI = I2C_BASE + 32'h04;
localparam [AW-1:0] I2C_CTR     = I2C_BASE + 32'h08;

// AES register addresses: AES_BASE=0x0100_0000, lower offset bits [7:2] decoded by slave
localparam [AW-1:0] AES_CTRL  = AES_BASE | 32'h00;
localparam [AW-1:0] AES_KEY0  = AES_BASE | 32'h04;
localparam [AW-1:0] AES_KEY1  = AES_BASE | 32'h08;
localparam [AW-1:0] AES_KEY2  = AES_BASE | 32'h0C;
localparam [AW-1:0] AES_KEY3  = AES_BASE | 32'h10;
localparam [AW-1:0] AES_TEXT0 = AES_BASE | 32'h14;
localparam [AW-1:0] AES_TEXT1 = AES_BASE | 32'h18;
localparam [AW-1:0] AES_TEXT2 = AES_BASE | 32'h1C;
localparam [AW-1:0] AES_TEXT3 = AES_BASE | 32'h20;
localparam [AW-1:0] AES_OUT0  = AES_BASE | 32'h24;
localparam [AW-1:0] AES_OUT1  = AES_BASE | 32'h28;
localparam [AW-1:0] AES_OUT2  = AES_BASE | 32'h2C;
localparam [AW-1:0] AES_OUT3  = AES_BASE | 32'h30;

localparam [127:0] NIST_KEY   = 128'h2b7e151628aed2a6abf7158809cf4f3c;
localparam [127:0] NIST_PLAIN = 128'h3243f6a8885a308d313198a2e0370734;
localparam [127:0] NIST_CIPH  = 128'h3925841d02dc09fbdc118597196a0b32;

localparam [127:0] NIST2_KEY   = 128'h000102030405060708090a0b0c0d0e0f;
localparam [127:0] NIST2_PLAIN = 128'h00112233445566778899aabbccddeeff;
localparam [127:0] NIST2_CIPH  = 128'h69c4e0d86a7b04300d8a8b41b570efad;

reg clk   = 1'b0;
reg rst_n = 1'b0;
always #CLK_HALF clk = ~clk;

reg  [IDW-1:0] m_awid    = 0;
reg  [AW-1:0]  m_awaddr  = 0;
reg  [7:0]     m_awlen   = 0;
reg  [2:0]     m_awsize  = 3'b010;
reg  [1:0]     m_awburst = 2'b01;
reg            m_awlock  = 0;
reg  [3:0]     m_awcache = 0;
reg  [2:0]     m_awprot  = 0;
reg  [3:0]     m_awqos   = 0;
reg            m_awvalid = 0;
wire           m_awready;

reg  [DW-1:0]  m_wdata  = 0;
reg  [SW-1:0]  m_wstrb  = 4'hf;
reg            m_wlast  = 1;
reg            m_wvalid = 0;
wire           m_wready;

wire [IDW-1:0] m_bid;
wire [1:0]     m_bresp;
wire           m_bvalid;
reg            m_bready = 0;

reg  [IDW-1:0] m_arid    = 0;
reg  [AW-1:0]  m_araddr  = 0;
reg  [7:0]     m_arlen   = 0;
reg  [2:0]     m_arsize  = 3'b010;
reg  [1:0]     m_arburst = 2'b01;
reg            m_arlock  = 0;
reg  [3:0]     m_arcache = 0;
reg  [2:0]     m_arprot  = 0;
reg  [3:0]     m_arqos   = 0;
reg            m_arvalid = 0;
wire           m_arready;

wire [IDW-1:0] m_rid;
wire [DW-1:0]  m_rdata;
wire [1:0]     m_rresp;
wire           m_rlast;
wire           m_rvalid;
reg            m_rready = 0;

wire scl_pad_o, scl_padoen_o, sda_pad_o, sda_padoen_o;
wire scl_pad_i = scl_padoen_o ? 1'b1 : scl_pad_o;
wire sda_pad_i = sda_padoen_o ? 1'b1 : sda_pad_o;

soc_top #(.DATA_WIDTH(DW), .ADDR_WIDTH(AW), .ID_WIDTH(IDW)) u_soc (
    .clk   (clk),
    .rst_n (rst_n),
    .s00_axi_awid(m_awid),      .s00_axi_awaddr(m_awaddr),
    .s00_axi_awlen(m_awlen),    .s00_axi_awsize(m_awsize),
    .s00_axi_awburst(m_awburst),.s00_axi_awlock(m_awlock),
    .s00_axi_awcache(m_awcache),.s00_axi_awprot(m_awprot),
    .s00_axi_awqos(m_awqos),    .s00_axi_awvalid(m_awvalid),
    .s00_axi_awready(m_awready),
    .s00_axi_wdata(m_wdata),    .s00_axi_wstrb(m_wstrb),
    .s00_axi_wlast(m_wlast),    .s00_axi_wvalid(m_wvalid),
    .s00_axi_wready(m_wready),
    .s00_axi_bid(m_bid),        .s00_axi_bresp(m_bresp),
    .s00_axi_bvalid(m_bvalid),  .s00_axi_bready(m_bready),
    .s00_axi_arid(m_arid),      .s00_axi_araddr(m_araddr),
    .s00_axi_arlen(m_arlen),    .s00_axi_arsize(m_arsize),
    .s00_axi_arburst(m_arburst),.s00_axi_arlock(m_arlock),
    .s00_axi_arcache(m_arcache),.s00_axi_arprot(m_arprot),
    .s00_axi_arqos(m_arqos),    .s00_axi_arvalid(m_arvalid),
    .s00_axi_arready(m_arready),
    .s00_axi_rid(m_rid),        .s00_axi_rdata(m_rdata),
    .s00_axi_rresp(m_rresp),    .s00_axi_rlast(m_rlast),
    .s00_axi_rvalid(m_rvalid),  .s00_axi_rready(m_rready),
    .s01_axi_awid({IDW{1'b0}}), .s01_axi_awaddr({AW{1'b0}}),
    .s01_axi_awlen(8'b0),       .s01_axi_awsize(3'b010),
    .s01_axi_awburst(2'b01),    .s01_axi_awlock(1'b0),
    .s01_axi_awcache(4'b0),     .s01_axi_awprot(3'b0),
    .s01_axi_awqos(4'b0),       .s01_axi_awvalid(1'b0),
    .s01_axi_awready(),
    .s01_axi_wdata({DW{1'b0}}), .s01_axi_wstrb({SW{1'b0}}),
    .s01_axi_wlast(1'b0),       .s01_axi_wvalid(1'b0),
    .s01_axi_wready(),
    .s01_axi_bid(),  .s01_axi_bresp(), .s01_axi_bvalid(), .s01_axi_bready(1'b1),
    .s01_axi_arid({IDW{1'b0}}), .s01_axi_araddr({AW{1'b0}}),
    .s01_axi_arlen(8'b0),       .s01_axi_arsize(3'b010),
    .s01_axi_arburst(2'b01),    .s01_axi_arlock(1'b0),
    .s01_axi_arcache(4'b0),     .s01_axi_arprot(3'b0),
    .s01_axi_arqos(4'b0),       .s01_axi_arvalid(1'b0),
    .s01_axi_arready(),
    .s01_axi_rid(), .s01_axi_rdata(), .s01_axi_rresp(),
    .s01_axi_rlast(), .s01_axi_rvalid(), .s01_axi_rready(1'b1),
    .scl_pad_i(scl_pad_i), .scl_pad_o(scl_pad_o), .scl_padoen_o(scl_padoen_o),
    .sda_pad_i(sda_pad_i), .sda_pad_o(sda_pad_o), .sda_padoen_o(sda_padoen_o),
    .i2c_irq()
);

initial begin
    $fsdbDumpfile("dump6.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA();
    $fsdbDumpMDA();
end

integer aw_to, w_to, b_to;

task axi_write;
    input [AW-1:0] addr;
    input [DW-1:0] data;
begin
    @(negedge clk);
    m_awaddr  = addr;
    m_awvalid = 1'b1;

    aw_to = 0;
    @(posedge clk);
    while (!m_awready) begin
        @(posedge clk);
        aw_to = aw_to + 1;
        if (aw_to > 200) begin $display("TIMEOUT: awready"); $finish; end
    end

    @(negedge clk);
    m_awvalid = 1'b0;

    m_wdata  = data;
    m_wstrb  = 4'hf;
    m_wlast  = 1'b1;
    m_wvalid = 1'b1;

    w_to = 0;
    @(posedge clk);
    while (!m_wready) begin
        @(posedge clk);
        w_to = w_to + 1;
        if (w_to > 200) begin $display("TIMEOUT: wready"); $finish; end
    end

    @(negedge clk);
    m_wvalid = 1'b0;

    m_bready = 1'b1;
    b_to = 0;
    @(posedge clk);
    while (!m_bvalid) begin
        @(posedge clk);
        b_to = b_to + 1;
        if (b_to > 200) begin $display("TIMEOUT: bvalid"); $finish; end
    end

    @(negedge clk);
    m_bready = 1'b0;
end
endtask

integer ar_to, r_to;
reg [DW-1:0] rd_data;

task axi_read;
    input  [AW-1:0] addr;
    output [DW-1:0] data;
begin
    @(negedge clk);
    m_araddr  = addr;
    m_arvalid = 1'b1;

    ar_to = 0;
    @(posedge clk);
    while (!m_arready) begin
        @(posedge clk);
        ar_to = ar_to + 1;
        if (ar_to > 200) begin $display("TIMEOUT: arready"); $finish; end
    end

    @(negedge clk);
    m_arvalid = 1'b0;

    m_rready = 1'b1;
    r_to = 0;
    @(posedge clk);
    while (!m_rvalid) begin
        @(posedge clk);
        r_to = r_to + 1;
        if (r_to > 200) begin $display("TIMEOUT: rvalid"); $finish; end
    end

    data = m_rdata;
    @(negedge clk);
    m_rready = 1'b0;
end
endtask

integer poll_cnt;

task aes_poll;
    input integer bit_pos;
    output timed_out;
    reg [DW-1:0] stat;
begin
    poll_cnt = 0; timed_out = 1'b0;
    begin : ploop
        forever begin
            axi_read(AES_CTRL, stat);
            if (stat[bit_pos]) disable ploop;
            poll_cnt = poll_cnt + 1;
            if (poll_cnt > 500) begin timed_out = 1'b1; disable ploop; end
        end
    end
end
endtask

task aes_encrypt;
    input  [127:0] key;
    input  [127:0] plain;
    output [127:0] ciph_out;
    output         tmo;
    reg [DW-1:0] r0,r1,r2,r3;
begin
    axi_write(AES_KEY0,  key[127:96]);
    axi_write(AES_KEY1,  key[ 95:64]);
    axi_write(AES_KEY2,  key[ 63:32]);
    axi_write(AES_KEY3,  key[ 31: 0]);
    axi_write(AES_TEXT0, plain[127:96]);
    axi_write(AES_TEXT1, plain[ 95:64]);
    axi_write(AES_TEXT2, plain[ 63:32]);
    axi_write(AES_TEXT3, plain[ 31: 0]);
    axi_write(AES_CTRL, 32'h0000_0003);
    aes_poll(16, tmo);
    if (!tmo) begin
        axi_read(AES_OUT0, r0);
        axi_read(AES_OUT1, r1);
        axi_read(AES_OUT2, r2);
        axi_read(AES_OUT3, r3);
        ciph_out = {r0, r1, r2, r3};
    end else
        ciph_out = 128'bx;
end
endtask

integer pass_cnt, fail_cnt;
reg tmo;
reg [DW-1:0]  r0, r1, r2, r3;
reg [127:0]   result128;
reg [127:0]   enc_out;
reg           enc_tmo;

initial begin
    pass_cnt = 0; fail_cnt = 0;

    rst_n = 1'b0;
    repeat(12) @(posedge clk);
    @(negedge clk); rst_n = 1'b1;
    repeat(5) @(posedge clk);

    $display("");
    $display("=============================================================");
    $display("  Secure IoT Gateway SoC — Full Integration Testbench");
    $display("  m00=I2C  m01=AES  m02..m10=dummy");
    $display("=============================================================");

    $display("\n[TEST 1] I2C register access via m00");

    axi_write(I2C_PRER_LO, 32'h0000_0063);
    axi_write(I2C_PRER_HI, 32'h0000_0000);
    axi_write(I2C_CTR,     32'h0000_0080);

    axi_read(I2C_PRER_LO, rd_data);
    if (rd_data[7:0] === 8'h63) begin
        $display("  [PASS] PRER_LO = 0x%02h", rd_data[7:0]);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] PRER_LO: exp=0x63 got=0x%02h", rd_data[7:0]);
        fail_cnt = fail_cnt + 1;
    end

    axi_read(I2C_CTR, rd_data);
    if (rd_data[7:0] === 8'h80) begin
        $display("  [PASS] CTR = 0x%02h (core enabled)", rd_data[7:0]);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] CTR: exp=0x80 got=0x%02h", rd_data[7:0]);
        fail_cnt = fail_cnt + 1;
    end

    $display("\n[TEST 2] AES key-only load (CTRL.KLD)");

    axi_write(AES_KEY0, NIST_KEY[127:96]);
    axi_write(AES_KEY1, NIST_KEY[ 95:64]);
    axi_write(AES_KEY2, NIST_KEY[ 63:32]);
    axi_write(AES_KEY3, NIST_KEY[ 31: 0]);
    axi_write(AES_CTRL, 32'h0000_0002);

    aes_poll(17, tmo);
    if (!tmo) begin
        $display("  [PASS] KDONE asserted after KLD");
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] KDONE timeout");
        fail_cnt = fail_cnt + 1;
    end

    $display("\n[TEST 3] AES encrypt — NIST FIPS-197 Appendix B");
    $display("  Key   = %032h", NIST_KEY);
    $display("  Plain = %032h", NIST_PLAIN);
    $display("  Exp   = %032h", NIST_CIPH);

    aes_encrypt(NIST_KEY, NIST_PLAIN, enc_out, enc_tmo);

    if (enc_tmo) begin
        $display("  [FAIL] AES DONE timeout");
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("  OUT   = %032h", enc_out);
        if (enc_out === NIST_CIPH) begin
            $display("  [PASS] Ciphertext matches NIST");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Ciphertext mismatch");
            fail_cnt = fail_cnt + 1;
        end
    end

    $display("\n[TEST 4] AES round-trip — inv_cipher auto-chain");
    $display("  Waiting ~11 more cycles after enc_done...");

    repeat(30) @(posedge clk);

    axi_read(AES_OUT0, r0);
    axi_read(AES_OUT1, r1);
    axi_read(AES_OUT2, r2);
    axi_read(AES_OUT3, r3);
    result128 = {r0, r1, r2, r3};
    $display("  inv OUT = %032h", result128);
    if (result128 === NIST_PLAIN) begin
        $display("  [PASS] Round-trip recovered plaintext");
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] Round-trip mismatch");
        $display("         exp = %032h", NIST_PLAIN);
        $display("         got = %032h", result128);
        fail_cnt = fail_cnt + 1;
    end

    $display("\n[TEST 5] AES encrypt — NIST FIPS-197 Appendix C.1");
    $display("  Key   = %032h", NIST2_KEY);
    $display("  Plain = %032h", NIST2_PLAIN);
    $display("  Exp   = %032h", NIST2_CIPH);

    aes_encrypt(NIST2_KEY, NIST2_PLAIN, enc_out, enc_tmo);

    if (enc_tmo) begin
        $display("  [FAIL] AES DONE timeout");
        fail_cnt = fail_cnt + 1;
    end else begin
        $display("  OUT   = %032h", enc_out);
        if (enc_out === NIST2_CIPH) begin
            $display("  [PASS] Ciphertext matches NIST vector 2");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  [FAIL] Ciphertext mismatch (vector 2)");
            fail_cnt = fail_cnt + 1;
        end
    end

    $display("\n[TEST 6] AES KEY readback");
    axi_read(AES_KEY0, r0); axi_read(AES_KEY1, r1);
    axi_read(AES_KEY2, r2); axi_read(AES_KEY3, r3);
    result128 = {r0,r1,r2,r3};
    if (result128 === NIST2_KEY) begin
        $display("  [PASS] KEY = %032h", result128);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] KEY mismatch: exp=%032h got=%032h", NIST2_KEY, result128);
        fail_cnt = fail_cnt + 1;
    end

    $display("\n[TEST 7] Dummy slave m02 routing (0x0200_0000)");
    axi_read(DUM_BASE, rd_data);
    if (rd_data === 32'hDEAD_0002) begin
        $display("  [PASS] Dummy m02 = 0x%08h", rd_data);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] Dummy m02: exp=0xDEAD0002 got=0x%08h", rd_data);
        fail_cnt = fail_cnt + 1;
    end

    $display("\n[TEST 8] AES soft-reset (CTRL.RST)");
    axi_write(AES_CTRL, 32'h0000_0004);
    repeat(4) @(posedge clk);
    axi_read(AES_CTRL, rd_data);
    if (rd_data[17:16] === 2'b00) begin
        $display("  [PASS] STATUS[17:16]=0 after soft-reset");
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("  [FAIL] STATUS not cleared: [17:16]=%02b", rd_data[17:16]);
        fail_cnt = fail_cnt + 1;
    end

    $display("");
    $display("=============================================================");
    $display("  RESULTS:  %0d PASS   %0d FAIL", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display("  *** ALL TESTS PASSED ***");
    else
        $display("  *** SOME TESTS FAILED ***");
    $display("=============================================================");
    $display("");

    repeat(20) @(posedge clk);
    $finish;
end

initial begin
    #5_000_000;
    $display("ERROR: simulation watchdog at %0t ns", $realtime);
    $finish;
end

endmodule
