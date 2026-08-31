import simt_defs::*;

module sm_top (
    input  logic clk,
    input  logic rst,
    output logic done_o,
    output logic error_o
);


  logic [DATA_W-1:0] fetch_pc[NUM_WARPS-1:0];

  logic [DATA_W-1:0] instr_addr;
  logic [DATA_W-1:0] instr_mem_data;
  logic [DATA_W-1:0] instr_head[NUM_WARPS-1:0];
  logic [DATA_W-1:0] instr_pc_head[NUM_WARPS-1:0];
  logic empty_instr[NUM_WARPS-1:0];

  logic advance_val;
  logic [$clog2(NUM_WARPS)-1:0] advance_warp;

  logic [4:0] head_rs1[NUM_WARPS-1:0];
  logic [4:0] head_rs2[NUM_WARPS-1:0];
  logic [4:0] head_rd[NUM_WARPS-1:0];
  logic [2:0] head_preg[NUM_WARPS-1:0];

  logic head_reg_we[NUM_WARPS-1:0];
  logic head_preg_we[NUM_WARPS-1:0];

  logic head_uses_rs1[NUM_WARPS-1:0];
  logic head_uses_rs2[NUM_WARPS-1:0];
  logic head_uses_preg[NUM_WARPS-1:0];

  logic head_valid[NUM_WARPS-1:0];
  logic scoreboard_ready[NUM_WARPS-1:0];
  logic sched_ready[NUM_WARPS-1:0];

  logic sched_issue_valid;
  logic [$clog2(NUM_WARPS)-1:0] sched_issue_warp;

  logic issue_ready;
  logic issue_fire;

  logic exec_valid;
  logic [DATA_W-1:0] exec_instr;
  logic [DATA_W-1:0] exec_pc;
  logic [$clog2(NUM_WARPS)-1:0] exec_warp;
  logic [NUM_LANES-1:0] exec_active_mask;
  logic exec_ready;

  logic exec_mem_we;
  logic exec_mem_op;
  logic exec_alu_op;

  logic [4:0] exec_rd;
  logic [4:0] exec_rs1;
  logic [4:0] exec_rs2;
  logic [2:0] exec_preg;

  logic [DATA_W-1:0] exec_imm;
  logic [2:0] exec_cond;
  logic [3:0] exec_mfsr_sel;

  logic exec_op2_sel;
  logic exec_reg_we;
  logic exec_preg_we;
  logic [1:0] exec_wb_sel;

  logic exec_branch_valid;
  logic exec_branch_predicated;
  logic [DATA_W-1:0] exec_branch_target_off;
  logic [DATA_W-1:0] exec_branch_reconv_off;
  logic exec_rcnv_valid;
  logic exec_exit_valid;

  logic exec_control;

  logic warp_done[NUM_WARPS-1:0];
  logic warp_stalled[NUM_WARPS-1:0];
  logic warp_error[NUM_WARPS-1:0];

  logic [NUM_LANES-1:0] warp_active_mask[NUM_WARPS-1:0];

  logic warp_redir_val[NUM_WARPS-1:0];
  logic [DATA_W-1:0] warp_redir_pc[NUM_WARPS-1:0];

  logic redir_val;
  logic [DATA_W-1:0] redir_pc;
  logic [$clog2(NUM_WARPS)-1:0] redir_warp;

  logic any_warp_stalled;
  logic global_block;

  logic [NUM_LANES-1:0] pred_vec;
  logic [DATA_W-1:0] mfsr_data[NUM_LANES-1:0];

  logic [DATA_W-1:0] lane_mem_addr[NUM_LANES-1:0];
  logic [DATA_W-1:0] lane_store_data[NUM_LANES-1:0];

  logic [DATA_W-1:0] lane_load_data[NUM_LANES-1:0];
  logic lane_load_we[NUM_LANES-1:0];

  logic mem_op;
  logic mem_we;
  logic [DATA_W-1:0] mem_addr;
  logic [DATA_W-1:0] mem_write_data;
  logic [DATA_W-1:0] mem_read_data;

  logic mem_busy;
  logic mem_done;
  logic mem_accept;

  logic [DATA_W-1:0] load_data;
  logic load_writeback_valid;
  logic [$clog2(NUM_LANES)-1:0] load_writeback_lane;

  fetch_control fetch_control_inst (
      .clk(clk),
      .rst(rst),
      .advance_val(advance_val),
      .advance_warp(advance_warp),
      .redir_val(redir_val),
      .redir_pc(redir_pc),
      .redir_warp(redir_warp),
      .fetch_pc(fetch_pc)
  );

  instruction_memory instruction_memory_inst (
      .clk(clk),
      .instr_addr(instr_addr),
      .instr(instr_mem_data)
  );

  instr_buffer instr_buffer_inst (
      .clk(clk),
      .rst(rst),
      .instr_i(instr_mem_data),
      .fetch_pc_i(fetch_pc),
      .issue_val(issue_fire),
      .issue_warp(sched_issue_warp),
      .redir_warp(redir_warp),
      .redir_val(redir_val),
      .warp_done(warp_done),
      .instr_addr_o(instr_addr),
      .instr_pc_o(instr_pc_head),
      .instr_o(instr_head),
      .empty_instr(empty_instr),
      .advance_val(advance_val),
      .advance_warp(advance_warp)
  );

  genvar i;

  generate
    for (i = 0; i < NUM_WARPS; i++) begin : head_decode_loop
      decoder head_decoder (
          .clk(clk),
          .rst(rst),
          .instr(instr_head[w]),
          .mem_we_i(),
          .mem_op(),
          .alu_op(),
          .rd_i(head_rd[w]),
          .rs1_i(head_rs1[w]),
          .rs2_i(head_rs2[w]),
          .p_i(head_preg[w]),
          .imm(),
          .cond(),
          .mfsr_sel(),
          .op2_sel(),
          .reg_we(head_reg_we[i]),
          .preg_we(head_preg_we[i]),
          .wb_sel(),
          .branch_valid(),
          .branch_predicated(),
          .branch_target_off(),
          .branch_reconv_off(),
          .rcnv_valid(),
          .exit_valid(),
          .uses_rs1(head_uses_rs1[i]),
          .uses_rs2(head_uses_rs2[i]),
          .uses_preg(head_uses_preg[i])
      );

      assign head_valid[i] = !empty_instr[i] && !warp_done[i];
    end
  endgenerate


  scoreboard scoreboard_inst (
      .clk(clk),
      .rst(rst),
      .rs1_i(head_rs1),
      .rs2_i(head_rs2),
      .rd_i(head_rd),
      .preg_i(head_preg),
      .pregd_i(head_preg),
      .reg_we_i(head_reg_we),
      .uses_rs1_i(head_uses_rs1),
      .uses_rs2_i(head_uses_rs2),
      .uses_preg_i(head_uses_preg),
      .preg_we_i(head_preg_we),
      .issue_val_i(issue_fire),
      .issue_warp_i(sched_issue_warp),
      .issue_rd_i(head_rd[sched_issue_warp]),
      .issue_reg_we_i(head_reg_we[sched_issue_warp]),
      .issue_pregd_i(head_preg[sched_issue_warp]),
      .issue_preg_we_i(head_preg_we[sched_issue_warp]),
      .wb_val_i(exec_valid && (!exec_mem_op || mem_done)),
      .wb_warp_i(exec_warp),
      .wb_rd_i(exec_rd),
      .wb_reg_we_i(exec_reg_we),
      .wb_pregd_i(exec_preg),
      .wb_preg_we_i(exec_preg_we),
      .instr_valid_i(head_valid),
      .ready_o(scoreboard_ready)
  );

  always_comb begin
    any_warp_stalled = 0;
    for (int i = 0; i < NUM_WARPS; i++) begin
      if (warp_stalled[i]) begin
        any_warp_stalled = 1;
      end
    end
  end

  assign exec_control = exec_valid && (exec_branch_valid || exec_rcnv_valid || exec_exit_valid);

  assign global_block = mem_busy || any_warp_stalled || redir_val || exec_control;

  always_comb begin
    for (int i = 0; i < NUM_WARPS; i++) begin
      sched_ready[i] = scoreboard_ready[i] && !warp_done[i] && !warp_stalled[i] && !global_block;
    end
  end

  scheduler scheduler_inst (
      .clk(clk),
      .rst(rst),
      .ready_i(sched_ready),
      .issue_accept_i(issue_fire),
      .issue_val_o(sched_issue_valid),
      .issue_warp_o(sched_issue_warp)
  );

  assign issue_fire = sched_issue_valid && issue_ready && !global_block;

  issue_exec_reg issue_exec_reg_inst (
      .clk(clk),
      .rst(rst),
      .issue_valid_i(issue_fire),
      .issue_instr_i(instr_head[sched_issue_warp]),
      .issue_pc_i(instr_pc_head[sched_issue_warp]),
      .issue_warp_i(sched_issue_warp),
      .issue_active_mask_i(warp_active_mask[sched_issue_warp]),
      .exec_ready_i(exec_ready),
      .issue_ready_o(issue_ready),
      .exec_valid_o(exec_valid),
      .exec_instr_o(exec_instr),
      .exec_pc_o(exec_pc),
      .exec_warp_o(exec_warp),
      .exec_active_mask_o(exec_active_mask)
  );

  decoder execution_decoder (
      .clk(clk),
      .rst(rst),
      .instr(exec_instr),
      .mem_we_i(exec_mem_we),
      .mem_op(exec_mem_op),
      .alu_op(exec_alu_op),
      .rd_i(exec_rd),
      .rs1_i(exec_rs1),
      .rs2_i(exec_rs2),
      .p_i(exec_preg),
      .imm(exec_imm),
      .cond(exec_cond),
      .mfsr_sel(exec_mfsr_sel),
      .op2_sel(exec_op2_sel),
      .reg_we(exec_reg_we),
      .preg_we(exec_preg_we),
      .wb_sel(exec_wb_sel),
      .branch_valid(exec_branch_valid),
      .branch_predicated(exec_branch_predicated),
      .branch_target_off(exec_branch_target_off),
      .branch_reconv_off(exec_branch_reconv_off),
      .rcnv_valid(exec_rcnv_valid),
      .exit_valid(exec_exit_valid),
      .uses_rs1(),
      .uses_rs2(),
      .uses_preg()
  );

  generate
    for (i = 0; i < NUM_WARPS; i++) begin : warp_control_loop
      warp_control warp_control_inst (
          .clk(clk),
          .rst(rst),
          .external_stall(mem_busy),
          .exec_pc(exec_pc),
          .branch_valid(exec_valid && exec_warp == $clog2(NUM_WARPS)'(i) && exec_branch_valid),
          .branch_predicated(exec_branch_predicated),
          .branch_target_off(exec_branch_target_off),
          .branch_reconv_off(exec_branch_reconv_off),
          .rcnv_valid(exec_valid && exec_warp == $clog2(NUM_WARPS)'(i) && exec_rcnv_valid),
          .exit_valid(exec_valid && exec_warp == $clog2(NUM_WARPS)'(i) && exec_exit_valid),
          .pred_vec(pred_vec),
          .done(warp_done[i]),
          .stalled(warp_stalled[i]),
          .active_mask(warp_active_mask[i]),
          .redir_val(warp_redir_val[i]),
          .redir_pc(warp_redir_pc[i]),
          .error(warp_error[i])
      );
    end
  endgenerate

  always_comb begin
    redir_val  = 0;
    redir_pc   = '0;
    redir_warp = '0;
    for (int i = 0; i < NUM_WARPS; i++) begin
      if (!redir_val && warp_redir_val[i]) begin
        redir_val  = 1;
        redir_pc   = warp_redir_pc[i];
        redir_warp = $clog2(NUM_WARPS)'(i);
      end
    end
  end

  mfsr_read_unit mfsr_read_unit_inst (
      .mfsr_sel(exec_mfsr_sel),
      .warp_id(exec_warp),
      .active_mask(exec_active_mask),
      .mfsr_data(mfsr_data)
  );

  mem_ctrl mem_ctrl_inst (
      .clk(clk),
      .rst(rst),
      .mem_we_i(exec_mem_we),
      .mem_op_i(exec_valid && exec_mem_op),
      .active_mask(exec_active_mask),
      .mem_addr_i(lane_mem_addr),
      .w_mem_data_i(lane_store_data),
      .r_mem_data(mem_read_data),
      .mem_op_o(mem_op),
      .mem_we_o(mem_we),
      .mem_addr_o(mem_addr),
      .w_mem_data_o(mem_write_data),
      .busy(mem_busy),
      .done(mem_done),
      .load_data(load_data),
      .load_writeback_valid(load_writeback_valid),
      .load_writeback_lane(load_writeback_lane),
      .mem_accept(mem_accept)
  );

  data_memory data_memory_inst (
      .clk(clk),
      .rst(rst),
      .we(mem_we),
      .mem_op_i(mem_op),
      .data_addr(mem_addr),
      .w_mem_data(mem_write_data),
      .r_mem_data(mem_read_data)
  );

  assign exec_ready = !exec_valid || !exec_mem_op || mem_done;

  always_comb begin
    for (int i = 0; i < NUM_LANES; i++) begin
      lane_load_data[i] = '0;
      lane_load_we[i]   = 0;
    end

    if (load_writeback_valid) begin
      lane_load_data[load_writeback_lane] = load_data;
      lane_load_we[load_writeback_lane]   = 1;
    end
  end

  genvar j;

  generate
    for (j = 0; j < NUM_LANES; j++) begin : lane_loop

      lane lane_inst (
          .clk(clk),
          .rst(rst),
          .warp_i(exec_warp),
          .mem_op(exec_valid && exec_mem_op),
          .alu_op(exec_alu_op),
          .rd_i(exec_rd),
          .rs1_i(exec_rs1),
          .rs2_i(exec_rs2),
          .p_i(exec_preg),
          .preg_we(exec_valid && exec_preg_we),
          .mfsr_in(mfsr_data[j]),
          .imm(exec_imm),
          .cond(exec_cond),
          .lane_active(exec_active_mask[j]),
          .op2_sel(exec_op2_sel),
          .reg_we(exec_valid && exec_reg_we),
          .load_reg_we(lane_load_we[j]),
          .wb_sel(exec_wb_sel),
          .r_mem_data(lane_load_data[j]),
          .pred_val_o(pred_vec[j]),
          .w_mem_data(lane_store_data[j]),
          .mem_addr(lane_mem_addr[j])
      );
    end
  endgenerate

  always_comb begin
    done_o  = 1;
    error_o = 0;
    for (int i = 0; i < NUM_WARPS; i++) begin
      if (!warp_done[i]) begin
        done_o = 0;
      end
      if (warp_error[i]) begin
        error_o = 1;
      end
    end
  end

endmodule
