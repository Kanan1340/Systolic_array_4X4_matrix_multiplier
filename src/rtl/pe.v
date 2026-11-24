module PE #(
  parameter DW   = 8,
  parameter ACCW = 32
) (
  input  wire             CLK,
  input  wire             RESET_N,
  input  wire             CLR,
  input  wire             EN,
  input  wire [DW-1:0]    A_IN,
  input  wire [DW-1:0]    B_IN,
  output wire [DW-1:0]    A_OUT,
  output wire [DW-1:0]    B_OUT,
  output wire [ACCW-1:0]  ACC_OUT
);

  localparam PW = 2 * DW;

  reg  [DW-1:0]   A_REG;
  reg  [DW-1:0]   B_REG;
  reg  [ACCW-1:0] ACC_REG;

  wire [PW-1:0]   PROD;
  wire [ACCW-1:0] PROD_EXT;

  assign PROD     = A_IN * B_IN;
  assign PROD_EXT = PROD;

  always @(posedge CLK or negedge RESET_N) begin
    if (!RESET_N) begin
      A_REG   <= {DW{1'b0}};
      B_REG   <= {DW{1'b0}};
      ACC_REG <= {ACCW{1'b0}};
    end
    else if (CLR) begin

      A_REG   <= {DW{1'b0}};
      B_REG   <= {DW{1'b0}};
      ACC_REG <= {ACCW{1'b0}};
    end
    else if (EN) begin
      A_REG   <= A_IN;
      B_REG   <= B_IN;
      ACC_REG <= ACC_REG + PROD_EXT;
    end
  end

  assign A_OUT   = A_REG;
  assign B_OUT   = B_REG;
  assign ACC_OUT = ACC_REG;

endmodule

