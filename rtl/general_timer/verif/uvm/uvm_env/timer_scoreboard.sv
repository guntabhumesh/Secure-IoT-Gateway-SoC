/*
 * File: timer_scoreboard.sv
 * Description: Scoreboard for General Timer IP
 */


class timer_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(timer_scoreboard)

    uvm_analysis_imp_apb #(apb_seq_item, timer_scoreboard) apb_export;
    uvm_analysis_imp_axi #(axi_seq_item, timer_scoreboard) axi_export;
    uvm_analysis_imp_wb  #(wb_seq_item,  timer_scoreboard) wb_export;
    uvm_analysis_imp_timer #(timer_seq_item, timer_scoreboard) timer_export;

    // Predicted Registers
    logic [31:0] reg_ctrl;
    logic [31:0] reg_load;
    logic [31:0] reg_pre;
    logic [31:0] reg_int_en;
    logic [31:0] reg_int_sts;
    logic [31:0] reg_cmp;

    function new(string name = "timer_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        apb_export  = new("apb_export", this);
        axi_export  = new("axi_export", this);
        wb_export   = new("wb_export", this);
        timer_export = new("timer_export", this);
        
        reg_ctrl    = 0;
        reg_load    = 0;
        reg_pre     = 0;
        reg_int_en  = 0;
        reg_int_sts = 0;
        reg_cmp     = 0;
    endfunction

    // APB Implementation
    function void write_apb(apb_seq_item item);
        if (item.write) begin
            update_regs(item.addr[5:0], item.data, item.strb);
        end
    endfunction

    // AXI Implementation
    function void write_axi(axi_seq_item item);
        if (item.write) begin
            update_regs(item.addr[5:0], item.data, item.strb);
        end
    endfunction

    // WB Implementation
    function void write_wb(wb_seq_item item);
        if (item.we && item.ack) begin
            update_regs(item.addr[5:0], item.data, item.sel);
        end
    endfunction

    // Common Register Update
    function void update_regs(logic [5:0] addr, logic [31:0] data, logic [3:0] strb);
        logic [31:0] current_val;
        
        case (addr)
            6'h00: current_val = reg_ctrl;
            6'h04: current_val = reg_load;
            6'h0C: current_val = reg_pre;
            6'h10: current_val = reg_int_en;
            6'h14: current_val = reg_int_sts;
            6'h18: current_val = reg_cmp;
            default: return; 
        endcase

        if (strb[0]) current_val[7:0]   = data[7:0];
        if (strb[1]) current_val[15:8]  = data[15:8];
        if (strb[2]) current_val[23:16] = data[23:16];
        if (strb[3]) current_val[31:24] = data[31:24];

        case (addr)
            6'h00: reg_ctrl    = current_val;
            6'h04: reg_load    = current_val;
            6'h0C: reg_pre     = current_val;
            6'h10: reg_int_en  = current_val;
            6'h14: reg_int_sts &= ~data;
            6'h18: reg_cmp     = current_val;
        endcase
        
        `uvm_info("SCB_REG", $sformatf("Register Write: Addr=%h, Data=%h, Final=%h", addr, data, current_val), UVM_HIGH)
    endfunction

    // Timer Interface Monitoring
    function void write_timer(timer_seq_item item);
        logic expected_irq = |(reg_int_sts & reg_int_en);
        if (item.irq !== expected_irq) begin
            `uvm_error("SCB_IRQ", $sformatf("IRQ Mismatch! Exp: %0b, Act: %0b (STS=%h, EN=%h)", 
                       expected_irq, item.irq, reg_int_sts, reg_int_en))
        end
    endfunction

endclass
