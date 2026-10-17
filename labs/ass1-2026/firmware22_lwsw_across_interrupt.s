/**
 * @brief Each loop iteration stores x4 to 0x100, so the abort-and-rerun
 *        from the interrupt re-executes a load/store path slot. If the
 *        aborted slot were dropped instead of re-run the countdown would
 *        miss zero.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x5, x0, 256;       /* 0x00 */
    addi x1, x0, 8;         /* 0x04 */
    csrrs x0, mstatus, x1;  /* 0x08 */
    addi x2, x0, 1;         /* 0x0c */
    slli x2, x2, 11;        /* 0x10 */
    csrrs x0, mie, x2;      /* 0x14 */
    addi x4, x0, 50;        /* 0x18 */
loop:
    addi x4, x4, -1;        /* 0x1c */
    sw x4, 0(x5);           /* 0x20 */
    bne x4, x0, loop;       /* 0x24 */
    nop;                    /* 0x28 */
    lw x6, 0(x5);           /* 0x2c after the return */
    ebreak;                 /* 0x30, pc dumps 0x34 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    addi x8, x0, 77;        /* 0x1000 */
    mret;                   /* 0x1004 */

/* expected result:
    expect h0:x4 = 0x0
    expect h0:x6 = 0x0
    expect h0:x8 = 77
    expect h0:mcause = 0x8000000B
    expect h0:mip = 0x000
    expect h0:pc = 0x34
*/
