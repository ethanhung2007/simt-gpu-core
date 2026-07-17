#include "Vcore_validation_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <vector>
#include <cstdint>

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

  // initial state
  dut->rst = 1;
  dut->instr = 0;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());

  dut->rst = 0;
  int cycles = 0;

  std::vector<int> program = {
    0x80800005,
    0x81000007,
    0x01844000,
    0x120c4000,
    0x32000000,
    0x20800000,
    0x30800004,
    0x81000019,
    0x50111000,
    0x6000600a,
    0x81800016,
    0x70000000,
    0x8180000b,
    0x70000000,
    0x31800004,
    0x90000000,
  };

  while (!dut->done && cycles < MAX_CYCLES) {
    int pc = dut->pc_o;

    dut->instr = program.at(pc >> 2);

    tick(dut.get(), contextp.get(), tfp.get());
    cycles++;
  }

  dut->final();
  tfp->close();
  return 0;
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
