class sys_sequencer extends uvm_sequencer #(sys_seq_item);

`uvm_component_utils(sys_sequencer);

function new(string name = "sys_sequencer",uvm_component parent);
super.new(name,parent);
endfunction

endclass
