interface sys_inf (input logic clk);

  logic       rst_n;      
  logic       ena;
  logic [7:0] ui_in;
  logic [7:0] uio_in;
  logic [7:0] uo_out;
  logic [7:0] uio_out;
  logic [7:0] uio_oe;

  clocking drv_cb @(posedge clk);
    default input #1 output #0;
    output ena, ui_in, uio_in;
    input  uo_out, uio_out, uio_oe;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1 output #0;
    input rst_n, ena, ui_in, uio_in, uo_out, uio_out, uio_oe;
  endclocking

  modport drv (clocking drv_cb, input clk, output rst_n);
  modport mon (clocking mon_cb, input clk, input rst_n);

endinterface
