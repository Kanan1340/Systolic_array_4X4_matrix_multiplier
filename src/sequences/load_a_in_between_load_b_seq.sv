class load_a_in_between_load_b_seq extends uvm_sequence #(sys_seq_item);

  `uvm_object_utils(load_a_in_between_load_b_seq)

  function new(string name = "load_a_in_between_load_b_seq");
    super.new(name);
  endfunction

  task send(bit la, bit lb, bit st, bit rd, int unsigned n, sys_seq_item::data_mode_e mode = sys_seq_item::RAND_DATA, bit ramp = 0);
    sys_seq_item item = sys_seq_item::type_id::create("item");
    item.data_mode = mode;                       
    start_item(item);
    if (!item.randomize() with {
          load_a == la;  load_b == lb;  start == st;  read == rd;
          reset == 0;                            
          num_cycles == n;
          if (ramp) foreach (in_arr[i]) in_arr[i] == i;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(item);
  endtask

  task body();
    send(0, 1, 0, 0, 8);                                   // Load B  
    send(1, 1, 0, 0, 16);                                  // Load A and B  
    send(0, 0, 1, 0, 30);                                  // Assert start and read req - in IDLE, then wait past the 29-cycles
    send(0, 0, 0, 1, 32);                                  // READ 16 bytes (low byte, high byte per element)
  endtask

endclass
