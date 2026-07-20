#include "Vcore_validation_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>

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

  dut->rst = 0;

  // MOV r1, 5
  dut->instr = 0x80800005;
  tick(dut.get(), contextp.get(), tfp.get());

  dut->instr = 0x81000007;
  tick(dut.get(), contextp.get(), tfp.get());

  // ADD r3, r1, r2
  dut->instr = 0x01844000;
  tick(dut.get(), contextp.get(), tfp.get());

  // MUL r4, r3, r2
  dut->instr = 0x120c4000;
  tick(dut.get(), contextp.get(), tfp.get());

  // STG r4, 0(r0)
  dut->instr = 0x32000000;
  tick(dut.get(), contextp.get(), tfp.get());

  for (int i = 0; i < 4; i++) {
    if (dut->w_mem_data[i] == 84) { std::cout << "MOV, ADD, MUL, STG values correct for lane" << i
                << std::endl;
    } else {
      std::cout << "MOV, ADD, MUL, STG values incorrect; R4[" << i << "] != 84"
                << std::endl;
      std::cout << "w_mem_data[" << i << "] output: " << dut->w_mem_data[i]
                << std::endl;
    }
  }

  // LDG r1, 0(r0)
  dut->instr = 0x20800000;
  for (int i = 0; i < 4; i++) {
    dut->r_mem_data[i] = 10 * (i + 1);
  }
  tick(dut.get(), contextp.get(), tfp.get());

  // STG r1, 4(r0)
  dut->instr = 0x30800004;
  tick(dut.get(), contextp.get(), tfp.get());

  for (int i = 0; i < 4; i++) {
    if (dut->w_mem_data[i] == 10 * (i + 1)) {
      std::cout << "LDG test passed for lane" << i << std::endl;
    } else {
      std::cout << "LDG test failed for lane" << i << std::endl;
      std::cout << "w_mem_data[" << i << "] output: " << dut->w_mem_data[i]
                << std::endl;
    }
  }

  for (int i = 0; i < 4; i++) {
    if (dut->mem_addr[i] == 4) {
      std::cout << "STG addr calculation test passed for lane" << i
                << std::endl;
    } else {
      std::cout << "STG addr calculation test failed for lane" << i
                << std::endl;
      std::cout << "mem_addr[" << i << "] output: " << dut->mem_addr[i]
                << std::endl;
    }
  }

  // MOV R2, 25
  dut->instr = 0x81000019;
  tick(dut.get(), contextp.get(), tfp.get());

  // PRED P0, R1, R2, LT
  dut->instr = 0x50111000;
  tick(dut.get(), contextp.get(), tfp.get());

  if (dut->pred_vec_o == 3)
    std::cout << "PRED vector value correct" << std::endl;
  else {
    std::cout << "PRED vector value incorrect" << std::endl;
    std::cout << "pred_vec: " << static_cast<int>(dut->pred_vec_o) << std::endl;
  }

  // BRAP P0, taken, reconverged
  dut->instr = 0x6000600a;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());

  if (dut->active_mask_o == 3)
    std::cout << "BRAP initial test passed; active_mask correct" << std::endl;
  else {
    std::cout << "BRAP initial test failed; active_mask incorrect" << std::endl;
    std::cout << "active_mask: " << static_cast<int>(dut->active_mask_o) << std::endl;
  }

  // taken: MOV r3, 11
  dut->instr = 0x8180000b;
  tick(dut.get(), contextp.get(), tfp.get());

  // RCNV
  dut->instr = 0x70000000;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());

  if (dut->active_mask_o == 12)
    std::cout << "RCNV test passed; active_mask correct" << std::endl;
  else {
    std::cout << "RCNV test failed; active_mask incorrect" << std::endl;
    std::cout << "active_mask: " << static_cast<int>(dut->active_mask_o) << std::endl;
  }

  // MOV r3, 22
  dut->instr = 0x81800016;
  tick(dut.get(), contextp.get(), tfp.get());

  // RCNV
  dut->instr = 0x70000000;
  tick(dut.get(), contextp.get(), tfp.get());
  tick(dut.get(), contextp.get(), tfp.get());
  if (dut->active_mask_o == 15)
    std::cout << "RCNV test passed; active_mask correct" << std::endl;
  else {
    std::cout << "RCNV test failed; active_mask incorrect" << std::endl;
    std::cout << "active_mask: " << static_cast<int>(dut->active_mask_o) << std::endl;
  }

  // reconverged: STG r3, 8(r0)
  dut->instr = 0x31800008;
  tick(dut.get(), contextp.get(), tfp.get());

  if (dut->w_mem_data[0] == 11)
    std::cout << "Lane 0 final value correct" << std::endl;
  else {
    std::cout << "Lane 0 final value incorrect" << std::endl;
    std::cout << "Lane 0 value: " << dut->w_mem_data[0] << std::endl;
  }

  if (dut->w_mem_data[1] == 11)
    std::cout << "Lane 1 final value correct" << std::endl;
  else {
    std::cout << "Lane 1 final value incorrect" << std::endl;
    std::cout << "Lane 1 value: " << dut->w_mem_data[1] << std::endl;
  }

  if (dut->w_mem_data[2] == 22)
    std::cout << "Lane 2 final value correct" << std::endl;
  else {
    std::cout << "Lane 2 final value incorrect" << std::endl;
    std::cout << "Lane 2 value: " << dut->w_mem_data[2] << std::endl;
  }

  if (dut->w_mem_data[3] == 22)
    std::cout << "Lane 3 final value correct" << std::endl;
  else {
    std::cout << "Lane 3 final value incorrect" << std::endl;
    std::cout << "Lane 3 value: " << dut->w_mem_data[3] << std::endl;
  }

  // exit
  dut->instr = 0x90000000;
  tick(dut.get(), contextp.get(), tfp.get());

  if (dut->exit_valid_o && dut->done_o && dut->active_mask_o == 0) {
    std::cout << "EXIT passed" << std::endl;
  }
  else std::cout << "EXIT failed" << std::endl;

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
