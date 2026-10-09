--------------------------------------------------------------------------------
-- Module: tb_gpio_axi
-- Description: VHDL Testbench for AXI4-Lite GPIO IP.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.axi_bfm_pkg.all;

entity tb_gpio_axi is
end entity tb_gpio_axi;

architecture tb of tb_gpio_axi is
  constant NUM_BITS   : integer := 8;
  constant CLK_PERIOD : time    := 10 ns;

  signal s_axi_aclk    : std_logic := '0';
  signal s_axi_aresetn : std_logic := '0';

  -- AXI4-Lite Write Address Channel
  signal s_axi_awaddr  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axi_awprot  : std_logic_vector(2 downto 0)  := (others => '0');
  signal s_axi_awvalid : std_logic                     := '0';
  signal s_axi_awready : std_logic;

  -- AXI4-Lite Write Data Channel
  signal s_axi_wdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axi_wstrb  : std_logic_vector(3 downto 0)  := (others => '0');
  signal s_axi_wvalid : std_logic                     := '0';
  signal s_axi_wready : std_logic;

  -- AXI4-Lite Write Response Channel
  signal s_axi_bresp  : std_logic_vector(1 downto 0);
  signal s_axi_bvalid : std_logic;
  signal s_axi_bready : std_logic := '0';

  -- AXI4-Lite Read Address Channel
  signal s_axi_araddr  : std_logic_vector(31 downto 0) := (others => '0');
  signal s_axi_arprot  : std_logic_vector(2 downto 0)  := (others => '0');
  signal s_axi_arvalid : std_logic                     := '0';
  signal s_axi_arready : std_logic;

  -- AXI4-Lite Read Data Channel
  signal s_axi_rdata  : std_logic_vector(31 downto 0);
  signal s_axi_rresp  : std_logic_vector(1 downto 0);
  signal s_axi_rvalid : std_logic;
  signal s_axi_rready : std_logic := '0';

  signal io   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => 'Z');
  signal intr : std_logic;

begin

  -- DUT
  u_dut : entity work.gpio_axi
    generic map(
      NUM_BITS => NUM_BITS
    )
    port map
    (
      s_axi_aclk    => s_axi_aclk,
      s_axi_aresetn => s_axi_aresetn,
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
      io            => io,
      intr          => intr
    );

  -- Clock generator
  s_axi_aclk <= not s_axi_aclk after CLK_PERIOD / 2;

  -- Stimulus
  process
    variable errors : integer := 0;
    variable rdata  : std_logic_vector(31 downto 0);
  begin
    report "Starting AXI Native Directed Test...";

    -- Reset
    s_axi_aresetn <= '0';
    wait for CLK_PERIOD * 5;
    s_axi_aresetn <= '1';
    wait until rising_edge(s_axi_aclk);

    -- Test 1: Basic R/W and DIR
    report "Test 1: Basic R/W and DIR";
    axi_write(x"00000008", x"000000FF", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- DIR=out
    axi_write(x"00000004", x"000000AA", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- DATA_O=AA

    wait for CLK_PERIOD * 10;
    axi_read(x"00000004", rdata, s_axi_aclk, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rready, s_axi_rvalid, s_axi_rdata);
    if rdata(7 downto 0) /= x"AA" then
      report "Test 1 Failed: DATA_O mismatch, got " & to_hstring(rdata(7 downto 0)) & " expected AA" severity error;
      errors := errors + 1;
    end if;

    -- Test 2: Atomic Operations
    report "Test 2: Atomic Operations";
    axi_write(x"00000004", x"00000055", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- DATA_O=55
    axi_write(x"00000020", x"00000011", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- SET 11
    wait for CLK_PERIOD * 10;
    axi_read(x"00000004", rdata, s_axi_aclk, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rready, s_axi_rvalid, s_axi_rdata);

    axi_write(x"00000004", x"00000044", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- DATA_O=44
    axi_write(x"00000028", x"00000022", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- TGL 22 -> 66
    wait for CLK_PERIOD * 10;
    axi_read(x"00000004", rdata, s_axi_aclk, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rready, s_axi_rvalid, s_axi_rdata);
    if rdata(7 downto 0) /= x"66" then
      report "Test 2 Failed: TGL failed, got " & to_hstring(rdata(7 downto 0)) & " expected 66" severity error;
      errors := errors + 1;
    end if;

    axi_write(x"00000024", x"00000044", s_axi_aclk, s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, s_axi_wready, s_axi_bready, s_axi_bvalid); -- CLR 44 -> 22
    wait for CLK_PERIOD * 10;
    axi_read(x"00000004", rdata, s_axi_aclk, s_axi_araddr, s_axi_arvalid, s_axi_arready, s_axi_rready, s_axi_rvalid, s_axi_rdata);
    if rdata(7 downto 0) /= x"22" then
      report "Test 2 Failed: CLR failed, got " & to_hstring(rdata(7 downto 0)) & " expected 22" severity error;
      errors := errors + 1;
    end if;

    report "AXI Native Directed Test Completion.";
    if errors = 0 then
      report "AXI TEST PASSED";
    else
      report "AXI TEST FAILED with " & integer'image(errors) & " errors" severity failure;
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
