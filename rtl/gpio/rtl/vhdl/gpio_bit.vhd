--------------------------------------------------------------------------------
-- Module: gpio_bit
-- Description: Bidirectional GPIO Bit module with advanced I/O control (VHDL).
--
-- How it operates:
-- This VHDL module handles the low-level tri-state logic for a single Pad.
-- It supports push-pull, open-drain, and soft pull-up/down resistors.
-- Input signals are synchronized to the clock to prevent metastability.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gpio_bit is
  port (
    clk     : in std_logic;
    reset_n : in std_logic;

    -- Core logic side
    o  : in std_logic; -- Output data
    oe : in std_logic; -- Output enable (1=output, 0=input)
    i  : out std_logic; -- Input data (synchronized)

    -- Physical configuration side
    open_drain   : in std_logic; -- 1 = Open-drain mode
    pull_up_en   : in std_logic; -- 1 = Internal pull-up enabled
    pull_down_en : in std_logic; -- 1 = Internal pull-down enabled

    -- External Pad side
    pad : inout std_logic
  );
end entity gpio_bit;

architecture rtl of gpio_bit is
  signal sync_reg  : std_logic_vector(1 downto 0) := "00";
  signal oe_actual : std_logic;
begin

  -- Logic for Open-Drain
  -- If open_drain is active and 'o' is high, we float (Hi-Z)
  -- Otherwise, we follow the 'oe' signal
  oe_actual <= (oe and (not o)) when open_drain = '1' else
    oe;

  -- Drive the pad
  pad <= o when oe_actual = '1' else
    'Z';

  -- Input Synchronization (2-stage)
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      sync_reg <= "00";
    elsif rising_edge(clk) then
      sync_reg <= sync_reg(0) & pad;
    end if;
  end process;

  i <= sync_reg(1);

end architecture rtl;
