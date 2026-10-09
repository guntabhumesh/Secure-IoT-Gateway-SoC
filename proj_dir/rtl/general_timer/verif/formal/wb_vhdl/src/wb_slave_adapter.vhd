--------------------------------------------------------------------------------
-- File: wb_slave_adapter.vhd
-- Description: Generic Wishbone B4 Slave Adapter (VHDL)
-- Converts Wishbone transactions into a simple native register bus.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_slave_adapter is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
  );
  port (
    -- Wishbone Interface
    wb_clk_i : in std_logic;
    wb_rst_i : in std_logic;

    wb_adr_i : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    wb_dat_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    wb_dat_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    wb_we_i  : in std_logic;
    wb_stb_i : in std_logic;
    wb_cyc_i : in std_logic;
    wb_sel_i : in std_logic_vector((DATA_WIDTH/8) - 1 downto 0);

    wb_ack_o   : out std_logic;
    wb_err_o   : out std_logic;
    wb_stall_o : out std_logic;

    -- Native Register Bus
    reg_addr  : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    reg_wdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_rdata : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_we    : out std_logic;
    reg_re    : out std_logic;
    reg_be    : out std_logic_vector((DATA_WIDTH/8) - 1 downto 0)
  );
end entity wb_slave_adapter;

architecture rtl of wb_slave_adapter is

  signal ack_q : std_logic;

begin

  -- Wishbone Output Assignments
  wb_err_o   <= '0';
  wb_stall_o <= '0';
  wb_dat_o   <= reg_rdata;
  wb_ack_o   <= ack_q;

  -- Native Bus Assignments
  reg_addr  <= wb_adr_i;
  reg_wdata <= wb_dat_i;
  reg_be    <= wb_sel_i;

  -- ACK Generation (1 wait state)
  process (wb_clk_i, wb_rst_i)
  begin
    if wb_rst_i = '1' then -- Assumed High Active reset based on name usually, but usually wishbone is active high reset
      ack_q <= '0';
    elsif rising_edge(wb_clk_i) then
      if (wb_cyc_i = '1' and wb_stb_i = '1' and ack_q = '0') then
        ack_q <= '1';
      else
        ack_q <= '0';
      end if;
    end if;
  end process;

  -- Write Enable: Gated by !ack_q (from Verilog fix)
  reg_we <= '1' when (wb_cyc_i = '1' and wb_stb_i = '1' and wb_we_i = '1' and ack_q = '0') else
    '0';

  -- Read Enable
  reg_re <= '1' when (wb_cyc_i = '1' and wb_stb_i = '1' and wb_we_i = '0') else
    '0';

end architecture rtl;
