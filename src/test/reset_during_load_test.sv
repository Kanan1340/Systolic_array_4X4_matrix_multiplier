
class reset_during_load_test extends uvm_test;

  `uvm_component_utils(reset_during_load_test)

  sys_environment env;

  function new(string name = "reset_during_load_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sys_environment::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    reset_during_load_seq seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting reset_during_load_test", UVM_LOW)

    seq = reset_during_load_seq::type_id::create("seq");
    seq.start(env.active_agent.seqr);

    #200ns;
    phase.drop_objection(this);
  endtask

endclass

