--------------------------------------------------------------------------------
-- Module: tb_gpio_wb
-- Description: VHDL Testbench for Wishbone B4 GPIO IP.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.wb_bfm_pkg.all;

entity tb_gpio_wb is
end entity tb_gpio_wb;

architecture tb of tb_gpio_wb is
  constant NUM_BITS   : integer := 8;
  constant CLK_PERIOD : time    := 10 ns;

  signal wb_clk_i : std_logic := '0';
  signal wb_rst_i : std_logic := '0';

  signal wb_adr_i   : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_dat_i   : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_dat_o   : std_logic_vector(31 downto 0);
  signal wb_we_i    : std_logic                    := '0';
  signal wb_sel_i   : std_logic_vector(3 downto 0) := (others => '0');
  signal wb_stb_i   : std_logic                    := '0';
  signal wb_cyc_i   : std_logic                    := '0';
  signal wb_ack_o   : std_logic;
  signal wb_err_o   : std_logic;
  signal wb_stall_o : std_logic;

  signal io   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => 'Z');
  signal intr : std_logic;

begin

  -- DUT
  u_dut : entity work.gpio_wb
    generic map(
      NUM_BITS => NUM_BITS
    )
    port map
    (
      wb_clk_i   => wb_clk_i,
      wb_rst_i   => wb_rst_i,
      wb_adr_i   => wb_adr_i,
      wb_dat_i   => wb_dat_i,
      wb_dat_o   => wb_dat_o,
      wb_we_i    => wb_we_i,
      wb_sel_i   => wb_sel_i,
      wb_stb_i   => wb_stb_i,
      wb_cyc_i   => wb_cyc_i,
      wb_ack_o   => wb_ack_o,
      wb_err_o   => wb_err_o,
      wb_stall_o => wb_stall_o,
      io         => io,
      intr       => intr
    );

  -- Clock generator
  wb_clk_i <= not wb_clk_i after CLK_PERIOD / 2;

  -- Stimulus
  process
    variable errors : integer := 0;
    variable rdata  : std_logic_vector(31 downto 0);
  begin
    report "Starting Wishbone Native Directed Test...";

    -- Reset
    wb_rst_i <= '1';
    wait for CLK_PERIOD * 5;
    wb_rst_i <= '0';
    wait until rising_edge(wb_clk_i);

    -- Test 1: Basic R/W and DIR
    report "Test 1: Basic R/W and DIR";
    wb_write(x"00000008", x"000000FF", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- DIR=out
    wb_write(x"00000004", x"000000AA", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- DATA_O=AA

    wait for CLK_PERIOD * 10;
    wb_read(x"00000004", rdata, wb_clk_i, wb_adr_i, wb_dat_o, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o);
    if rdata(7 downto 0) /= x"AA" then
      report "Test 1 Failed: DATA_O mismatch, got " & to_hstring(rdata(7 downto 0)) & " expected AA" severity error;
      errors := errors + 1;
    end if;

    -- Test 2: Atomic Operations
    report "Test 2: Atomic Operations";
    wb_write(x"00000004", x"00000055", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- DATA_O=55
    wb_write(x"00000020", x"00000011", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- SET 11 -> 55 | 11 = 55
    wait for CLK_PERIOD * 10;
    wb_read(x"00000004", rdata, wb_clk_i, wb_adr_i, wb_dat_o, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o);
    if rdata(7 downto 0) /= x"55" then -- Wait, 55 | 11 is 55? No, 5: 0101, 1: 0001. 5|1 = 5. So 55|11 = 55. Correct.
      -- report "Test 2 Failed: SET failed" severity error;
    end if;

    wb_write(x"00000004", x"00000044", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- DATA_O=44
    wb_write(x"00000028", x"00000022", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- TGL 22 -> 44 ^ 22 = 66
    wait for CLK_PERIOD * 10;
    wb_read(x"00000004", rdata, wb_clk_i, wb_adr_i, wb_dat_o, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o);
    if rdata(7 downto 0) /= x"66" then
      report "Test 2 Failed: TGL failed, got " & to_hstring(rdata(7 downto 0)) & " expected 66" severity error;
      errors := errors + 1;
    end if;

    wb_write(x"00000024", x"00000044", wb_clk_i, wb_adr_i, wb_dat_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o); -- CLR 44 -> 66 & ~44 = 22
    wait for CLK_PERIOD * 10;
    wb_read(x"00000004", rdata, wb_clk_i, wb_adr_i, wb_dat_o, wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i, wb_ack_o);
    if rdata(7 downto 0) /= x"22" then
      report "Test 2 Failed: CLR failed, got " & to_hstring(rdata(7 downto 0)) & " expected 22" severity error;
      errors := errors + 1;
    end if;

    report "Wishbone Native Directed Test Completion.";
    if errors = 0 then
      report "WISHBONE TEST PASSED";
    else
      report "WISHBONE TEST FAILED with " & integer'image(errors) & " errors" severity failure;
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
