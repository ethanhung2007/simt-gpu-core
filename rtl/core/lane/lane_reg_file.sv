import simt_defs::*;

module lane_reg_file (
    input logic rst,
    input logic clk,
    input logic [$clog2(NUM_WARPS)-1:0] warp_i,
    input logic we,
    input logic [31:0] data,
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output logic [31:0] rs1_val,
    output logic [31:0] rs2_val
    //  output logic [31:0] tb_r3_out
);


  logic [DATA_W-1:0] registers[NUM_WARPS-1:0][REG_COUNT-1:0];

  assign rs1_val = registers[warp_i][rs1];
  assign rs2_val = registers[warp_i][rs2];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NUM_WARPS; i++) begin
        for (int j = 0; j < REG_COUNT; j++) begin
          registers[i][j] <= '0;
        end
      end
    end else if (we) begin
      registers[warp_i][rd] <= data;
    end
  end

  //assign tb_r3_out = registers[3];

endmodule
