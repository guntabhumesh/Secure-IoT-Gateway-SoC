--
-- Native VHDL Testbench for Timer APB Wrapper
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_timer_apb is
end entity tb_timer_apb;

architecture behavioral of tb_timer_apb is
  component timer_apb is
    port (
      pclk       : in std_logic;
      presetn    : in std_logic;
      paddr      : in std_logic_vector(31 downto 0);
      pprot      : in std_logic_vector(2 downto 0);
      psel       : in std_logic;
      penable    : in std_logic;
      pwrite     : in std_logic;
      pwdata     : in std_logic_vector(31 downto 0);
      pstrb      : in std_logic_vector(3 downto 0);
      pready     : out std_logic;
      prdata     : out std_logic_vector(31 downto 0);
      pslverr    : out std_logic;
      ext_meas_i : in std_logic;
      capture_i  : in std_logic;
      pwm_o      : out std_logic;
      trigger_o  : out std_logic;
      irq        : out std_logic
    );
  end component timer_apb;

  signal pclk    : std_logic                     := '0';
  signal presetn : std_logic                     := '0';
  signal paddr   : std_logic_vector(31 downto 0) := (others => '0');
  signal pprot   : std_logic_vector(2 downto 0)  := (others => '0');
  signal psel    : std_logic                     := '0';
  signal penable : std_logic                     := '0';
  signal pwrite  : std_logic                     := '0';
  signal pwdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal pstrb   : std_logic_vector(3 downto 0)  := "1111";
  signal pready  : std_logic;
  signal prdata  : std_logic_vector(31 downto 0);
  signal pslverr : std_logic;
  signal irq     : std_logic;

  signal ext_meas_i : std_logic := '0';
  signal capture_i  : std_logic := '0';
  signal pwm_o      : std_logic;
  signal trigger_o  : std_logic;

  constant ADDR_CTRL   : std_logic_vector(31 downto 0) := x"00000000";
  constant ADDR_LOAD   : std_logic_vector(31 downto 0) := x"00000004";
  constant ADDR_VAL    : std_logic_vector(31 downto 0) := x"00000008";
  constant ADDR_INT_EN : std_logic_vector(31 downto 0) := x"00000010";

  constant TB_TIMEOUT : time := 30 us;

begin

  dut : timer_apb
  port map
  (
    pclk       => pclk,
    presetn    => presetn,
    paddr      => paddr,
    pprot      => pprot,
    psel       => psel,
    penable    => penable,
    pwrite     => pwrite,
    pwdata     => pwdata,
    pstrb      => pstrb,
    pready     => pready,
    prdata     => prdata,
    pslverr    => pslverr,
    ext_meas_i => ext_meas_i,
    capture_i  => capture_i,
    pwm_o      => pwm_o,
    trigger_o  => trigger_o,
    irq        => irq
  );

  clk_gen : process
  begin
    while now < TB_TIMEOUT loop
      pclk <= '0';
      wait for 5 ns;
      pclk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  stim_proc : process
    procedure apb_write(addr : std_logic_vector(31 downto 0); data : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(pclk);
      paddr   <= addr;
      pwrite  <= '1';
      psel    <= '1';
      pwdata  <= data;
      penable <= '0';
      wait until rising_edge(pclk);
      penable <= '1';
      if pready = '0' then
        wait until pready = '1';
      end if;
      wait until rising_edge(pclk);
      psel    <= '0';
      penable <= '0';
      pwrite  <= '0';
    end procedure;

    procedure apb_read(addr : std_logic_vector(31 downto 0); expected : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(pclk);
      paddr   <= addr;
      pwrite  <= '0';
      psel    <= '1';
      penable <= '0';
      wait until rising_edge(pclk);
      penable <= '1';
      if pready = '0' then
        wait until pready = '1';
      end if;
      -- Latch data
      assert prdata = expected report "APB Read Mismatch" severity error;
      wait until rising_edge(pclk);
      psel    <= '0';
      penable <= '0';
    end procedure;
  begin
    report "Starting APB Timer Test";
    presetn <= '0';
    wait for 50 ns;
    presetn <= '1';
    wait for 20 ns;

    -- Test 1: R/W Verification
    report "TEST 1: APB Register R/W";
    apb_write(ADDR_LOAD, x"DEADBEEF");
    apb_read(ADDR_LOAD, x"DEADBEEF");

    -- Test 2: Timer Function
    report "TEST 2: Timer Functionality via APB";
    apb_write(ADDR_LOAD, std_logic_vector(to_unsigned(10, 32)));
    apb_write(ADDR_INT_EN, x"00000001");
    apb_write(ADDR_CTRL, x"00000001"); -- Enable

    wait until irq = '1';
    report "IRQ Received";

    report "APB TESTS PASSED";
    wait;
  end process;

end architecture behavioral;
