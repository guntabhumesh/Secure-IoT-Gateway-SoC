--
-- General Purpose Timer Core (VHDL-2008)
--
-- Description:
--   32-bit down counter with prescaler and interrupt generation.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_core is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    -- Control
    en       : in std_logic                     := '0'; -- Enable Timer
    mode     : in std_logic                     := '0'; -- 0 = One-Shot, 1 = Repeat
    dir      : in std_logic                     := '0'; -- 0 = Down, 1 = Up
    pwm_en   : in std_logic                     := '0'; -- PWM Enable
    ext_en   : in std_logic                     := '0'; -- External Count Enable
    pre_en   : in std_logic                     := '0'; -- Prescaler Enable
    pre_val  : in std_logic_vector(15 downto 0) := (others => '0');
    load_val : in std_logic_vector(31 downto 0) := (others => '0');
    cmp_val  : in std_logic_vector(31 downto 0) := (others => '0'); -- PWM Compare
    load_cmd : in std_logic                     := '0'; -- Force Load

    -- External IO
    ext_meas_i : in std_logic := '0';
    capture_i  : in std_logic := '0';

    -- Output
    current_val : out std_logic_vector(31 downto 0);
    capture_val : out std_logic_vector(31 downto 0); -- Captured Value
    capture_stb : out std_logic; -- Capture Strobe
    pwm_o       : out std_logic;
    trigger_o   : out std_logic;
    irq         : out std_logic
  );
end entity timer_core;

architecture rtl of timer_core is
  signal counter   : unsigned(31 downto 0) := (others => '0');
  signal prescaler : unsigned(15 downto 0) := (others => '0');
  signal tick      : std_logic             := '0';
  signal clk_tick  : std_logic             := '0';
  signal ext_tick  : std_logic             := '0';

  -- Edge Detectors
  signal ext_meas_d  : std_logic := '0';
  signal capture_d   : std_logic := '0';
  signal ext_meas_re : std_logic;
  signal capture_re  : std_logic;

  -- One-Shot Done Logic
  signal op_done : std_logic := '0';

begin

  current_val <= std_logic_vector(counter);

  -- Edge Detection
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      ext_meas_d <= '0';
      capture_d  <= '0';
    elsif rising_edge(clk) then
      ext_meas_d <= ext_meas_i;
      capture_d  <= capture_i;
    end if;
  end process;

  ext_meas_re <= ext_meas_i and not ext_meas_d;
  capture_re  <= capture_i and not capture_d;
  ext_tick    <= ext_meas_re;

  -- One-Shot Done Logic
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      op_done <= '0';
    elsif rising_edge(clk) then
      if load_cmd = '1' or en = '0' then
        op_done <= '0';
      elsif en = '1' and tick = '1' and mode = '0' and op_done = '0' then
        if dir = '0' and counter = 0 then
          op_done <= '1';
        elsif dir = '1' and counter = unsigned(load_val) then
          op_done <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Capture Logic
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      capture_val <= (others => '0');
      capture_stb <= '0';
    elsif rising_edge(clk) then
      if capture_re = '1' then
        capture_val <= std_logic_vector(counter);
        capture_stb <= '1';
      else
        capture_stb <= '0';
      end if;
    end if;
  end process;

  -- Prescaler Logic (Internal)
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      prescaler <= (others => '0');
      clk_tick  <= '0';
    elsif rising_edge(clk) then
      if load_cmd = '1' then
        prescaler <= unsigned(pre_val);
        clk_tick  <= '0';
      elsif en = '1' and ext_en = '0' then
        if pre_en = '1' then
          if prescaler = 0 then
            prescaler <= unsigned(pre_val);
            clk_tick  <= '1';
          else
            prescaler <= prescaler - 1;
            clk_tick  <= '0';
          end if;
        else
          prescaler <= (others => '0');
          clk_tick  <= '1';
        end if;
      else
        clk_tick <= '0';
      end if;
    end if;
  end process;

  -- Tick Selection
  tick <= ext_tick when ext_en = '1' else
    clk_tick;

  -- Counter Logic & Trigger
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      counter   <= (others => '0');
      irq       <= '0';
      trigger_o <= '0';
    elsif rising_edge(clk) then
      if load_cmd = '1' then
        counter   <= unsigned(load_val);
        irq       <= '0';
        trigger_o <= '0';
      elsif en = '1' and tick = '1' and op_done = '0' then
        if dir = '0' then
          -- Down Count
          if counter = 0 then
            irq       <= '1';
            trigger_o <= '1';
            if mode = '1' then
              counter <= unsigned(load_val);
            else
              counter <= (others => '0');
            end if;
          else
            counter   <= counter - 1;
            irq       <= '0';
            trigger_o <= '0';
          end if;
        else
          -- Up Count
          if counter = unsigned(load_val) then
            irq       <= '1';
            trigger_o <= '1';
            if mode = '1' then
              counter <= (others => '0');
            else
              counter <= unsigned(load_val);
            end if;
          else
            counter   <= counter + 1;
            irq       <= '0';
            trigger_o <= '0';
          end if;
        end if;
      else
        irq       <= '0';
        trigger_o <= '0';
      end if;
    end if;
  end process;

  -- PWM Logic
  process (all)
  begin
    if pwm_en = '0' then
      pwm_o <= '0';
    else
      if dir = '0' then
        -- Down Mode: 1 when counter <= CMP
        if counter <= unsigned(cmp_val) then
          pwm_o      <= '1';
        else
          pwm_o <= '0';
        end if;
      else
        -- Up Mode: 1 when counter < CMP
        if counter < unsigned(cmp_val) then
          pwm_o <= '1';
        else
          pwm_o <= '0';
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
