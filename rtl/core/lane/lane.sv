import simt_defs::*;

module lane (
    input logic clk,
    input logic rst,
    input logic mem_we_i,  // 1 for store, 0 for load
    input logic mem_op,  // 1 if mem op, 0 if not
    input logic alu_op,  // 1 for mul, 0 for add  
    input logic [4:0] rd_i, rs1_i, rs2_i,  // for load/store rb = rs1; i for index
    input logic [2:0] p_i,
    input logic preg_we,
    input logic [DATA_W-1:0] imm,
    input logic [2:0] cond,
    input logic lane_active,
    input logic op2_sel,  // if 1 reg, 0 then imm  
    input logic reg_we,
    input logic [1:0] wb_sel,  // if 0 reg, 1 then imm, 2 then mem  
    input logic [DATA_W-1:0] r_mem_data,
    output logic pred_val_o,
    output logic mem_valid,  // indicates that this instr is mem related
    output logic mem_we_o,
    output logic [DATA_W-1:0] w_mem_data,
    output logic [DATA_W-1:0] mem_addr
//  output logic [DATA_W-1:0] debug_rs1_val,  
//  output logic [DATA_W-1:0] debug_rs2_val,  
//  output logic [DATA_W-1:0] debug_w_data  
);

  logic [DATA_W-1:0] rs1_val, rs2_val, rs1_reg, rs2_reg;
  logic [DATA_W-1:0] alu_res;
  logic [DATA_W-1:0] w_data;
  logic lane_reg_we, lane_preg_we;
  logic p_res;

  lane_alu alu (
      .alu_op(alu_op),
      .rs1_val(rs1_val),
      .rs2_val(rs2_val),
      .res(alu_res)
  );

  lane_reg_file reg_file (
      .rst(rst),
      .clk(clk),
      .we(lane_reg_we),
      .data(w_data),
      .rd(rd_i),
      .rs1(rs1_i),
      .rs2(rs2_i),
      .rs1_val(rs1_reg),
      .rs2_val(rs2_reg)
  );

  lane_comparator comparator (
      .rs1_val(rs1_val),
      .rs2_val(rs2_val),
      .cond(cond),
      .res(p_res)
  );

  lane_preg_file preg_file (
      .rst(rst),
      .clk(clk),
      .we(lane_preg_we),
      .pdata(p_res),
      .prd(p_i),
      .prs(p_i),
      .prs_val(pred_val_o)
  );

  always_comb begin
    rs1_val = rs1_reg;
    rs2_val = op2_sel ? rs2_reg : imm;
    w_data = '0;
    w_mem_data = rs2_reg;
    mem_addr = alu_res;
    lane_reg_we = lane_active && reg_we;
    lane_preg_we = lane_active && preg_we;
    case (wb_sel)
      ALU_RESULT: w_data = alu_res;
      IMM_RESULT: w_data = imm;
      MEM_DATA: w_data = r_mem_data;
      default: w_data = 0;
    endcase
    mem_we_o  = (mem_op) && mem_we_i && lane_active;
    mem_valid = (mem_op) && lane_active;
  end

  //test code  
//always_comb begin  
// debug_rs1_val = rs1_reg;  
// debug_rs2_val = rs2_reg;  
// debug_w_data = w_data;  
//end  

endmodule
