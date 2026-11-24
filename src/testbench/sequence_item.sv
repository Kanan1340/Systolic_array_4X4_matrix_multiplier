class sys_seq_item extends uvm_sequence_item;

  `uvm_object_utils(sys_seq_item)

  rand bit          load_a;
  rand bit          load_b;
  rand bit          start;
  rand bit          read;
  rand bit          reset;
  rand bit [3:0]    in_arr[16];
  rand bit [3:0]    upper_nib;
  rand int unsigned num_cycles;

  typedef enum {RAND_DATA, IDENTITY, ZEROS, MAXVAL} data_mode_e;
  data_mode_e data_mode = RAND_DATA;

  bit         rst_n, ena;
  bit [7:0]   ui_in;
  logic [7:0] uo_out, uio_out, uio_oe;
  logic       busy, done;

  constraint c_data {
    foreach (in_arr[i]) {
      (data_mode == IDENTITY) -> in_arr[i] == ((i % 5 == 0) ? 4'd1 : 4'd0);
      (data_mode == ZEROS)    -> in_arr[i] == 4'd0;
      (data_mode == MAXVAL)   -> in_arr[i] == 4'hF;
    }
  }

  constraint c_len {
    num_cycles inside {[1:48]};
    soft num_cycles == 16;
  }

  function new(string name = "sys_seq_item");
    super.new(name);
  endfunction


endclass
