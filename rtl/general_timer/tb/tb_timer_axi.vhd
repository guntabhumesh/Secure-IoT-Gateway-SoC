--
-- Native VHDL Testbench for Timer AXI Wrapper
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_timer_axi is
end entity tb_timer_axi;

architecture behavioral of tb_timer_axi is
  component timer_axi is
    port (
      aclk       : in std_logic;
      aresetn    : in std_logic;
      awaddr     : in std_logic_vector(31 downto 0);
      awprot     : in std_logic_vector(2 downto 0);
      awvalid    : in std_logic;
      awready    : out std_logic;
      wdata      : in std_logic_vector(31 downto 0);
      wstrb      : in std_logic_vector(3 downto 0);
      wvalid     : in std_logic;
      wready     : out std_logic;
      bresp      : out std_logic_vector(1 downto 0);
      bvalid     : out std_logic;
      bready     : in std_logic;
      araddr     : in std_logic_vector(31 downto 0);
      arprot     : in std_logic_vector(2 downto 0);
      arvalid    : in std_logic;
      arready    : out std_logic;
      rdata      : out std_logic_vector(31 downto 0);
      rresp      : out std_logic_vector(1 downto 0);
      rvalid     : out std_logic;
      rready     : in std_logic;
      ext_meas_i : in std_logic;
      capture_i  : in std_logic;
      pwm_o      : out std_logic;
      trigger_o  : out std_logic;
      irq        : out std_logic
    );
  end component timer_axi;

  signal aclk    : std_logic                     := '0';
  signal aresetn : std_logic                     := '0';
  signal awaddr  : std_logic_vector(31 downto 0) := (others => '0');
  signal awprot  : std_logic_vector(2 downto 0)  := (others => '0');
  signal awvalid : std_logic                     := '0';
  signal awready : std_logic;
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrb   : std_logic_vector(3 downto 0)  := x"F";
  signal wvalid  : std_logic                     := '0';
  signal wready  : std_logic;
  signal bresp   : std_logic_vector(1 downto 0);
  signal bvalid  : std_logic;
  signal bready  : std_logic                     := '0';
  signal araddr  : std_logic_vector(31 downto 0) := (others => '0');
  signal arprot  : std_logic_vector(2 downto 0)  := (others => '0');
  signal arvalid : std_logic                     := '0';
  signal arready : std_logic;
  signal rdata   : std_logic_vector(31 downto 0);
  signal rresp   : std_logic_vector(1 downto 0);
  signal rvalid  : std_logic;
  signal rready  : std_logic := '0';
  signal irq     : std_logic;

  signal ext_meas_i : std_logic := '0';
  signal capture_i  : std_logic := '0';
  signal pwm_o      : std_logic;
  signal trigger_o  : std_logic;

  constant ADDR_CTRL   : std_logic_vector(31 downto 0) := x"00000000";
  constant ADDR_LOAD   : std_logic_vector(31 downto 0) := x"00000004";
  constant ADDR_INT_EN : std_logic_vector(31 downto 0) := x"00000010";

  constant TB_TIMEOUT : time := 30 us;

begin

  dut : timer_axi
  port map
  (
    aclk       => aclk,
    aresetn    => aresetn,
    awaddr     => awaddr,
    awprot     => awprot,
    awvalid    => awvalid,
    awready    => awready,
    wdata      => wdata,
    wstrb      => wstrb,
    wvalid     => wvalid,
    wready     => wready,
    bresp      => bresp,
    bvalid     => bvalid,
    bready     => bready,
    araddr     => araddr,
    arprot     => arprot,
    arvalid    => arvalid,
    arready    => arready,
    rdata      => rdata,
    rresp      => rresp,
    rvalid     => rvalid,
    rready     => rready,
    ext_meas_i => ext_meas_i,
    capture_i  => capture_i,
    pwm_o      => pwm_o,
    trigger_o  => trigger_o,
    irq        => irq
  );

  clk_gen : process
  begin
    while now < TB_TIMEOUT loop
      aclk <= '0';
      wait for 5 ns;
      aclk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  stim_proc : process
    procedure axi_write(addr : std_logic_vector(31 downto 0); data : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(aclk);
      awaddr  <= addr;
      awvalid <= '1';
      wdata   <= data;
      wvalid  <= '1';
      bready  <= '1';

      -- Wait for AW and W acceptance
      while(awready = '0') loop wait until rising_edge(aclk);
      end loop;
      awvalid <= '0';

      while(wready = '0') loop wait until rising_edge(aclk);
      end loop;
      wvalid <= '0'; -- assuming wready stays high or we caught it? AXI Logic in TB is simple

      -- Wait for response
      while(bvalid = '0') loop wait until rising_edge(aclk);
      end loop;
      bready <= '0';
    end procedure;

    procedure axi_read(addr : std_logic_vector(31 downto 0); expected : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(aclk);
      araddr  <= addr;
      arvalid <= '1';
      rready  <= '1';

      while(arready = '0') loop wait until rising_edge(aclk);
      end loop;
      arvalid <= '0';

      while(rvalid = '0') loop wait until rising_edge(aclk);
      end loop;
      assert rdata = expected report "AXI Read Mismatch" severity error;
      rready <= '0';
    end procedure;

  begin
    report "Starting AXI Timer Test";
    aresetn <= '0';
    wait for 50 ns;
    aresetn <= '1';
    wait for 20 ns;

    report "TEST 1: AXI Register R/W";
    axi_write(ADDR_LOAD, x"CAFEBABE");
    axi_read(ADDR_LOAD, x"CAFEBABE");

    report "TEST 2: Timer via AXI";
    axi_write(ADDR_LOAD, std_logic_vector(to_unsigned(15, 32)));
    axi_write(ADDR_INT_EN, x"00000001");
    axi_write(ADDR_CTRL, x"00000001");

    wait until irq = '1';
    report "IRQ Received";

    report "AXI TESTS PASSED";
    wait;
  end process;

end architecture behavioral;
