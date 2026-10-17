/**
 * @brief The enable bit's cycle: cleared when an interrupt vectors,
 *        restored by mret. The handler reads mstatus, main reads it again
 *        after the return.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 8;       /* 0x00 */
    csrrs x0, mstatus, x1;/* 0x04 */
    addi x1, x0, 1;       /* 0x08 */
    slli x1, x1, 11;      /* 0x0c */
    csrrs x0, mie, x1;    /* 0x10 */
    addi x4, x0, 50;      /* 0x14 */
    nop;                  /* 0x18 */
loop:
    addi x4, x4, -1;      /* 0x1c */
    bne x4, x0, loop;     /* 0x20 */
    csrrs x7, mstatus, x0;/* 0x24 after mret */
    ebreak;               /* 0x28, pc dumps 0x2c */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    csrrs x6, mstatus, x0; /* 0x1000 inside the handler */
    mret;                  /* 0x1004 */

/* expected result:
    expect h0:x6 = 0x0
    expect h0:x7 = 0x8
    expect h0:x4 = 0x0
    expect h0:mstatus = 0x8
    expect h0:mcause = 0x8000000B
    expect h0:mip = 0x000
    expect h0:pc = 0x2C
*/
