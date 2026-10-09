/*
 * File: timer_if.sv
 * Description: SystemVerilog Interface for General Timer specific IO
 */
interface timer_if (input logic clk, input logic rst_n);
    logic        ext_meas_i;
    logic        capture_i;
    logic        pwm_o;
    logic        trigger_o;
    logic        irq;

    // Clocking block for synchronous signals
    clocking cb @(posedge clk);
        output ext_meas_i, capture_i;
        input  pwm_o, trigger_o, irq;
    endclocking

    modport master (clocking cb, input clk, rst_n);
    modport monitor (input clk, rst_n, ext_meas_i, capture_i, pwm_o, trigger_o, irq);

endinterface
