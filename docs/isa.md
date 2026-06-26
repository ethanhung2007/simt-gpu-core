# WARP ISA

## Overview

The WARP ISA is a 32-bit wide ISA with 32 regular and 8 predicate registers. There are currently 10 instructions that use 4 bit opcodes. Additional registers include PC, am (active mask), and sp (stack pointer). Each warp also supports 8 lanes (hence am register is 8 bits wide). 

## Instruction Set Summary

### ADD 

```text 
Direct integer add. 

Format:
ADD rd, rs1, rs2

Semantics:
for each active lane i:
   rd[i] = rs1[i] + rs2[i]


Example:
ADD R2, R1, R0    ; R2[i] = R1[i] + R0[i]
```

### MUL

```text
Direct integer multiply, keeping the lower 32 bits. 

Format:
MUL rd, rs1, rs2

Semantics:
for each active lane i:
   rd[i] = (rs1[i] * rs2[i])[31:0]

Example:
MUL R2, R1, R0    ; R2[i] = (R1[i] * R0[i])[31:0]
```

### LDG

```tex
Direct global-memory load into a register.

Format:
LDG rd, imm(rb)

Semantics:
for each active lane i:
  rd[i] = global_mem[rb[i] + imm]

Inactive lanes do not perform memory access.

Example:
LDG R2, 5(R1)    ; R2[i] = global_mem[R1[i] + 5]
```

### STG

```text
Direct global-memory store from a register.

Format:
STG rs, imm(rb)

Semantics:
for each active lane i:
  global_mem[rb[i] + imm] = rs[i] 

Inactive lanes do not perform memory access.

Example:
STG R2, 5(R1)    ; global_mem[R1[i] + 5] = R2[i]
```

### BRA

```text
Unconditional PC-relative branch. 

Format:
BRA symbol 

Semantics:
PC += pc_offset

Example:
BRA LOOP    ; PC += 30
```

### PRED

```text
Compares two values with a relational operator and writes a predicate register. Conditions include less than (LT), greater than (GT), and equal to (EQ). 

Format:
PRED p, rs1, rs2, cond

LT = 001
EQ = 010
GT = 100

Semantics:
for each active lane i:
  p[i] = compare(rs1[i], rs2[i], cond)

Inactive lanes set p[i] = 0.


Example:
PRED p0, R0, R1, LT    ; p[i] = R0[i] < R1[i]
```

### BRAP 

```text
Conditionally branches to PC-relative offset based on predicate register. If active lanes disagree on predicate value, the warp diverges and the deferred path is pushed onto SIMT stack.

Format:
BRAP p, target, reconv

Semantics:
target_pc = PC + target_offset
fallthrough_pc = PC + 1
reconv_pc = PC + reconv_offset

taken_mask = am & p
fallthrough_mask = am & ~p 

if taken_mask == 0:
  PC = fallthrough_pc
else if fallthrough_mask == 0:
  PC = target_pc
else:
  push entry {
    deferred_valid = 1
    deferred_pc = fallthrough_pc
    deferred_mask = fallthrough_mask
    reconv_pc
    reconv_mask = am
  }
  am = taken_mask
  PC = target_pc

Example:
BRAP p0, LOOP, DONE
```

### RCNV

```text
Reconverges the diverged paths using SIMT stack.

Format:
RCNV

Semantics:
if deferred_valid == 1:
  PC = deferred_pc
  am = deferred_mask
  deferred_valid = 0
else:
  PC = reconv_pc
  am = reconv_mask
  pop entry from SIMT stack

Example: 
RCNV    ; switch to deferred path or reconverge the warp
```

### MOV

```text
Loads an immediate value into the given register.

Format:
MOV rd, imm

Semantics:
For each active lane i:
  rd[i] = imm

Example:
MOV R0, 20    ; R0[i] = 20
```

### EXIT

```text
Terminates the currently active lanes.

Format:
EXIT

Semantics:
For each active lane i:
  am[i] = 0

Example:
EXIT    ; terminate all currently active lanes

```

## Opcode Table

| Opcode | Instruction |
|--------|-------------|
| `0x0`  |   `ADD`     |
| `0x1`  |   `MUL`     |
| `0x2`  |   `LDG`     |
| `0x3`  |   `STG`     |
| `0x4`  |   `BRA`     |
| `0x5`  |   `PRED`    |
| `0x6`  |   `BRAP`    |
| `0x7`  |   `RCNV`    |
| `0x8`  |   `MOV`     |
| `0x9`  |   `EXIT`    |

## Instruction Encoding

### R-Type (`ADD`, `MUL`):

```text 
 31        28 27        23 22        18 17        13 12          0
+------------+------------+------------+------------+-------------+
|   opcode   |     rd     |    rs1     |    rs2     |   unused    |
+------------+------------+------------+------------+-------------+
```

### M-Type (LDG, STG):
```text 
31         28 27        23 22        18 17                       0
+------------+------------+------------+-------------------------+
|   opcode   |  rd / rs   |     rb     |         imm18           |
+------------+------------+------------+-------------------------+
```

### B-Type (BRA):

```text 
31         28 27                                                0
+------------+--------------------------------------------------+
|   opcode   |                       imm28                      |
+------------+--------------------------------------------------+
```

### P-Type (PRED):

```text 
31         28 27      25 24        20 19        15 14    12 11    0
+------------+----------+------------+------------+--------+------+
|   opcode   |    p     |    rs1     |    rs2     |  cond  |unused|
+------------+----------+------------+------------+--------+------+
```

### PB-Type (BRAP):
```text 
31         28 27      25 24                  13 12              1   0
+------------+----------+----------------------+----------------+---+
|   opcode   |    p     |     target_off12     |  reconv_off12  | u |
+------------+----------+----------------------+----------------+---+
```

### I-Type (MOV):

```text 
31         28 27      23 22                                     0
+------------+----------+---------------------------------------+
|   opcode   |    rd    |                 imm23                 |
+------------+----------+---------------------------------------+
```

### Z-Type (RCNV, EXIT):

```text 
31         28 27                                                0
+------------+--------------------------------------------------+
|   opcode   |                     unused                       |
+------------+--------------------------------------------------+
```

## Additional Notes

### SIMT Stack Entry Specifics

```text
For each stack entry, the format below should be used:

entry1 {
  deferred_valid (1 bit)
  deferred_pc (32 bits)
  deferred_mask (8 bits)
  reconv_pc (32 bits)
  reconv_mask (8 bits)
}
```

### Immediate Values
```text
Assume that all immediate values are sign extended.
```
