class read_without_done_test extends uvm_test;

  `uvm_component_utils(read_without_done_test)

  sys_environment env;

  function new(string name = "read_without_done_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sys_environment::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    read_without_done_seq seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting read_without_done_test", UVM_LOW)

    seq = read_without_done_seq::type_id::create("seq");
    seq.start(env.active_agent.seqr);

    #200ns;                            
    phase.drop_objection(this);
  endtask

endclass

