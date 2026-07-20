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
  dut->instr = 0;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());

  dut->rst = 0;
  int cycles = 0;

  std::vector<uint32_t> program = {
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

  while (!dut->done_o && !dut->error_o && cycles < MAX_CYCLES) {
    uint32_t pc = dut->pc_o;
    uint32_t index = pc >> 2;

    if (index >= program.size()) {
      std::cout << "Test failed: PC out of range: 0x" << std::hex << pc << std::dec << std::endl;
      passed = false;
      break;
    }

    dut->instr = program.at(index);

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

  if (passed) {
    for (int i = 0; i < 4; i++) {
      if (dut->tb_r3_out[i] != 11) {
        std::cout << "Test failed, lane " << i << " final r3 value incorrect" << std::endl;
        std::cout << "Lane " << i << " r3 value: " << dut->tb_r3_out[i] << std::endl;
        passed = false;
      }
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
