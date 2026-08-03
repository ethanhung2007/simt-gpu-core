import simt_defs::*;

module data_memory (
    input logic clk,
    input logic rst,
    input logic we,
    input logic mem_op_i,
    input logic [DATA_W-1:0] data_addr,
    input logic [DATA_W-1:0] w_mem_data,
    output logic [DATA_W-1:0] r_mem_data
);

  logic [7:0] word_index;

  (* ram_style = "block" *) logic [DATA_W-1:0] data_mem[255:0];

  assign word_index = data_addr[9:2];
  
  always_ff @(posedge clk) begin
    if (mem_op_i) begin
      if (we) begin
        data_mem[word_index] <= w_mem_data;
      end else begin
        r_mem_data <= data_mem[word_index];
      end
    end
  end

endmodule
