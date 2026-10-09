--
-- General Purpose Timer AXI4-Lite Wrapper (VHDL-2008)
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_axi is
  port (
    aclk    : in std_logic;
    aresetn : in std_logic;

    -- Write Address Output
    awaddr  : in std_logic_vector(31 downto 0) := (others => '0');
    awprot  : in std_logic_vector(2 downto 0)  := (others => '0');
    awvalid : in std_logic                     := '0';
    awready : out std_logic;

    -- Write Data
    wdata  : in std_logic_vector(31 downto 0) := (others => '0');
    wstrb  : in std_logic_vector(3 downto 0)  := (others => '0');
    wvalid : in std_logic                     := '0';
    wready : out std_logic;

    -- Write Response
    bresp  : out std_logic_vector(1 downto 0);
    bvalid : out std_logic;
    bready : in std_logic := '0';

    -- Read Address
    araddr  : in std_logic_vector(31 downto 0) := (others => '0');
    arprot  : in std_logic_vector(2 downto 0)  := (others => '0');
    arvalid : in std_logic                     := '0';
    arready : out std_logic;

    -- Read Data
    rdata  : out std_logic_vector(31 downto 0);
    rresp  : out std_logic_vector(1 downto 0);
    rvalid : out std_logic;
    rready : in std_logic := '0';

    -- External IO
    ext_meas_i : in std_logic := '0';
    capture_i  : in std_logic := '0';
    pwm_o      : out std_logic;
    trigger_o  : out std_logic;

    -- Interrupt
    irq : out std_logic
  );
end entity timer_axi;

architecture rtl of timer_axi is
  component timer_regs is
    port (
      clk   : in std_logic;
      rst_n : in std_logic;
      cs    : in std_logic;
      we    : in std_logic;
      addr  : in std_logic_vector(5 downto 0);
      wdata : in std_logic_vector(31 downto 0);
      rdata : out std_logic_vector(31 downto 0);

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

      current_val : in std_logic_vector(31 downto 0);
      capture_val : in std_logic_vector(31 downto 0);
      capture_stb : in std_logic;
      core_irq    : in std_logic;
      intr_o      : out std_logic
    );
  end component timer_regs;

  component timer_core is
    port (
      clk      : in std_logic;
      rst_n    : in std_logic;
      en       : in std_logic;
      mode     : in std_logic;
      dir      : in std_logic;
      pwm_en   : in std_logic;
      ext_en   : in std_logic;
      pre_en   : in std_logic;
      pre_val  : in std_logic_vector(15 downto 0);
      load_val : in std_logic_vector(31 downto 0);
      cmp_val  : in std_logic_vector(31 downto 0);
      load_cmd : in std_logic;

      ext_meas_i : in std_logic;
      capture_i  : in std_logic;

      current_val : out std_logic_vector(31 downto 0);
      capture_val : out std_logic_vector(31 downto 0);
      capture_stb : out std_logic;
      pwm_o       : out std_logic;
      trigger_o   : out std_logic;
      irq         : out std_logic
    );
  end component timer_core;

  -- Internal signals
  signal cs, we    : std_logic                     := '0';
  signal addr      : std_logic_vector(5 downto 0)  := (others => '0');
  signal reg_rdata : std_logic_vector(31 downto 0) := (others => '0');

  signal en, mode, dir, pwm_en, ext_en, cap_en, pre_en, load_cmd : std_logic                     := '0';
  signal core_irq_pulse, capture_stb, core_intr                  : std_logic                     := '0';
  signal pre_val                                                 : std_logic_vector(15 downto 0) := (others => '0');
  signal load_val, cmp_val, current_val, capture_val             : std_logic_vector(31 downto 0) := (others => '0');

  -- Adapter signals
  signal reg_addr       : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_wdata      : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_rdata_wire : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_we         : std_logic                     := '0';
  signal reg_re         : std_logic                     := '0';
  signal reg_be         : std_logic_vector(3 downto 0)  := (others => '0');

begin

  -- AXI4-Lite Slave Adapter
  u_axi_adapter : entity work.axi4lite_slave_adapter
    generic map(
      ADDR_WIDTH => 32,
      DATA_WIDTH => 32
    )
    port map
    (
      aclk          => aclk,
      aresetn       => aresetn,
      s_axi_awaddr  => awaddr,
      s_axi_awprot  => awprot,
      s_axi_awvalid => awvalid,
      s_axi_awready => awready,
      s_axi_wdata   => wdata,
      s_axi_wstrb   => wstrb,
      s_axi_wvalid  => wvalid,
      s_axi_wready  => wready,
      s_axi_bresp   => bresp,
      s_axi_bvalid  => bvalid,
      s_axi_bready  => bready,
      s_axi_araddr  => araddr,
      s_axi_arprot  => arprot,
      s_axi_arvalid => arvalid,
      s_axi_arready => arready,
      s_axi_rdata   => rdata,
      s_axi_rresp   => rresp,
      s_axi_rvalid  => rvalid,
      s_axi_rready  => rready,
      reg_addr      => reg_addr,
      reg_wdata     => reg_wdata,
      reg_rdata     => reg_rdata_wire,
      reg_we        => reg_we,
      reg_re        => reg_re,
      reg_be        => reg_be
    );

  -- Internal Mapping
  cs             <= reg_we or reg_re;
  we             <= reg_we;
  addr           <= reg_addr(5 downto 0);
  reg_rdata_wire <= reg_rdata;

  -- Register instantiation
  u_timer_regs : timer_regs
  port map
  (
    clk => aclk, rst_n => aresetn,
    cs => cs, we => we, addr => addr,
    wdata => reg_wdata, rdata => reg_rdata,

    en => en, mode => mode, dir => dir,
    pwm_en => pwm_en, ext_en => ext_en, cap_en => cap_en,
    pre_en => pre_en, pre_val => pre_val,
    load_val => load_val, cmp_val => cmp_val,
    load_cmd => load_cmd,

    current_val => current_val, capture_val => capture_val,
    capture_stb => capture_stb, core_irq => core_irq_pulse,
    intr_o => core_intr
  );

  -- Core instantiation
  u_timer_core : timer_core
  port map
  (
    clk => aclk, rst_n => aresetn,
    en => en, mode => mode, dir => dir,
    pwm_en => pwm_en, ext_en => ext_en,
    pre_en => pre_en, pre_val => pre_val,
    load_val => load_val, cmp_val => cmp_val,
    load_cmd => load_cmd,

    ext_meas_i => ext_meas_i, capture_i => capture_i,

    current_val => current_val, capture_val => capture_val,
    capture_stb => capture_stb,
    pwm_o => pwm_o, trigger_o => trigger_o,
    irq         => core_irq_pulse
  );

  irq <= core_intr;

end architecture rtl;
