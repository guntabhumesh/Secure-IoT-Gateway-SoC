--------------------------------------------------------------------------------
-- File: apb_slave_adapter.vhd
-- Description: Generic APB4 Slave Adapter (VHDL)
-- Converts APB transactions into a simple native register bus.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apb_slave_adapter is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
  );
  port (
    -- APB Interface
    pclk    : in std_logic;
    presetn : in std_logic;

    paddr   : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    pprot   : in std_logic_vector(2 downto 0);
    psel    : in std_logic;
    penable : in std_logic;
    pwrite  : in std_logic;
    pwdata  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    pstrb   : in std_logic_vector((DATA_WIDTH/8) - 1 downto 0);

    prdata  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    pready  : out std_logic;
    pslverr : out std_logic;

    -- Native Register Bus
    reg_addr  : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    reg_wdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_rdata : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_we    : out std_logic;
    reg_re    : out std_logic;
    reg_be    : out std_logic_vector((DATA_WIDTH/8) - 1 downto 0)
  );
end entity apb_slave_adapter;

architecture rtl of apb_slave_adapter is
begin

  -- APB Logic (Zero-wait state)
  pready  <= '1';
  pslverr <= '0';

  -- Pass-through
  prdata <= reg_rdata;

  -- Native Bus Mapping
  reg_addr  <= paddr;
  reg_wdata <= pwdata;
  reg_be    <= pstrb;

  -- Write Enable: PSEL and PENABLE and PWRITE
  reg_we <= '1' when (psel = '1' and penable = '1' and pwrite = '1') else
    '0';

  -- Read Enable: PSEL and !PWRITE (Matches Verilog implementation)
  reg_re <= '1' when (psel = '1' and pwrite = '0') else
    '0';

end architecture rtl;
