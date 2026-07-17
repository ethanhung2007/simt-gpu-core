#include <iostream>
#include <memory>
#include "Vlane.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

void tick(Vlane* dut, VerilatedContext* contextp, VerilatedVcdC* tfp) ;

int main() {

  // initialize verilator context manager
  auto contextp = std::make_unique<VerilatedContext>(); 

  // instantiate lane module
  auto dut = std::make_unique<Vlane>(contextp.get()); 

  // setup waveform tracing
  Verilated::traceEverOn(true);
  auto tfp = std::make_unique<VerilatedVcdC>();
  dut->trace(tfp.get(), 99);
  tfp->open("lane_waveform.vcd");

  // initial state
  dut->clk = 0;
  dut->rst = 0;
  dut->we = 0;
  dut->alu_op = 0;
  dut->op2_sel = 0;
  dut->wb_sel = 0; 
  dut->rd_i = 0;
  dut->rs1_i = 0;
  dut->rs2_i = 0;
  dut->imm = 0;

  // drive MOV R3, 8
  dut->rd_i = 3;
  dut->imm = 8;
  dut->we = 1;
  dut->op2_sel = 0;
  dut->wb_sel = 1;
  tick(dut.get(), contextp.get(), tfp.get());

  dut->we = 0;
  dut->rs1_i = 3;
  dut->eval();

  if (dut->debug_rs1_val != 8) std::cout << "Write Failed; R3 != 8" << std::endl; 

  // test rst
  dut->rst = 1;
  tick(dut.get(), contextp.get(), tfp.get());
  dut->rst = 0;

  dut->we = 0;
  dut->rs1_i = 3;
  dut->eval();

  if (dut->debug_rs1_val != 0) std::cout << "Reset Failed" << std::endl; 
  else std::cout << "Reset Passed" << std::endl;

  // drive MOV R1, 5
  dut->rd_i = 1;
  dut->imm = 5;
  dut->we = 1;
  dut->op2_sel = 0;
  dut->wb_sel = 1;
  tick(dut.get(), contextp.get(), tfp.get());

  // drive MOV R2, 7
  dut->rd_i = 2;
  dut->imm = 7;
  dut->we = 1;
  dut->op2_sel = 0;
  dut->wb_sel = 1;
  tick(dut.get(), contextp.get(), tfp.get());

  // drive ADD R3, R1, R2
  dut->rd_i = 3;
  dut->rs1_i = 1;
  dut->rs2_i = 2;
  dut->we = 1;
  dut->op2_sel = 1;
  dut->alu_op = 0;
  dut->wb_sel = 0;
  tick(dut.get(), contextp.get(), tfp.get());

  // check R3 == 12
  dut->we = 0;
  dut->rs1_i = 3;
  dut->eval();

  if (dut->debug_rs1_val == 12) {
      std::cout << "ADD Test Passed" << std::endl;
  } else {
      std::cout << "ADD Test Failed; R3 != 12" << std::endl;
  }

  // drive MOV R1, 6
  dut->rd_i = 1;
  dut->imm = 6;
  dut->we = 1;
  dut->op2_sel = 0;
  dut->wb_sel = 1;
  tick(dut.get(), contextp.get(), tfp.get());

  // drive MUL R3, R1, R2
  dut->rd_i = 3;
  dut->rs1_i = 1;
  dut->rs2_i = 2;
  dut->we = 1;
  dut->op2_sel = 1;
  dut->alu_op = 1;
  dut->wb_sel = 0;
  tick(dut.get(), contextp.get(), tfp.get());

  // check R3 == 42
  dut->we = 0;
  dut->rs1_i = 3;
  dut->eval();

  if (dut->debug_rs1_val == 42) {
      std::cout << "MUL Test Passed" << std::endl;
  } else {
      std::cout << "MUL Test Failed; R3 != 42" << std::endl;
  }

    dut->final();
    tfp->close();
    return 0;
  } 

void tick(Vlane* dut, VerilatedContext* contextp, VerilatedVcdC* tfp) {
    dut->clk = 0;
    dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);

    dut->clk = 1;
    dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);

    dut->clk = 0;
    dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}
