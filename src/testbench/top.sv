`timescale 1ns/1ps
`include "interface.sv"
`include "sys_pkg.sv"
`include "sys_assertion.sv"
 
module sys_tb_top;
  import uvm_pkg::*;
  import sys_pkg::*;
 
  bit clk;
 
  sys_inf duvif (clk);
 
  tt_um_systolic_mm dut (
    .ui_in  (duvif.ui_in),
    .uo_out (duvif.uo_out),
    .uio_in (duvif.uio_in),
    .uio_out(duvif.uio_out),
    .uio_oe (duvif.uio_oe),
    .ena    (duvif.ena),
    .clk    (clk),
    .rst_n  (duvif.rst_n)
  );
 
  initial begin
    uvm_config_db #(virtual sys_inf.drv)::set(null, "*", "vif", duvif);
    uvm_config_db #(virtual sys_inf.mon)::set(null, "*", "vif", duvif);
    run_test();
  end
 
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
 
bind tt_um_systolic_mm sys_assertion assertion_inst (
  .clk    (clk),
  .rst_n  (rst_n),
  .ena    (ena),
  .ui_in  (ui_in),
  .uo_out (uo_out),
  .uio_in (uio_in),
  .uio_out(uio_out),
  .uio_oe (uio_oe)
);