class start_read_together_start_wins_test extends uvm_test;

  `uvm_component_utils(start_read_together_start_wins_test)

  sys_environment env;

  function new(string name = "start_read_together_start_wins_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sys_environment::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    start_read_together_start_wins_seq seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting start_read_together_start_wins_test", UVM_LOW)

    seq = start_read_together_start_wins_seq::type_id::create("seq");
    seq.start(env.active_agent.seqr);

    #200ns;                            
    phase.drop_objection(this);
  endtask

endclass


