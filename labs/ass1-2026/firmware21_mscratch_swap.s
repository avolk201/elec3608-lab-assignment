/**
 * @brief The context-swap idiom: one csrrw loads the saved value and
 *        stores the new one. The handler exchanges mscratch and x10 and
 *        returns.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x10, x0, 1365;     /* 0x00 K = 0x555 */
    addi x9, x0, 291;       /* 0x04 P = 0x123 */
    csrrw x0, mscratch, x9; /* 0x08 park P */
    addi x1, x0, 8;         /* 0x0c */
    csrrs x0, mstatus, x1;  /* 0x10 */
    addi x2, x0, 1;         /* 0x14 */
    slli x2, x2, 11;        /* 0x18 */
    csrrs x0, mie, x2;      /* 0x1c */
    addi x4, x0, 50;        /* 0x20 */
    nop;                    /* 0x24 */
loop:
    addi x4, x4, -1;        /* 0x28 */
    bne x4, x0, loop;       /* 0x2c */
    nop;                    /* 0x30 */
    ebreak;                 /* 0x34, pc dumps 0x38 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    csrrw x13, mscratch, x10; /* 0x1000 x13=P, mscratch=K */
    mret;                     /* 0x1004 */

/* expected result:
    expect h0:x13 = 291
    expect h0:mscratch = 1365
    expect h0:x10 = 1365
    expect h0:x4 = 0x0
    expect h0:mcause = 0x8000000B
    expect h0:mip = 0x000
    expect h0:pc = 0x38
*/
