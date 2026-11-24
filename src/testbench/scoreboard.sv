class scoreboard extends uvm_scoreboard;
    `uvm_analysis_imp_decl(_in_mon)
    `uvm_analysis_imp_decl(_out_mon)

  `uvm_component_utils(scoreboard)

  uvm_analysis_imp_in_mon  #(sys_seq_item, scoreboard) in_mon_imp;
  uvm_analysis_imp_out_mon #(sys_seq_item, scoreboard) out_mon_imp;

  sys_seq_item in_q[$], out_q[$];

  typedef enum {S_IDLE, S_LOAD_A, S_LOAD_B, S_COMPUTE, S_DONE, S_READ} state_e;
  state_e   state;
  bit [3:0] a_mem[16], b_mem[16];
  bit [3:0] a_index, b_index;
  bit [9:0] c_exp[16];
  bit [4:0] rd_index;
  int       busy_cnt;
  bit       model_valid;
  bit       cbuf_clean;

  int checks, errors;

  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);
    in_mon_imp  = new("in_mon_imp", this);
    out_mon_imp = new("out_mon_imp", this);
  endfunction

  function void write_in_mon(sys_seq_item item);
    in_q.push_back(item);
    try_check();
  endfunction

  function void write_out_mon(sys_seq_item item);
    out_q.push_back(item);
    try_check();
  endfunction

  function void try_check();
    while (in_q.size() > 0 && out_q.size() > 0) begin
      sys_seq_item i = in_q.pop_front();
      sys_seq_item o = out_q.pop_front();
      process_cycle(i, o);
    end
  endfunction

  function void process_cycle(sys_seq_item i, sys_seq_item o);
    if (!i.rst_n) begin
      reset_expected();
      model_valid = 1;
      check_outputs(o);
      return;
    end
    if (!model_valid) return;
    check_outputs(o);
    step(i);
  endfunction

  function void check_outputs(sys_seq_item o);
    bit       exp_busy = (state == S_COMPUTE);
    bit       exp_done = (state == S_DONE) || (state == S_READ);
    bit [7:0] exp_byte;

    checks++;

    if (o.busy !== exp_busy) begin
      `uvm_error("SB", $sformatf("BUSY mismatch: exp=%0b got=%0b state=%s", exp_busy, o.busy, state.name()))
      errors++;
    end
    if (o.done !== exp_done) begin
      `uvm_error("SB", $sformatf("DONE mismatch: exp=%0b got=%0b state=%s", exp_done, o.done, state.name()))
      errors++;
    end
    if (o.uio_out[7:6] !== 2'b00 || o.uio_out[3:0] !== 4'b0000) begin
      `uvm_error("SB", $sformatf("reserved uio_out bits not low: %b", o.uio_out))
      errors++;
    end
    if (o.uio_oe !== 8'hF0) begin
      `uvm_error("SB", $sformatf("uio_oe not 8'hF0: %h", o.uio_oe))
      errors++;
    end
    if (exp_done || cbuf_clean) begin
      exp_byte = rd_index[0] ? {6'b0, c_exp[rd_index >> 1][9:8]} : c_exp[rd_index >> 1][7:0];
      if (o.uo_out !== exp_byte) begin
        `uvm_error("SB", $sformatf("uo_out mismatch at rd_index=%0d: exp=%02h got=%02h", rd_index, exp_byte, o.uo_out))
        errors++;
      end
    end
  endfunction

  function void step(sys_seq_item i);
    case (state)
      S_IDLE, S_DONE: begin
        if (i.load_a) begin
          a_mem[a_index] = i.ui_in[3:0]; a_index++; state = S_LOAD_A;
        end
        else if (i.load_b) begin
          b_mem[b_index] = i.ui_in[3:0]; b_index++; state = S_LOAD_B;
        end
        else if (i.start) begin
          compute(); busy_cnt = 28; cbuf_clean = 0; rd_index = 0; state = S_COMPUTE;
        end
        else if (i.read && state == S_DONE) begin
          rd_index = (rd_index == 31) ? 5'd0 : rd_index + 1;
          state = S_READ;
        end
      end
      S_LOAD_A: begin
        if (i.load_a) begin a_mem[a_index] = i.ui_in[3:0]; a_index++; end
        else begin state = S_IDLE; a_index = 0; end
      end
      S_LOAD_B: begin
        if (i.load_b) begin b_mem[b_index] = i.ui_in[3:0]; b_index++; end
        else begin state = S_IDLE; b_index = 0; end
      end
      S_COMPUTE: begin
        busy_cnt--;
        if (busy_cnt == 0) state = S_DONE;
      end
      S_READ: begin
        if (i.read) rd_index = (rd_index == 31) ? 5'd0 : rd_index + 1;
        else        state = S_DONE;
      end
    endcase
  endfunction

  function void compute();
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++) begin
        bit [9:0] sum = 0;
        for (int k = 0; k < 4; k++)
          sum += a_mem[r*4 + k] * b_mem[k*4 + c];
        c_exp[r*4 + c] = sum;
      end
  endfunction

  function void reset_expected();
    state = S_IDLE;
    foreach (a_mem[k]) begin a_mem[k] = 0; b_mem[k] = 0; c_exp[k] = 0; end
    a_index = 0; b_index = 0; rd_index = 0; busy_cnt = 0;
    cbuf_clean = 1;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("checks=%0d errors=%0d", checks, errors), UVM_LOW)
    if (errors == 0) `uvm_info("SB", "TEST PASSED", UVM_NONE)
    else             `uvm_error("SB", "TEST FAILED")
  endfunction

endclass