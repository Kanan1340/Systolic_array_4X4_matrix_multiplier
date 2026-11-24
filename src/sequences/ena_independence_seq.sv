class ena_independence_seq extends uvm_sequence #(sys_seq_item);

  `uvm_object_utils(ena_independence_seq)

  function new(string name = "ena_independence_seq");
    super.new(name);
  endfunction

  task send(bit la, bit lb, bit st, bit rd, int unsigned n, bit en, sys_seq_item::data_mode_e mode = sys_seq_item::RAND_DATA);
    sys_seq_item item = sys_seq_item::type_id::create("item");
    item.data_mode = mode;
    item.ena = en;
    start_item(item);
    if (!item.randomize() with {
          load_a == la; load_b == lb; start == st; read == rd;
          reset == 0;
          num_cycles == n;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(item);
  endtask

  task body();
    send(1, 0, 0, 0, 16, 1);
    send(0, 1, 0, 0, 16, 0);
    send(0, 0, 1, 0, 30, 1);
    send(0, 0, 0, 1, 32, 0);
  endtask

endclass
