--
-- General Purpose Timer Registers (VHDL-2008)
--
-- Description:
--   Register file for the General Timer.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_regs is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    -- Bus Interface
    cs    : in std_logic                     := '0';
    we    : in std_logic                     := '0';
    addr  : in std_logic_vector(5 downto 0)  := (others => '0');
    wdata : in std_logic_vector(31 downto 0) := (others => '0');
    rdata : out std_logic_vector(31 downto 0);

    -- Core Interface
    en       : out std_logic;
    mode     : out std_logic;
    dir      : out std_logic;
    pwm_en   : out std_logic;
    ext_en   : out std_logic;
    cap_en   : out std_logic;
    pre_en   : out std_logic;
    pre_val  : out std_logic_vector(15 downto 0);
    load_val : out std_logic_vector(31 downto 0);
    cmp_val  : out std_logic_vector(31 downto 0);
    load_cmd : out std_logic;

    current_val : in std_logic_vector(31 downto 0) := (others => '0');
    capture_val : in std_logic_vector(31 downto 0) := (others => '0');
    capture_stb : in std_logic                     := '0';
    core_irq    : in std_logic                     := '0';

    -- System
    intr_o : out std_logic
  );
end entity timer_regs;

architecture rtl of timer_regs is
  -- Register Addresses
  constant ADDR_CTRL    : unsigned(5 downto 0) := "000000"; -- 0x00
  constant ADDR_LOAD    : unsigned(5 downto 0) := "000100"; -- 0x04
  constant ADDR_VAL     : unsigned(5 downto 0) := "001000"; -- 0x08
  constant ADDR_PRE     : unsigned(5 downto 0) := "001100"; -- 0x0C
  constant ADDR_INT_EN  : unsigned(5 downto 0) := "010000"; -- 0x10
  constant ADDR_INT_STS : unsigned(5 downto 0) := "010100"; -- 0x14
  constant ADDR_CMP     : unsigned(5 downto 0) := "011000"; -- 0x18
  constant ADDR_CAP     : unsigned(5 downto 0) := "011100"; -- 0x1C

  -- Registers
  signal reg_ctrl    : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_load    : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_pre     : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_int_en  : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_int_sts : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_cmp     : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_cap     : std_logic_vector(31 downto 0) := (others => '0');

begin

  -- Control Assignments
  en     <= reg_ctrl(0);
  mode   <= reg_ctrl(1);
  pre_en <= reg_ctrl(2);
  dir    <= reg_ctrl(3);
  pwm_en <= reg_ctrl(4);
  ext_en <= reg_ctrl(5);
  cap_en <= reg_ctrl(6);

  pre_val <= reg_pre(15 downto 0);
  cmp_val <= reg_cmp;

  load_cmd <= '1' when (cs = '1' and we = '1' and addr = std_logic_vector(ADDR_LOAD)) else
    '0';

  -- Bypass reg_load when writing
  load_val <= wdata when (cs = '1' and we = '1' and addr = std_logic_vector(ADDR_LOAD)) else
    reg_load;

  -- Interrupt Output
  intr_o <= (reg_int_sts(0) and reg_int_en(0)) or (reg_int_sts(1) and reg_int_en(1));

  -- Read Logic
  process (all)
  begin
    rdata <= (others => '0');
    if cs = '1' then
      case addr is
        when std_logic_vector(ADDR_CTRL) =>
          rdata <= reg_ctrl;
        when std_logic_vector(ADDR_LOAD) =>
          rdata <= reg_load;
        when std_logic_vector(ADDR_VAL) =>
          rdata <= current_val;
        when std_logic_vector(ADDR_PRE) =>
          rdata <= reg_pre;
        when std_logic_vector(ADDR_INT_EN) =>
          rdata <= reg_int_en;
        when std_logic_vector(ADDR_INT_STS) =>
          rdata <= reg_int_sts;
        when std_logic_vector(ADDR_CMP) =>
          rdata <= reg_cmp;
        when std_logic_vector(ADDR_CAP) =>
          rdata <= reg_cap;
        when others      =>
          rdata <= (others => '0');
      end case;
    end if;
  end process;

  -- Write Logic
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      reg_ctrl    <= (others => '0');
      reg_load    <= (others => '0');
      reg_pre     <= (others => '0');
      reg_cmp     <= (others => '0');
      reg_cap     <= (others => '0');
      reg_int_en  <= (others => '0');
      reg_int_sts <= (others => '0');
    elsif rising_edge(clk) then

      -- Interrupt Status and Write Logic
      if cs = '1' and we = '1' then
        if addr = std_logic_vector(ADDR_CTRL) then
          reg_ctrl <= wdata;
        elsif addr = std_logic_vector(ADDR_LOAD) then
          reg_load <= wdata;
        elsif addr = std_logic_vector(ADDR_PRE) then
          reg_pre <= wdata;
        elsif addr = std_logic_vector(ADDR_CMP) then
          reg_cmp <= wdata;
        elsif addr = std_logic_vector(ADDR_INT_EN) then
          reg_int_en <= wdata;
        end if;
      end if;

      -- Capture Update
      if capture_stb = '1' and cap_en = '1' then
        reg_cap <= capture_val;
      end if;

      -- Interrupt Status (Sticky bits)
      reg_int_sts(31 downto 2) <= (others => '0');

      if (core_irq = '1') then
        reg_int_sts(0) <= '1';
      elsif (cs = '1' and we = '1' and addr = std_logic_vector(ADDR_INT_STS) and wdata(0) = '1') then
        reg_int_sts(0) <= '0';
      end if;

      if (capture_stb = '1') then
        reg_int_sts(1) <= '1';
      elsif (cs = '1' and we = '1' and addr = std_logic_vector(ADDR_INT_STS) and wdata(1) = '1') then
        reg_int_sts(1) <= '0';
      end if;
    end if;
  end process;

end architecture rtl;
