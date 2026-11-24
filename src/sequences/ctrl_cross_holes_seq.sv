class ctrl_cross_holes_seq extends uvm_sequence #(sys_seq_item);
 
  `uvm_object_utils(ctrl_cross_holes_seq)
 
  function new(string name = "ctrl_cross_holes_seq");
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
 
 
  task start_and_wait();
    send(0, 0, 1, 0, 30);
  endtask
 
  task body();
    send(1, 0, 0, 0, 16);                  // Load A
    send(0, 1, 0, 0, 16);                  // Load B
 
    // ---------- part 1: the four missing combinations, FSM in IDLE ----------
    send(1, 0, 1, 0, 16);                  // 1010: LOAD_A + START           -> LOAD_A wins
    send(1, 0, 1, 1, 16);                  // 1011: LOAD_A + START + READ    -> LOAD_A wins
    send(1, 1, 1, 0, 16);                  // 1110: LOAD_A + LOAD_B + START  -> LOAD_A wins, B not written
    send(0, 1, 1, 1, 16);                  // 0111: LOAD_B + START + READ    -> LOAD_B wins
    send(1, 1, 1, 1, 16);                  // 1111: ALL REQ at once          -> LOAD_A wins
    send(1, 1, 0, 1, 16);                  // 1101: ALL REQ except START     -> LOAD_A wins
 
    // ---------- part 2: the same four combinations with the FSM in DONE ----------
    // each load ends in IDLE, so start_and_wait() is needed before every one
    start_and_wait();                      // IDLE -> COMPUTE -> DONE
    send(1, 0, 1, 0, 16);                  // 1010 in DONE  (DONE -> LOAD_A)
    start_and_wait();
    send(1, 0, 1, 1, 16);                  // 1011 in DONE
    start_and_wait();
    send(1, 1, 1, 0, 16);                  // 1110 in DONE
    start_and_wait();
    send(0, 1, 1, 1, 16);                  // 0111 in DONE  (DONE -> LOAD_B)
    start_and_wait();
    send(1, 1, 1, 1, 16);                  // 1111: ALL REQ at once          -> LOAD_A wins
    start_and_wait();
    send(1, 1, 0, 1, 16);                  // 1101: ALL REQ except START     -> LOAD_A wins
 
    // ---------- part 3: paused read, then START in DONE (checks the pointer clear) ----------
    start_and_wait();                      // DONE
    send(0, 0, 0, 1, 6);                   // read 6 bytes, then release   (READ -> DONE)
    send(0, 0, 1, 0, 30);                  // START in DONE                (DONE -> COMPUTE), pointer cleared
    send(0, 0, 0, 1, 32);                  // full read, must start again at byte 0
  endtask
 
endclass