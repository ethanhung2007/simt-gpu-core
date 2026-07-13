import simt_defs::*;

module warp_simt_stack (
    input logic clk,
    input logic en,
    input logic rst,
    input logic [1:0] op,  // 2 for clear_deferred , 1 for push, 0 for pop
    output logic [1:0] ret_code,  // 0 for success, 1 for push when full, 2 for pop/peak when empty
    input simt_stack_entry_t push_entry,
    output simt_stack_entry_t stack_output
);

  simt_stack_entry_t stack[31:0];
  logic [5:0] sp;

  always_comb begin
    if (sp == 0)
      stack_output = 0;
    else 
      stack_output = stack[sp - 1];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      ret_code <= 0;
      sp <= '0;
      for (int i = 0; i < 32; i++) stack[i] <= '0;
    end else if (en) begin
      if (op == 0) begin
        if (sp == 0) ret_code <= 2;
        else begin
          ret_code <= 0;
          sp <= sp - 1;
        end
      end else if (op == 1) begin
        if (sp == 32) ret_code <= 1;
        else begin
          ret_code <= 0;
          stack[sp] <= push_entry;
          sp <= sp + 1;
        end
      end else if (op == 2) begin
        if (sp == 0) begin
          ret_code <= 2;
        end else begin
          ret_code <= 0;
          stack[sp - 1].deferred_valid <= 0;
        end
      end
    end
  end

endmodule
