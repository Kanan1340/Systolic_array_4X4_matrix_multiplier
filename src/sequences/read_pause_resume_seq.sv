class read_pause_resume_seq extends uvm_sequence #(sys_seq_item);

  `uvm_object_utils(read_pause_resume_seq)

  function new(string name = "read_pause_resume_seq");
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
    send(1, 0, 0, 0, 16);                                  // load A = random input 
    send(0, 1, 0, 0, 16);                                  // load B = random input 
    send(0, 0, 1, 0, 30);                                  // START, then wait past the 29-cycle compute
    send(0, 0, 0, 1, 10);                                  // READ 10 bytes (low byte, high byte per element)
    send(0, 0, 0, 0, 5);                                   // Release READ and wait in DONE for 2-cycle
    send(0, 0, 0, 1, 22);                                  // READ other 22 bytes (low byte, high byte per element)
  endtask

endclass
