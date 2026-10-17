/**
 * @brief Two illegal instructions in a row, recovered from both. The
 *        handler counts entries and records the newest mepc.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 20;     /* 0x00 */
    fence;               /* 0x04 first illegal, mepc=0x08 */
    addi x2, x0, 30;     /* 0x08 */
    fence;               /* 0x0c second illegal, mepc=0x10 */
    addi x3, x0, 40;     /* 0x10 */
    ebreak;              /* 0x14, pc dumps 0x18 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    addi x5, x5, 1;       /* 0x1000 */
    csrrs x6, mepc, x0;   /* 0x1004 */
    mret;                 /* 0x1008 */

/* expected result:
    expect h0:x5 = 2
    expect h0:x6 = 0x10
    expect h0:x1 = 20
    expect h0:x2 = 30
    expect h0:x3 = 40
    expect h0:mcause = 0x2
    expect h0:mepc = 0x10
    expect h0:pc = 0x18
*/
