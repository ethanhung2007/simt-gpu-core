TOP := core_validation_top
TB  := core_tb.cpp

ROOT := ../../..

RTL := \
	$(ROOT)/rtl/common/simt_defs.sv \
	$(ROOT)/rtl/core/lane/lane_adder.sv \
	$(ROOT)/rtl/core/lane/lane_alu.sv \
	$(ROOT)/rtl/core/lane/lane_comparator.sv \
	$(ROOT)/rtl/core/lane/lane_preg_file.sv \
	$(ROOT)/rtl/core/lane/lane_reg_file.sv \
	$(ROOT)/rtl/core/lane/lane.sv \
	$(ROOT)/rtl/core/decoder.sv \
	$(ROOT)/rtl/core/warp/warp_simt_stack.sv \
	$(ROOT)/rtl/core/warp/warp_control.sv \
	$(ROOT)/rtl/memory/instruction_memory.sv \
	$(ROOT)/rtl/memory/data_memory.sv \
	$(ROOT)/rtl/memory/mem_ctrl.sv \
	$(ROOT)/rtl/core/mfsr_read_unit.sv \
	$(ROOT)/rtl/core/core_validation_top.sv

OBJ_DIR := obj_dir
WAVE := core_validation_top_waveform.vcd

VERILATOR_FLAGS := \
	--cc \
	--exe \
	--build \
	--trace \
	--top-module $(TOP) \
	--Mdir $(OBJ_DIR) \
	-Wall \
	-Wno-fatal

.PHONY: all run wave lint clean

all:
	verilator $(VERILATOR_FLAGS) $(RTL) $(TB)

run: all
	./$(OBJ_DIR)/V$(TOP)

wave: run
	surfer $(WAVE)

lint:
	verilator \
		--lint-only \
		-Wall \
		-Wno-fatal \
		--top-module $(TOP) \
		$(RTL)

clean:
	rm -rf $(OBJ_DIR) $(WAVE)
