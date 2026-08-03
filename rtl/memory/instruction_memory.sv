import simt_defs::*;

module instruction_memory (
    input logic clk,
    input logic [DATA_W-1:0] instr_addr,
    output logic [DATA_W-1:0] instr
);

  (* ram_style = "block" *) logic [DATA_W-1:0] instr_mem[255:0];

  initial begin
    $readmemh("out.hex", instr_mem); // puts output of assembler into memory
  end

  always_ff @(posedge clk) begin
    instr <= instr_mem[instr_addr[9:2]]; // 9:2 because bits 1 and 0 are always zero; bits 9:2 provide 8 bit index
  end

endmodule
