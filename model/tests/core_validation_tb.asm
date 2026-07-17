mov R1, 5
mov R2, 7
add R3, R1, R2
mul R4, R3, R2
stg R4, 0(R0)
ldg R1, 0(R0)
stg R1, 4(R0)
mov R2, 25
pred P0, R1, R2, lt
brap P0, taken, reconverged
mov R3, 22
rcnv
taken
mov R3, 11
rcnv
reconverged stg R3, 4(R0)
exit
