class reset_during_compute_seq extends uvm_sequence #(sys_seq_item);
 
  `uvm_object_utils(reset_during_compute_seq)
 
  function new(string name = "reset_during_compute_seq");
    super.new(name);
  endfunction
 
  task send(bit la, bit lb, bit st, bit rd, bit rst, int unsigned n, sys_seq_item::data_mode_e mode = sys_seq_item::RAND_DATA);
    sys_seq_item item = sys_seq_item::type_id::create("item");
    item.data_mode = mode;
    start_item(item);
    if (!item.randomize() with {
          load_a == la; load_b == lb; start == st; read == rd;
          reset == rst;
          num_cycles == n;
        })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(item);
  endtask
 
  task body();
    send(1, 0, 0, 0, 0, 16);
    send(0, 1, 0, 0, 0, 16);
    send(0, 0, 1, 0, 0, 1);
    send(0, 0, 0, 0, 1, 6);             // Reset in Compute state
    send(0, 0, 1, 0, 0, 29);
    send(0, 0, 0, 0, 1, 6);             // Reset in Done state
    send(0, 0, 1, 0, 0, 29);
    send(0, 0, 0, 1, 0, 10);
    send(0, 0, 0, 1, 1, 10);            // Reset in Read state
    send(0, 0, 0, 1, 0, 32);
    send(0, 0, 1, 0, 1, 12);
  endtask
 
endclass