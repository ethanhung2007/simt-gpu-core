import simt_defs::*;

module fetch_control (
    input logic clk,
    input logic rst,
    input logic advance_val,
    input logic [$clog2(NUM_WARPS)-1:0] advance_warp,
    input logic redir_val,  // if branch or brap from warp_control 
    input logic [DATA_W-1:0] redir_pc,
    input logic [$clog2(NUM_WARPS)-1:0] redir_warp,
    output logic [DATA_W-1:0] fetch_pc[NUM_WARPS-1:0]
);

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NUM_WARPS; i++) begin
        fetch_pc[i] <= 0;
      end
    end else if (redir_val) begin
      fetch_pc[redir_warp] <= redir_pc;
    end else if (advance_val) begin
      fetch_pc[advance_warp] <= fetch_pc[advance_warp] + 4;
    end
  end

endmodule
