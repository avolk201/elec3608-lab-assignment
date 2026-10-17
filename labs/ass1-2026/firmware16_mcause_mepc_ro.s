/**
 * @brief mcause and mepc ignore instruction writes. The illegal fence at
 *        0x08 traps; the handler records both, overwrites both, re-reads,
 *        then mrets to the skipped address.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    nop;                 /* 0x00 */
    nop;                 /* 0x04 */
    fence;               /* 0x08 illegal, mepc=0x0c */
    addi x1, x0, 111;    /* 0x0c reached via mret */
    nop;                 /* 0x10 */
    ebreak;              /* 0x14, pc dumps 0x18 */

.section mtvec_section ,"ax",@progbits
.global _mtvec
_mtvec:
    csrrs x5, mcause, x0; /* 0x1000 */
    csrrs x6, mepc, x0;   /* 0x1004 */
    addi x7, x0, -1;      /* 0x1008 */
    csrrw x0, mcause, x7; /* 0x100c */
    csrrw x0, mepc, x7;   /* 0x1010 */
    csrrs x8, mepc, x0;   /* 0x1014 */
    csrrs x9, mcause, x0; /* 0x1018 */
    mret;                 /* 0x101c -> 0x0c */

/* expected result:
    expect h0:x5 = 0x2
    expect h0:x6 = 0xC
    expect h0:x8 = 0xC
    expect h0:x9 = 0x2
    expect h0:x1 = 111
    expect h0:mepc = 0xC
    expect h0:mcause = 0x2
    expect h0:pc = 0x18
*/
