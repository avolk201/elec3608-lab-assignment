/**
 * @brief A trap and an interrupt in one program. The illegal fence hits
 *        before the pin pulse; one handler dispatches on mcause, records
 *        the trap mepc, and mrets both times.
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
    nop;                   /* 0x14 */
    fence;                 /* 0x18 illegal, mepc=0x1c */
    addi x4, x0, 40;       /* 0x1c resume point */
    nop;                   /* 0x20 */
loop:
    addi x4, x4, -1;       /* 0x24 */
    bne x4, x0, loop;      /* 0x28 */
    nop;                   /* 0x2c */
    ebreak;                /* 0x30, pc dumps 0x34 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    csrrs x6, mcause, x0;  /* 0x1000 */
    addi x7, x0, 2;        /* 0x1004 */
    beq x6, x7, trap_path; /* 0x1008 */
    mret;                  /* 0x100c interrupt path */
trap_path:
    csrrs x9, mepc, x0;    /* 0x1010 */
    mret;                  /* 0x1014 -> 0x1c */

/* expected result:
    expect h0:x9 = 0x1C
    expect h0:x6 = 0x8000000B
    expect h0:mcause = 0x8000000B
    expect h0:x4 = 0x0
    expect h0:mip = 0x000
    expect h0:pc = 0x34
*/
