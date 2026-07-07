TOP = lane

RTL = ../../rtl/common/simt_defs.sv \
      ../../rtl/warp/lane_alu.sv \
      ../../rtl/warp/lane_reg_file.sv \
      ../../rtl/warp/lane.sv

TB = lane_tb.cpp

build:
	verilator --cc --exe --build --trace -Wall --top-module $(TOP) $(RTL) $(TB)

run:
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir
