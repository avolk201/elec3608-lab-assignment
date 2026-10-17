/**
 * @brief INTR held high across the mret: mret clears mip, the pin re-pends
 *        immediately, the handler runs a second time and disables further
 *        takes before halting. Needs ton_intr=35 toff_intr=80 (Makefile
 *        wires this for firmware18).
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 8;        /* 0x00 */
    csrrs x0, mstatus, x1; /* 0x04 */
    addi x1, x0, 1;        /* 0x08 */
    slli x1, x1, 11;       /* 0x0c */
    csrrs x0, mie, x1;     /* 0x10 */
    addi x4, x0, 50;       /* 0x14 */
    nop;                   /* 0x18 */
loop:
    addi x4, x4, -1;       /* 0x1c */
    bne x4, x0, loop;      /* 0x20 */
    nop;                   /* 0x24 */
    ebreak;                /* 0x28 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    addi x6, x6, 1;        /* 0x1000 entry counter */
    addi x7, x0, 1;        /* 0x1004 */
    beq x6, x7, first;     /* 0x1008 */
    addi x8, x0, 8;        /* 0x100c second visit: build clear mask */
    csrrc x0, mstatus, x8; /* 0x1010 */
    ebreak;                /* 0x1014, pc dumps 0x1018 */
first:
    mret;                  /* 0x1018 back to the still-high pin */

/* expected result:
    expect h0:x6 = 2
    expect h0:x8 = 8
    expect h0:mstatus = 0x0
    expect h0:mip = 0x800
    expect h0:mcause = 0x8000000B
    expect h0:pc = 0x1018
*/
