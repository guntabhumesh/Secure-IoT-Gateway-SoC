--------------------------------------------------------------------------------
-- Module: gpio_wb
-- Description: Wishbone B4 Wrapper for Professional-Grade GPIO IP (VHDL).
--
-- How it operates:
-- This module provides a VHDL implementation of the Wishbone B4 slave
-- interface. It handles Wishbone signals (cyc, stb, we, ack) and translates
-- them into internal register accesses. It instantiates the common VHDL
-- register block and the multi-bit GPIO bit wrapper.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_wb is
  generic (
    NUM_BITS : integer := 32
  );
  port (
    wb_clk_i : in std_logic;
    wb_rst_i : in std_logic;

    -- Wishbone Interface
    wb_adr_i   : in std_logic_vector(31 downto 0);
    wb_dat_i   : in std_logic_vector(31 downto 0);
    wb_dat_o   : out std_logic_vector(31 downto 0);
    wb_we_i    : in std_logic;
    wb_sel_i   : in std_logic_vector(3 downto 0);
    wb_stb_i   : in std_logic;
    wb_cyc_i   : in std_logic;
    wb_ack_o   : out std_logic;
    wb_err_o   : out std_logic;
    wb_stall_o : out std_logic;

    -- GPIO Pins
    io : inout std_logic_vector(NUM_BITS - 1 downto 0);

    -- Interrupt Output
    intr : out std_logic
  );
end entity gpio_wb;

architecture rtl of gpio_wb is
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

  signal reset_n : std_logic;
begin

  reset_n <= not wb_rst_i;

  -- Wishbone Slave Adapter
  u_wb_adapter : entity work.wb_slave_adapter
    generic map(
      ADDR_WIDTH => 32,
      DATA_WIDTH => 32
    )
    port map
    (
      wb_clk_i   => wb_clk_i,
      wb_rst_i   => wb_rst_i,
      wb_adr_i   => wb_adr_i,
      wb_dat_i   => wb_dat_i,
      wb_dat_o   => wb_dat_o,
      wb_we_i    => wb_we_i,
      wb_stb_i   => wb_stb_i,
      wb_cyc_i   => wb_cyc_i,
      wb_sel_i   => wb_sel_i,
      wb_ack_o   => wb_ack_o,
      wb_err_o   => wb_err_o,
      wb_stall_o => wb_stall_o,
      reg_addr   => reg_addr,
      reg_wdata  => reg_wdata,
      reg_rdata  => reg_rdata,
      reg_we     => reg_we,
      reg_re     => reg_re,
      reg_be     => reg_be
    );

  -- Register Block
  u_gpio_regs : entity work.gpio_regs
    generic map(NUM_BITS => NUM_BITS)
    port map
    (
      clk          => wb_clk_i,
      reset_n      => reset_n,
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
      clk          => wb_clk_i,
      reset_n      => reset_n,
      o            => reg_data_o,
      oe           => reg_dir,
      i            => gpio_i,
      open_drain   => open_drain,
      pull_up_en   => pull_up_en,
      pull_down_en => pull_down_en,
      io           => io
    );

end architecture rtl;
