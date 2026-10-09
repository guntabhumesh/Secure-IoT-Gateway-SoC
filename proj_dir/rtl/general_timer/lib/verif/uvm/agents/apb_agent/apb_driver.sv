/*
 * File: apb_driver.sv
 * Description: APB Driver
 */

class apb_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    task run_phase(uvm_phase phase);
        // Reset inputs
        vif.cb.psel    <= 0;
        vif.cb.penable <= 0;
        vif.cb.pwrite  <= 0;
        vif.cb.pstrb   <= 0;
        vif.cb.pprot   <= 0;
        vif.cb.paddr   <= 0;
        vif.cb.pwdata  <= 0;

        wait(vif.presetn == 1);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_seq_item item);
        // Setup Phase
        @ (vif.cb);
        vif.cb.paddr   <= item.addr;
        vif.cb.pwrite  <= item.write;
        vif.cb.psel    <= 1;
        vif.cb.penable <= 0;
        if (item.write) begin
            vif.cb.pwdata <= item.data;
            vif.cb.pstrb  <= item.strb;
        end else begin
            vif.cb.pstrb  <= 0; // Read ignores write strobe usually, but good to be clean
        end
        vif.cb.pprot   <= item.prot;

        // Access Phase
        @ (vif.cb);
        vif.cb.penable <= 1;

        // Wait for Ready
        do begin
            @ (vif.cb);
        end while (vif.cb.pready !== 1'b1);

        if (!item.write) begin
            item.rdata = vif.cb.prdata;
        end
        item.slverr = vif.cb.pslverr;

        // End of Transfer
        vif.cb.psel    <= 0;
        vif.cb.penable <= 0;
    endtask

endclass
