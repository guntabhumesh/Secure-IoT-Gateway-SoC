//-------------------------------------------------------------------------------
// File: timer_binds.sv
// Description: Bind file for formal verification of General Timer IP
//-------------------------------------------------------------------------------

module timer_binds;

    // Bind properties to timer_core
    bind timer_core timer_core_props props_core (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .mode(mode),
        .dir(dir),
        .pre_en(pre_en),
        .pre_val(pre_val),
        .load_val(load_val),
        .load_cmd(load_cmd),
        .counter(counter),
        .tick(tick),
        .irq(irq),
        .trigger_o(trigger_o),
        .capture_re(capture_re),
        .capture_stb(capture_stb),
        .capture_val(capture_val),
        .pwm_en(pwm_en),
        .cmp_val(cmp_val),
        .pwm_o(pwm_o)
    );

    // Bind properties to timer_regs
    bind timer_regs timer_regs_props props_regs (
        .clk(clk),
        .rst_n(rst_n),
        .cs(cs),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .reg_ctrl(reg_ctrl),
        .reg_load(reg_load),
        .current_val(current_val)
    );

    // Note: Bus interface props will be bound in specific SBY tasks 
    // to match individual top levels (timer_axi, timer_apb, timer_wb)

endmodule
