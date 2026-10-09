--------------------------------------------------------------------------------
-- Module: gpio_regs
-- Description: Common register block for Professional-Grade GPIO IP (VHDL).
--
-- How it operates:
-- This VHDL module implements the core register logic and feature set of the
-- GPIO IP. It managed internal state, edge/level interrupt detection,
-- input debouncing with configurable thresholds, and PWM generation per pin.
--
-- Author: Gemini-3 AI
-- License: MIT
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_regs is
  generic (
    NUM_BITS : integer := 32
  );
  port (
    clk     : in std_logic;
    reset_n : in std_logic;

    -- Internal Bus Interface
    addr  : in std_logic_vector(31 downto 0);
    wdata : in std_logic_vector(31 downto 0);
    rdata : out std_logic_vector(31 downto 0);
    we    : in std_logic;
    re    : in std_logic;
    be    : in std_logic_vector(3 downto 0);
    ack   : out std_logic;

    -- Interface to GPIO Wrapper
    reg_data_o : out std_logic_vector(NUM_BITS - 1 downto 0);
    reg_dir    : out std_logic_vector(NUM_BITS - 1 downto 0);
    gpio_i     : in std_logic_vector(NUM_BITS - 1 downto 0);

    -- Physical Configuration to Wrapper
    open_drain   : out std_logic_vector(NUM_BITS - 1 downto 0);
    pull_up_en   : out std_logic_vector(NUM_BITS - 1 downto 0);
    pull_down_en : out std_logic_vector(NUM_BITS - 1 downto 0);

    -- Interrupt Output
    intr : out std_logic
  );
end entity gpio_regs;

architecture rtl of gpio_regs is
  -- Register Offsets
  constant ADDR_DATA_I   : std_logic_vector(6 downto 0) := "0000000"; -- 0x00
  constant ADDR_DATA_O   : std_logic_vector(6 downto 0) := "0000100"; -- 0x04
  constant ADDR_DIR      : std_logic_vector(6 downto 0) := "0001000"; -- 0x08
  constant ADDR_INT_EN   : std_logic_vector(6 downto 0) := "0001100"; -- 0x0C
  constant ADDR_INT_TYP  : std_logic_vector(6 downto 0) := "0010000"; -- 0x10
  constant ADDR_INT_POL  : std_logic_vector(6 downto 0) := "0010100"; -- 0x14
  constant ADDR_INT_ANY  : std_logic_vector(6 downto 0) := "0011000"; -- 0x18
  constant ADDR_INT_STS  : std_logic_vector(6 downto 0) := "0011100"; -- 0x1C
  constant ADDR_SET_O    : std_logic_vector(6 downto 0) := "0100000"; -- 0x20
  constant ADDR_CLR_O    : std_logic_vector(6 downto 0) := "0100100"; -- 0x24
  constant ADDR_TGL_O    : std_logic_vector(6 downto 0) := "0101000"; -- 0x28
  constant ADDR_DEB_TH   : std_logic_vector(6 downto 0) := "0101100"; -- 0x2C
  constant ADDR_DEB_EN   : std_logic_vector(6 downto 0) := "0110000"; -- 0x30
  constant ADDR_INV_IN   : std_logic_vector(6 downto 0) := "0110100"; -- 0x34
  constant ADDR_INV_OUT  : std_logic_vector(6 downto 0) := "0111000"; -- 0x38
  constant ADDR_OD_EN    : std_logic_vector(6 downto 0) := "0111100"; -- 0x3C
  constant ADDR_WR_MASK  : std_logic_vector(6 downto 0) := "1000000"; -- 0x40
  constant ADDR_PU_EN    : std_logic_vector(6 downto 0) := "1000100"; -- 0x44
  constant ADDR_PD_EN    : std_logic_vector(6 downto 0) := "1001000"; -- 0x48
  constant ADDR_PWM_EN   : std_logic_vector(6 downto 0) := "1001100"; -- 0x4C
  constant ADDR_PWM_CFG  : std_logic_vector(6 downto 0) := "1010000"; -- 0x50
  constant ADDR_PWM_DUTY : std_logic_vector(6 downto 0) := "1010100"; -- 0x54

  -- Register State
  signal s_reg_data_o  : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_dir     : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_int_en  : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_int_typ : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_int_pol : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_int_any : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_int_sts : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_deb_th  : std_logic_vector(31 downto 0)           := (others => '0');
  signal s_reg_deb_en  : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_inv_in  : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_inv_out : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_od_en   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_wr_mask : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_pu_en   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_pd_en   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_pwm_en  : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal s_reg_pwm_cfg : std_logic_vector(31 downto 0)           := (others => '0');

  type duty_array is array (0 to NUM_BITS - 1) of std_logic_vector(15 downto 0);
  signal s_reg_pwm_duty : duty_array := (others => (others => '0'));

  signal pwm_cnt       : unsigned(15 downto 0) := (others => '0');
  signal pwm_prescaler : unsigned(15 downto 0) := (others => '0');
  signal pwm_val       : std_logic_vector(NUM_BITS - 1 downto 0);

  signal gpio_i_deb   : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal gpio_i_deb_q : std_logic_vector(NUM_BITS - 1 downto 0) := (others => '0');
  signal intr_cond    : std_logic_vector(NUM_BITS - 1 downto 0);

begin

  -- Parameter Validation
  assert NUM_BITS <= 32
  report "NUM_BITS must be <= 32. Current value is " & integer'image(NUM_BITS)
    severity failure;

  -- PWM Engine
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      pwm_cnt       <= (others => '0');
      pwm_prescaler <= (others => '0');
    elsif rising_edge(clk) then
      if pwm_prescaler >= unsigned(s_reg_pwm_cfg(15 downto 0)) then
        pwm_prescaler <= (others => '0');
        if pwm_cnt >= unsigned(s_reg_pwm_cfg(31 downto 16)) then
          pwm_cnt <= (others => '0');
        else
          pwm_cnt <= pwm_cnt + 1;
        end if;
      else
        pwm_prescaler <= pwm_prescaler + 1;
      end if;
    end if;
  end process;

  gen_pwm_val : for p in 0 to NUM_BITS - 1 generate
    pwm_val(p) <= '1' when pwm_cnt < unsigned(s_reg_pwm_duty(p)) else
    '0';
  end generate;

  -- Physical Interface
  reg_data_o   <= (s_reg_pwm_en and pwm_val) or (not s_reg_pwm_en and (s_reg_data_o xor s_reg_inv_out));
  reg_dir      <= s_reg_dir;
  open_drain   <= s_reg_od_en;
  pull_up_en   <= s_reg_pu_en;
  pull_down_en <= s_reg_pd_en;

  -- Debouncing Logic
  gen_deb : for i in 0 to NUM_BITS - 1 generate
    signal deb_cnt     : unsigned(31 downto 0) := (others => '0');
    signal gpio_i_sync : std_logic;
  begin
    gpio_i_sync <= gpio_i(i) xor s_reg_inv_in(i);
    process (clk, reset_n)
    begin
      if reset_n = '0' then
        deb_cnt       <= (others => '0');
        gpio_i_deb(i) <= '0';
      elsif rising_edge(clk) then
        if s_reg_deb_en(i) = '1' then
          if gpio_i_sync /= gpio_i_deb(i) then
            if deb_cnt >= unsigned(s_reg_deb_th) then
              gpio_i_deb(i) <= gpio_i_sync;
              deb_cnt       <= (others => '0');
            else
              deb_cnt <= deb_cnt + 1;
            end if;
          else
            deb_cnt <= (others => '0');
          end if;
        else
          gpio_i_deb(i) <= gpio_i_sync;
          deb_cnt       <= (others => '0');
        end if;
      end if;
    end process;
  end generate;

  -- Edge Detection
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      gpio_i_deb_q <= (others => '0');
    elsif rising_edge(clk) then
      gpio_i_deb_q <= gpio_i_deb;
    end if;
  end process;

  -- Interrupt Logic
  process (all)
    variable v_gpio_edge_pos : std_logic_vector(NUM_BITS - 1 downto 0);
    variable v_gpio_edge_neg : std_logic_vector(NUM_BITS - 1 downto 0);
    variable v_gpio_edge_any : std_logic_vector(NUM_BITS - 1 downto 0);
  begin
    v_gpio_edge_pos := gpio_i_deb and (not gpio_i_deb_q);
    v_gpio_edge_neg := (not gpio_i_deb) and gpio_i_deb_q;
    v_gpio_edge_any := v_gpio_edge_pos or v_gpio_edge_neg;

    for k in 0 to NUM_BITS - 1 loop
      if s_reg_int_typ(k) = '1' then -- Edge
        if s_reg_int_any(k) = '1' then
          intr_cond(k) <= v_gpio_edge_any(k);
        elsif s_reg_int_pol(k) = '1' then
          intr_cond(k) <= v_gpio_edge_pos(k);
        else
          intr_cond(k) <= v_gpio_edge_neg(k);
        end if;
      else -- Level
        if s_reg_int_pol(k) = '1' then
          intr_cond(k) <= gpio_i_deb(k);
        else
          intr_cond(k) <= not gpio_i_deb(k);
        end if;
      end if;
    end loop;
  end process;

  -- Register Writes
  process (clk, reset_n)
    variable duty_idx : integer;
  begin
    if reset_n = '0' then
      s_reg_data_o   <= (others => '0');
      s_reg_dir      <= (others => '0');
      s_reg_int_en   <= (others => '0');
      s_reg_int_typ  <= (others => '0');
      s_reg_int_pol  <= (others => '0');
      s_reg_int_any  <= (others => '0');
      s_reg_int_sts  <= (others => '0');
      s_reg_deb_th   <= (others => '0');
      s_reg_deb_en   <= (others => '0');
      s_reg_inv_in   <= (others => '0');
      s_reg_inv_out  <= (others => '0');
      s_reg_od_en    <= (others => '0');
      s_reg_wr_mask  <= (others => '0');
      s_reg_pu_en    <= (others => '0');
      s_reg_pd_en    <= (others => '0');
      s_reg_pwm_en   <= (others => '0');
      s_reg_pwm_cfg  <= (others => '0');
      s_reg_pwm_duty <= (others => (others => '0'));
    elsif rising_edge(clk) then
      for j in 0 to NUM_BITS - 1 loop
        if s_reg_int_en(j) = '1' and s_reg_int_typ(j) = '1' and intr_cond(j) = '1' then
          s_reg_int_sts(j) <= '1';
        end if;
      end loop;

      if we = '1' then
        case addr(6 downto 0) is
          when ADDR_DATA_O =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' and s_reg_wr_mask(k) = '0' then
                s_reg_data_o(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_DIR =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_dir(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INT_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_int_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INT_TYP =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_int_typ(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INT_POL =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_int_pol(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INT_ANY =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_int_any(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INT_STS =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_int_sts(k) <= s_reg_int_sts(k) and (not wdata(k));
              end if;
            end loop;
          when ADDR_SET_O =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_data_o(k) <= s_reg_data_o(k) or wdata(k);
              end if;
            end loop;
          when ADDR_CLR_O =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_data_o(k) <= s_reg_data_o(k) and (not wdata(k));
              end if;
            end loop;
          when ADDR_TGL_O =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_data_o(k) <= s_reg_data_o(k) xor wdata(k);
              end if;
            end loop;
          when ADDR_INV_IN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_inv_in(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_INV_OUT =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_inv_out(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_OD_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_od_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_WR_MASK =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_wr_mask(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_PU_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_pu_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_PD_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_pd_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_PWM_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_pwm_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_DEB_TH =>
            if be(0) = '1' then
              s_reg_deb_th(7 downto 0) <= wdata(7 downto 0);
            end if;
            if be(1) = '1' then
              s_reg_deb_th(15 downto 8) <= wdata(15 downto 8);
            end if;
            if be(2) = '1' then
              s_reg_deb_th(23 downto 16) <= wdata(23 downto 16);
            end if;
            if be(3) = '1' then
              s_reg_deb_th(31 downto 24) <= wdata(31 downto 24);
            end if;
          when ADDR_DEB_EN =>
            for k in 0 to NUM_BITS - 1 loop
              if be(k/8) = '1' then
                s_reg_deb_en(k) <= wdata(k);
              end if;
            end loop;
          when ADDR_PWM_CFG =>
            if be(0) = '1' then
              s_reg_pwm_cfg(7 downto 0) <= wdata(7 downto 0);
            end if;
            if be(1) = '1' then
              s_reg_pwm_cfg(15 downto 8) <= wdata(15 downto 8);
            end if;
            if be(2) = '1' then
              s_reg_pwm_cfg(23 downto 16) <= wdata(23 downto 16);
            end if;
            if be(3) = '1' then
              s_reg_pwm_cfg(31 downto 24) <= wdata(31 downto 24);
            end if;
          when others =>
            if addr(6 downto 0) >= ADDR_PWM_DUTY then
              duty_idx := (to_integer(unsigned(addr(6 downto 0))) - to_integer(unsigned(ADDR_PWM_DUTY))) / 4;
              if duty_idx < NUM_BITS then
                if be(0) = '1' then
                  s_reg_pwm_duty(duty_idx)(7 downto 0) <= wdata(7 downto 0);
                end if;
                if be(1) = '1' then
                  s_reg_pwm_duty(duty_idx)(15 downto 8) <= wdata(15 downto 8);
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Register Reads
  process (all)
    variable v_duty_idx : integer;
  begin
    rdata <= (others => '0');
    case addr(6 downto 0) is
      when ADDR_DATA_I  => rdata(NUM_BITS - 1 downto 0)  <= gpio_i_deb;
      when ADDR_DATA_O  => rdata(NUM_BITS - 1 downto 0)  <= s_reg_data_o;
      when ADDR_DIR     => rdata(NUM_BITS - 1 downto 0)     <= s_reg_dir;
      when ADDR_INT_EN  => rdata(NUM_BITS - 1 downto 0)  <= s_reg_int_en;
      when ADDR_INT_TYP => rdata(NUM_BITS - 1 downto 0) <= s_reg_int_typ;
      when ADDR_INT_POL => rdata(NUM_BITS - 1 downto 0) <= s_reg_int_pol;
      when ADDR_INT_ANY => rdata(NUM_BITS - 1 downto 0) <= s_reg_int_any;
      when ADDR_INT_STS =>
        for r in 0 to NUM_BITS - 1 loop
          if s_reg_int_typ(r) = '1' then
            rdata(r) <= s_reg_int_sts(r);
          else
            rdata(r) <= intr_cond(r);
          end if;
        end loop;
      when ADDR_DEB_TH  => rdata                         <= s_reg_deb_th;
      when ADDR_DEB_EN  => rdata(NUM_BITS - 1 downto 0)  <= s_reg_deb_en;
      when ADDR_INV_IN  => rdata(NUM_BITS - 1 downto 0)  <= s_reg_inv_in;
      when ADDR_INV_OUT => rdata(NUM_BITS - 1 downto 0) <= s_reg_inv_out;
      when ADDR_OD_EN   => rdata(NUM_BITS - 1 downto 0)   <= s_reg_od_en;
      when ADDR_WR_MASK => rdata(NUM_BITS - 1 downto 0) <= s_reg_wr_mask;
      when ADDR_PU_EN   => rdata(NUM_BITS - 1 downto 0)   <= s_reg_pu_en;
      when ADDR_PD_EN   => rdata(NUM_BITS - 1 downto 0)   <= s_reg_pd_en;
      when ADDR_PWM_EN  => rdata(NUM_BITS - 1 downto 0)  <= s_reg_pwm_en;
      when ADDR_PWM_CFG => rdata                        <= s_reg_pwm_cfg;
      when others       =>
        if addr(6 downto 0) >= ADDR_PWM_DUTY then
          v_duty_idx := (to_integer(unsigned(addr(6 downto 0))) - to_integer(unsigned(ADDR_PWM_DUTY))) / 4;
          if v_duty_idx < NUM_BITS then
            rdata(15 downto 0) <= s_reg_pwm_duty(v_duty_idx);
          end if;
        else
          rdata <= x"DEADBEEF";
        end if;
    end case;
  end process;

  -- Combined Interrupt Output
  process (all)
  begin
    intr <= '0';
    for m in 0 to NUM_BITS - 1 loop
      if s_reg_int_en(m) = '1' then
        if s_reg_int_typ(m) = '1' then
          if s_reg_int_sts(m) = '1' then
            intr <= '1';
          end if;
        else
          if intr_cond(m) = '1' then
            intr <= '1';
          end if;
        end if;
      end if;
    end loop;
  end process;

  -- Simple Acknowledgement (1 cycle)
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      ack <= '0';
    elsif rising_edge(clk) then
      ack <= we or re;
    end if;
  end process;

end architecture rtl;
