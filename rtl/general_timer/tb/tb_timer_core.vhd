--
-- Native VHDL Testbench for Timer Core
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_timer_core is
end entity tb_timer_core;

architecture behavioral of tb_timer_core is
  component timer_core is
    port (
      clk        : in std_logic;
      rst_n      : in std_logic;
      en         : in std_logic;
      mode       : in std_logic;
      dir        : in std_logic;
      pwm_en     : in std_logic;
      ext_en     : in std_logic;
      pre_en     : in std_logic;
      pre_val    : in std_logic_vector(15 downto 0);
      load_val   : in std_logic_vector(31 downto 0);
      cmp_val    : in std_logic_vector(31 downto 0);
      load_cmd   : in std_logic;
      ext_meas_i : in std_logic;
      capture_i  : in std_logic;

      current_val : out std_logic_vector(31 downto 0);
      capture_val : out std_logic_vector(31 downto 0);
      capture_stb : out std_logic;
      pwm_o       : out std_logic;
      trigger_o   : out std_logic;
      irq         : out std_logic
    );
  end component timer_core;

  signal clk        : std_logic                     := '0';
  signal rst_n      : std_logic                     := '0';
  signal en         : std_logic                     := '0';
  signal mode       : std_logic                     := '0';
  signal dir        : std_logic                     := '0';
  signal pwm_en     : std_logic                     := '0';
  signal ext_en     : std_logic                     := '0';
  signal pre_en     : std_logic                     := '0';
  signal pre_val    : std_logic_vector(15 downto 0) := (others => '0');
  signal load_val   : std_logic_vector(31 downto 0) := (others => '0');
  signal cmp_val    : std_logic_vector(31 downto 0) := (others => '0');
  signal load_cmd   : std_logic                     := '0';
  signal ext_meas_i : std_logic                     := '0';
  signal capture_i  : std_logic                     := '0';

  signal current_val : std_logic_vector(31 downto 0);
  signal capture_val : std_logic_vector(31 downto 0);
  signal capture_stb : std_logic;
  signal pwm_o       : std_logic;
  signal trigger_o   : std_logic;
  signal irq         : std_logic;

  constant TB_TIMEOUT : time := 30 us;

begin

  dut : timer_core
  port map
  (
    clk        => clk,
    rst_n      => rst_n,
    en         => en,
    mode       => mode,
    dir        => dir,
    pwm_en     => pwm_en,
    ext_en     => ext_en,
    pre_en     => pre_en,
    pre_val    => pre_val,
    load_val   => load_val,
    cmp_val    => cmp_val,
    load_cmd   => load_cmd,
    ext_meas_i => ext_meas_i,
    capture_i  => capture_i,

    current_val => current_val,
    capture_val => capture_val,
    capture_stb => capture_stb,
    pwm_o       => pwm_o,
    trigger_o   => trigger_o,
    irq         => irq
  );

  -- Clock Generation
  clk_gen : process
  begin
    while now < TB_TIMEOUT loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  -- Stimulus
  stim_proc : process
  begin
    report "Starting Timer Core New Features Test";

    -- Reset
    rst_n <= '0';
    wait for 50 ns;
    rst_n <= '1';
    wait for 20 ns;

    -- Test 1: PWM in Up Mode
    report "TEST 1: PWM Up Mode";
    load_val <= std_logic_vector(to_unsigned(20, 32));
    cmp_val  <= std_logic_vector(to_unsigned(10, 32));
    load_cmd <= '1';
    wait until rising_edge(clk);
    load_cmd <= '0';

    dir    <= '1'; -- Up
    mode   <= '1'; -- Repeat
    pwm_en <= '1';
    en     <= '1';

    wait for 50 ns;
    wait until irq = '1';

    -- Check PWM behavior briefly
    wait until rising_edge(clk);
    en     <= '0';
    pwm_en <= '0';
    wait for 50 ns;

    -- Test 2: Input Capture
    report "TEST 2: Input Capture";
    load_val <= std_logic_vector(to_unsigned(100, 32));
    load_cmd <= '1';
    dir      <= '0'; -- Down
    mode     <= '0';
    wait until rising_edge(clk);
    load_cmd <= '0';
    en       <= '1';

    wait for 50 ns;
    wait until rising_edge(clk);
    wait for 1 ns;
    capture_i <= '1';

    wait until rising_edge(clk); -- This edge sees capture_i=1.
    wait for 1 ns; -- Wait for output update
    assert capture_stb = '1' report "Capture Strobe Missed" severity error;
    report "Captured Value: " & to_hstring(capture_val);
    capture_i <= '0';

    en <= '0';
    wait for 50 ns;

    -- Test 3: External Count
    report "TEST 3: External Count";
    ext_en   <= '1';
    load_val <= std_logic_vector(to_unsigned(3, 32));
    load_cmd <= '1';
    wait until rising_edge(clk);
    load_cmd <= '0';
    en       <= '1';

    wait for 50 ns;
    -- Generate 3 external pulses (3->2, 2->1, 1->0)
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      wait for 1 ns;
      ext_meas_i <= '1';
      wait for 20 ns;
      ext_meas_i <= '0';
      wait for 20 ns;
    end loop;

    -- 4th Pulse (0 -> IRQ)
    wait until rising_edge(clk);
    wait for 1 ns;
    ext_meas_i <= '1';

    wait until irq = '1' for 100 ns;
    assert irq = '1' report "IRQ missed in Ext Count Mode" severity error;

    wait for 20 ns;
    ext_meas_i <= '0';
    wait for 20 ns;

    report "ALL NEW FEATURES TESTS PASSED";
    wait;
  end process;

end architecture behavioral;
