import simt_defs::*;

module mfsr_read_unit (
    input logic [3:0] mfsr_sel,
    input logic [$clog2(NUM_WARPS)-1:0] warp_id,
    input logic [NUM_LANES-1:0] active_mask,
    output logic [DATA_W-1:0] mfsr_data[NUM_LANES-1:0]
);

  // needs to have a case switch in order to determine what the mfsr data should be

  always_comb begin
    for (int i = 0; i < NUM_LANES; i++) begin
      mfsr_data[i] = 0;
    end
    case (mfsr_sel)
      LANEID: begin
        for (int i = 0; i < NUM_LANES; i++) begin
          mfsr_data[i] = i;
        end
      end
      WARPID: begin
        for (int i = 0; i < NUM_LANES; i++) begin
          mfsr_data[i] = warp_id;
        end
      end
      TID: begin
        for (int i = 0; i < NUM_LANES; i++) begin
          mfsr_data[i] = warp_id * NUM_LANES + i;
        end
      end
      LANEMASK_LT: begin
        for (int i = 0; i < NUM_LANES; i++) begin
          mfsr_data[i] = (1 << i) - 1;
        end
      end
      ACTIVEMASK: begin
        for (int i = 0; i < NUM_LANES; i++) begin
          mfsr_data[i] = DATA_W'(active_mask);
        end
      end
    endcase
  end


endmodule
