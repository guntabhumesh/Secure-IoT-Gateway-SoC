/*
 * File: gpio_scoreboard.sv
 * Description: GPIO Scoreboard
 */

class gpio_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(gpio_scoreboard)

    uvm_analysis_imp_apb #(apb_seq_item, gpio_scoreboard) apb_export;
    uvm_analysis_imp_axi #(axi_seq_item, gpio_scoreboard) axi_export;
    uvm_analysis_imp_wb  #(wb_seq_item, gpio_scoreboard)  wb_export;
    uvm_analysis_imp_gpio #(gpio_seq_item, gpio_scoreboard) gpio_export;

    // Registers
    logic [31:0] reg_data_o;
    logic [31:0] reg_dir;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        apb_export  = new("apb_export", this);
        axi_export  = new("axi_export", this);
        wb_export   = new("wb_export", this);
        gpio_export = new("gpio_export", this);
        reg_data_o = 0;
        reg_dir = 0;
    endfunction

    // APB Write Implementation
    function void write_apb(apb_seq_item item);
        if (item.write) update_regs(item.addr, item.data, item.strb);
    endfunction

    // AXI Write Implementation
    function void write_axi(axi_seq_item item);
        if (item.write) update_regs(item.addr, item.data, item.strb);
    endfunction

    // WB Write Implementation
    function void write_wb(wb_seq_item item);
        if (item.we) update_regs(item.addr, item.data, item.sel);
    endfunction

    // Common Register Update
    function void update_regs(logic [31:0] addr, logic [31:0] data, logic [3:0] strb);
        logic [31:0] current_val;
        
        // Get current value to apply partial updates
        case (addr)
            32'h04: current_val = reg_data_o;
            32'h08: current_val = reg_dir;
            default: current_val = 0;
        endcase

        // Apply byte enables
        if (strb[0]) current_val[7:0]   = data[7:0];
        if (strb[1]) current_val[15:8]  = data[15:8];
        if (strb[2]) current_val[23:16] = data[23:16];
        if (strb[3]) current_val[31:24] = data[31:24];

        // Write back
        case (addr)
            32'h04: reg_data_o = current_val; // DATA_O
            32'h08: reg_dir    = current_val; // DIR
        endcase
    endfunction

    // GPIO Monitor Implementation
    function void write_gpio(gpio_seq_item item);
        `uvm_info("SCB", $sformatf("GPIO Change detected: Pins=%h OEN=%h", item.opins, item.oen), UVM_LOW);
        
        // Simple check: driven output pins should match DATA_O where DIR is 1
        if (item.opins !== (reg_data_o & reg_dir)) begin
             if (item.oen !== reg_dir) begin
                 `uvm_error("SCB", $sformatf("DIR Mismatch! Exp: %h, Act: %h", reg_dir, item.oen));
             end
        end
    endfunction

endclass
