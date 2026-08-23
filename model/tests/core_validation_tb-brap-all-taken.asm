mov R1, 1
mov R2, 2
pred P0, R1, R2, lt
brap P0, taken, reconverged

mov R3, 99
rcnv

taken
mov R3, 11
rcnv

reconverged
mov R4, 7
exit
