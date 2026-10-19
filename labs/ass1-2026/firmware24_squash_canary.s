/**
 * @brief Wrong-path squash canary. The counting branch at 0x20 takes
 *        four times and jumps over its successor, addi x9,x9,1 at 0x24.
 *        That slot is fetched four times as dead-path and once live on
 *        the fall-through, so x9 must read exactly 1. The handler mret
 *        similarly jumps over a second canary at 0x1008. A pipelined
 *        design that commits dying slots reads x9 = 5 or 6.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 8;         /* 0x00 */
    csrrs x0, mstatus, x1;  /* 0x04 GIE */
    addi x1, x0, 1;         /* 0x08 */
    slli x1, x1, 11;        /* 0x0c */
    csrrs x0, mie, x1;      /* 0x10 MEIE */
    addi x9, x0, 0;         /* 0x14 canary sum */
    addi x10, x0, 5;        /* 0x18 trip count */
loop:
    addi x10, x10, -1;      /* 0x1c */
    bne x10, x0, loop;      /* 0x20 taken on trips 1-4 */
    addi x9, x9, 1;         /* 0x24 dead four times, live once */
    addi x11, x0, 77;       /* 0x28 */
    ebreak;                 /* 0x2c, pc dumps 0x30 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    csrrs x12, mepc, x0;    /* 0x1000 */
    mret;                   /* 0x1004 */
    addi x9, x9, 1;         /* 0x1008 only ever right-path after a bad mret */

/* expected result:
    expect h0:x9 = 1 (one live pass; five dead slots must not land)
    expect h0:x10 = 0x0
    expect h0:x11 = 77
    expect h0:mcause = 0x8000000B
    expect h0:mip = 0x000
    expect h0:mstatus = 0x8
    expect h0:pc = 0x30
*/
