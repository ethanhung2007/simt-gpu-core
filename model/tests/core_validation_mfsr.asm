mfsr r1, laneid
mov r2, 2
pred p0, r1, r2, lt
brap p0, taken, reconverged

mov r3, 99
rcnv

taken
mov r3, 11
rcnv

reconverged
mov r4, 7
exit
