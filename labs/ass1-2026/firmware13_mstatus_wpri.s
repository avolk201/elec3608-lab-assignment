/**
 * @brief mstatus keeps only its enable bit. The suite switches interrupts
 *        with bit 3 (csrs mstatus, 8), so a write of -1 must leave exactly
 *        0x8 and a clear of -1 must leave 0.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, -1;          /* 0x00 */
    csrrw x2, mstatus, x1;    /* 0x04 x2=old (0) */
    csrrs x3, mstatus, x0;    /* 0x08 read back */
    csrrci x4, mstatus, 31;   /* 0x0c x4=0x8, enable cleared */
    csrrs x5, mstatus, x0;    /* 0x10 */
    nop;                      /* 0x14 */
    ebreak;                   /* 0x18, pc dumps 0x1c */

/* expected result:
    expect h0:x2 = 0x0
    expect h0:x3 = 0x8
    expect h0:x4 = 0x8
    expect h0:x5 = 0x0
    expect h0:mstatus = 0x0
    expect h0:pc = 0x1C
*/
