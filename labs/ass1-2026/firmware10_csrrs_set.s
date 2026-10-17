/**
 * @brief CSRRS on mscratch: returns the old value and ORs in the source
 *        bits. With rs1=x0 it must read without writing.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 0xF0;      /* 0x00 */
    csrrw x2, mscratch, x1; /* 0x04 x2=old (0), mscratch=0xF0 */
    addi x3, x0, 0x0F;      /* 0x08 */
    csrrs x4, mscratch, x3; /* 0x0c x4=0xF0, mscratch=0xFF */
    csrrs x5, mscratch, x0; /* 0x10 read only */
    nop;                    /* 0x14 */
    ebreak;                 /* 0x18, pc dumps 0x1c */

/* expected result:
    expect h0:x0 = 0
    expect h0:x2 = 0x0
    expect h0:x3 = 0xF
    expect h0:x4 = 0xF0
    expect h0:x5 = 0xFF
    expect h0:mscratch = 0xFF
    expect h0:pc = 0x1C
*/
