module lane_adder (
    input logic [31:0] in1,
    input logic [31:0] in2,
    output logic [31:0] res
);

  import simt_defs::*;

  always_comb begin
    res = in1 + in2;
  end

endmodule
