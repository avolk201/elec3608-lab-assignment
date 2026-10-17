/**
 * @brief CSRRC clears the source bits. CSRRW with rd=x0 must still write
 *        the CSR, it only skips the readback.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    addi x1, x0, 0xFF;      /* 0x00 */
    csrrw x0, mscratch, x1; /* 0x04 write, no destination */
    addi x2, x0, 0x0F;      /* 0x08 */
    csrrc x3, mscratch, x2; /* 0x0c x3=0xFF, mscratch=0xF0 */
    csrrc x0, mscratch, x2; /* 0x10 same clear, no readback */
    csrrs x4, mscratch, x0; /* 0x14 */
    nop;                    /* 0x18 */
    ebreak;                 /* 0x1c, pc dumps 0x20 */

/* expected result:
    expect h0:x3 = 0xFF
    expect h0:x4 = 0xF0
    expect h0:mscratch = 0xF0
    expect h0:pc = 0x20
*/
