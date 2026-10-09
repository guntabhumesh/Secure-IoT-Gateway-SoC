--------------------------------------------------------------------------------
-- Module: gpio_axi
-- Description: AXI4-Lite Wrapper for Professional-Grade GPIO IP (VHDL).
--
-- How it operates:
-- This module provides a VHDL implementation of the AXI4-Lite slave interface.
-- It translates AXI bus signals into internal register accesses for the 
-- GPIO logic. It instantiates the common VHDL register block and the
-- multi-bit GPIO bit wrapper.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

-- gpio_axi.vhd
--
-- VHDL AXI4-Lite Slave Adapter for GPIO IP.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_axi is
  generic (
    NUM_BITS : integer := 32
  );
  port (
    -- AXI4-Lite Interface
    s_axi_aclk    : in std_logic;
    s_axi_aresetn : in std_logic;

    -- Write Address Channel
    s_axi_awaddr  : in std_logic_vector(31 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;

    -- Write Data Channel
    s_axi_wdata  : in std_logic_vector(31 downto 0);
    s_axi_wstrb  : in std_logic_vector(3 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wready : out std_logic;

    -- Write Response Channel
    s_axi_bresp  : out std_logic_vector(1 downto 0);
    s_axi_bvalid : out std_logic;
    s_axi_bready : in std_logic;

    -- Read Address Channel
    s_axi_araddr  : in std_logic_vector(31 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out std_logic;

    -- Read Data Channel
    s_axi_rdata  : out std_logic_vector(31 downto 0);
    s_axi_rresp  : out std_logic_vector(1 downto 0);
    s_axi_rvalid : out std_logic;
    s_axi_rready : in std_logic;

    -- GPIO Pins
    io : inout std_logic_vector(NUM_BITS - 1 downto 0);

    -- Interrupt Output
    intr : out std_logic
  );
end entity gpio_axi;

architecture rtl of gpio_axi is
  -- Internal Bus Signals
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

  -- Physical Config Signals
  signal open_drain   : std_logic_vector(NUM_BITS - 1 downto 0);
  signal pull_up_en   : std_logic_vector(NUM_BITS - 1 downto 0);
  signal pull_down_en : std_logic_vector(NUM_BITS - 1 downto 0);

begin

  -- AXI4-Lite Slave Adapter
  u_axi_adapter : entity work.axi4lite_slave_adapter
    generic map(
      ADDR_WIDTH => 32,
      DATA_WIDTH => 32
    )
    port map
    (
      aclk          => s_axi_aclk,
      aresetn       => s_axi_aresetn,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,
      reg_addr      => reg_addr,
      reg_wdata     => reg_wdata,
      reg_rdata     => reg_rdata,
      reg_we        => reg_we,
      reg_re        => reg_re,
      reg_be        => reg_be
    );

  -- Register Block
  u_gpio_regs : entity work.gpio_regs
    generic map(NUM_BITS => NUM_BITS)
    port map
    (
      clk          => s_axi_aclk,
      reset_n      => s_axi_aresetn,
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
      clk          => s_axi_aclk,
      reset_n      => s_axi_aresetn,
      o            => reg_data_o,
      oe           => reg_dir,
      i            => gpio_i,
      open_drain   => open_drain,
      pull_up_en   => pull_up_en,
      pull_down_en => pull_down_en,
      io           => io
    );

end architecture rtl;
