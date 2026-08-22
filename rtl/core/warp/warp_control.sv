import simt_defs::*;

module warp_control #(
    parameter int NUM_WARP_LANES = NUM_LANES
) (
    input logic clk,
    input logic rst,
    input logic external_stall,
    input logic branch_valid,
    input logic branch_predicated,
    input logic [DATA_W-1:0] branch_target_off,
    input logic [DATA_W-1:0] branch_reconv_off,
    input logic rcnv_valid,
    input logic exit_valid,
    input logic [NUM_WARP_LANES-1:0] pred_vec,
    output logic done,
    output logic stalled,
    output logic [DATA_W-1:0] pc,
    output logic [NUM_WARP_LANES-1:0] active_mask,
    output logic error
);


  logic stack_en;
  logic [1:0] stack_ret_code;  // 0 for success, 1 for push when full, 2 for pop when empty
  logic [1:0] stack_op;  // 2 for clear_deferred , 1 for push, 0 for pop
  logic [DATA_W-1:0] brap_target_pc, brap_fallthrough_pc, brap_reconv_pc;
  logic [NUM_WARP_LANES-1:0] taken_mask, fallthrough_mask;

  logic stack_empty;
  logic stack_full;

  typedef enum logic [2:0] {
    NORMAL,
    BRAP_RESOLVE,
    RCNV_RESOLVE,
    DONE,
    ERROR
  } state_t;

  state_t state, next_state;

  simt_stack_entry_t push_entry;
  simt_stack_entry_t top_entry;

  warp_simt_stack simt_stack (
      .clk(clk),
      .en(stack_en),
      .rst(rst),
      .op(stack_op),
      .ret_code(stack_ret_code),
      .push_entry(push_entry),
      .stack_output(top_entry),
      .stack_full(stack_full),
      .stack_empty(stack_empty)
  );

  // update fsm comb block
  always_comb begin
    case (state)
      NORMAL: begin
        if (exit_valid) next_state = DONE;
        else if (branch_predicated && branch_valid) next_state = BRAP_RESOLVE;
        else if (rcnv_valid) next_state = RCNV_RESOLVE;
        else next_state = NORMAL;
      end
      BRAP_RESOLVE: next_state = stack_full ? ERROR : NORMAL;
      RCNV_RESOLVE: next_state = stack_empty ? ERROR : NORMAL;
      DONE: next_state = DONE;
      ERROR: next_state = ERROR;
      default: next_state = state;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= '0;  // starting pc set as 0 for now
      active_mask <= {NUM_WARP_LANES{1'b1}};
      done <= '0;
      state <= NORMAL;
      brap_target_pc <= '0;
      brap_fallthrough_pc <= '0;
      brap_reconv_pc <= '0;
      taken_mask <= '0;
      fallthrough_mask <= '0;
    end else if (!external_stall) begin
      state <= next_state;
      if (state == NORMAL) begin
        if (branch_valid) begin
          if (branch_predicated) begin
            brap_target_pc <= pc + (branch_target_off << 2); // offsets are encoded in 32 bit instruction units
            brap_fallthrough_pc <= pc + 4;
            brap_reconv_pc <= pc + (branch_reconv_off << 2);
            taken_mask <= active_mask & pred_vec;
            fallthrough_mask <= active_mask & (~pred_vec);
          end else begin
            pc <= pc + (branch_target_off << 2);
          end
        end else if (exit_valid) begin
          done <= 1;
          active_mask <= '0;
        end else
        if (rcnv_valid) begin
        end else begin
          pc <= pc + 4;
        end
      end else if (state == BRAP_RESOLVE) begin
        if (!stack_full) begin
          if (taken_mask == 0) pc <= brap_fallthrough_pc;
          else if (fallthrough_mask == 0) pc <= brap_target_pc;
          else begin
            active_mask <= taken_mask;
            pc <= brap_target_pc;
          end
        end
      end else if (state == RCNV_RESOLVE) begin
        if (!stack_empty) begin
          if (top_entry.deferred_valid == 1) begin
            pc <= top_entry.deferred_pc;
            active_mask <= top_entry.deferred_mask;
          end else begin
            pc <= top_entry.reconv_pc;
            active_mask <= top_entry.reconv_mask;
          end
        end
      end else if (state == ERROR) begin
        done <= 1;
        active_mask <= '0;
      end else if (state == DONE) begin
        done <= 1;
        active_mask <= '0;
      end
    end
  end

  // combinational logic block
  always_comb begin
    stalled = state != NORMAL || external_stall;
    stack_en = 0;
    stack_op = 1;
    push_entry = '0;
    error = (state == ERROR);

    if (!external_stall) begin
      if (state == BRAP_RESOLVE && taken_mask != '0 && fallthrough_mask != '0) begin
        if (!stack_full) begin
          stack_op = 1;
          push_entry.deferred_valid = 1;
          push_entry.deferred_pc = brap_fallthrough_pc;
          push_entry.deferred_mask = fallthrough_mask;
          push_entry.reconv_pc = brap_reconv_pc;
          push_entry.reconv_mask = active_mask;
          stack_en = 1;
        end
      end else if (state == BRAP_RESOLVE && (taken_mask != '0 || fallthrough_mask != '0)) begin
        if (!stack_full) begin
          stack_op = 1;
          push_entry.deferred_valid = 0;
          push_entry.reconv_pc = brap_reconv_pc;
          push_entry.reconv_mask = active_mask;
          stack_en = 1;
        end
      end else if (state == RCNV_RESOLVE) begin
        if (!stack_empty) begin
          stack_en = 1;
          if (top_entry.deferred_valid == 1) stack_op = 2;
          else stack_op = 0;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst && !external_stall && state == NORMAL) begin
      assert ($onehot0({branch_valid, rcnv_valid, exit_valid}))
      else $error("Multiple control instructions valid at once");
    end
  end


endmodule
