/*
 * File: timer_sequences.sv
 * Description: UVM Sequences for General Timer IP
 */

// Base sequence for Timer IO
class timer_io_seq extends uvm_sequence #(timer_seq_item);
    `uvm_object_utils(timer_io_seq)
    function new(string name = "timer_io_seq"); super.new(name); endfunction

    task body();
        req = timer_seq_item::type_id::create("req");
        start_item(req);
        req.ext_meas_i = 0;
        req.capture_i = 0;
        finish_item(req);
    endtask
endclass

// Base Register Sequence with common tasks
class timer_reg_base_seq #(type T = uvm_sequence_item) extends uvm_sequence #(T);
    function new(string name = "timer_reg_base_seq"); super.new(name); endfunction
    
    // Default body to avoid warnings
    virtual task body();
        `uvm_info("SEQ", "Base register sequence body running", UVM_HIGH)
    endtask
endclass

// Sequence for AXI register access
class timer_axi_reg_seq extends timer_reg_base_seq #(axi_seq_item);
    `uvm_object_utils(timer_axi_reg_seq)
    function new(string name = "timer_axi_reg_seq"); super.new(name); endfunction

    task write_reg(logic [31:0] addr, logic [31:0] data);
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.write = 1;
        req.strb = 4'hf;
        finish_item(req);
    endtask

    task read_reg(logic [31:0] addr);
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.write = 0;
        finish_item(req);
    endtask
endclass

// Sequence for APB register access
class timer_apb_reg_seq extends timer_reg_base_seq #(apb_seq_item);
    `uvm_object_utils(timer_apb_reg_seq)
    function new(string name = "timer_apb_reg_seq"); super.new(name); endfunction

    task write_reg(logic [31:0] addr, logic [31:0] data);
        req = apb_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.write = 1;
        finish_item(req);
    endtask

    task read_reg(logic [31:0] addr);
        req = apb_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.write = 0;
        finish_item(req);
    endtask
endclass

// Sequence for WB register access
class timer_wb_reg_seq extends timer_reg_base_seq #(wb_seq_item);
    `uvm_object_utils(timer_wb_reg_seq)
    function new(string name = "timer_wb_reg_seq"); super.new(name); endfunction

    task write_reg(logic [31:0] addr, logic [31:0] data);
        req = wb_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.we = 1;
        req.sel = 4'hf;
        finish_item(req);
    endtask

    task read_reg(logic [31:0] addr);
        req = wb_seq_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.we = 0;
        finish_item(req);
    endtask
endclass
// Sequence for PWM verification
class timer_pwm_seq extends timer_axi_reg_seq;
    `uvm_object_utils(timer_pwm_seq)
    function new(string name = "timer_pwm_seq"); super.new(name); endfunction

    task body();
        `uvm_info("SEQ", "Running PWM sequence", UVM_LOW)
        write_reg(32'h04, 32'h0000_0100); // LOAD = 256
        write_reg(32'h18, 32'h0000_0080); // CMP = 128 (50% duty)
        write_reg(32'h00, 32'h0000_0011); // EN=1, PWM_EN=1
        #5000;
        write_reg(32'h18, 32'h0000_0040); // CMP = 64 (25% duty)
        #5000;
    endtask
endclass

// Sequence for Capture stress
class timer_capture_trigger_seq extends timer_io_seq;
    `uvm_object_utils(timer_capture_trigger_seq)
    function new(string name = "timer_capture_trigger_seq"); super.new(name); endfunction

    task body();
        repeat(10) begin
            req = timer_seq_item::type_id::create("req");
            start_item(req);
            req.capture_i = 1;
            finish_item(req);
            #20;
            start_item(req);
            req.capture_i = 0;
            finish_item(req);
            #100;
        end
    endtask
endclass

// Sequence for Prescaler sweep
class timer_prescaler_seq extends timer_axi_reg_seq;
    `uvm_object_utils(timer_prescaler_seq)
    function new(string name = "timer_prescaler_seq"); super.new(name); endfunction

    task body();
        foreach (val[i]) begin
            write_reg(32'h0C, val[i]); // PRE
            write_reg(32'h00, 32'h0000_0005); // EN=1, PRE_EN=1
            #1000;
        end
    endtask
    
    logic [31:0] val[] = '{32'h0, 32'h1, 32'hF, 32'hFF};
endclass
