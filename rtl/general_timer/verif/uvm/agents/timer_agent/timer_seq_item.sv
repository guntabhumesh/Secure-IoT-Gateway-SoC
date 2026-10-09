/*
 * File: timer_seq_item.sv
 * Description: UVM Sequence Item for Timer specific IO
 */
class timer_seq_item extends uvm_sequence_item;
    `uvm_object_utils(timer_seq_item)

    rand logic ext_meas_i;
    rand logic capture_i;
    logic        pwm_o;
    logic        trigger_o;
    logic        irq;

    function new(string name = "timer_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("ext_meas_i=%0b, capture_i=%0b, pwm_o=%0b, trigger_o=%0b, irq=%0b",
                         ext_meas_i, capture_i, pwm_o, trigger_o, irq);
    endfunction

endclass
