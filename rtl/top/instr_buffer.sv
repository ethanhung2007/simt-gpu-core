import simt_defs::*;

module instr_buffer (
    input logic clk,
    input logic rst,
    input logic [DATA_W-1:0] instr_i,  // comes from instr mem
    input logic [DATA_W-1:0] fetch_pc_i[NUM_WARPS-1:0],  // comes from fetch_control
    input logic issue_val,
    input logic [$clog2(NUM_WARPS)-1:0] issue_warp,
    input logic [$clog2(NUM_WARPS)-1:0] redir_warp,
    input logic redir_val,
    input logic warp_done [NUM_WARPS-1:0],
    output logic [DATA_W-1:0] instr_addr_o,  // goes to instr_mem
    output logic [DATA_W-1:0] instr_o[NUM_WARPS-1:0],
    output logic empty_instr[NUM_WARPS-1:0],
    output logic advance_val,
    output logic [$clog2(NUM_WARPS)-1:0] advance_warp
);

  localparam BUFFER_DEPTH = 16;

  // buffer related signals
  logic [DATA_W-1:0] instr_warp_buffer[NUM_WARPS-1:0][BUFFER_DEPTH-1:0];
  logic [$clog2(BUFFER_DEPTH)-1:0] write_pointer[NUM_WARPS-1:0];
  logic [$clog2(BUFFER_DEPTH)-1:0] read_pointer[NUM_WARPS-1:0];
  logic [$clog2(BUFFER_DEPTH):0] counter[NUM_WARPS-1:0];
  logic buffer_full[NUM_WARPS-1:0];  // 1 if full
  logic buffer_empty[NUM_WARPS-1:0];  // 1 if empty

  // warp related signals
  logic [$clog2(NUM_WARPS)-1:0] cur_warp;

  // mem_delay signals
  logic fetch_pending;
  logic [$clog2(NUM_WARPS)-1:0] pending_warp;

  always_ff @(posedge clk) begin
    if (rst) begin
      cur_warp <= 0;
      fetch_pending <= 0;
      pending_warp <= 0;
      for (int i = 0; i < NUM_WARPS; i++) begin
        write_pointer[i] <= 0;
        read_pointer[i] <= 0;
        counter[i] <= 0;
      end
    end else begin
      fetch_pending <= advance_val;
      if (advance_val) pending_warp <= advance_warp;

      if (fetch_pending && (pending_warp != redir_warp || !redir_val) && !warp_done[pending_warp]) begin
        instr_warp_buffer[pending_warp][write_pointer[pending_warp]] <= instr_i;
        write_pointer[pending_warp] <= write_pointer[pending_warp] + 1;
      end

      if (redir_val) begin
        counter[redir_warp] <= 0;
        read_pointer[redir_warp] <= 0;
        write_pointer[redir_warp] <= 0;
      end

      if (cur_warp == NUM_WARPS - 1) cur_warp <= 0;
      else cur_warp <= cur_warp + 1;

      if ((issue_val && !empty_instr[issue_warp]) && (!redir_val || redir_warp != issue_warp) && !warp_done[issue_warp])
        read_pointer[issue_warp] <= read_pointer[issue_warp] + 1;

      if ((fetch_pending && !(issue_val && !buffer_empty[issue_warp] && pending_warp == issue_warp)) && (pending_warp != redir_warp || !redir_val) && !warp_done[pending_warp]) begin
        counter[pending_warp] <= counter[pending_warp] + 1;
      end
      if ((issue_val && !buffer_empty[issue_warp] && !(fetch_pending && pending_warp == issue_warp)) && (issue_warp != redir_warp || !redir_val) && !warp_done[issue_warp]) begin
        counter[issue_warp] <= counter[issue_warp] - 1;
      end

    end
  end

  assign instr_addr_o = fetch_pc_i[cur_warp];

  always_comb begin
    advance_val = !redir_val && (counter[cur_warp] < BUFFER_DEPTH) && !(fetch_pending && pending_warp == cur_warp && counter[cur_warp] == BUFFER_DEPTH - 1) && !warp_done[cur_warp];
    advance_warp = cur_warp;
    for (int i = 0; i < NUM_WARPS; i++) begin
      buffer_empty[i] = counter[i] == 0;
      buffer_full[i]  = counter[i] == BUFFER_DEPTH;
    end

    for (int i = 0; i < NUM_WARPS; i++) begin
      if (buffer_empty[i]) begin
        empty_instr[i] = 1;
        instr_o[i] = 0;
      end else begin
        empty_instr[i] = 0;
        instr_o[i] = instr_warp_buffer[i][read_pointer[i]];
      end
    end
  end

endmodule
