#include "Vcore_validation_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdint>
#include <iostream>
#include <memory>
#include <vector>

#define MAX_CYCLES 100

void tick(Vcore_validation_top *dut, VerilatedContext *contextp,
          VerilatedVcdC *tfp);

int main() {

  // initialize verilator context manager
  auto contextp = std::make_unique<VerilatedContext>();

  // instantiate core module
  auto dut = std::make_unique<Vcore_validation_top>(contextp.get());

  // setup waveform tracing
  Verilated::traceEverOn(true);
  auto tfp = std::make_unique<VerilatedVcdC>();
  dut->trace(tfp.get(), 99);
  tfp->open("core_validation_top_waveform.vcd");

  bool passed = true;

  // initial state
  dut->rst = 1;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());

  dut->rst = 0;
  int cycles = 0;

  while (!dut->done_o && !dut->error_o && cycles < MAX_CYCLES) {
    tick(dut.get(), contextp.get(), tfp.get());
    cycles++;
  }

  if (passed) {
    if (dut->error_o) {
      std::cout << "Error in program occured" << std::endl;
      passed = false;
    } else if (!dut->done_o) {
      std::cout << "Test failed, timeout after: " << cycles << " cycles" << std::endl;
      passed = false;
    }
  }

  if (passed)
    std::cout << "Programing passed; completed in " << cycles << " cycles"
              << std::endl;

  dut->final();
  tfp->close();
  return passed ? 0 : 1;
}

void tick(Vcore_validation_top *dut, VerilatedContext *contextp,
          VerilatedVcdC *tfp) {
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
