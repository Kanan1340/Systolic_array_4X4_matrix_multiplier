class sys_agent extends uvm_agent;

  `uvm_component_utils(sys_agent)

  sys_sequencer seqr;
  sys_driver    drv;
  in_monitor    i_mon;
  out_mon       o_mon;

  function new(string name = "sys_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      seqr  = sys_sequencer::type_id::create("seqr", this);
      drv   = sys_driver::type_id::create("drv", this);
      i_mon = in_monitor::type_id::create("i_mon", this);
    end
    else begin
      o_mon = out_mon::type_id::create("o_mon", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass