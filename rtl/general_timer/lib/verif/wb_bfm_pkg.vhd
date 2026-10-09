--------------------------------------------------------------------------------
-- File: wb_bfm_pkg.vhd
-- Description: Shared Wishbone B4 Bus Functional Model Package (VHDL).
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package wb_bfm_pkg is

  procedure wb_write(
    constant addr : in std_logic_vector(31 downto 0);
    constant data : in std_logic_vector(31 downto 0);
    signal clk    : in std_logic;
    signal wb_adr : out std_logic_vector(31 downto 0);
    signal wb_dat : out std_logic_vector(31 downto 0);
    signal wb_we  : out std_logic;
    signal wb_cyc : out std_logic;
    signal wb_stb : out std_logic;
    signal wb_sel : out std_logic_vector(3 downto 0);
    signal wb_ack : in std_logic
  );

  procedure wb_read(
    constant addr     : in std_logic_vector(31 downto 0);
    variable data     : out std_logic_vector(31 downto 0);
    signal clk        : in std_logic;
    signal wb_adr     : out std_logic_vector(31 downto 0);
    signal wb_dat_out : in std_logic_vector(31 downto 0);
    signal wb_we      : out std_logic;
    signal wb_cyc     : out std_logic;
    signal wb_stb     : out std_logic;
    signal wb_sel     : out std_logic_vector(3 downto 0);
    signal wb_ack     : in std_logic
  );

end package wb_bfm_pkg;

package body wb_bfm_pkg is

  procedure wb_write(
    constant addr : in std_logic_vector(31 downto 0);
    constant data : in std_logic_vector(31 downto 0);
    signal clk    : in std_logic;
    signal wb_adr : out std_logic_vector(31 downto 0);
    signal wb_dat : out std_logic_vector(31 downto 0);
    signal wb_we  : out std_logic;
    signal wb_cyc : out std_logic;
    signal wb_stb : out std_logic;
    signal wb_sel : out std_logic_vector(3 downto 0);
    signal wb_ack : in std_logic
  ) is
  begin
    wb_adr <= addr;
    wb_dat <= data;
    wb_we  <= '1';
    wb_cyc <= '1';
    wb_stb <= '1';
    wb_sel <= x"F";

    loop
      wait until rising_edge(clk);
      if wb_ack = '1' then
        exit;
      end if;
    end loop;

    wb_cyc <= '0';
    wb_stb <= '0';
    wb_we  <= '0';
  end procedure;

  procedure wb_read(
    constant addr     : in std_logic_vector(31 downto 0);
    variable data     : out std_logic_vector(31 downto 0);
    signal clk        : in std_logic;
    signal wb_adr     : out std_logic_vector(31 downto 0);
    signal wb_dat_out : in std_logic_vector(31 downto 0);
    signal wb_we      : out std_logic;
    signal wb_cyc     : out std_logic;
    signal wb_stb     : out std_logic;
    signal wb_sel     : out std_logic_vector(3 downto 0);
    signal wb_ack     : in std_logic
  ) is
  begin
    wb_adr <= addr;
    wb_we  <= '0';
    wb_cyc <= '1';
    wb_stb <= '1';
    wb_sel <= x"F";

    loop
      wait until rising_edge(clk);
      if wb_ack = '1' then
        data := wb_dat_out;
        exit;
      end if;
    end loop;

    wb_cyc <= '0';
    wb_stb <= '0';
  end procedure;

end package body wb_bfm_pkg;
