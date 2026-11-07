class gpio_monitor extends uvm_monitor;
  virtual gpio_if vif;
  uvm_analysis_port #(gpio_item) ap;
  `uvm_component_utils(gpio_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", $sformatf("{%s}: virtual interface vif not found in config_db", get_full_name()))
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] prev_val;
    gpio_item item;

    @(posedge vif.rst_n);
    repeat(10) @(posedge vif.clk);
    prev_val = vif.gpio_o;

    forever begin
      @(vif.gpio_o);
      if (vif.rst_n && (vif.gpio_o !== prev_val)) begin
        item = gpio_item::type_id::create("item");
        item.gpio_i  = vif.gpio_i;
        item.gpio_o  = vif.gpio_o;
        item.gpio_oe = vif.gpio_oe;
        ap.write(item);

        `uvm_info(get_type_name(), $sformatf("[GPIO MONITOR RECEIVED] From GPIO IP: Pin Transition: 0x%08h -> 0x%08h",
                  prev_val, vif.gpio_o), UVM_LOW)
        prev_val = vif.gpio_o;
      end
    end
  endtask
endclass
