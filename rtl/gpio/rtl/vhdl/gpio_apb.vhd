--------------------------------------------------------------------------------
-- Module: gpio_apb
-- Description: APB Wrapper for Professional-Grade GPIO IP (VHDL).
--
-- How it operates:
-- This module provides a VHDL implementation of the APB slave interface.
-- It handles APB protocol signals (psel, penable, pwrite) and maps them to
-- internal register controls. It instantiates the common VHDL register block
-- and the multi-bit GPIO bit wrapper.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

-- gpio_apb.vhd
--
-- VHDL APB Slave Adapter for GPIO IP.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_apb is
  generic (
    NUM_BITS : integer := 32
  );
  port (
    pclk    : in std_logic;
    presetn : in std_logic;

    -- APB Interface
    paddr   : in std_logic_vector(31 downto 0);
    psel    : in std_logic;
    penable : in std_logic;
    pwrite  : in std_logic;
    pwdata  : in std_logic_vector(31 downto 0);
    pstrb   : in std_logic_vector(3 downto 0);
    pprot   : in std_logic_vector(2 downto 0);
    prdata  : out std_logic_vector(31 downto 0);
    pready  : out std_logic;
    pslverr : out std_logic;

    -- GPIO Pins
    io : inout std_logic_vector(NUM_BITS - 1 downto 0);

    -- Interrupt Output
    intr : out std_logic
  );
end entity gpio_apb;

architecture rtl of gpio_apb is
  signal reg_addr  : std_logic_vector(31 downto 0);
  signal reg_wdata : std_logic_vector(31 downto 0);
  signal reg_rdata : std_logic_vector(31 downto 0);
  signal reg_we    : std_logic;
  signal reg_re    : std_logic;
  signal reg_be    : std_logic_vector(3 downto 0);
  signal reg_ack   : std_logic;

  signal reg_data_o : std_logic_vector(NUM_BITS - 1 downto 0);
  signal reg_dir    : std_logic_vector(NUM_BITS - 1 downto 0);
  signal gpio_i     : std_logic_vector(NUM_BITS - 1 downto 0);

  signal open_drain   : std_logic_vector(NUM_BITS - 1 downto 0);
  signal pull_up_en   : std_logic_vector(NUM_BITS - 1 downto 0);
  signal pull_down_en : std_logic_vector(NUM_BITS - 1 downto 0);

begin

  -- APB Slave Adapter
  u_apb_adapter : entity work.apb_slave_adapter
    generic map(
      ADDR_WIDTH => 32,
      DATA_WIDTH => 32
    )
    port map
    (
      pclk      => pclk,
      presetn   => presetn,
      paddr     => paddr,
      pprot     => pprot,
      psel      => psel,
      penable   => penable,
      pwrite    => pwrite,
      pwdata    => pwdata,
      pstrb     => pstrb,
      prdata    => prdata,
      pready    => pready,
      pslverr   => pslverr,
      reg_addr  => reg_addr,
      reg_wdata => reg_wdata,
      reg_rdata => reg_rdata,
      reg_we    => reg_we,
      reg_re    => reg_re,
      reg_be    => reg_be
    );

  -- Register Block
  u_gpio_regs : entity work.gpio_regs
    generic map(NUM_BITS => NUM_BITS)
    port map
    (
      clk          => pclk,
      reset_n      => presetn,
      addr         => reg_addr,
      wdata        => reg_wdata,
      rdata        => reg_rdata,
      we           => reg_we,
      re           => reg_re,
      be           => reg_be,
      ack          => reg_ack,
      reg_data_o   => reg_data_o,
      reg_dir      => reg_dir,
      gpio_i       => gpio_i,
      open_drain   => open_drain,
      pull_up_en   => pull_up_en,
      pull_down_en => pull_down_en,
      intr         => intr
    );

  -- IO Wrapper
  u_gpio_wrapper : entity work.gpio_wrapper
    generic map(NUM_BITS => NUM_BITS)
    port map
    (
      clk          => pclk,
      reset_n      => presetn,
      o            => reg_data_o,
      oe           => reg_dir,
      i            => gpio_i,
      open_drain   => open_drain,
      pull_up_en   => pull_up_en,
      pull_down_en => pull_down_en,
      io           => io
    );

end architecture rtl;
