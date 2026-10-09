/*
 * File: gpio_if.sv
 * Description: GPIO SystemVerilog Interface
 */
interface gpio_if #(parameter NUM_BITS = 32) (input logic clk, input logic rst_n);
    logic [NUM_BITS-1:0] ipins;
    logic [NUM_BITS-1:0] opins;
    logic [NUM_BITS-1:0] oen;
    logic                intr;

    clocking cb @(posedge clk);
        output ipins;
        input  opins, oen, intr;
    endclocking
    
    modport master (clocking cb, input clk, rst_n);
    modport monitor (input clk, rst_n, ipins, opins, oen, intr);

endinterface
