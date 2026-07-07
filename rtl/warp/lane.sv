module lane (
    input logic clk,
    input logic rst,
    input logic alu_op, // 1 for mul, 0 for add
    input logic [4:0] rd_i, rs1_i, rs2_i, // rb will use rs1 when needed; i for index
    input logic [31:0] imm,
    input logic [2:0] cond,
    input logic op2_sel, // if 1 reg, 0 then imm
    input logic we,
    input logic [1:0] wb_sel // if 0 reg, 1 then imm, 2 then mem
);

  import simt_defs::*;

  logic [31:0] rs1_val, rs2_val, rs1_reg, rs2_reg;
  logic [31:0] alu_res;
  logic [31:0] w_data;

  lane_alu alu (
      .alu_op(alu_op),
      .rs1_val(rs1_val),
      .rs2_val(rs2_val),
      .res(alu_res)
  );

  lane_reg_file reg_file (
      .rst(rst),
      .clk(clk),
      .we(we),
      .data(w_data),
      .rd(rd_i),
      .rs1(rs1_i),
      .rs2(rs2_i),
      .rs1_val(rs1_reg),
      .rs2_val(rs2_reg)
  );
  
  always_comb begin
    rs1_val = rs1_reg;
    rs2_val = op2_sel ? rs2_reg : imm;
    w_data = '0;
    case(wb_sel) 
      ALU_RESULT: w_data = alu_res;
      IMM_RESULT: w_data = imm;
      // MEM_DATA: 
    endcase
  end


endmodule
