import simt_defs::*;

module decoder (
    input logic clk,
    input logic rst,
    input logic [DATA_W-1:0] instr,
    output logic mem_we_i, // 1 for store, 0 for load
    output logic mem_op,
    output logic alu_op,
    output logic [4:0] rd_i, rs1_i, rs2_i,
    output logic [2:0] p_i,
    output logic [DATA_W-1:0] imm,
    output logic [2:0] cond,
    output logic [3:0] mfsr_sel,
    output logic op2_sel,
    output logic reg_we,
    output logic preg_we,
    output logic [1:0] wb_sel,
    output logic branch_valid,
    output logic branch_predicated,
    output logic [DATA_W-1:0] branch_target_off,
    output logic [DATA_W-1:0] branch_reconv_off,
    output logic rcnv_valid,
    output logic exit_valid,
    output logic uses_rs1,
    output logic uses_rs2,
    output logic uses_preg
);

  logic [3:0] opcode;

  assign opcode = instr[31:28];

  always_comb begin
    mem_we_i = 0;
    mem_op = 0;
    alu_op = 0;
    rd_i = 0;
    rs1_i = 0;
    rs2_i = 0;
    p_i = 0;
    imm = 0;
    cond = 0;
    op2_sel = 1;
    preg_we = 0;
    reg_we = 0;
    wb_sel = ALU_RESULT;
    branch_valid = 0;
    branch_predicated = 0;
    branch_target_off = 0;
    branch_reconv_off = 0;
    rcnv_valid = 0;
    exit_valid = 0;
    mfsr_sel = 0;
    uses_rs1 = 0;
    uses_rs2 = 0;
    uses_preg = 0;

    case (opcode)
      OP_ADD: begin
        rd_i = instr[27:23];
        rs1_i = instr[22:18];
        rs2_i = instr[17:13];
        reg_we = 1;
        uses_rs1 = 1;
        uses_rs2 = 1;
      end
      OP_MUL: begin
        alu_op = 1;
        rd_i = instr[27:23];
        rs1_i = instr[22:18];
        rs2_i = instr[17:13];
        reg_we = 1;
        uses_rs1 = 1;
        uses_rs2 = 1;
      end
      OP_LDG: begin
        mem_op = 1;
        rd_i = instr[27:23];
        rs1_i = instr[22:18];
        imm = {{14{instr[17]}}, instr[17:0]};
        op2_sel = 0;
        reg_we = 1;
        wb_sel = MEM_DATA;
        uses_rs1 = 1;
      end
      OP_STG: begin
        mem_we_i = 1;
        mem_op = 1;
        rs1_i = instr[22:18];
        rs2_i = instr[27:23];
        imm = {{14{instr[17]}}, instr[17:0]};
        op2_sel = 0;
        uses_rs1 = 1;
        uses_rs2 = 1;
      end
      OP_BRA: begin
        branch_target_off = {{4{instr[27]}}, instr[27:0]};
        branch_valid = 1;
      end
      OP_PRED: begin
        rs1_i = instr[24:20];
        rs2_i = instr[19:15]; 
        p_i = instr[27:25];
        cond = instr[14:12];
        op2_sel = 1;
        preg_we = 1;
        uses_rs1 = 1;
        uses_rs2 = 1;
      end
      OP_BRAP: begin
        p_i = instr[27:25];
        branch_target_off = {{20{instr[24]}}, instr[24:13]};
        branch_reconv_off = {{20{instr[12]}}, instr[12:1]};
        branch_valid = 1;
        branch_predicated = 1;
        uses_preg = 1;
      end
      OP_RCNV: begin
        rcnv_valid = 1;
      end
      OP_MOV: begin
        rd_i = instr[27:23];
        imm = {{(DATA_W-23){1'b0}}, instr[22:0]};
        reg_we = 1;
        wb_sel = IMM_RESULT;
      end
      OP_EXIT: begin
        exit_valid = 1;
      end
      OP_MFSR: begin
        rd_i = instr[27:23];
        mfsr_sel = instr[22:19];
        reg_we = 1;
        wb_sel = WB_MFSR;
      end
    endcase
  end

endmodule
