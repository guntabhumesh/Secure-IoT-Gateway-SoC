--------------------------------------------------------------------------------
-- File: apb_bfm_pkg.vhd
-- Description: Shared APB4 Bus Functional Model Package (VHDL).
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package apb_bfm_pkg is

  procedure apb_write(
    constant addr    : in std_logic_vector(31 downto 0);
    constant data    : in std_logic_vector(31 downto 0);
    signal clk       : in std_logic;
    signal paddr_s   : out std_logic_vector(31 downto 0);
    signal pwdata_s  : out std_logic_vector(31 downto 0);
    signal pwrite_s  : out std_logic;
    signal psel_s    : out std_logic;
    signal penable_s : out std_logic;
    signal pstrb_s   : out std_logic_vector(3 downto 0);
    signal pready_i  : in std_logic
  );

  procedure apb_read(
    constant addr    : in std_logic_vector(31 downto 0);
    variable data    : out std_logic_vector(31 downto 0);
    signal clk       : in std_logic;
    signal paddr_s   : out std_logic_vector(31 downto 0);
    signal prdata_i  : in std_logic_vector(31 downto 0);
    signal pwrite_s  : out std_logic;
    signal psel_s    : out std_logic;
    signal penable_s : out std_logic;
    signal pready_i  : in std_logic
  );

end package apb_bfm_pkg;

package body apb_bfm_pkg is

  procedure apb_write(
    constant addr    : in std_logic_vector(31 downto 0);
    constant data    : in std_logic_vector(31 downto 0);
    signal clk       : in std_logic;
    signal paddr_s   : out std_logic_vector(31 downto 0);
    signal pwdata_s  : out std_logic_vector(31 downto 0);
    signal pwrite_s  : out std_logic;
    signal psel_s    : out std_logic;
    signal penable_s : out std_logic;
    signal pstrb_s   : out std_logic_vector(3 downto 0);
    signal pready_i  : in std_logic
  ) is
  begin
    wait until rising_edge(clk);
    paddr_s   <= addr;
    pwdata_s  <= data;
    pwrite_s  <= '1';
    psel_s    <= '1';
    penable_s <= '0';
    pstrb_s   <= x"F";

    wait until rising_edge(clk);
    penable_s <= '1';

    loop
      wait until rising_edge(clk);
      if pready_i = '1' then
        exit;
      end if;
    end loop;

    psel_s    <= '0';
    penable_s <= '0';
  end procedure;

  procedure apb_read(
    constant addr    : in std_logic_vector(31 downto 0);
    variable data    : out std_logic_vector(31 downto 0);
    signal clk       : in std_logic;
    signal paddr_s   : out std_logic_vector(31 downto 0);
    signal prdata_i  : in std_logic_vector(31 downto 0);
    signal pwrite_s  : out std_logic;
    signal psel_s    : out std_logic;
    signal penable_s : out std_logic;
    signal pready_i  : in std_logic
  ) is
  begin
    wait until rising_edge(clk);
    paddr_s   <= addr;
    pwrite_s  <= '0';
    psel_s    <= '1';
    penable_s <= '0';

    wait until rising_edge(clk);
    penable_s <= '1';

    loop
      wait until rising_edge(clk);
      if pready_i = '1' then
        data := prdata_i;
        exit;
      end if;
    end loop;

    psel_s    <= '0';
    penable_s <= '0';
  end procedure;

end package body apb_bfm_pkg;
