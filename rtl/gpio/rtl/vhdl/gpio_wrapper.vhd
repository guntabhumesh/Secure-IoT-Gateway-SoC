--------------------------------------------------------------------------------
-- Module: gpio_wrapper
-- Description: Physical I/O wrapper for Professional-Grade GPIO IP (VHDL).
--
-- How it operates:
-- This VHDL module performs structural instantiation of NUM_BITS individual
-- gpio_bit modules. It acts as the physical layer, connecting internal
-- register controls to the outside pads.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gpio_wrapper is
  generic (
    NUM_BITS : integer := 32
  );
  port (
    clk     : in std_logic;
    reset_n : in std_logic;

    -- Core logic interface
    o  : in std_logic_vector(NUM_BITS - 1 downto 0);
    oe : in std_logic_vector(NUM_BITS - 1 downto 0);
    i  : out std_logic_vector(NUM_BITS - 1 downto 0);

    -- Physical configuration
    open_drain   : in std_logic_vector(NUM_BITS - 1 downto 0);
    pull_up_en   : in std_logic_vector(NUM_BITS - 1 downto 0);
    pull_down_en : in std_logic_vector(NUM_BITS - 1 downto 0);

    -- External IO Pins
    io : inout std_logic_vector(NUM_BITS - 1 downto 0)
  );
end entity gpio_wrapper;

architecture rtl of gpio_wrapper is
begin

  gen_gpio_bits : for k in 0 to NUM_BITS - 1 generate
    u_gpio_bit : entity work.gpio_bit
      port map
      (
        clk          => clk,
        reset_n      => reset_n,
        o            => o(k),
        oe           => oe(k),
        i            => i(k),
        open_drain   => open_drain(k),
        pull_up_en   => pull_up_en(k),
        pull_down_en => pull_down_en(k),
        pad          => io(k)
      );
  end generate;

end architecture rtl;
