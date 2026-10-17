/**
 * @brief mie keeps only bit 11 (MEIE). Write -1, read back, clear with -1.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, -1;       /* 0x00 */
    csrrw x2, mie, x1;     /* 0x04 x2=old (0) */
    csrrs x3, mie, x0;     /* 0x08 read back */
    csrrc x4, mie, x1;     /* 0x0c x4=0x800 */
    csrrs x5, mie, x0;     /* 0x10 */
    nop;                   /* 0x14 */
    ebreak;                /* 0x18, pc dumps 0x1c */

/* expected result:
    expect h0:x2 = 0x0
    expect h0:x3 = 0x800
    expect h0:x4 = 0x800
    expect h0:x5 = 0x0
    expect h0:mie = 0x0
    expect h0:pc = 0x1C
*/
