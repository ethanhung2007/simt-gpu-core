from enum import IntEnum

opcodes = {"add" : 0,
           "mul" : 1,
           "ldg" : 2,
           "stg" : 3,
           "bra" : 4,
           "pred" : 5,
           "brap" : 6,
           "rcnv" : 7,
           "mov" : 8,
           "exit" : 9}

INSTR_WIDTH = 32
REGS_NUM = 32
LANES_NUM = 8
PREGS_NUM = 8

CONDITION_CODES = {"lt" : 1,
                   "eq" : 2,
                   "gt" : 4}

INSTRUCTIONS = ["add", "mul", "ldg", "stg", "bra", "pred", "brap", "rcnv", "mov", "exit"]
