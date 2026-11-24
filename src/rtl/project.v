`default_nettype none

module tt_um_systolic_mm (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  localparam MN   = 4;
  localparam PN   = 2;
  localparam DW   = 4;
  localparam ACCW = 10;

  wire [7:0] DATA_OUT;
  wire       BUSY;
  wire       DONE;

  systolic_array #(
    .MN       (MN),
    .PN       (PN),
    .DW       (DW),
    .ACCW     (ACCW)
  ) U_MM (
    .CLK      (clk),
    .RESET_N  (rst_n),
    .DATA_IN  (ui_in),
    .LOAD_A   (uio_in[0]),
    .LOAD_B   (uio_in[1]),
    .START    (uio_in[2]),
    .READ     (uio_in[3]),
    .DATA_OUT (DATA_OUT),
    .BUSY     (BUSY),
    .DONE     (DONE)
  );

  assign uo_out  = DATA_OUT;
  assign uio_out = {2'b00, DONE, BUSY, 4'b0000};
  assign uio_oe  = 8'b1111_0000;

  wire _UNUSED = ena;

endmodule

