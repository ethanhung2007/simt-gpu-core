# WARP ISA

## Instruction Set Summary
ADD rd, rs1, rs2              -- integer add
MUL rd, rs1, rs2              -- integer multiply
LDG rd, \[base+offset\]       -- global load (coalesced)
STG rs, \[base+offset\]       -- global store
BRA target                    -- uniform branch (all lanes same)
PRED p, rs1, rs2, cond        -- set predicate register
@p BRA target, reconv         -- divergent branch (enters SIMT stack)
RCNV                          -- reconverge divergent warp using SIMT stack
MOV rd, imm                   -- load immediate
EXIT                          -- terminate warp

## Opcode Table
| Opcode | Instruction |
| 0x0 | ADD |
| 0x1 | MUL |
| 0x2 | LDG |
| 0x3 | STG |
| 0x4 | BRA |
| 0x5 | PRED |
| 0x6 | @p BRA |
| 0x7 | RCNV |
| 0x8 | MOV |
| 0x9 | EXIT |

## Instruction Encoding

R-Type (ADD, MUL):

 31        28 27        23 22        18 17        13 12          0
+------------+------------+------------+------------+-------------+
|   opcode   |     rd     |    rs1     |    rs2     |   unused    |
+------------+------------+------------+------------+-------------+

M-Type (LDG, STG):

31        28 27        23 22        18 17                      0
+------------+------------+------------+-------------------------+
|   opcode   |  rd / rs   |    base    |      PCoffset18         |
+------------+------------+------------+-------------------------+

B-Type (BRA):

31        28 27                                                0
+------------+--------------------------------------------------+
|   opcode   |                    PCoffset28                    |
+------------+--------------------------------------------------+

P-Type (PRED):

31        28 27      25 24        20 19        15 14    12 11   0
+------------+----------+------------+------------+--------+------+
|   opcode   |    p     |    rs1     |    rs2     |  cond  |unused|
+------------+----------+------------+------------+--------+------+

PB-Type (@p BRA):

31        28 27      25 24                  13 12              1 0
+------------+----------+----------------------+----------------+--+
|   opcode   |    p     |     target_off12     |  reconv_off12  |u |
+------------+----------+----------------------+----------------+--+

I-Type (MOV):

31        28 27      25 24                                     0
+------------+----------+---------------------------------------+
|   opcode   |    rd    |                 imm24                 |
+------------+----------+---------------------------------------+

Z-Type (RCNV, EXIT):

31        28 27                                                0
+------------+--------------------------------------------------+
|   opcode   |                     unused                       |
+------------+--------------------------------------------------+

## Instruction Semantics
