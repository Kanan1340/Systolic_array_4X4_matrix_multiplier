module systolic_array #(
  parameter MN   = 4,
  parameter PN   = 2,
  parameter DW   = 4,
  parameter ACCW = 10
) (
  input  wire       CLK,
  input  wire       RESET_N,
  input  wire [7:0] DATA_IN,
  input  wire       LOAD_A,
  input  wire       LOAD_B,
  input  wire       START,
  input  wire       READ,
  output wire [7:0] DATA_OUT,
  output wire       BUSY,
  output wire       DONE
);

  localparam MNN       = MN * MN;
  localparam PNN       = PN * PN;
  localparam BLK       = MN / PN;
  localparam NPASS     = BLK * BLK;
  localparam T_LAST    = MN - 1 + 2 * (PN - 1);
  localparam TW        = $clog2(T_LAST + 2);
  localparam PTRW      = $clog2(MNN);
  localparam BW        = (BLK < 2) ? 1 : $clog2(BLK);
  localparam SELW      = $clog2(BLK * MN);
  localparam OB_RAW    = 1 << $clog2((ACCW + 7) / 8);
  localparam OBYTES    = (OB_RAW < 2) ? 2 : OB_RAW;
  localparam BSEL_W    = $clog2(OBYTES);
  localparam RDW       = $clog2(MNN * OBYTES);
  localparam OW        = OBYTES * 8;
  localparam ACC_EXACT = 2 * DW + $clog2(MN);

  localparam [2:0] S_IDLE    = 3'd0;
  localparam [2:0] S_LOAD_A  = 3'd1;
  localparam [2:0] S_LOAD_B  = 3'd2;
  localparam [2:0] S_COMPUTE = 3'd3;
  localparam [2:0] S_WB      = 3'd4;
  localparam [2:0] S_DONE    = 3'd5;
  localparam [2:0] S_READ    = 3'd6;

  reg  [2:0]      STATE;
  reg  [2:0]      NEXT_STATE;
  reg  [PTRW-1:0] A_PTR;
  reg  [PTRW-1:0] B_PTR;
  reg  [TW-1:0]   T_CNT;
  reg  [BW-1:0]   PASS_I;
  reg  [BW-1:0]   PASS_J;
  reg  [RDW-1:0]  RD_PTR;

  reg  [DW-1:0] A_MEM [0:MNN-1];
  reg  [DW-1:0] B_MEM [0:MNN-1];

  integer       I;

  wire WR_A;
  wire WR_B;
  wire CLR_ACC;
  wire EN_MAC;
  wire WB_NOW;
  wire START_RUN;
  wire LAST_PASS;

  assign LAST_PASS = (PASS_I == (BLK - 1)) && (PASS_J == (BLK - 1));

  always @(*) begin
    NEXT_STATE = STATE;
    case (STATE)
      S_IDLE: begin
        if      (LOAD_A) NEXT_STATE = S_LOAD_A;
        else if (LOAD_B) NEXT_STATE = S_LOAD_B;
        else if (START)  NEXT_STATE = S_COMPUTE;
      end
      S_LOAD_A: begin
        if (!LOAD_A) NEXT_STATE = S_IDLE;
      end
      S_LOAD_B: begin
        if (!LOAD_B) NEXT_STATE = S_IDLE;
      end
      S_COMPUTE: begin
        if (T_CNT == T_LAST) NEXT_STATE = S_WB;
      end
      S_WB: begin

        if (LAST_PASS) NEXT_STATE = S_DONE;
        else           NEXT_STATE = S_COMPUTE;
      end
      S_DONE: begin
        if      (LOAD_A) NEXT_STATE = S_LOAD_A;
        else if (LOAD_B) NEXT_STATE = S_LOAD_B;
        else if (START)  NEXT_STATE = S_COMPUTE;
        else if (READ)   NEXT_STATE = S_READ;
      end
      S_READ: begin
        if (!READ) NEXT_STATE = S_DONE;
      end
      default: NEXT_STATE = S_IDLE;
    endcase
  end

  assign WR_A      = (NEXT_STATE == S_LOAD_A);
  assign WR_B      = (NEXT_STATE == S_LOAD_B);

  assign CLR_ACC   = (NEXT_STATE == S_COMPUTE) && (STATE != S_COMPUTE);
  assign EN_MAC    = (STATE == S_COMPUTE);
  assign WB_NOW    = (STATE == S_WB);

  assign START_RUN = (NEXT_STATE == S_COMPUTE) &&
                     ((STATE == S_IDLE) || (STATE == S_DONE));

  assign BUSY      = (STATE == S_COMPUTE) || (STATE == S_WB);
  assign DONE      = (STATE == S_DONE) || (STATE == S_READ);

  always @(posedge CLK or negedge RESET_N) begin
    if (!RESET_N) begin
      STATE  <= S_IDLE;
      A_PTR  <= {PTRW{1'b0}};
      B_PTR  <= {PTRW{1'b0}};
      T_CNT  <= {TW{1'b0}};
      PASS_I <= {BW{1'b0}};
      PASS_J <= {BW{1'b0}};
      RD_PTR <= {RDW{1'b0}};
      for (I = 0; I < MNN; I = I + 1) begin
        A_MEM[I] <= {DW{1'b0}};
        B_MEM[I] <= {DW{1'b0}};
      end
    end
    else begin
      STATE <= NEXT_STATE;

      if (!LOAD_A)   A_PTR <= {PTRW{1'b0}};
      else if (WR_A) A_PTR <= A_PTR + 1'b1;

      if (WR_A) A_MEM[A_PTR] <= DATA_IN[DW-1:0];

      if (!LOAD_B)   B_PTR <= {PTRW{1'b0}};
      else if (WR_B) B_PTR <= B_PTR + 1'b1;

      if (WR_B) B_MEM[B_PTR] <= DATA_IN[DW-1:0];

      if (CLR_ACC)                 T_CNT <= {TW{1'b0}};
      else if (STATE == S_COMPUTE) T_CNT <= T_CNT + 1'b1;

      if (START_RUN) begin
        PASS_I <= {BW{1'b0}};
        PASS_J <= {BW{1'b0}};
      end
      else if (WB_NOW) begin
        if (PASS_J == (BLK - 1)) begin
          PASS_J <= {BW{1'b0}};
          if (PASS_I != (BLK - 1)) PASS_I <= PASS_I + 1'b1;
        end
        else begin
          PASS_J <= PASS_J + 1'b1;
        end
      end

      if (START_RUN)
        RD_PTR <= {RDW{1'b0}};
      else if (NEXT_STATE == S_READ)
        RD_PTR <= (RD_PTR == (MNN*OBYTES - 1)) ? {RDW{1'b0}} : RD_PTR + 1'b1;
    end
  end

  wire [DW-1:0]       AH [0:PN*(PN+1)-1];
  wire [DW-1:0]       BV [0:PN*(PN+1)-1];
  wire [PNN*ACCW-1:0] ACC_BUS;

  genvar GI, GJ, GK, GB;

  generate

    for (GI = 0; GI < PN; GI = GI + 1) begin : A_INJECT
      wire [BLK*MN*DW-1:0] ABUS;
      wire [TW-1:0]        KA;
      wire [SELW-1:0]      ASEL;

      for (GB = 0; GB < BLK; GB = GB + 1) begin : BLOCK
        for (GK = 0; GK < MN; GK = GK + 1) begin : PACK
          assign ABUS[(GB*MN + GK)*DW +: DW] = A_MEM[MN*(PN*GB + GI) + GK];
        end
      end

      assign KA   = T_CNT - GI;
      assign ASEL = (KA < MN) ? (PASS_I*MN + KA) : {SELW{1'b0}};
      assign AH[(PN+1)*GI] = (KA < MN) ? ABUS[ASEL*DW +: DW] : {DW{1'b0}};
    end

    for (GJ = 0; GJ < PN; GJ = GJ + 1) begin : B_INJECT
      wire [BLK*MN*DW-1:0] BBUS;
      wire [TW-1:0]        KB;
      wire [SELW-1:0]      BSEL;

      for (GB = 0; GB < BLK; GB = GB + 1) begin : BLOCK
        for (GK = 0; GK < MN; GK = GK + 1) begin : PACK
          assign BBUS[(GB*MN + GK)*DW +: DW] = B_MEM[MN*GK + PN*GB + GJ];
        end
      end

      assign KB   = T_CNT - GJ;
      assign BSEL = (KB < MN) ? (PASS_J*MN + KB) : {SELW{1'b0}};
      assign BV[GJ] = (KB < MN) ? BBUS[BSEL*DW +: DW] : {DW{1'b0}};
    end

    for (GI = 0; GI < PN; GI = GI + 1) begin : PE_ROW
      for (GJ = 0; GJ < PN; GJ = GJ + 1) begin : PE_COL
        wire [ACCW-1:0] ACC_LOCAL;

        PE #(
          .DW      (DW),
          .ACCW    (ACCW)
        ) U_PE (
          .CLK     (CLK),
          .RESET_N (RESET_N),
          .CLR     (CLR_ACC),
          .EN      (EN_MAC),
          .A_IN    (AH[(PN+1)*GI + GJ]),
          .B_IN    (BV[PN*GI + GJ]),
          .A_OUT   (AH[(PN+1)*GI + GJ + 1]),
          .B_OUT   (BV[PN*(GI+1) + GJ]),
          .ACC_OUT (ACC_LOCAL)
        );

        assign ACC_BUS[(PN*GI + GJ)*ACCW +: ACCW] = ACC_LOCAL;
      end
    end
  endgenerate

  wire [PTRW-1:0]   RD_ELEM;
  wire [BSEL_W-1:0] RD_BYTE;
  wire [ACCW-1:0]   C_RD;
  wire [OW-1:0]     ACC_PAD;

  assign RD_ELEM = RD_PTR[RDW-1:BSEL_W];
  assign RD_BYTE = RD_PTR[BSEL_W-1:0];

  generate
    if (NPASS > 1) begin : C_BUFFERED
      reg [ACCW-1:0] CBUF [0:MNN-1];

      integer        CI;
      integer        WI;
      integer        WJ;

      always @(posedge CLK or negedge RESET_N) begin
        if (!RESET_N) begin
          for (CI = 0; CI < MNN; CI = CI + 1)
            CBUF[CI] <= {ACCW{1'b0}};
        end
        else if (WB_NOW) begin
          for (WI = 0; WI < PN; WI = WI + 1)
            for (WJ = 0; WJ < PN; WJ = WJ + 1)
              CBUF[MN*(PN*PASS_I + WI) + PN*PASS_J + WJ]
                <= ACC_BUS[(PN*WI + WJ)*ACCW +: ACCW];
        end
      end

      assign C_RD = CBUF[RD_ELEM];
    end
    else begin : C_DIRECT
      assign C_RD = ACC_BUS[RD_ELEM*ACCW +: ACCW];
    end
  endgenerate

  assign ACC_PAD  = C_RD;
  assign DATA_OUT = ACC_PAD[RD_BYTE*8 +: 8];

endmodule

