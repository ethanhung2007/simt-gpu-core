import simt_defs::*;

module core_validation_top #(
    parameter int NUM_TEST_LANES = NUM_LANES
) (
    input logic clk,
    input logic rst,
    output logic [DATA_W-1:0] fetch_pc,
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
    //  output logic [NUM_TEST_LANES-1:0] mem_valid_o,
    //  output logic [NUM_TEST_LANES-1:0] mem_we_o,
    output logic [DATA_W-1:0] w_mem_data[NUM_TEST_LANES-1:0],
    output logic [DATA_W-1:0] mem_addr[NUM_TEST_LANES-1:0],
    output logic [DATA_W-1:0] exec_pc_tb,
    output logic exec_valid_tb,
    output logic [DATA_W-1:0] instr_tb
    //  output logic [NUM_TEST_LANES-1:0] tb_r3_out[DATA_W-1:0]
);

  // lane related declarations
  logic [DATA_W-1:0] r_mem_data[NUM_TEST_LANES-1:0];
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
  logic [4:0] rd_lane;

  // branch related declarations
  logic branch_predicated;
  logic [DATA_W-1:0] branch_target_off;
  logic [DATA_W-1:0] branch_reconv_off;

  // mem_ctrl related declarations
  logic [NUM_TEST_LANES-1:0] load_reg_we;
  logic [DATA_W-1:0] instr;
  logic mem_op_mem;
  logic mem_we_mem;
  logic [DATA_W-1:0] mem_addr_mem;
  logic [DATA_W-1:0] w_mem_data_mem;
  logic [DATA_W-1:0] r_mem_data_mem;
  logic [DATA_W-1:0] load_data;
  logic load_writeback_valid;
  logic [4:0] saved_load_rd; // using a saved rd to enable potetentially better pipelining for the future
  logic [$clog2(NUM_TEST_LANES)-1:0] load_writeback_lane;
  logic mem_accept;
  logic mem_busy;

  // pipelined registers for synchronous instr memory
  logic [DATA_W-1:0] exec_pc;
  logic exec_valid;
  logic dec_reg_we;
  logic dec_preg_we;
  logic dec_mem_op;
  logic dec_branch_valid;
  logic dec_rcnv_valid;
  logic dec_exit_valid;

  // mfsr registers
  logic [DATA_W-1:0] mfsr_data[NUM_TEST_LANES-1:0];
  logic [3:0] mfsr_sel;
//logic [$clog2(NUM_WARPS)-1:0] warp_id,


  always_ff @(posedge clk) begin
    if (rst) begin
      exec_pc <= '0;
      exec_valid <= 0;
    end else begin
      exec_pc <= fetch_pc;
      if (branch_valid_o || rcnv_valid_o || stalled_o) exec_valid <= 0;
      else exec_valid <= 1;
    end
  end

  assign exec_valid_tb = exec_valid;
  assign exec_pc_tb = exec_pc;
  assign instr_tb = instr;

  warp_control warp_control_inst (
      .clk(clk),
      .rst(rst),
      .exec_pc(exec_pc),
      .external_stall(mem_busy),
      .branch_valid(branch_valid_o),
      .branch_predicated(branch_predicated),
      .branch_target_off(branch_target_off),
      .branch_reconv_off(branch_reconv_off),
      .rcnv_valid(rcnv_valid_o),
      .exit_valid(exit_valid_o),
      .pred_vec(pred_vec_o),
      .done(done_o),
      .stalled(stalled_o),
      .pc(fetch_pc),
      .active_mask(active_mask_o),
      .error(error_o)
  );

  // gate decoder signals
  assign reg_we_o = dec_reg_we && exec_valid;
  assign preg_we_o = dec_preg_we && exec_valid;
  assign mem_op_o = dec_mem_op && exec_valid;
  assign branch_valid_o = dec_branch_valid && exec_valid;
  assign rcnv_valid_o = dec_rcnv_valid && exec_valid;
  assign exit_valid_o = dec_exit_valid && exec_valid;

  mem_ctrl mem_ctrl_inst (
      .clk(clk),
      .rst(rst),
      .mem_we_i(mem_we_i),
      .mem_op_i(mem_op_o),
      .active_mask(active_mask_o),
      .mem_addr_i(mem_addr),
      .w_mem_data_i(w_mem_data),
      .r_mem_data(r_mem_data_mem),
      .mem_op_o(mem_op_mem),
      .mem_we_o(mem_we_mem),
      .mem_addr_o(mem_addr_mem),
      .w_mem_data_o(w_mem_data_mem),  // only for writing into mem
      .mem_accept(mem_accept),
      .busy(mem_busy),
      .done(),
      .load_data(load_data),
      .load_writeback_valid(load_writeback_valid),
      .load_writeback_lane(load_writeback_lane)
  );

  always_comb begin
    for (int i = 0; i < NUM_TEST_LANES; i++) begin
      r_mem_data[i]  = '0;
      load_reg_we[i] = 0;
    end

    if (load_writeback_valid) begin
      r_mem_data[load_writeback_lane]  = load_data;
      load_reg_we[load_writeback_lane] = 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      saved_load_rd <= '0;
    end else if (mem_accept && !mem_we_i) begin
      saved_load_rd <= rd_i;
    end
  end

  assign rd_lane = load_writeback_valid ? saved_load_rd : rd_i;

  data_memory data_mem_inst (
      .clk(clk),
      .rst(rst),
      .we(mem_we_mem),
      .mem_op_i(mem_op_mem),
      .data_addr(mem_addr_mem),
      .w_mem_data(w_mem_data_mem),
      .r_mem_data(r_mem_data_mem)
  );

  instruction_memory instr_mem_inst (
      .clk(clk),
      .instr_addr(fetch_pc),
      .instr(instr)
  );

  decoder warp_decoder_inst (
      .clk(clk),
      .rst(rst),
      .instr(instr),
      .mem_we_i(mem_we_i),
      .mem_op(dec_mem_op),
      .alu_op(alu_op),
      .rd_i(rd_i),
      .rs1_i(rs1_i),
      .rs2_i(rs2_i),
      .p_i(p_i),
      .imm(imm),
      .cond(cond),
      .mfsr_sel(mfsr_sel),
      .op2_sel(op2_sel),
      .reg_we(dec_reg_we),
      .preg_we(dec_preg_we),
      .wb_sel(wb_sel),
      .branch_valid(dec_branch_valid),
      .branch_predicated(branch_predicated),
      .branch_target_off(branch_target_off),
      .branch_reconv_off(branch_reconv_off),
      .rcnv_valid(dec_rcnv_valid),
      .exit_valid(dec_exit_valid)
  );

  mfsr_read_unit mfsr_read_unit_inst (
      .mfsr_sel(mfsr_sel),
//    .warp_id(warp_id),
      .active_mask(active_mask_o),
      .mfsr_data(mfsr_data)
  );

  genvar i;
  generate
    for (i = 0; i < NUM_TEST_LANES; i++) begin : lane_loop
      lane lane_inst (
          .clk(clk),
          .rst(rst),
          //        .mem_we_i(mem_we_i),
          .mem_op(mem_op_o),
          .alu_op(alu_op),
          .rd_i(rd_lane),
          .rs1_i(rs1_i),
          .rs2_i(rs2_i),
          .p_i(p_i),
          .preg_we(preg_we_o),
          .mfsr_in(mfsr_data[i]),
          .imm(imm),
          .cond(cond),
          .lane_active(active_mask_o[i]),
          .op2_sel(op2_sel),
          .reg_we(reg_we_o),
          .load_reg_we(load_reg_we[i]),
          .wb_sel(wb_sel),
          .r_mem_data(r_mem_data[i]),
          .pred_val_o(pred_vec_o[i]),
          //        .mem_valid(mem_valid_o[i]),
          //        .mem_we_o(mem_we_o[i]),
          .w_mem_data(w_mem_data[i]),
          .mem_addr(mem_addr[i])
          //        .tb_r3_out(tb_r3_out[i])
      );
    end
  endgenerate

endmodule
