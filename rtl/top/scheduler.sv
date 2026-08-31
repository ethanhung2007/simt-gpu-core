import simt_defs::*;

module scheduler (
    input logic clk,
    input logic rst,
    input logic ready_i[NUM_WARPS-1:0],
    input logic issue_accept_i,
    output logic issue_val_o,
    output logic [$clog2(NUM_WARPS)-1:0] issue_warp_o
);

  logic [$clog2(NUM_WARPS)-1:0] rr_ptr;
  logic found;
  logic [$clog2(NUM_WARPS):0] candidate;

  always_ff @(posedge clk) begin
    if (rst) begin
      rr_ptr <= 0;
    end else if (issue_accept_i) begin
      if (issue_warp_o == NUM_WARPS - 1) rr_ptr <= 0;
      else rr_ptr <= issue_warp_o + 1;
    end
  end

  always_comb begin
    issue_val_o = 0;
    issue_warp_o = rr_ptr;
    found = 0;
    for (int i = 0; i < NUM_WARPS; i++) begin
      candidate = rr_ptr + i;

      if (candidate >= NUM_WARPS) candidate = candidate - NUM_WARPS;

      if (!found && ready_i[candidate]) begin
        issue_val_o = 1;
        issue_warp_o = candidate[$clog2(NUM_WARPS)-1:0];
        found = 1;
      end
    end
  end

endmodule
