class overload_input_test extends uvm_test;

  `uvm_component_utils(overload_input_test)

  sys_environment env;

  function new(string name = "overload_input_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sys_environment::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    overload_input_seq seq;

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting overload_input_test", UVM_LOW)

    seq = overload_input_seq::type_id::create("seq");
    seq.start(env.active_agent.seqr);

    #200ns;                            // let the last samples reach the scoreboard
    phase.drop_objection(this);
  endtask

endclass

