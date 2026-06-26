start
add r5, r4, r3
MUL r4, r3, r1
BRA END
LDG r3, 5(r3)
STG r3, 5(r3)
PRED p1, r1, r3, LT
BRAP p2, END, start
END mov r3, 5
