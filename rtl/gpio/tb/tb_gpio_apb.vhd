--------------------------------------------------------------------------------
-- Module: tb_gpio_apb
-- Description: VHDL Testbench for APB4 GPIO IP.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.apb_bfm_pkg.all;

entity tb_gpio_apb is
end entity tb_gpio_apb;

architecture tb of tb_gpio_apb is
  constant NUM_BITS   : integer := 8;
  constant CLK_PERIOD : time    := 10 ns;

  signal pclk    : std_logic := '0';
  signal presetn : std_logic := '0';

  signal paddr   : std_logic_vector(31 downto 0) := (others => '0');
  signal pwrite  : std_logic                     := '0';
  signal psel    : std_logic                     := '0';
  signal penable : std_logic                     := '0';
  signal pwdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal pprot   : std_logic_vector(2 downto 0)  := (others => '0');
  signal pstrb   : std_logic_vector(3 downto 0)  := (others => '0');
  signal pready  : std_logic;
  signal prdata  : std_logic_vector(31 downto 0);
  signal pslverr : std_logic;

  signal io   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => 'Z');
  signal intr : std_logic;

begin

  -- DUT
  u_dut : entity work.gpio_apb
    generic map(
      NUM_BITS => NUM_BITS
    )
    port map
    (
      pclk    => pclk,
      presetn => presetn,
      paddr   => paddr,
      pwrite  => pwrite,
      psel    => psel,
      penable => penable,
      pwdata  => pwdata,
      pprot   => pprot,
      pstrb   => pstrb,
      pready  => pready,
      prdata  => prdata,
      pslverr => pslverr,
      io      => io,
      intr    => intr
    );

  -- Clock generator
  pclk <= not pclk after CLK_PERIOD / 2;

  -- Stimulus
  process
    variable errors : integer := 0;
    variable rdata  : std_logic_vector(31 downto 0);
  begin
    report "Starting APB Native Directed Test...";

    -- Reset
    presetn <= '0';
    wait for CLK_PERIOD * 5;
    presetn <= '1';
    wait until rising_edge(pclk);

    -- Test 1: Basic R/W and DIR
    report "Test 1: Basic R/W and DIR";
    apb_write(x"00000008", x"000000FF", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- DIR=out
    apb_write(x"00000004", x"000000AA", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- DATA_O=AA

    wait for CLK_PERIOD * 10;
    apb_read(x"00000004", rdata, pclk, paddr, prdata, pwrite, psel, penable, pready);
    if rdata(7 downto 0) /= x"AA" then
      report "Test 1 Failed: DATA_O mismatch, got " & to_hstring(rdata(7 downto 0)) & " expected AA" severity error;
      errors := errors + 1;
    end if;

    -- Test 2: Atomic Operations
    report "Test 2: Atomic Operations";
    apb_write(x"00000004", x"00000055", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- DATA_O=55
    apb_write(x"00000020", x"00000011", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- SET 11
    wait for CLK_PERIOD * 10;
    apb_read(x"00000004", rdata, pclk, paddr, prdata, pwrite, psel, penable, pready);
    -- 55 | 11 is 55.

    apb_write(x"00000004", x"00000044", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- DATA_O=44
    apb_write(x"00000028", x"00000022", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- TGL 22 -> 66
    wait for CLK_PERIOD * 10;
    apb_read(x"00000004", rdata, pclk, paddr, prdata, pwrite, psel, penable, pready);
    if rdata(7 downto 0) /= x"66" then
      report "Test 2 Failed: TGL failed, got " & to_hstring(rdata(7 downto 0)) & " expected 66" severity error;
      errors := errors + 1;
    end if;

    apb_write(x"00000024", x"00000044", pclk, paddr, pwdata, pwrite, psel, penable, pstrb, pready); -- CLR 44 -> 22
    wait for CLK_PERIOD * 10;
    apb_read(x"00000004", rdata, pclk, paddr, prdata, pwrite, psel, penable, pready);
    if rdata(7 downto 0) /= x"22" then
      report "Test 2 Failed: CLR failed, got " & to_hstring(rdata(7 downto 0)) & " expected 22" severity error;
      errors := errors + 1;
    end if;

    report "APB Native Directed Test Completion.";
    if errors = 0 then
      report "APB TEST PASSED";
    else
      report "APB TEST FAILED with " & integer'image(errors) & " errors" severity failure;
    end if;

    finish;
  end process;

  -- Timeout Watchdog
  process
  begin
    wait for 1 ms;
    report "TIMEOUT - Testbench hung" severity failure;
    finish;
  end process;

end architecture tb;
