module lane_comparator (
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    input logic [2:0] cond,
    output logic res // 1 if true, 0 if false
);

always_comb begin
  case (cond) 
    3'b100: res = (rs1_val > rs2_val) ? 1 : 0;
    3'b010: res = (rs1_val == rs2_val) ? 1 : 0;
    3'b001: res = (rs1_val < rs2_val) ? 1 : 0;
  endcase
end

endmodule
