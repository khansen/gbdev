.equ IWRAM_START,  0x03000000

.include "dma_constants.s"
.include "track_constants.s"

.section .bss
.align 4

vram_buffer: .space 256*2

frame_counter: .space 4

keys_held: .space 2
keys_pressed: .space 2

vram_buffer_offset: .space 2

current_framebuffer: .space 1

.equ CANDLE_FLAME_WIDTH, 6
.equ CANDLE_FLAME_SPACE, 3
.equ FIRE_ROWS, 50
.equ FIRE_COLUMNS, 34

fire_data: .space (1+FIRE_COLUMNS+1)*(FIRE_ROWS+2)
lfsr: .space 1

.section .text
.global _start
.global jump_table
.code 32
.cpu arm7tdmi

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
    .ascii "SNOWBRO-0004"
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

.equ DISPCNT,   0x04000000
.equ DISPSTAT,  0x04000004
.equ VCOUNT,    0x04000006
.equ BG0CNT,    0x04000008
.equ BG2PA,     0x04000020
.equ BG2PB,     0x04000022
.equ BG2PC,     0x04000024
.equ BG2PD,     0x04000026
.equ BG_SIZE_256x256, 0x0000
.equ BG_COLOR_16, 0x0000
.equ BG_PRIORITY_0, 0x0000
.equ BG_CHAR_BASE_BLOCK_0, 0x0000
.equ BG_SCREEN_BASE_BLOCK_2, 0x0200
.equ BG_MODE0,   0x0000
.equ BG_MODE3,   0x0003
.equ BG_MODE5,   0x0005
.equ BG0_ENABLE, 0x0100
.equ BG1_ENABLE, 0x0200
.equ BG2_ENABLE, 0x0400
.equ BG3_ENABLE, 0x0800
.equ OBJ_ENABLE, 0x1000
.equ VIDEO_BUFFER, 0x06000000
.equ SCREEN_WIDTH, 240
.equ SCREEN_HEIGHT, 160

.equ KEY_INPUT, 0x04000130
.equ KEY_A,   0x001
.equ KEY_B,   0x002
.equ KEY_SL,  0x004
.equ KEY_ST,  0x008
.equ KEY_RT,  0x010
.equ KEY_LFT, 0x020
.equ KEY_UP,  0x040
.equ KEY_DWN, 0x080
.equ KEY_R,   0x100
.equ KEY_L,   0x200

.macro generate_random_byte
    ldr r1, =lfsr
    ldrb r0, [r1]               @ Load the current LFSR value into R0
    MOV R2, R0, LSR #7          @ Extract bit 7 of the LFSR
    EOR R2, R2, R0, LSR #5      @ XOR bit 7 with bit 5
    EOR R2, R2, R0, LSR #4      @ XOR the result with bit 4
    EOR R2, R2, R0, LSR #3      @ XOR the result with bit 3
    AND R2, R2, #1              @ Keep only the least significant bit (feedback bit)

    MOV R0, R0, LSL #1          @ Shift the LFSR left by 1
    ORR R0, R0, R2              @ Insert the feedback bit into bit 0

    STRB R0, [r1]               @ Store the updated LFSR value back to memory
.endm

_start:
    @ Set up the stack pointer for IRQ mode
    ldr r0, =0x03007FE0   @ IRQ stack top in IWRAM
    msr CPSR_c, #0x92     @ Set to IRQ mode, disable IRQ
    mov sp, r0            @ Set IRQ stack pointer
    msr CPSR_c, #0x1F     @ Return to system mode

    bl clear_iwram

    bl clear_vram

    @ Initialize random number seed
    ldr r0, =lfsr
    ldr r1, =0xAB
    strb r1, [r0]

    @ Copy image data to VRAM framebuffer 0
    ldr r0, =image_data
    ldr r1, =VIDEO_BUFFER
    mov r2, #((160*128*2) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    bl dma3

    @ Copy image data to VRAM framebuffer 1
    ldr r0, =image_data
    ldr r1, =(VIDEO_BUFFER + 0xA000)
    mov r2, #((160*128*2) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    bl dma3

    @ Stretch background to full resolution
    ldr r0, =BG2PA
    mov r1, #0x00AA
    strh r1, [r0]
    ldr r0, =BG2PB
    mov r1, #0x0000
    strh r1, [r0]
    ldr r0, =BG2PC
    mov r1, #0x0000
    strh r1, [r0]
    ldr r0, =BG2PD
    mov r1, #0x00C8
    strh r1, [r0]

    bl init_sound

    ldr r0, =play_note_callback
    bl set_play_note_callback
    ldr r0, =song_song
    bl start_song

    ldr r0, =0x03007FFC    @ IRQ Vector address
    ldr r1, =vblank_handler @ Address of the VBlank handler
    str r1, [r0]           @ Write handler address to IRQ vector

    ldr r0, =DISPSTAT
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
    ldr r0, =DISPCNT
    ldr r1, =(BG2_ENABLE | OBJ_ENABLE | BG_MODE5)
    str r1, [r0]

@ Loop forever, logic happens in VBlank handler
infinite_loop:
    b infinite_loop

clear_iwram:
@    ldr r0, =zero
    eor r0, r0, r0
    ldr r1, =IWRAM_START
    mov r2, #((32 * 1024) / 4) @ Number of words to transfer (32KB)
@ Have not been able to get DMA to work with DMA_SRC_FIXED
@    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_FIXED | DMA_DST_INC)
@    b dma3
    b cpu_mem_fill

clear_vram:
@    ldr r0, =zero
    eor r0, r0, r0
    ldr r1, =0x06000000
    mov r2, #((16 * 1024) / 4) @ Number of words to transfer (32KB)
@ Have not been able to get DMA to work with DMA_SRC_FIXED
@    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_FIXED | DMA_DST_INC)
@    bl dma3
    b cpu_mem_fill

@ r0 = value (word)
@ r1 = destination address
@ r2 = word count
cpu_mem_fill:
    str r0, [r1], #4
    subs r2, r2, #1
    bne cpu_mem_fill
    bx lr

read_key_input:
    ldr r0, =KEY_INPUT
    ldrh r1, [r0]
    ldr r2, =-1
    eor r1, r1, r2  @ invert all bits (so that 1=input, 0=no input)
    ldr r0, =keys_held
    ldrh r2, [r0] @ old keys_held
    strh r1, [r0] @ write new keys_held
    eor r2, r2, r1
    and r2, r2, r1
    strh r2, [r0, #2] @ keys_pressed
    bx lr

flush_vram_buffer:
    ldr r0, =vram_buffer_offset
    ldrh r1, [r0]
    tst r1, r1
    beq 1f
    eor r1, r1, r1
    strh r1, [r0] @ vram_buffer_offset = 0
    ldr r0, =vram_buffer
    b write_vram_string_array
    1:
    bx lr

@ r0 = address of string
write_vram_string_array:
    ldrh r1, [r0], #2 @ lower 16 bits of destination address
    tst r1, r1
    beq 1b
    orr r1, r1, #0x06000000 @ Absolute VRAM address
    ldrh r2, [r0], #2 @ count
    2: @ loop
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    subs r2, r2, #1
    bne 2b
    b write_vram_string_array

@ r0 = lower 16 bits of start address (hword)
@ r1 = count (hword)
@ returns r0 = buffer address
@ destroys r2 and r3
begin_vram_string:
    ldr r2, =vram_buffer
    ldr r3, =vram_buffer_offset
    ldrh r3, [r3]
    add r2, r2, r3
    strh r0, [r2], #2 @ start address
    strh r1, [r2], #2 @ count
    mov r0, r2
    bx lr

@ r0 = buffer address
@ destroys r1
end_vram_string:
    eor r1, r1, r1
    strh r1, [r0]
    ldr r1, =vram_buffer
    sub r0, r0, r1
    ldr r1, =vram_buffer_offset
    str r0, [r1]
    bx lr

@ r0 = source address
@ r1 = destination address
@ r2 = size in words
memcpy32:
    bx lr

swap_framebuffers:
    ldr r0, =current_framebuffer
    ldrb r1, [r0]
    tst r1, r1
    eor r1, r1, #1
    strb r1, [r0]
    ldr r0, =DISPCNT
    ldr r1, [r0]
    bicne r1, r1, #0x0010
    orreq r1, r1, #0x0010
    str r1, [r0]
    bx lr

play_note_callback:
    push {r0, r1}
    ldr r0, =(fire_data+(1+FIRE_COLUMNS+1)*(FIRE_ROWS-8)+2)
    1:
    orrs r1, r1, r1
    beq 2f
    add r0, r0, #(CANDLE_FLAME_WIDTH + CANDLE_FLAME_SPACE)
    sub r1, r1, #1
    b 1b
    2:
    mov r1, #255 @ full intensity
    strb r1, [r0, #1]
    strb r1, [r0, #2]
    strb r1, [r0, #(1+FIRE_COLUMNS+1)]
    strb r1, [r0, #(1+FIRE_COLUMNS+1+1)]
    strb r1, [r0, #(1+FIRE_COLUMNS+1+2)]
    strb r1, [r0, #(1+FIRE_COLUMNS+1+3)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*2)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*2+1)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*2+2)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*2+3)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*3)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*3+1)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*3+2)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*3+3)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*4+1)]
    strb r1, [r0, #((1+FIRE_COLUMNS+1)*4+2)]
    pop {r0, r1}
    bx lr

vblank_handler:
    push {lr}

    @ TODO: skip if still processing previous vblank
    bl flush_vram_buffer

    bl swap_framebuffers

    bl read_key_input

    bl update_sound

    mov r0, #0
    ldr r1, =main_handler_jump_table
    bl jump_table

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

mute_or_unmute_sound_channels:
    ldr r0, =keys_pressed
    ldrh r0, [r0]
    ldr r1, =sound_status
    ldrb r2, [r1]
    tst r0, #KEY_UP
    beq 1f @ up_not_pressed
    eor r2, r2, #1 @ toggle channel 1
    1: @ up_not_pressed
    tst r0, #KEY_DWN
    beq 1f @ down_not_pressed
    eor r2, r2, #2 @ toggle channel 2
    1: @ down_not_pressed
    tst r0, #KEY_LFT
    beq 1f @ left_not_pressed
    eor r2, r2, #4 @ toggle channel 3
    1: @ left_not_pressed
    tst r0, #KEY_RT
    beq 1f @ right_not_pressed
    eor r2, r2, #8 @ toggle channel 4
    1: @ right_not_pressed
    strb r2, [r1]
    bx lr

main_handler_0:
    push {lr}
    bl mute_or_unmute_sound_channels
    @ Silly stretch effect
    ldr r0, =frame_counter
    ldr r0, [r0]
    lsl r0, r0, #1
    ldr r1, =0x3ff
    and r1, r0, r1
    cmp r1, #0x200
    blt 1f
    ldr r0, =0x3ff
    eor r1, r1, r0
    1:
    ldr r0, =BG2PA
    strh r1, [r0]
    ldr r0, =BG2PB
    lsr r1, r1, #2
    strh r1, [r0]
    ldr r0, =BG2PC
    strh r1, [r0]
    pop {lr}
    bx lr

.rodata:
.align 4
zero: .word 0

.macro MAKE_FRAMEBUFFER_OFFSET x, y
.word ((160 * \y) + \x) * 2
.endm

candle_framebuffer_offsets:
MAKE_FRAMEBUFFER_OFFSET 42, 8
MAKE_FRAMEBUFFER_OFFSET 72, 0
MAKE_FRAMEBUFFER_OFFSET 89, 10
MAKE_FRAMEBUFFER_OFFSET 124, 20

.macro RGB r, g, b
.hword (\b << 10) | (\g << 5) | \r
.endm

palette:
RGB  0,  0,  0
RGB  1,  0,  0
RGB  2,  0,  0
RGB  3,  0,  0
RGB  5,  0,  0
RGB  8,  0,  0
RGB 10,  0,  0
RGB 12,  0,  0
RGB 14,  0,  0
RGB 17,  0,  0
RGB 20,  0,  0
RGB 23,  0,  0
RGB 26,  0,  0
RGB 29,  0,  0
RGB 31,  2,  0
RGB 31,  5,  0
RGB 31,  8,  0
RGB 31, 11,  0
RGB 31, 14,  0
RGB 31, 16,  0
RGB 31, 18,  0
RGB 31, 20,  0
RGB 31, 22,  0
RGB 31, 24,  0
RGB 31, 26,  0
RGB 31, 28,  0
RGB 31, 20,  0
RGB 31, 31,  0
RGB 31, 31,  3
RGB 31, 31,  6
RGB 31, 31,  9
RGB 31, 31, 12
RGB 31, 31, 15
RGB 31, 31, 18
RGB 31, 31, 21
RGB 31, 31, 24
RGB 31, 31, 26
RGB 31, 31, 27
RGB 31, 31, 27
RGB 31, 31, 28
RGB 31, 31, 28
RGB 31, 31, 28
RGB 31, 31, 29
RGB 31, 31, 29
RGB 31, 31, 29
RGB 31, 31, 29
RGB 31, 31, 30
RGB 31, 31, 30
RGB 31, 31, 30
RGB 31, 31, 30
RGB 31, 31, 30
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31
RGB 31, 31, 31

.extern dma3
.extern init_sound
.extern set_play_note_callback
.extern song_song
.extern start_song
