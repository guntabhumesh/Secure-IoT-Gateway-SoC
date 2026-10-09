--------------------------------------------------------------------------------
-- File: axi_bfm_pkg.vhd
-- Description: Shared AXI4-Lite Bus Functional Model Package (VHDL).
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi_bfm_pkg is

  constant CLK_PERIOD : time := 10 ns; -- Default, can be overridden if needed but packages are static

  procedure axi_write(
    constant addr  : in std_logic_vector(31 downto 0);
    constant data  : in std_logic_vector(31 downto 0);
    signal clk     : in std_logic;
    signal awaddr  : out std_logic_vector(31 downto 0);
    signal awvalid : out std_logic;
    signal awready : in std_logic;
    signal wdata   : out std_logic_vector(31 downto 0);
    signal wstrb   : out std_logic_vector(3 downto 0);
    signal wvalid  : out std_logic;
    signal wready  : in std_logic;
    signal bready  : out std_logic;
    signal bvalid  : in std_logic
  );

  procedure axi_read(
    constant addr  : in std_logic_vector(31 downto 0);
    variable data  : out std_logic_vector(31 downto 0);
    signal clk     : in std_logic;
    signal araddr  : out std_logic_vector(31 downto 0);
    signal arvalid : out std_logic;
    signal arready : in std_logic;
    signal rready  : out std_logic;
    signal rvalid  : in std_logic;
    signal rdata   : in std_logic_vector(31 downto 0)
  );

end package axi_bfm_pkg;

package body axi_bfm_pkg is

  procedure axi_write(
    constant addr  : in std_logic_vector(31 downto 0);
    constant data  : in std_logic_vector(31 downto 0);
    signal clk     : in std_logic;
    signal awaddr  : out std_logic_vector(31 downto 0);
    signal awvalid : out std_logic;
    signal awready : in std_logic;
    signal wdata   : out std_logic_vector(31 downto 0);
    signal wstrb   : out std_logic_vector(3 downto 0);
    signal wvalid  : out std_logic;
    signal wready  : in std_logic;
    signal bready  : out std_logic;
    signal bvalid  : in std_logic
  ) is
  begin
    wait until rising_edge(clk);
    awaddr  <= addr;
    awvalid <= '1';
    wdata   <= data;
    wstrb   <= x"F";
    wvalid  <= '1';
    bready  <= '1';

    loop
      wait until rising_edge(clk);
      if awready = '1' then
        awvalid <= '0';
      end if;
      if wready = '1' then
        wvalid <= '0';
      end if;
      if bvalid = '1' then
        bready <= '0';
        exit;
      end if;
    end loop;
  end procedure;

  procedure axi_read(
    constant addr  : in std_logic_vector(31 downto 0);
    variable data  : out std_logic_vector(31 downto 0);
    signal clk     : in std_logic;
    signal araddr  : out std_logic_vector(31 downto 0);
    signal arvalid : out std_logic;
    signal arready : in std_logic;
    signal rready  : out std_logic;
    signal rvalid  : in std_logic;
    signal rdata   : in std_logic_vector(31 downto 0)
  ) is
  begin
    wait until rising_edge(clk);
    araddr  <= addr;
    arvalid <= '1';
    rready  <= '1';

    loop
      wait until rising_edge(clk);
      if arready = '1' then
        arvalid <= '0';
      end if;
      if rvalid = '1' then
        data := rdata;
        rready <= '0';
        exit;
      end if;
    end loop;
  end procedure;

end package body axi_bfm_pkg;
