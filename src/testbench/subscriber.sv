class sys_subscriber extends uvm_subscriber #(sys_seq_item);
`uvm_component_utils(sys_subscriber)
sys_seq_item tr;
 
  covergroup cg;
    option.per_instance = 1;
 
    ENA_CP: coverpoint tr.ena {
      bins low  = {0};
      bins high = {1};
    }
 
    UI_IN_LOWER_CP: coverpoint tr.ui_in[3:0]{
      bins input_lower_data[] = {[4'h0:4'hF]};  
    }
 
    UI_IN_UPPER_CP: coverpoint tr.ui_in[7:4] {
      bins input_upper_data = {[4'h0:4'hF]}; 
    }
 
    LOAD_A_CP: coverpoint tr.load_a {
      bins inactive = {0};
      bins active = {1};
    }
    LOAD_B_CP: coverpoint tr.load_b {
	bins inactive = {0};
	bins active = {1};
    }
    START_CP: coverpoint tr.start {
	bins inactive = {0};
	bins active = {1};
    }
 
    READ_CP: coverpoint tr.read {
	bins inactive = {0};
	bins active = {1};
    }
 
    CTRL_CROSS: cross LOAD_A_CP, LOAD_B_CP, START_CP, READ_CP;
    UI_IN_LOWER_LOAD_A_CROSS: cross UI_IN_LOWER_CP, LOAD_A_CP;
    UI_IN_LOWER_LOAD_B_CROSS:  cross UI_IN_LOWER_CP, LOAD_B_CP;
  endgroup
 
  function new(string name = "sys_subscriber", uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction
 
  function void write(sys_seq_item t);
    tr = t;
    cg.sample();
  endfunction
 
endclass
