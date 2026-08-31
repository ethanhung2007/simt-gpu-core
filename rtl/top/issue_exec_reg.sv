import simt_defs::*;

module issue_exec_reg (
    input logic clk,
    input logic rst,
    input logic issue_valid_i,
    input logic [DATA_W-1:0] issue_instr_i,
    input logic [DATA_W-1:0] issue_pc_i,
    input logic [$clog2(NUM_WARPS)-1:0] issue_warp_i,
    input logic [NUM_LANES-1:0] issue_active_mask_i,
    input logic exec_ready_i,
    output logic issue_ready_o,
    output logic exec_valid_o,
    output logic [DATA_W-1:0] exec_instr_o,
    output logic [DATA_W-1:0] exec_pc_o,
    output logic [$clog2(NUM_WARPS)-1:0] exec_warp_o,
    output logic [NUM_LANES-1:0] exec_active_mask_o
);

  always_comb begin
    issue_ready_o = !exec_valid_o || exec_ready_i;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      exec_valid_o <= 0;
      exec_instr_o <= 0;
      exec_pc_o <= 0;
      exec_warp_o <= 0;
      exec_active_mask_o <= 0;
    end else if (issue_ready_o) begin
      exec_valid_o <= issue_valid_i;
      if (issue_valid_i) begin
        exec_instr_o <= issue_instr_i;
        exec_pc_o <= issue_pc_i;
        exec_warp_o <= issue_warp_i;
        exec_active_mask_o <= issue_active_mask_i;
      end
    end
  end

endmodule
