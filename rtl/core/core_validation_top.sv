import simt_defs::*;

module core_validation_top #(
    parameter int NUM_TEST_LANES = NUM_LANES
) (
    input logic clk,
    input logic rst,
    input logic [DATA_W-1:0] instr,
    output logic [DATA_W-1:0] pc_o,
    output logic [NUM_TEST_LANES-1:0] active_mask_o,
    output logic [NUM_TEST_LANES-1:0] pred_vec_o,
    output logic done_o,
    output logic stalled_o,
    output logic error_o,
    output logic reg_we_o,
    output logic preg_we_o,
    output logic mem_op_o,
    output logic branch_valid_o,
    output logic rcnv_valid_o,
    output logic exit_valid_o,
    input logic [DATA_W-1:0] r_mem_data[NUM_TEST_LANES-1:0],
    output logic [NUM_TEST_LANES-1:0] mem_valid_o,
    output logic [NUM_TEST_LANES-1:0] mem_we_o,
    output logic [DATA_W-1:0] w_mem_data[NUM_TEST_LANES-1:0],
    output logic [DATA_W-1:0] mem_addr[NUM_TEST_LANES-1:0]
//  output logic [NUM_TEST_LANES-1:0] tb_r3_out[DATA_W-1:0]
);

  logic mem_we_i;
  logic alu_op;
  logic [4:0] rd_i;
  logic [4:0] rs1_i;
  logic [4:0] rs2_i;
  logic [2:0] p_i;
  logic [DATA_W-1:0] imm;
  logic [2:0] cond;
  logic op2_sel;
  logic [1:0] wb_sel;

  logic branch_predicated;
  logic [DATA_W-1:0] branch_target_off;
  logic [DATA_W-1:0] branch_reconv_off;

  warp_control #(
      .NUM_WARP_LANES(NUM_TEST_LANES)
  ) warp_control_inst (
      .clk(clk),
      .rst(rst),
      .branch_valid(branch_valid_o),
      .branch_predicated(branch_predicated),
      .branch_target_off(branch_target_off),
      .branch_reconv_off(branch_reconv_off),
      .rcnv_valid(rcnv_valid_o),
      .exit_valid(exit_valid_o),
      .pred_vec(pred_vec_o),
      .done(done_o),
      .stalled(stalled_o),
      .pc(pc_o),
      .active_mask(active_mask_o),
      .error(error_o)
  );

  decoder warp_decoder_inst (
      .clk(clk),
      .rst(rst),
      .instr(instr),
      .mem_we_i(mem_we_i),
      .mem_op(mem_op_o),
      .alu_op(alu_op),
      .rd_i(rd_i),
      .rs1_i(rs1_i),
      .rs2_i(rs2_i),
      .p_i(p_i),
      .imm(imm),
      .cond(cond),
      .op2_sel(op2_sel),
      .reg_we(reg_we_o),
      .preg_we(preg_we_o),
      .wb_sel(wb_sel),
      .branch_valid(branch_valid_o),
      .branch_predicated(branch_predicated),
      .branch_target_off(branch_target_off),
      .branch_reconv_off(branch_reconv_off),
      .rcnv_valid(rcnv_valid_o),
      .exit_valid(exit_valid_o)
  );

  genvar i;
  generate
    for (i = 0; i < NUM_TEST_LANES; i++) begin : lane_loop
      lane lane_inst (
          .clk(clk),
          .rst(rst),
          .mem_we_i(mem_we_i),
          .mem_op(mem_op_o),
          .alu_op(alu_op),
          .rd_i(rd_i),
          .rs1_i(rs1_i),
          .rs2_i(rs2_i),
          .p_i(p_i),
          .preg_we(preg_we_o),
          .imm(imm),
          .cond(cond),
          .lane_active(active_mask_o[i]),
          .op2_sel(op2_sel),
          .reg_we(reg_we_o),
          .wb_sel(wb_sel),
          .r_mem_data(r_mem_data[i]),
          .pred_val_o(pred_vec_o[i]),
          .mem_valid(mem_valid_o[i]),
          .mem_we_o(mem_we_o[i]),
          .w_mem_data(w_mem_data[i]),
          .mem_addr(mem_addr[i])
//        .tb_r3_out(tb_r3_out[i])
      );
    end
  endgenerate

endmodule
