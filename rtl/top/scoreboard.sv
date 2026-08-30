import simt_defs::*;

module scoreboard ( // checks for RAW and WAW logic. checks for WAW due to the varying cycles depending on instruction
    input logic clk,
    input logic rst,
    input logic [4:0] rs1_i[NUM_WARPS-1:0],
    input logic [4:0] rs2_i[NUM_WARPS-1:0],
    input logic [4:0] rd_i[NUM_WARPS-1:0],
    input logic [2:0] preg_i[NUM_WARPS-1:0],
    input logic [2:0] pregd_i[NUM_WARPS-1:0],
    input logic reg_we_i[NUM_WARPS-1:0],
    input logic uses_rs1_i[NUM_WARPS-1:0],
    input logic uses_rs2_i[NUM_WARPS-1:0],
    input logic uses_preg_i[NUM_WARPS-1:0],
    input logic preg_we_i[NUM_WARPS-1:0],
    input logic issue_val_i,
    input logic [$clog2(NUM_WARPS)-1:0] issue_warp_i,
    input logic [4:0] issue_rd_i,
    input logic issue_reg_we_i,
    input logic [2:0] issue_pregd_i,
    input logic issue_preg_we_i,
    input logic wb_val_i,
    input logic [$clog2(NUM_WARPS)-1:0] wb_warp_i,
    input logic [4:0] wb_rd_i,
    input logic wb_reg_we_i,
    input logic [2:0] wb_pregd_i,
    input logic wb_preg_we_i,
    input logic instr_valid_i[NUM_WARPS-1:0],
    output logic ready_o[NUM_WARPS-1:0]
);

  logic [NUM_WARPS-1:0][ REG_COUNT-1:0] reg_busy;  // uses packed array to clear easier
  logic [NUM_WARPS-1:0][PREG_COUNT-1:0] preg_busy;

  always_ff @(posedge clk) begin
    if (rst) begin
      reg_busy  <= 0;
      preg_busy <= 0;
    end else begin
      if (wb_val_i) begin
        if (wb_reg_we_i) begin
          reg_busy[wb_warp_i][wb_rd_i] <= 0;
        end
        if (wb_preg_we_i) begin
          preg_busy[wb_warp_i][wb_pregd_i] <= 0;
        end
      end
      if (issue_val_i) begin
        if (issue_reg_we_i) begin
          reg_busy[issue_warp_i][issue_rd_i] <= 1;
        end
        if (issue_preg_we_i) begin
          preg_busy[issue_warp_i][issue_pregd_i] <= 1;
        end
      end
    end
  end

  always_comb begin
    ready_o = '{default: 1'b0};  // needs to be done like this becuase unpacked
    for (int i = 0; i < NUM_WARPS; i++) begin
      if (instr_valid_i[i]) begin
        ready_o[i] = 1;
        if (reg_busy[i][rs1_i[i]] && uses_rs1_i[i]) ready_o[i] = 0;
        if (reg_busy[i][rs2_i[i]] && uses_rs2_i[i]) ready_o[i] = 0;
        if (preg_busy[i][preg_i[i]] && uses_preg_i[i]) ready_o[i] = 0;
        if (reg_busy[i][rd_i[i]] && reg_we_i[i]) ready_o[i] = 0;
        if (preg_busy[i][pregd_i[i]] && preg_we_i[i]) ready_o[i] = 0;
      end
    end
  end

endmodule
