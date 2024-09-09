.section .bss
.align 4
frame_counter: .space 4

.section .text
.global _start
.global jump_table
.code 32

_entry:
    b _start

@ TODO: fixup the checksum
header:
    .byte 0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD
    .byte 0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20
    .byte 0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31, 0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF
    .byte 0x85, 0xF4, 0xDF, 0x94, 0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC
    .byte 0x9F, 0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03, 0x98, 0x76
    .byte 0x23, 0x1D, 0xC7, 0x61, 0x03, 0x04, 0xAE, 0x56, 0xBF, 0x38, 0x84, 0x00, 0x40, 0xA7, 0x0E, 0xFD
    .byte 0xFF, 0x52, 0xFE, 0x03, 0x6F, 0x95, 0x30, 0xF1, 0x97, 0xFB, 0xC0, 0x85, 0x60, 0xD6, 0x80, 0x25
    .byte 0xA9, 0x63, 0xBE, 0x03, 0x01, 0x4E, 0x38, 0xE2, 0xF9, 0xA2, 0x34, 0xFF, 0xBB, 0x3E, 0x03, 0x44
    .byte 0x78, 0x00, 0x90, 0xCB, 0x88, 0x11, 0x3A, 0x94, 0x65, 0xC0, 0x7C, 0x63, 0x87, 0xF0, 0x3C, 0xAF
    .byte 0xD6, 0x25, 0xE4, 0x8B, 0x38, 0x0A, 0xAC, 0x72, 0x21, 0xD4, 0xF8, 0x07
gameTitle:
    .ascii "SNOWBRO-0001"
gameCode:
    .ascii "    "
makerCode:
    .ascii "KH"
    .byte 0x96
    .byte 0
    .byte 0
    .rept 7
        .byte 0
    .endr
    .byte 0
    .byte 0
    .rept 2
        .byte 0
    .endr

.equ VIDEO_MODE, 0x04000000
.equ MODE3, 0x0003
.equ BG2_ENABLE, 0x0400
.equ VIDEO_BUFFER, 0x06000000
.equ SCREEN_WIDTH, 240
.equ SCREEN_HEIGHT, 160

_start:
    @ Set up the stack pointer for IRQ mode
    ldr r0, =0x03007FE0   @ IRQ stack top in IWRAM
    msr CPSR_c, #0x92     @ Set to IRQ mode, disable IRQ
    mov sp, r0            @ Set IRQ stack pointer
    msr CPSR_c, #0x1F     @ Return to system mode

    @ TODO: copy tiles to VRAM
    @ TODO: copy palettes to VRAM
    @ TODO: copy tilemaps to VRAM

    bl init_sound

    ldr r0, =song_song
    bl start_song

    ldr r0, =0x03007FFC    @ IRQ Vector address
    ldr r1, =vblank_handler @ Address of the VBlank handler
    str r1, [r0]           @ Write handler address to IRQ vector

    ldr r0, =0x04000004   @ Address of DISPSTAT register
    mov r1, #0x0008       @ Set bit 3 to enable VBlank interrupt
    strh r1, [r0]         @ Write to DISPSTAT register

    ldr r0, =0x04000200    @ IME Register
    mov r1, #1             @ VBlank Interrupt
    strh r1, [r0]          @ Write to IME Register

    @ Enable Master Interrupt in IME register
    ldr r0, =0x04000208   @ IME register address
    mov r1, #0x0001       @ Enable all interrupts
    str r1, [r0]

    @ Enable IRQ in CPSR
    mrs r0, CPSR
    bic r0, r0, #0x80     @ Clear the I (interrupt disable) bit
    msr CPSR_c, r0

    @ Enable video
    ldr r0, =VIDEO_MODE
    ldr r1, =(BG2_ENABLE | MODE3)
    str r1, [r0]

@ Loop forever, logic happens in VBlank handler
infinite_loop:
    b infinite_loop

vblank_handler:
    push {lr}

    @ TODO: skip if still processing previous vblank
    @ TODO: flush VRAM buffer
    @ TODO: copy sprites using DMA?
    @ TODO: read input

    mov r0, #1
    ldr r1, =main_handler_jump_table
    bl jump_table

    bl update_sound

    @ Increment frame_counter
    ldr r0, =frame_counter
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    @ Acknowledge vblank interrupt
    ldr r0, =0x04000202 @ IF register
    mov r1, #0x0001
    strh r1, [r0]

    pop {lr}
    bx lr

@ r0 = index
@ r1 = address of the jump table
jump_table:
    ldr r0, [r1, r0, lsl #2]
    bx r0

.align 4
main_handler_jump_table:
.word main_handler_0
.word main_handler_1

main_handler_0:
    ldr r0, =VIDEO_BUFFER
    ldr r1, =image_data
    ldr r2, =64
1:
    ldrh r3, [r1], #2 
    strh r3, [r0], #2
    subs r2, r2, #1
    bne 1b
    bx lr

main_handler_1:
    ldr r0, =VIDEO_BUFFER
    ldr r1, =image_data
    ldr r2, =64
1:
    ldrh r3, [r1], #2
    eor r3, r3, #0xFF
    strh r3, [r0], #2
    subs r2, r2, #1
    bne 1b
    bx lr

.extern image_data
.extern init_sound
.extern song_song
.extern start_song
