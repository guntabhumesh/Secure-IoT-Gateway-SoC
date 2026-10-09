--------------------------------------------------------------------------------
-- File: axi4lite_slave_adapter.vhd
-- Description: Generic AXI4-Lite Slave Adapter (VHDL)
-- Converts AXI4-Lite transactions into a simple native register bus.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4lite_slave_adapter is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
  );
  port (
    -- AXI4-Lite Interface
    aclk    : in std_logic;
    aresetn : in std_logic;

    -- Write Address Channel
    s_axi_awaddr  : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;

    -- Write Data Channel
    s_axi_wdata  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    s_axi_wstrb  : in std_logic_vector((DATA_WIDTH/8) - 1 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wready : out std_logic;

    -- Write Response Channel
    s_axi_bresp  : out std_logic_vector(1 downto 0);
    s_axi_bvalid : out std_logic;
    s_axi_bready : in std_logic;

    -- Read Address Channel
    s_axi_araddr  : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out std_logic;

    -- Read Data Channel
    s_axi_rdata  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    s_axi_rresp  : out std_logic_vector(1 downto 0);
    s_axi_rvalid : out std_logic;
    s_axi_rready : in std_logic;

    -- Native Register Bus
    reg_addr  : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
    reg_wdata : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_rdata : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    reg_we    : out std_logic;
    reg_re    : out std_logic;
    reg_be    : out std_logic_vector((DATA_WIDTH/8) - 1 downto 0)
  );
end entity axi4lite_slave_adapter;

architecture rtl of axi4lite_slave_adapter is

  -- Internal Signals
  signal aw_en      : std_logic;
  signal awready_i  : std_logic;
  signal wready_i   : std_logic;
  signal bvalid_i   : std_logic;
  signal arready_i  : std_logic;
  signal rvalid_i   : std_logic;
  signal awaddr_reg : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal rdata_reg  : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

  -- Output Assignments (Native Bus)
  reg_we    <= '1' when (awready_i = '1' and s_axi_awvalid = '1' and s_axi_wvalid = '1') else '0';
  reg_addr  <= s_axi_awaddr when (awready_i = '1') else s_axi_araddr;
  reg_wdata <= s_axi_wdata;
  reg_be    <= s_axi_wstrb;
  reg_re    <= '1' when (arready_i = '1' and s_axi_arvalid = '1') else '0';

  s_axi_awready <= awready_i;
  s_axi_wready  <= wready_i;
  s_axi_arready <= arready_i;
  s_axi_bvalid  <= bvalid_i;
  s_axi_rvalid  <= rvalid_i;
  s_axi_bresp   <= "00"; -- OKAY
  s_axi_rresp   <= "00"; -- OKAY
  s_axi_rdata   <= rdata_reg;

  -- Write Address Handshake
  process (aclk, aresetn)
  begin
    if aresetn = '0' then
      awready_i <= '0';
      aw_en     <= '1';
    elsif rising_edge(aclk) then
      if (awready_i = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
        awready_i  <= '1';
        aw_en      <= '0';
        awaddr_reg <= s_axi_awaddr; -- Latch address
      elsif (s_axi_bready = '1' and bvalid_i = '1') then
        aw_en     <= '1';
        awready_i <= '0';
      else
        awready_i <= '0';
      end if;
    end if;
  end process;

  -- Write Data Handshake
  process (aclk, aresetn)
  begin
    if aresetn = '0' then
      wready_i <= '0';
    elsif rising_edge(aclk) then
      if (wready_i = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and aw_en = '1') then
        wready_i <= '1';
      else
        wready_i <= '0';
      end if;
    end if;
  end process;

  -- Write Response
  process (aclk, aresetn)
  begin
    if aresetn = '0' then
      bvalid_i <= '0';
    elsif rising_edge(aclk) then
      if (awready_i = '1' and s_axi_awvalid = '1' and wready_i = '1' and s_axi_wvalid = '1' and bvalid_i = '0') then
        bvalid_i <= '1';
      elsif (s_axi_bready = '1' and bvalid_i = '1') then
        bvalid_i <= '0';
      end if;
    end if;
  end process;

  -- Read Address Handshake
  process (aclk, aresetn)
  begin
    if aresetn = '0' then
      arready_i <= '0';
    elsif rising_edge(aclk) then
      -- Block arready if a read is already in progress (rvalid_i = '1')
      -- and not being cleared in this cycle.
      if (arready_i = '0' and s_axi_arvalid = '1' and rvalid_i = '0') then
        arready_i <= '1';
      else
        arready_i <= '0';
      end if;
    end if;
  end process;

  -- Read Data Handshake & Latch
  process (aclk, aresetn)
  begin
    if aresetn = '0' then
      rvalid_i  <= '0';
      rdata_reg <= (others => '0');
    elsif rising_edge(aclk) then
      if (arready_i = '1' and s_axi_arvalid = '1' and rvalid_i = '0') then
        rvalid_i  <= '1';
        rdata_reg <= reg_rdata;
      elsif (s_axi_rready = '1' and rvalid_i = '1') then
        rvalid_i <= '0';
      end if;
    end if;
  end process;

end architecture rtl;
