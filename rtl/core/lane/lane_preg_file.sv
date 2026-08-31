import simt_defs::*;

module lane_preg_file (
    input logic rst,
    input logic clk,
    input logic we,
    input logic pdata,
    input logic [$clog2(NUM_WARPS)-1:0] warp_i,
    input logic [2:0] prd,
    input logic [2:0] prs,
    output logic prs_val
);


  logic [PREG_COUNT-1:0] pregisters[NUM_WARPS-1:0];

  assign prs_val = pregisters[warp_i][prs];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NUM_WARPS; i++) begin
        pregisters[i] <= '0;
      end
    end else if (we) begin
      pregisters[warp_i][prd] <= pdata;
    end
  end

endmodule
