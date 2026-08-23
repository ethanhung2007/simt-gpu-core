package simt_defs;

  parameter int DATA_W = 32;
  parameter int NUM_LANES = 4;
  parameter int REG_COUNT = 32;
  parameter int PREG_COUNT = 8;

  typedef enum logic [3:0] {
    OP_ADD  = 4'h0,
    OP_MUL  = 4'h1,
    OP_LDG  = 4'h2,
    OP_STG  = 4'h3,
    OP_BRA  = 4'h4,
    OP_PRED = 4'h5,
    OP_BRAP = 4'h6,
    OP_RCNV = 4'h7,
    OP_MOV  = 4'h8,
    OP_EXIT = 4'h9,
    OP_MFSR = 4'h10
  } opcode_t;

  typedef enum logic [1:0] {
    ALU_RESULT,
    IMM_RESULT,
    MEM_DATA,
    WB_MFSR
  } wb_sel_t;

  typedef enum logic [3:0] {
    LANEID,
    WARPID,
    TID,
    LANEMASK_LT,
    ACTIVEMASK
  } mfsr_opt_t;

  typedef struct packed {
    logic deferred_valid;
    logic [DATA_W-1:0] deferred_pc;
    logic [NUM_LANES-1:0] deferred_mask;
    logic [DATA_W-1:0] reconv_pc;
    logic [NUM_LANES-1:0] reconv_mask;
  } simt_stack_entry_t;

endpackage
