start
mov r1, 10
mov r2, 3
add r3, r1, r2
mul r4, r1, r2
stg r3, 0(r1)
ldg r5, 0(r1)
pred p0, r1, r2, gt
bra skip
mov r6, 9
skip brap p0, taken, reconv
mov r7, 0
reconv rcnv
taken mov r7, 1
exit
