class ena_independence_test extends uvm_test;

  `uvm_component_utils(ena_independence_test)

  sys_environment env;

  function new(string name = "ena_independence_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sys_environment::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    ena_independence_seq seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting ena_independence_test", UVM_LOW)

    seq = ena_independence_seq::type_id::create("seq");
    seq.start(env.active_agent.seqr);

    #200ns;
    phase.drop_objection(this);
  endtask

endclass

