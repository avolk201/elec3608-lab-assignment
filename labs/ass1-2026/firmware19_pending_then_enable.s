/**
 * @brief A masked interrupt is not lost: the pin fires during the loop
 *        while GIE is off, and the take happens when software enables
 *        afterwards, with the pin long gone.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 1;        /* 0x00 */
    slli x1, x1, 11;       /* 0x04 */
    csrrs x0, mie, x1;     /* 0x08 MEIE on, GIE off */
    addi x4, x0, 20;       /* 0x0c */
    nop;                   /* 0x10 */
loop:
    addi x4, x4, -1;       /* 0x14 */
    bne x4, x0, loop;      /* 0x18 */
    addi x2, x0, 8;        /* 0x1c */
    csrrs x0, mstatus, x2; /* 0x20 the pending bit fires here */
    nop;                   /* 0x24 */
    ebreak;                /* 0x28, pc dumps 0x2c after return */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    addi x5, x0, 10;       /* 0x1000 */
    mret;                  /* 0x1004 */

/* expected result:
    expect h0:x5 = 10
    expect h0:x4 = 0x0
    expect h0:mcause = 0x8000000B
    expect h0:mip = 0x000
    expect h0:mstatus = 0x8
    expect h0:pc = 0x2C
*/
