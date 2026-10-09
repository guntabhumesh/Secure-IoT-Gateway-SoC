/*
 * File: ahb_if.sv
 * Description: AHB5-Lite Interface
 */

interface ahb_if (input logic hclk, input logic hresetn);

    // Address Phase
    logic [31:0] haddr;
    logic [1:0]  htrans;
    logic        hwrite;
    logic [2:0]  hsize;
    logic [2:0]  hburst;
    logic [3:0]  hprot;
    logic        hsel;
    
    // Data Phase/Response
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready; // HREADYOUT from slave
    logic [1:0]  hresp;

    clocking cb @(posedge hclk);
        default input #1ns output #1ns;
        output haddr, htrans, hwrite, hsize, hburst, hprot, hsel, hwdata;
        input  hrdata, hready, hresp;
    endclocking

    clocking monitor_cb @(posedge hclk);
        default input #1ns output #1ns;
        input haddr, htrans, hwrite, hsize, hburst, hprot, hsel, hwdata;
        input hrdata, hready, hresp;
    endclocking
    clocking slave_cb @(posedge hclk);
        default input #1ns output #1ns;
        input  haddr, htrans, hwrite, hsize, hburst, hprot, hsel, hwdata;
        output hrdata, hready, hresp;
    endclocking

endinterface
