--------------------------------------------------------------------------------
-- File: ahb_slave_adapter.vhd
-- Description: Generic AHB-Lite Slave Adapter (VHDL)
-- Converts AHB-Lite transactions into a simple native register bus.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ahb_slave_adapter is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
  );
  port (
    hclk    : in std_logic;
    hresetn : in std_logic;

    -- AHB-Lite Interface
    hsel      : in std_logic;
    haddr     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    htrans    : in std_logic_vector(1 downto 0);
    hwrite    : in std_logic;
    hsize     : in std_logic_vector(2 downto 0);
    hburst    : in std_logic_vector(2 downto 0);
    hprot     : in std_logic_vector(3 downto 0);
    hwdata    : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    hready_i  : in std_logic;
    hready_o  : out std_logic;
    hresp     : out std_logic_vector(1 downto 0);
    hrdata    : out std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- Native Register Bus
    reg_addr  : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    reg_wdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_rdata : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_we    : out std_logic;
    reg_re    : out std_logic;
    reg_be    : out std_logic_vector((DATA_WIDTH/8) - 1 downto 0)
  );
end entity ahb_slave_adapter;

architecture rtl of ahb_slave_adapter is

  -- Address Phase Registers
  signal addr_reg   : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal write_reg  : std_logic;
  signal size_reg   : std_logic_vector(2 downto 0);
  signal active_req : std_logic;

begin

  -- Capture Address Phase
  process (hclk, hresetn)
  begin
    if hresetn = '0' then
      addr_reg   <= (others => '0');
      write_reg  <= '0';
      size_reg   <= (others => '0');
      active_req <= '0';
    elsif rising_edge(hclk) then
      if hsel = '1' and hready_i = '1' and htrans(1) = '1' then
        addr_reg   <= haddr;
        write_reg  <= hwrite;
        size_reg   <= hsize;
        active_req <= '1';
      elsif hready_i = '1' then
        active_req <= '0';
      end if;
    end if;
  end process;

  -- Data Phase (Native Bus Outputs)
  reg_addr  <= addr_reg;
  reg_wdata <= hwdata;
  reg_we    <= '1' when (active_req = '1' and write_reg = '1') else '0';
  reg_re    <= '1' when (active_req = '1' and write_reg = '0') else '0';

  -- Byte Enable Logic
  process (active_req, size_reg, addr_reg)
    variable byte_sel : integer;
    variable be_v     : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
  begin
    be_v := (others => '0');
    if active_req = '1' then
      byte_sel := to_integer(unsigned(addr_reg(1 downto 0)));
      case size_reg is
        when "000" => -- Byte
          case byte_sel is
            when 0 => be_v := "0001";
            when 1 => be_v := "0010";
            when 2 => be_v := "0100";
            when 3 => be_v := "1000";
            when others => be_v := "0000";
          end case;
        when "001" => -- Halfword
          if byte_sel = 0 then
            be_v := "0011";
          else
            be_v := "1100";
          end if;
        when "010" => -- Word
          be_v := "1111";
        when others =>
          be_v := "1111";
      end case;
    end if;
    reg_be <= be_v;
  end process;

  -- AHB Responses
  hready_o <= '1';
  hresp    <= "00";
  hrdata   <= reg_rdata;

end architecture rtl;
