.equ DMA3_SRC,     0x040000D4
.equ DMA3_DEST,    0x040000D8
.equ DMA3_CNT,     0x040000DC

.global dma3
.section .text
.code 32

@ r0 = source address
@ r1 = destination address
@ r2 = count
dma3:
    ldr r3, =DMA3_SRC
    str r0, [r3]
    ldr r3, =DMA3_DEST
    str r1, [r3]
    ldr r3, =DMA3_CNT
    str r2, [r3]
    bx lr
