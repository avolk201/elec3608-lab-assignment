/**
 * @brief mip is written by hardware only. The pin fires while GIE is off
 *        (same mask setup as given firmware05), then software tries to
 *        overwrite and clear it.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 1;         /* 0x00 */
    slli x1, x1, 11;        /* 0x04 */
    csrrs x0, mie, x1;      /* 0x08 MEIE on, GIE off */
    addi x9, x0, 50;        /* 0x0c */
    nop;                    /* 0x10 */
loop:
    addi x9, x9, -1;        /* 0x14 */
    bne x9, x0, loop;       /* 0x18 */
    addi x2, x0, -1;        /* 0x1c */
    csrrw x3, mip, x2;      /* 0x20 x3=old, write must be dropped */
    csrrc x4, mip, x2;      /* 0x24 x4=0x800, clear must be dropped */
    csrrs x5, mip, x0;      /* 0x28 */
    ebreak;                 /* 0x2c, pc dumps 0x30 */

/* expected result:
    expect h0:x3 = 0x800
    expect h0:x4 = 0x800
    expect h0:x5 = 0x800
    expect h0:mip = 0x800
    expect h0:mcause = 0x0
    expect h0:pc = 0x30
*/
