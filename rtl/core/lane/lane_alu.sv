module lane_alu (
    input logic alu_op,
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    output logic [31:0] res
);

  import simt_defs::*;

  always_comb begin
    if (alu_op) 
      res = rs1_val * rs2_val;
    else 
      res = rs1_val + rs2_val;
  end

endmodule
