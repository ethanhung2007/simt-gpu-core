module lane_reg_file (
    input logic rst,
    input logic clk,
    input logic we,
    input logic [31:0] data,
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output logic [31:0] rs1_val,
    output logic [31:0] rs2_val
//  output logic [31:0] tb_r3_out
);

  import simt_defs::*;

  logic [31:0] registers[31:0];

  assign rs1_val = registers[rs1];
  assign rs2_val = registers[rs2];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < REG_COUNT; i++) registers[i] <= '0;
    end else if (we) registers[rd] <= data;
  end

//assign tb_r3_out = registers[3];

endmodule
