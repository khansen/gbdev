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

.equ DISPCNT,    0x04000000
.equ DISPSTAT,   0x04000004
.equ VCOUNT,     0x04000006
.equ BG0CNT,     0x04000008
.equ BG_SIZE_256x256, 0x0000
.equ BG_COLOR_16, 0x0000
.equ BG_PRIORITY_0, 0x0000
.equ BG_CHAR_BASE_BLOCK_0, 0x0000
.equ BG_SCREEN_BASE_BLOCK_2, 0x0200
.equ BG_MODE0,   0x0000
.equ BG_MODE3,   0x0003
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

_start:
    @ Set up the stack pointer for IRQ mode
    ldr r0, =0x03007FE0   @ IRQ stack top in IWRAM
    msr CPSR_c, #0x92     @ Set to IRQ mode, disable IRQ
    mov sp, r0            @ Set IRQ stack pointer
    msr CPSR_c, #0x1F     @ Return to system mode

    bl clear_iwram

    @ Configure BG0
    ldr r0, =BG0CNT
    mov r1, #(BG_SIZE_256x256 | BG_COLOR_16 | BG_PRIORITY_0 | BG_CHAR_BASE_BLOCK_0 | BG_SCREEN_BASE_BLOCK_2)
    strh r1, [r0]

    bl clear_vram

    @ Copy tiles to VRAM
    ldr r0, =bg_tiles
    ldr r1, =0x06000000  @ Character Base Block 0
    mov r2, #((bg_tiles_end - bg_tiles) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    bl dma3

    @ Copy palettes to VRAM
    ldr r0, =bg_palettes
    ldr r1, =0x05000000  @ BG palette RAM
    mov r2, #((bg_palettes_end - bg_palettes) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    bl dma3

    @ Copy tilemap to VRAM
    ldr r0, =bg_tilemap
    bl write_vram_string_array

    bl init_sound

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
    ldr r1, =(BG0_ENABLE | OBJ_ENABLE | BG_MODE0)
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

vblank_handler:
    push {lr}

    @ TODO: skip if still processing previous vblank
    bl flush_vram_buffer
    @ TODO: copy sprites using DMA?
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

print_vcount:
    push {lr}
    ldr r0, =0x1076
    ldr r1, =2
    bl begin_vram_string
    ldr r1, =VCOUNT
    ldrh r1, [r1]
    and r2, r1, #0xf0
    lsr r2, r2, #4
    cmp r2, #9
    add r2, r2, #CHAR_0
    addgt r2, r2, #(CHAR_A - CHAR_9 - 1)
    strh r2, [r0], #2
    and r2, r1, #0x0f
    cmp r2, #9
    add r2, r2, #CHAR_0
    addgt r2, r2, #(CHAR_A - CHAR_9 - 1)
    strh r2, [r0], #2
    bl end_vram_string
    pop {lr}
    bx lr

draw_channel_indicators:
    push {lr}
    ldr r4, =tracks
    @ upper half
    ldr r0, =0x1414
    ldr r1, =11 @ 2+1+2+1+2+1+2 tiles
    bl begin_vram_string

    @ channel 1
    ldrb r2, [r4, #TRACK_EFFECTIVE_VOL_BYTE]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel1_blank_top
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x60
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel1_channel2_separator_top
draw_channel_indicators__draw_channel1_blank_top:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel1_channel2_separator_top:
    strh r2, [r0], #2 @ space

    @ channel 2
    ldrb r2, [r4, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*1)]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel2_blank_top
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x60
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel2_channel3_separator_top
draw_channel_indicators__draw_channel2_blank_top:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel2_channel3_separator_top:
    strh r2, [r0], #2 @ space

    @channel 3
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #4 @ channel 3 muted?
    ldrb r2, [r4, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*2)]
    movne r2, #0
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel3_blank_top
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x60
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel3_channel4_separator_top
draw_channel_indicators__draw_channel3_blank_top:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel3_channel4_separator_top:
    strh r2, [r0], #2 @ space

    @ channel 4
    ldrb r2, [r4, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*3)]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel4_blank_top
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x60
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators__top_half_done
draw_channel_indicators__draw_channel4_blank_top:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators__top_half_done:
    bl end_vram_string

    @ lower half
    ldr r0, =0x1454
    ldr r1, =11 @ 2+1+2+1+2+1+2 tiles
    bl begin_vram_string

    @ channel 1
    ldrb r2, [r4, #TRACK_EFFECTIVE_VOL_BYTE]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel1_blank_bottom
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x61
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel1_channel2_separator_bottom
draw_channel_indicators__draw_channel1_blank_bottom:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel1_channel2_separator_bottom:
    strh r2, [r0], #2 @ space

    @ channel 2
    ldrb r2, [r4, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*1)]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel2_blank_bottom
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x61
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel2_channel3_separator_bottom
draw_channel_indicators__draw_channel2_blank_bottom:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel2_channel3_separator_bottom:
    strh r2, [r0], #2 @ space

    @channel 3
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #4 @ channel 3 muted?
    ldrb r2, [r4, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*2)]
    movne r2, #0
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel3_blank_bottom
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x61
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators_draw_channel3_channel4_separator_bottom
draw_channel_indicators__draw_channel3_blank_bottom:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators_draw_channel3_channel4_separator_bottom:
    strh r2, [r0], #2 @ space

    @ channel 4
    ldrb r2, [r4, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*3)]
    ands r2, r2, #0xe0
    beq draw_channel_indicators__draw_channel4_blank_bottom
    lsr r2, r2, #3 @ ball size (0..7) * 4
    add r2, r2, #0x61
    strh r2, [r0], #2
    add r2, r2, #2
    strh r2, [r0], #2
    eor r2, r2, r2
    b draw_channel_indicators__bottom_half_done
draw_channel_indicators__draw_channel4_blank_bottom:
    strh r2, [r0], #2 @ space
    strh r2, [r0], #2 @ space
draw_channel_indicators__bottom_half_done:
    bl end_vram_string

    pop {lr}
    bx lr

main_handler_0:
    push {lr}
    bl mute_or_unmute_sound_channels
    bl draw_channel_indicators
    bl print_vcount
    pop {lr}
    bx lr

.ltorg

.rodata:
.align 4
zero: .word 0

bg_tiles:
.incbin "font.bin"
.incbin "ball.bin"
bg_tiles_end:

bg_palettes:
@ 0 - scenery and letters
.hword 0b0111110000000000
.hword 0b0000000000000000
.hword 0b0111111000010000
.hword 0b0111111111111111
@ 1 - orb
.hword 0b0111110000000000
.hword 0b0111111000011111
.hword 0b0011110100001111
.hword 0b0001000100000010
@ 2 - flag
.hword 0b0000000000000000
.hword 0b0000000000011111
.hword 0b0101000000000000
.hword 0b0111111111111111
bg_palettes_end:

.equ CHAR_SPACE, 0x00
.equ CHAR_EXCL, 0x01
.equ CHAR_BSOL, 0x02
.equ CHAR_NUM, 0x03
.equ CHAR_DOLLAR, 0x04
.equ CHAR_PERCNT, 0x05
.equ CHAR_AMP, 0x06
.equ CHAR_APOS, 0x07
.equ CHAR_LPAREN, 0x08
.equ CHAR_RPAREN, 0x09
.equ CHAR_AST, 0x0A
.equ CHAR_PLUS, 0x0B
.equ CHAR_COMMA, 0x0C
.equ CHAR_MINUS, 0x0D
.equ CHAR_PERIOD, 0x0E
.equ CHAR_SOL, 0x0F
.equ CHAR_COLON, 0x1A
.equ CHAR_0, 0x10
.equ CHAR_1, 0x11
.equ CHAR_2, 0x12
.equ CHAR_3, 0x13
.equ CHAR_4, 0x14
.equ CHAR_5, 0x15
.equ CHAR_6, 0x16
.equ CHAR_7, 0x17
.equ CHAR_8, 0x18
.equ CHAR_9, 0x19
.equ CHAR_A, 0x21
.equ CHAR_B, 0x22
.equ CHAR_C, 0x23
.equ CHAR_D, 0x24
.equ CHAR_E, 0x25
.equ CHAR_F, 0x26
.equ CHAR_G, 0x27
.equ CHAR_H, 0x28
.equ CHAR_I, 0x29
.equ CHAR_J, 0x2A
.equ CHAR_K, 0x2B
.equ CHAR_L, 0x2C
.equ CHAR_M, 0x2D
.equ CHAR_N, 0x2E
.equ CHAR_O, 0x2F
.equ CHAR_P, 0x30
.equ CHAR_Q, 0x31
.equ CHAR_R, 0x32
.equ CHAR_S, 0x33
.equ CHAR_T, 0x34
.equ CHAR_U, 0x35
.equ CHAR_V, 0x36
.equ CHAR_W, 0x37
.equ CHAR_X, 0x38
.equ CHAR_Y, 0x39
.equ CHAR_Z, 0x3A
.equ CHAR_a, 0x41
.equ CHAR_b, 0x42
.equ CHAR_c, 0x43
.equ CHAR_d, 0x44
.equ CHAR_e, 0x45
.equ CHAR_f, 0x46
.equ CHAR_g, 0x47
.equ CHAR_h, 0x48
.equ CHAR_i, 0x49
.equ CHAR_j, 0x4A
.equ CHAR_k, 0x4B
.equ CHAR_l, 0x4C
.equ CHAR_m, 0x4D
.equ CHAR_n, 0x4E
.equ CHAR_o, 0x4F
.equ CHAR_p, 0x50
.equ CHAR_q, 0x51
.equ CHAR_r, 0x52
.equ CHAR_s, 0x53
.equ CHAR_t, 0x54
.equ CHAR_u, 0x55
.equ CHAR_v, 0x56
.equ CHAR_w, 0x57
.equ CHAR_x, 0x58
.equ CHAR_y, 0x59
.equ CHAR_z, 0x5A

bg_tilemap:
.hword 0x1090,14,CHAR_S,CHAR_u,CHAR_p,CHAR_e,CHAR_r,CHAR_SPACE,CHAR_M,CHAR_a,CHAR_r,CHAR_i,CHAR_o,CHAR_SPACE,CHAR_6,CHAR_4
.hword 0x1114,10,CHAR_M,CHAR_a,CHAR_i,CHAR_n,CHAR_SPACE,CHAR_T,CHAR_h,CHAR_e,CHAR_m,CHAR_e
.hword 0x118a,21,CHAR_LPAREN,CHAR_B,CHAR_o,CHAR_b,CHAR_MINUS,CHAR_o,CHAR_m,CHAR_b,CHAR_SPACE,CHAR_B,CHAR_a,CHAR_t,CHAR_t,CHAR_l,CHAR_e,CHAR_f,CHAR_i,CHAR_e,CHAR_l,CHAR_d,CHAR_RPAREN

.hword 0x1252,12,CHAR_O,CHAR_r,CHAR_i,CHAR_g,CHAR_i,CHAR_n,CHAR_a,CHAR_l,CHAR_SPACE,CHAR_b,CHAR_y,CHAR_COLON
.hword 0x12D4,10,CHAR_K,CHAR_o,CHAR_j,CHAR_i,CHAR_SPACE,CHAR_K,CHAR_o,CHAR_n,CHAR_d,CHAR_o

.hword 0x138e,17,CHAR_R,CHAR_e,CHAR_m,CHAR_i,CHAR_x,CHAR_e,CHAR_d,CHAR_SPACE,CHAR_i,CHAR_n,CHAR_SPACE,CHAR_N,CHAR_o,CHAR_r,CHAR_w,CHAR_a,CHAR_y

.hword 0x1482,28,CHAR_U,CHAR_s,CHAR_e,CHAR_SPACE,CHAR_D,CHAR_MINUS,CHAR_p,CHAR_a,CHAR_d,CHAR_SPACE,CHAR_t,CHAR_o,CHAR_SPACE,CHAR_t,CHAR_o,CHAR_g,CHAR_g,CHAR_l,CHAR_e,CHAR_SPACE,CHAR_c,CHAR_h,CHAR_a,CHAR_n,CHAR_n,CHAR_e,CHAR_l,CHAR_s
.hword 0

.extern dma3
.extern init_sound
.extern song_song
.extern start_song
.extern tracks
.extern sound_status
