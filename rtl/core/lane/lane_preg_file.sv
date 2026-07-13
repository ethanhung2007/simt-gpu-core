module lane_preg_file (
    input logic rst,
    input logic clk,
    input logic we,
    input logic pdata,
    input logic [2:0] prd,
    input logic [2:0] prs,
    output logic prs_val
);

  import simt_defs::*;

  logic [PREG_COUNT - 1:0] pregisters;

  assign prs_val = pregisters[prs];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < PREG_COUNT; i++) pregisters[i] <= '0;
    end else if (we) pregisters[prd] <= pdata;
    end

endmodule

