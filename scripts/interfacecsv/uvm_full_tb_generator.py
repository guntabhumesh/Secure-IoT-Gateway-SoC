#!/usr/bin/env python3
"""
UVM Testbench Generator
Usage:
  python3 uvm_full_tb_generator.py <vip_name> <signals.csv>

CSV format (no header required):
signal_name,direction,width
"""

import csv
import os
import sys

if len(sys.argv) != 3:
    print('Usage: python3 uvm_full_tb_generator.py <vip_name> <signals.csv>')
    sys.exit(1)

VIP = sys.argv[1].lower()
CSV_FILE = sys.argv[2]

CLK_NAMES = ['clk', 'clock']
RST_NAMES = ['rst', 'rst_n', 'reset', 'reset_n']


def read_signals(csv_file):
    sigs = []
    with open(csv_file) as f:
        for row in csv.reader(f):
            if len(row) < 3:
                continue
            if not row[2].strip().isdigit():
                continue
            sigs.append({
                'name': row[0].strip(),
                'dir': row[1].strip().lower(),
                'width': int(row[2].strip())
            })
    return sigs


def sv_type(width):
    return 'bit' if width == 1 else f'bit [{width-1}:0]'


def interface_type(width):
    return 'logic' if width == 1 else f'logic [{width-1}:0]'


def transaction(signals):
    s = f'class {VIP}_item extends uvm_sequence_item;\n\n'
    for sig in signals:
        if sig['name'] not in CLK_NAMES + RST_NAMES:
            rand = 'rand ' if sig['dir'] == 'input' else ''
            s += f'  {rand}{sv_type(sig["width"])} {sig["name"]};\n'
    s += f"\n  `uvm_object_utils_begin({VIP}_item)\n"
    for sig in signals:
        if sig['name'] not in CLK_NAMES + RST_NAMES:
            s += f'    `uvm_field_int({sig["name"]}, UVM_ALL_ON)\n'
    s += "  `uvm_object_utils_end\n\n"
    s += f'  function new(string name="{VIP}_item");\n    super.new(name);\n  endfunction\n'
    s += 'endclass\n'
    return s


def sequencer():
    return f'''class {VIP}_sequencer extends uvm_sequencer #({VIP}_item);
  `uvm_component_utils({VIP}_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
'''


def driver(signals):
    drive_stmts = []
    for s in signals:
        if s['dir'] == 'input' and s['name'] not in CLK_NAMES + RST_NAMES:
            drive_stmts.append(f'      vif.{s["name"]} <= req.{s["name"]};')
    drive_body = '\n'.join(drive_stmts) if drive_stmts else '      // No input signals to drive'

    return f'''class {VIP}_driver extends uvm_driver #({VIP}_item);
  virtual {VIP}_if vif;
  `uvm_component_utils({VIP}_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {VIP}_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{{%s}}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
{drive_body}
      seq_item_port.item_done();
    end
  endtask
endclass
'''


def monitor(signals):
    sample_stmts = []
    for s in signals:
        if s['name'] not in CLK_NAMES + RST_NAMES:
            sample_stmts.append(f'      item.{s["name"]} = vif.{s["name"]};')
    sample_body = '\n'.join(sample_stmts) if sample_stmts else '      // No signals to sample'

    return f'''class {VIP}_monitor extends uvm_monitor;
  virtual {VIP}_if vif;
  uvm_analysis_port #({VIP}_item) ap;
  `uvm_component_utils({VIP}_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {VIP}_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{{%s}}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    {VIP}_item item;
    forever begin
      @(posedge vif.clk);
      item = {VIP}_item::type_id::create("item");
{sample_body}
      ap.write(item);
    end
  endtask
endclass
'''


def agent():
    return f'''class {VIP}_agent extends uvm_agent;
  {VIP}_driver drv;
  {VIP}_monitor mon;
  {VIP}_sequencer seqr;

  `uvm_component_utils({VIP}_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = {VIP}_driver::type_id::create("drv", this);
    mon  = {VIP}_monitor::type_id::create("mon", this);
    seqr = {VIP}_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
'''


def scoreboard():
    return f'''class {VIP}_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #({VIP}_item, {VIP}_scoreboard) ap_imp;

  `uvm_component_utils({VIP}_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_imp = new("ap_imp", this);
  endfunction

  virtual function void write({VIP}_item item);
    `uvm_info(get_type_name(), $sformatf("Observed transaction: %s", item.sprint()), UVM_HIGH)
  endfunction
endclass
'''


def env():
    return f'''class {VIP}_env extends uvm_env;
  {VIP}_agent agent;
  {VIP}_scoreboard sb;

  `uvm_component_utils({VIP}_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = {VIP}_agent::type_id::create("agent", this);
    sb    = {VIP}_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.ap_imp);
  endfunction
endclass
'''


def base_sequence():
    return f'''class {VIP}_base_sequence extends uvm_sequence #({VIP}_item);
  `uvm_object_utils({VIP}_base_sequence)

  function new(string name="{VIP}_base_sequence");
    super.new(name);
  endfunction

  task body();
    {VIP}_item item;
    repeat (10) begin
      item = {VIP}_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask
endclass
'''


def test():
    return f'''class {VIP}_test extends uvm_test;
  {VIP}_env env;

  `uvm_component_utils({VIP}_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = {VIP}_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    {VIP}_base_sequence seq;
    phase.raise_objection(this);
    seq = {VIP}_base_sequence::type_id::create("seq");
    seq.start(env.agent.seqr);
    #100;
    phase.drop_objection(this);
  endtask
endclass
'''


def interface(signals):
    s = f'interface {VIP}_if (input logic clk, input logic rst_n);\n'
    for sig in signals:
        if sig['name'] in CLK_NAMES + RST_NAMES:
            continue
        s += f'  {interface_type(sig["width"])} {sig["name"]};\n'
    s += 'endinterface\n'
    return s


def package():
    return f'''package {VIP}_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "{VIP}_item.sv"
  `include "{VIP}_base_sequence.sv"
  `include "{VIP}_sequencer.sv"
  `include "{VIP}_driver.sv"
  `include "{VIP}_monitor.sv"
  `include "{VIP}_agent.sv"
  `include "{VIP}_scoreboard.sv"
  `include "{VIP}_env.sv"
  `include "{VIP}_test.sv"
endpackage
'''


def tb_top():
    return f'''module tb_top;
  import uvm_pkg::*;
  import {VIP}_pkg::*;

  logic clk;
  logic rst_n;

  // Clock Generation (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset Generation
  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // Interface instantiation
  {VIP}_if vif(clk, rst_n);

  initial begin
    uvm_config_db#(virtual {VIP}_if)::set(null, "*", "vif", vif);
    run_test("{VIP}_test");
  end
endmodule
'''


signals = read_signals(CSV_FILE)
outdir = f'{VIP}_uvm_tb'
os.makedirs(outdir, exist_ok=True)
files = {
    f'{VIP}_if.sv': interface(signals),
    f'{VIP}_item.sv': transaction(signals),
    f'{VIP}_base_sequence.sv': base_sequence(),
    f'{VIP}_sequencer.sv': sequencer(),
    f'{VIP}_driver.sv': driver(signals),
    f'{VIP}_monitor.sv': monitor(signals),
    f'{VIP}_agent.sv': agent(),
    f'{VIP}_scoreboard.sv': scoreboard(),
    f'{VIP}_env.sv': env(),
    f'{VIP}_test.sv': test(),
    f'{VIP}_pkg.sv': package(),
    'tb_top.sv': tb_top()
}

for n, c in files.items():
    with open(os.path.join(outdir, n), 'w') as f:
        f.write(c)
print('Generated complete UVM TB in:', outdir)
