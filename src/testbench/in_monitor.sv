class in_monitor extends uvm_monitor;

  `uvm_component_utils(in_monitor)

  uvm_analysis_port #(sys_seq_item) in_ap;  
  virtual sys_inf.mon vif;

  function new(string name = "in_monitor", uvm_component parent = null);
    super.new(name, parent);
    in_ap = new("in_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual sys_inf.mon)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"in_monitor did not get vif for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    sys_seq_item rx;
    forever begin
      @(vif.mon_cb);
      rx = sys_seq_item::type_id::create("rx");
      rx.rst_n  = vif.mon_cb.rst_n;
      rx.ena    = vif.mon_cb.ena;
      rx.ui_in  = vif.mon_cb.ui_in;
      rx.load_a = vif.mon_cb.uio_in[0];
      rx.load_b = vif.mon_cb.uio_in[1];
      rx.start  = vif.mon_cb.uio_in[2];
      rx.read   = vif.mon_cb.uio_in[3];
      `uvm_info("IN_MON",
  $sformatf("rst_n=%0b ena=%0b ui_in=0x%02h load_a=%0b load_b=%0b start=%0b read=%0b",
            rx.rst_n, rx.ena, rx.ui_in, rx.load_a, rx.load_b, rx.start, rx.read),
  UVM_HIGH)
	in_ap.write(rx);
    end
  endtask

endclass

