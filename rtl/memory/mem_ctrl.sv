import simt_defs::*;

module mem_ctrl (
    input logic clk,
    input logic rst,
    input logic mem_we_i,
    input logic mem_op_i,
    input logic [NUM_LANES-1:0] active_mask,
    input logic [DATA_W-1:0] mem_addr_i[NUM_LANES-1:0],
    input logic [DATA_W-1:0] w_mem_data_i[NUM_LANES-1:0], // input from lanes to write into data mem
    input logic [DATA_W-1:0] r_mem_data,  // input from data mem to load into lanes
    output logic mem_op_o,
    output logic mem_we_o,
    output logic [DATA_W-1:0] mem_addr_o,
    output logic [DATA_W-1:0] w_mem_data_o,
    output logic busy,
    output logic done,
    output logic [DATA_W-1:0] load_data,  // load into lanes
    output logic load_writeback_valid,
    output logic [$clog2(NUM_LANES)-1:0] load_writeback_lane,
    output logic mem_accept // logic for saved_rd, allowing for future implementation for pipelining
);

  typedef enum logic [3:0] {
    IDLE,
    STORE,
    LOAD_FIRST,
    LOAD_STREAM,
    LOAD_DRAIN,
    DONE
  } state_t;

  state_t state, next_state;


  // controller needs to save certain internal info, s for save, r for registered
  logic [NUM_LANES-1:0] active_mask_s, active_mask_r;
  logic [$clog2(
NUM_LANES
)-1:0] current_lane_s;  // current: address sent to memory now; pending: previous send
  logic [$clog2(NUM_LANES)-1:0] current_lane_r, pending_lane_r;

  logic valid_lane;  // determines whether there is a valid next lane

  int   i;  // will be used in priority encoders, needs to be outside the loop for scope purposes

  assign mem_accept = state == IDLE && mem_op_i && valid_lane;

  // next_state always block
  always_comb begin
    case (state)
      IDLE: next_state = (mem_op_i && valid_lane) ? (mem_we_i ? STORE : LOAD_FIRST) : IDLE;
      STORE: next_state = valid_lane ? STORE : DONE;
      LOAD_FIRST: next_state = valid_lane ? LOAD_STREAM : LOAD_DRAIN;
      LOAD_STREAM: next_state = valid_lane ? LOAD_STREAM : LOAD_DRAIN;
      LOAD_DRAIN: next_state = DONE;
      DONE: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      active_mask_r <= 0;
      current_lane_r <= 0;
      pending_lane_r <= 0;
      done <= 0;
    end else begin
      state <= next_state;
      if (state == IDLE) begin
        if (mem_op_i && valid_lane) begin
          active_mask_r  <= active_mask_s;
          current_lane_r <= current_lane_s;
        end
      end else if (state == STORE) begin
        if (next_state == DONE) done <= 1;
        active_mask_r  <= active_mask_s;
        current_lane_r <= current_lane_s;
      end else if (state == LOAD_FIRST) begin
        active_mask_r  <= active_mask_s;
        current_lane_r <= current_lane_s;
        pending_lane_r <= current_lane_r;
      end else if (state == LOAD_STREAM) begin
        active_mask_r  <= active_mask_s;
        current_lane_r <= current_lane_s;
        pending_lane_r <= current_lane_r;
      end else if (state == LOAD_DRAIN) begin
        done <= 1;
      end else if (state == DONE) begin
        done <= 0;
      end
    end
  end

  always_comb begin // priority encoder always block; seperate for now might merge into main as i figure out logic
    current_lane_s = 0;
    if (state == IDLE) active_mask_s = active_mask;
    else active_mask_s = active_mask_r;
    valid_lane = 0;
    for (
        i = 0; i < NUM_LANES; i++
    ) begin  // priority encoder (MSB highest) to determine next lane
      if (active_mask_s[i]) begin
        valid_lane = 1;
        current_lane_s = i;
      end
    end
    if (valid_lane)
      active_mask_s[current_lane_s] = 0; // need to set the lane that is being worked on to 0 to find next lane later on
  end

  always_comb begin
    mem_we_o = 0;
    mem_op_o = 0;
    mem_addr_o = 0;
    w_mem_data_o = 0;
    load_data = 0;
    load_writeback_lane = 0;
    load_writeback_valid = 0;
    if (state == STORE) begin
      mem_addr_o = mem_addr_i[current_lane_r];
      w_mem_data_o = w_mem_data_i[current_lane_r];
      mem_we_o = 1;
      mem_op_o = 1;
    end else if (state == LOAD_FIRST) begin
      mem_addr_o = mem_addr_i[current_lane_r];
      mem_op_o   = 1;
    end else if (state == LOAD_STREAM) begin
      mem_addr_o = mem_addr_i[current_lane_r];
      mem_op_o = 1;
      load_data = r_mem_data;
      load_writeback_lane = pending_lane_r;
      load_writeback_valid = 1;
    end else if (state == LOAD_DRAIN) begin
      load_data = r_mem_data;
      load_writeback_lane = pending_lane_r;
      load_writeback_valid = 1;
    end
  end


  assign busy = next_state != IDLE;



endmodule
