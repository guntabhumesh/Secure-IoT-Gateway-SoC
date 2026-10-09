/*
 * File: timer_coverage.sv
 * Description: Functional coverage for General Timer IP
 */


class timer_coverage extends uvm_component;
    `uvm_component_utils(timer_coverage)

    uvm_analysis_imp_apb #(apb_seq_item, timer_coverage) apb_export;
    uvm_analysis_imp_axi #(axi_seq_item, timer_coverage) axi_export;
    uvm_analysis_imp_wb  #(wb_seq_item,  timer_coverage) wb_export;
    uvm_analysis_imp_timer #(timer_seq_item, timer_coverage) timer_export;

    // Internal State
    logic [31:0] reg_ctrl;
    logic [31:0] reg_load;
    logic [31:0] reg_pre;
    logic [31:0] reg_int_en;
    logic [31:0] reg_cmp;

    covergroup timer_cg;
        // --- Configuration Coverpoints ---
        // Timer Enable bit
        cp_en: coverpoint reg_ctrl[0] {
            bins disabled = {0};
            bins enabled  = {1};
        }

        // Timer Mode (One-Shot/Continuous)
        cp_mode: coverpoint reg_ctrl[1] {
            bins one_shot   = {0};
            bins continuous = {1};
        }

        // Prescaler Enable
        cp_pre_en: coverpoint reg_ctrl[2] {
            bins bypassed = {0};
            bins enabled  = {1};
        }

        // Count Direction
        cp_dir: coverpoint reg_ctrl[3] {
            bins down = {0};
            bins up   = {1};
        }

        // PWM Enable
        cp_pwm_en: coverpoint reg_ctrl[4] {
            bins disabled = {0};
            bins enabled  = {1};
        }

        // Capture Enable
        cp_cap_en: coverpoint reg_ctrl[6] {
            bins disabled = {0};
            bins enabled  = {1};
        }

        // --- Event Coverpoints (from last sampled timer_seq_item) ---
        cp_irq: coverpoint t_item.irq {
            bins no_irq = {0};
            bins irq_occurred = {1};
        }

        cp_pwm: coverpoint t_item.pwm_o {
            bins low  = {0};
            bins high = {1};
        }

        cp_capture: coverpoint t_item.capture_i {
            bins no_capture = {0};
            bins captured   = {1};
        }

        // --- Crosses ---
        // Configuration crosses
        cross_cfg: cross cp_mode, cp_pre_en, cp_dir, cp_pwm_en;

        // event crosses
        cross_irq_mode: cross cp_irq, cp_mode {
            ignore_bins no_event = binsof(cp_irq) intersect {0};
        }
        
        cross_pwm_cfg: cross cp_pwm, cp_pwm_en {
             ignore_bins disabled = binsof(cp_pwm_en) intersect {0};
             ignore_bins no_pwm   = binsof(cp_pwm) intersect {0};
        }

        cross_cap_cfg: cross cp_capture, cp_cap_en {
             ignore_bins disabled = binsof(cp_cap_en) intersect {0};
             ignore_bins no_cap   = binsof(cp_capture) intersect {0};
        }
    endgroup

    // Item for event coverage sampling
    timer_seq_item t_item;

    function new(string name = "timer_coverage", uvm_component parent = null);
        super.new(name, parent);
        apb_export   = new("apb_export", this);
        axi_export   = new("axi_export", this);
        wb_export    = new("wb_export", this);
        timer_export = new("timer_export", this);
        
        timer_cg = new();
        t_item   = timer_seq_item::type_id::create("t_item");
        
        reg_ctrl   = 0;
        reg_load   = 0;
        reg_pre    = 0;
        reg_int_en = 0;
        reg_cmp    = 0;
    endfunction

    // APB Implementation
    function void write_apb(apb_seq_item item);
        if (item.write) update_regs(item.addr[5:0], item.data, item.strb);
    endfunction

    // AXI Implementation
    function void write_axi(axi_seq_item item);
        if (item.write) update_regs(item.addr[5:0], item.data, item.strb);
    endfunction

    // WB Implementation
    function void write_wb(wb_seq_item item);
        if (item.we && item.ack) update_regs(item.addr[5:0], item.data, item.sel);
    endfunction

    // Common Register Update
    function void update_regs(logic [5:0] addr, logic [31:0] data, logic [3:0] strb);
        logic [31:0] current_val;
        case (addr)
            6'h00: current_val = reg_ctrl;
            6'h04: current_val = reg_load;
            6'h0C: current_val = reg_pre;
            6'h10: current_val = reg_int_en;
            6'h18: current_val = reg_cmp;
            default: return;
        endcase

        if (strb[0]) current_val[7:0]   = data[7:0];
        if (strb[1]) current_val[15:8]  = data[15:8];
        if (strb[2]) current_val[23:16] = data[23:16];
        if (strb[3]) current_val[31:24] = data[31:24];

        case (addr)
            6'h00: reg_ctrl   = current_val;
            6'h04: reg_load   = current_val;
            6'h0C: reg_pre    = current_val;
            6'h10: reg_int_en = current_val;
            6'h18: reg_cmp    = current_val;
        endcase
        
        timer_cg.sample();
    endfunction

    // Timer Implementation
    function void write_timer(timer_seq_item t);
        t_item.copy(t);
        timer_cg.sample();
    endfunction

endclass
