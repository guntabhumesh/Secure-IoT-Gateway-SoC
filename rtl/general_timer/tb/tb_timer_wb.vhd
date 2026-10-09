--
-- Native VHDL Testbench for Timer Wishbone Wrapper
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_timer_wb is
end entity tb_timer_wb;

architecture behavioral of tb_timer_wb is
  component timer_wb is
    port (
      wb_clk_i   : in std_logic;
      wb_rst_i   : in std_logic;
      wb_adr_i   : in std_logic_vector(31 downto 0);
      wb_dat_i   : in std_logic_vector(31 downto 0);
      wb_we_i    : in std_logic;
      wb_stb_i   : in std_logic;
      wb_cyc_i   : in std_logic;
      wb_sel_i   : in std_logic_vector(3 downto 0);
      wb_dat_o   : out std_logic_vector(31 downto 0);
      wb_ack_o   : out std_logic;
      wb_err_o   : out std_logic;
      ext_meas_i : in std_logic;
      capture_i  : in std_logic;
      pwm_o      : out std_logic;
      trigger_o  : out std_logic;
      irq        : out std_logic
    );
  end component timer_wb;

  signal wb_clk_i : std_logic                     := '0';
  signal wb_rst_i : std_logic                     := '0';
  signal wb_adr_i : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_dat_i : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_we_i  : std_logic                     := '0';
  signal wb_stb_i : std_logic                     := '0';
  signal wb_cyc_i : std_logic                     := '0';
  signal wb_sel_i : std_logic_vector(3 downto 0)  := x"F";
  signal wb_dat_o : std_logic_vector(31 downto 0);
  signal wb_ack_o : std_logic;
  signal wb_err_o : std_logic;
  signal irq      : std_logic;

  signal ext_meas_i : std_logic := '0';
  signal capture_i  : std_logic := '0';
  signal pwm_o      : std_logic;
  signal trigger_o  : std_logic;

  constant ADDR_CTRL   : std_logic_vector(31 downto 0) := x"00000000";
  constant ADDR_LOAD   : std_logic_vector(31 downto 0) := x"00000004";
  constant ADDR_INT_EN : std_logic_vector(31 downto 0) := x"00000010";

  constant TB_TIMEOUT : time := 30 us;

begin

  dut : timer_wb
  port map
  (
    wb_clk_i   => wb_clk_i,
    wb_rst_i   => wb_rst_i,
    wb_adr_i   => wb_adr_i,
    wb_dat_i   => wb_dat_i,
    wb_we_i    => wb_we_i,
    wb_stb_i   => wb_stb_i,
    wb_cyc_i   => wb_cyc_i,
    wb_sel_i   => wb_sel_i,
    wb_dat_o   => wb_dat_o,
    wb_ack_o   => wb_ack_o,
    wb_err_o   => wb_err_o,
    ext_meas_i => ext_meas_i,
    capture_i  => capture_i,
    pwm_o      => pwm_o,
    trigger_o  => trigger_o,
    irq        => irq
  );

  clk_gen : process
  begin
    while now < TB_TIMEOUT loop
      wb_clk_i <= '0';
      wait for 5 ns;
      wb_clk_i <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  stim_proc : process
    procedure wb_write(addr : std_logic_vector(31 downto 0); data : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(wb_clk_i);
      wb_adr_i <= addr;
      wb_dat_i <= data;
      wb_we_i  <= '1';
      wb_stb_i <= '1';
      wb_cyc_i <= '1';

      wait until wb_ack_o = '1';
      wait until rising_edge(wb_clk_i);
      wb_stb_i <= '0';
      wb_cyc_i <= '0';
      wb_we_i  <= '0';
    end procedure;

    procedure wb_read(addr : std_logic_vector(31 downto 0); expected : std_logic_vector(31 downto 0)) is
    begin
      wait until rising_edge(wb_clk_i);
      wb_adr_i <= addr;
      wb_we_i  <= '0';
      wb_stb_i <= '1';
      wb_cyc_i <= '1';

      wait until wb_ack_o = '1';
      assert wb_dat_o = expected report "WB Read Mismatch" severity error;
      wait until rising_edge(wb_clk_i);
      wb_stb_i <= '0';
      wb_cyc_i <= '0';
    end procedure;

  begin
    report "Starting WB Timer Test";
    wb_rst_i <= '1';
    wait for 50 ns;
    wb_rst_i <= '0';
    wait for 20 ns;

    report "TEST 1: WB Register R/W";
    wb_write(ADDR_LOAD, x"FEEDFACE");
    wb_read(ADDR_LOAD, x"FEEDFACE");

    report "TEST 2: Timer via WB";
    wb_write(ADDR_LOAD, std_logic_vector(to_unsigned(20, 32)));
    wb_write(ADDR_INT_EN, x"00000001");
    wb_write(ADDR_CTRL, x"00000001");

    wait until irq = '1';
    report "IRQ Received";

    report "WB TESTS PASSED";
    wait;
  end process;

end architecture behavioral;
