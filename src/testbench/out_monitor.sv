class out_mon extends uvm_monitor;

  `uvm_component_utils(out_mon)

  uvm_analysis_port #(sys_seq_item) out_ap;
  virtual sys_inf.mon vif;

  function new(string name = "out_mon", uvm_component parent = null);
    super.new(name, parent);
    out_ap = new("out_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual sys_inf.mon)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"out_mon did not get vif for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    sys_seq_item rx;
    forever begin
      @(vif.mon_cb);
      rx = sys_seq_item::type_id::create("rx");
      rx.uo_out  = vif.mon_cb.uo_out;
      rx.uio_out = vif.mon_cb.uio_out;
      rx.uio_oe  = vif.mon_cb.uio_oe;
      rx.busy    = vif.mon_cb.uio_out[4];
      rx.done    = vif.mon_cb.uio_out[5];
      `uvm_info("OUT_MON",
  $sformatf("uo_out=%0b uio_out=%0b rx.uio_oe=0x%02h rx.busy=%0b rx.done=%0b ",
            rx.uo_out, rx.uio_out, rx.uio_oe, rx.busy, rx.done),
  UVM_MEDIUM)

      out_ap.write(rx);
    end
  endtask

endclass
