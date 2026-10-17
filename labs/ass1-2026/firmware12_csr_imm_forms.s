/**
 * @brief Immediate forms: CSRRWI writes uimm, CSRRSI and CSRRCI set or
 *        clear the uimm bits, and uimm=0 must not write.
 * @course University of Sydney ELEC3608 2026 Assignment 1
 */

.section .text
.global main
.global _start
_start:
    csrrwi x1, mscratch, 9;  /* 0x00 x1=0, mscratch=9 */
    csrrsi x2, mscratch, 16; /* 0x04 x2=9, mscratch=25 */
    csrrci x3, mscratch, 9;  /* 0x08 x3=25, mscratch=16 */
    csrrsi x4, mscratch, 0;  /* 0x0c x4=16, no write */
    csrrwi x0, mscratch, 5;  /* 0x10 write with no destination */
    csrrs  x5, mscratch, x0; /* 0x14 */
    nop;                     /* 0x18 */
    ebreak;                  /* 0x1c, pc dumps 0x20 */

/* expected result:
    expect h0:x1 = 0x0
    expect h0:x2 = 9
    expect h0:x3 = 25
    expect h0:x4 = 16
    expect h0:x5 = 5
    expect h0:mscratch = 5
    expect h0:pc = 0x20
*/
