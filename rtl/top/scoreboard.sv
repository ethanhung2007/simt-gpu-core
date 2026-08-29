import simt_defs::*;

module scoreboard (
    input logic clk,
    input logic rst,
    input logic [DATA_W-1:0] instr_i[NUM_WARPS-1:0],
    input logic empty_instr_i[NUM_WARPS-1:0],
    output logic reg_dep[NUM_WARPS-1:0], // whether the given warp has depedency
    output logic [4:0] dep_regs[NUM_WARPS-1:0], // which register has a dependency
    output logic preg_dep[NUM_WARPS-1:0],
    output logic [2:0] dep_pregs[NUM_WARPS-1:0]
);

  

endmodule
