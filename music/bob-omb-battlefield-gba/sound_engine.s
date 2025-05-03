.equ TRACK_PATTERN_PTR_WORD,    0
.equ TRACK_ENVELOPE_PTR_WORD,   4
.equ TRACK_PERIOD_HWORD,        8
.equ TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD, 10
.equ TRACK_SPEED_BYTE,          12
.equ TRACK_TICK_BYTE,           13
.equ TRACK_PATTERN_ROWCOUNT_BYTE, 14
.equ TRACK_PATTERN_ROW_BYTE,    15
.equ TRACK_PATTERN_ROWSTATUS_BYTE, 16
.equ TRACK_ORDER_POS_BYTE,      17
.equ TRACK_EFFECT_KIND_BYTE,    18
.equ TRACK_EFFECT_PARAM_BYTE,   19
.equ TRACK_EFFECT_POS_BYTE,     20
.equ TRACK_EFFECT_PORTAMENTO_CTRL_BYTE, 21
.equ TRACK_MASTERVOL_BYTE,      22
.equ TRACK_PERIODINDEX_BYTE,    23
.equ TRACK_SQUARE_DUTYCTRL_BYTE, 24
.equ TRACK_ENVELOPE_PHASE_BYTE, 25
.equ TRACK_ENVELOPE_POS_BYTE,   26
.equ TRACK_ENVELOPE_VOL_BYTE,   27
.equ TRACK_ENVELOPE_STEP_BYTE,  28
.equ TRACK_ENVELOPE_DEST_BYTE,  29
.equ TRACK_ENVELOPE_HOLD_BYTE,  30
.equ TRACK_SIZEOF,              32

.equ NUM_TRACKS, 4

.equ INSTRUMENT_ENVELOPE_PTR_WORD, 0
.equ INSTRUMENT_EFFECT_KIND_BYTE, 4
.equ INSTRUMENT_EFFECT_PARAM_BYTE, 5
.equ INSTRUMENT_SQUARE_DUTYCTRL_BYTE, 6

.equ ENV_RESET, 0x80
.equ ENV_PROCESS, 0x40
.equ ENV_SUSTAIN, 0x20

.equ NO_EFFECT, 0
.equ SLIDE_UP_EFFECT, 1
.equ SLIDE_DOWN_EFFECT, 2
.equ PORTAMENTO_EFFECT, 3
.equ VIBRATO_EFFECT, 4
.equ ARPEGGIO_EFFECT, 5
.equ VOLUME_SLIDE_EFFECT, 6
.equ CUT_EFFECT, 7

.equ SOUND_CONTROL_REGISTERS_BASE_ADDRESS, 0x04000060
.equ SOUND1CNT_L, 0x00
.equ SOUND1CNT_H, 0x02
.equ SOUND1CNT_X, 0x04
.equ SOUND2CNT_L, 0x08
.equ SOUND2CNT_H, 0x0c
.equ SOUND3CNT_L, 0x10
.equ SOUND3CNT_H, 0x12
.equ SOUND3CNT_X, 0x14
.equ SOUND4CNT_L, 0x18
.equ SOUND4CNT_H, 0x1c
.equ SOUNDCNT_L, 0x20
.equ SOUNDCNT_H, 0x22
.equ SOUNDCNT_X, 0x24
.equ WAVERAM, 0x30

.section .rodata
.align 4
NR43_values:
.byte 0xf7,0xf3,0xe5,0xd7,0xe3,0xd5,0xe2,0xc7 @ 0-7
.byte 0xd3,0xc5,0xd2,0xb7,0xb6,0xb5,0xd1,0xa7 @ 8-15
.byte 0xa6,0xa5,0xc1,0x97,0xa3,0x95,0xa2,0x87 @ 16-23
.byte 0x86,0x85,0x92,0x77,0x76,0x75,0x74,0x67 @ 24-31
.byte 0x66,0x65,0x81,0x57,0x63,0x55,0x71,0x47 @ 32-39
.byte 0x53,0x45,0x52,0x37,0x43,0x35,0x60,0x27 @ 40-47
.byte 0x33,0x25,0x41,0x17,0x16,0x15,0x14,0x07 @ 48-55
.byte 0x13,0x05,0x04,0x03,0x02,0x01,0x00,0x00 @ 56-63

@ ProTracker sine table
vibrato_table:
.byte 0x00,0x18,0x31,0x4A,0x61,0x78,0x8D,0xA1
.byte 0xB4,0xC5,0xD4,0xE0,0xEB,0xF4,0xFA,0xFD
.byte 0xFF,0xFD,0xFA,0xF4,0xEB,0xE0,0xD4,0xC5
.byte 0xB4,0xA1,0x8D,0x78,0x61,0x4A,0x31,0x18

period_table:
.hword 0x02c,0x09d,0x107,0x16b,0x1ca,0x223,0x277,0x2c7,0x311,0x358,0x39b,0x3db @ 0-11
.hword 0x416,0x44e,0x483,0x4b6,0x4e5,0x511,0x53c,0x563,0x589,0x5ac,0x5ce,0x5ed @ 12-23
.hword 0x60b,0x627,0x642,0x65b,0x672,0x689,0x69e,0x6b2,0x6c4,0x6d6,0x6e7,0x6f7 @ 24-35
.hword 0x706,0x714,0x721,0x72d,0x739,0x744,0x74f,0x759,0x762,0x76b,0x773,0x77b @ 36-47
.hword 0x783,0x78a,0x791,0x797,0x79d,0x7a3,0x7a8,0x7ad,0x7b2,0x7b6,0x7ba,0x7be @ 48-59
.hword 0x7c2,0x7c5,0x7c9,0x7cc,0x7cf,0x7d2,0x7d4,0x7d7,0x7d9,0x7db,0x7dd,0x7df @ 60-71

volume_table:
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00      @ MasterVol = 0
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01      @ 1
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02      @ 2
.byte 0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x02,0x02,0x02,0x02,0x02,0x03      @ 3
.byte 0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x02,0x02,0x02,0x02,0x03,0x03,0x03,0x04      @ ..
.byte 0x00,0x00,0x00,0x01,0x01,0x01,0x02,0x02,0x02,0x03,0x03,0x03,0x04,0x04,0x04,0x05
.byte 0x00,0x00,0x00,0x01,0x01,0x02,0x02,0x02,0x03,0x03,0x04,0x04,0x04,0x05,0x05,0x06
.byte 0x00,0x00,0x00,0x01,0x01,0x02,0x02,0x03,0x03,0x04,0x04,0x05,0x05,0x06,0x06,0x07
.byte 0x00,0x00,0x01,0x01,0x02,0x02,0x03,0x03,0x04,0x04,0x05,0x05,0x06,0x06,0x07,0x08
.byte 0x00,0x00,0x01,0x01,0x02,0x03,0x03,0x04,0x04,0x05,0x06,0x06,0x07,0x07,0x08,0x09
.byte 0x00,0x00,0x01,0x02,0x02,0x03,0x04,0x04,0x05,0x06,0x06,0x07,0x08,0x08,0x09,0x0A
.byte 0x00,0x00,0x01,0x02,0x02,0x03,0x04,0x05,0x05,0x06,0x07,0x08,0x08,0x09,0x0A,0x0B
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x04,0x05,0x06,0x07,0x08,0x08,0x09,0x0A,0x0B,0x0C
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E
.byte 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F

default_wav_ram:
@ bank 0
.byte 0x11, 0x23, 0x56, 0x78, 0xa9, 0x98, 0x76, 0x57
.byte 0x9a, 0xdf, 0xfe, 0xc9, 0x85, 0x42, 0x11, 0x31
@ bank 1
.byte 0x11, 0x23, 0x56, 0x78, 0xa9, 0x98, 0x76, 0x57
.byte 0x9a, 0xdf, 0xfe, 0xc9, 0x85, 0x42, 0x11, 0x31

.section .bss
.align 4
tracks: .space NUM_TRACKS * TRACK_SIZEOF

.align 4
instrument_table_ptr: .space 4
pattern_table_ptr: .space 4
order_table_ptr: .space 4
master_vol: .space 1
sound_status: .space 1
shadow_nr12: .space 1
shadow_nr22: .space 1
shadow_nr32: .space 1
shadow_nr42: .space 1

.section .text
.global init_sound
.global start_song
.global update_sound
.global sound_status
.extern jump_table
.code 32

init_sound:
    ldr r0, =SOUND_CONTROL_REGISTERS_BASE_ADDRESS
    ldr r1, =0x80
    strh r1, [r0, #SOUNDCNT_X]
    ldr r1, =8
    strh r1, [r0, #SOUND1CNT_L] @ disable sweep
    ldr r1, =0xff77 @ all sound output, vol max
    strh r1, [r0, #SOUNDCNT_L]
    ldr r1, =0x02 @ full-range output sounds 1-4
    strh r1, [r0, #SOUNDCNT_H]
    ldr r0, =sound_status
    mov r1, #0
    strb r1, [r0] @ unmute all channels
    ldr r0, =default_wav_ram
    b copy_from_r0_into_waveram

@ r0 = pointer to song
start_song:
    ldr r1, [r0], #4
    ldr r2, =instrument_table_ptr
    str r1, [r2]
    ldr r1, [r0], #4
    ldr r2, =pattern_table_ptr
    str r1, [r2]
    ldr r1, =tracks
    ldrb r2, =NUM_TRACKS
    1: @ loop
    ldrb r3, [r0], #1
    strb r3, [r1, #TRACK_ORDER_POS_BYTE]
    cmp r3, #0xff
    beq 2f @ skip
    ldrb r3, [r0], #1 @ fetch initial speed
@    lsl r3, r3, #3 @ slow it down by factor of 8 - useful for debugging
    2: @ skip
    strb r3, [r1, #TRACK_SPEED_BYTE]
    subs r3, r3, #1
    strb r3, [r1, #TRACK_TICK_BYTE]
    eor r3, r3, r3
    strb r3, [r1, #TRACK_EFFECT_KIND_BYTE]
    strb r3, [r1, #TRACK_PERIODINDEX_BYTE]
    strh r3, [r1, #TRACK_PERIOD_HWORD]
    strb r3, [r1, #TRACK_ENVELOPE_PHASE_BYTE]
    strb r3, [r1, #TRACK_PATTERN_ROW_BYTE]
    add r3, r3, #1
    strb r3, [r1, #TRACK_PATTERN_ROWCOUNT_BYTE]
    ldrb r3, =0xf0 @ max volume
    strb r3, [r1, #TRACK_MASTERVOL_BYTE]
    add r1, r1, #TRACK_SIZEOF
    subs r2, r2, #1
    bne 1b @ loop
    ldr r1, =order_table_ptr
    str r0, [r1]
    ldr r1, =master_vol
    strb r3, [r1] @ max volume
    bx lr

copy_from_r0_into_waveram:
    ldr r1, =(SOUND_CONTROL_REGISTERS_BASE_ADDRESS + WAVERAM)
@ bank 0
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
@ bank 1
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    bx lr

update_sound:
    push {r4, r5, lr}
    ldr r0, =tracks
    ldrb r1, =NUM_TRACKS
update_sound__loop:
    ldrb r2, [r0, #TRACK_SPEED_BYTE]
    cmp r2, #0xff @ is track used?
    beq update_sound__next_track
    @ process track
    ldrb r3, [r0, #TRACK_TICK_BYTE]
    add r3, r3, #1
    cmp r3, r2 @ tick == speed?
    beq update_sound__next_row
    strb r3, [r0, #TRACK_TICK_BYTE]
    b update_sound__mixer_tick
update_sound__next_row:
    eor r3, r3, r3
    strb r3, [r0, #TRACK_TICK_BYTE]
    ldrb r2, [r0, #TRACK_PATTERN_ROWCOUNT_BYTE]
    ldrb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    add r3, r3, #1
    cmp r3, r2 @ row == rowCount?
    bne update_sound__no_new_pattern
    @ end of pattern
    eor r3, r3, r3
    strb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    ldr r2, =order_table_ptr
    ldr r2, [r2]
    ldrb r3, [r0, #TRACK_ORDER_POS_BYTE]
update_sound__order_loop:
    ldrb r4, [r2, r3] @ order_table[order_pos]
    add r3, r3, #1
    cmp r4, #0xf0
    bcs update_sound__order_special
    @ r4 = pattern index
    strb r3, [r0, #TRACK_ORDER_POS_BYTE]
    ldr r2, =pattern_table_ptr
    ldr r2, [r2]
    ldr r2, [r2, r4, lsl #2] @ pattern_table[index]
    ldrb r3, [r2], #1 @ first byte of pattern is the row count
    strb r3, [r0, #TRACK_PATTERN_ROWCOUNT_BYTE]
    b update_sound__fetch_row_status
update_sound__order_special:
    @ TODO: implement order commands. Assume 0xfe for now
    ldrb r3, [r2, r3] @ order_table[order_pos]
    b update_sound__order_loop
update_sound__no_new_pattern:
    strb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    ands r3, r3, #7
    ldrb r3, [r0, #TRACK_PATTERN_ROWSTATUS_BYTE]
    ldr r2, [r0, #TRACK_PATTERN_PTR_WORD]
    bne update_sound__check_row_status
update_sound__fetch_row_status:
    ldrb r3, [r2], #1
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
update_sound__check_row_status:
    lsrs r3, r3, #1
    strb r3, [r0, #TRACK_PATTERN_ROWSTATUS_BYTE]
    bcc update_sound__mixer_tick
update_sound__pattern_fetch_loop:
    ldrb r3, [r2], #1 @ fetch pattern byte
    cmp r3, #0xb0
    bcc update_sound__is_note
    cmp r3, #0xc0
    bcc update_sound__is_set_instrument_command
    cmp r3, #0xd0
    bcc update_sound__is_set_speed_command
    cmp r3, #0xe0
    bcc update_sound__is_set_volume_command
    cmp r3, #0xf0
    bcs update_sound__is_other_command
    @ set effect and param
    ands r3, r3, #0x0f
    strb r3, [r0, #TRACK_EFFECT_KIND_BYTE]
    beq update_sound__pattern_fetch_loop @ effect = 0 --> no parameter byte
    ldrb r3, [r2], #1
    strb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    eor r3, r3, r3
    strb r3, [r0, #TRACK_EFFECT_POS_BYTE]
    b update_sound__pattern_fetch_loop
update_sound__is_note:
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
    eor r2, r2, r2
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    strh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    ldrb r2, [r0, #TRACK_MASTERVOL_BYTE]
    lsrs r2, r2, #1
    bcs 1f @ skip @ CF=1 if the volume has been overridden by a previous volume command
    ldrb r2, =0x78
    1: @ skip
    lsl r2, r2, #1
    strb r2, [r0, #TRACK_MASTERVOL_BYTE]
    ldrb r2, =ENV_RESET
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    ldrb r2, [r0, #TRACK_EFFECT_KIND_BYTE]
    cmp r2, #PORTAMENTO_EFFECT
    beq update_sound__init_slide
    @ no slide, set new period immediately
    add r3, r3, r3
    ldr r2, =period_table
    ldrh r2, [r2, r3] @ period_table[index]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    lsr r3, r3, #1
    orr r3, r3, #0x80 @ trigger channel
    strb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    ldrb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    and r2, r3, #0x0c @ initial counter
    lsr r2, r2, #2
    bic r3, r3, #0x03
    orr r3, r3, r2 @ copy initial counter to current counter
    strb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    b update_sound__mixer_tick
update_sound__is_set_instrument_command:
    and r3, r3, #0x0f @ instrument in lower 4 bits
    bl set_instrument
    b update_sound__pattern_fetch_loop
update_sound__is_set_speed_command:
    and r3, r3, #0x0f @ new speed - 1
    add r3, r3, #1
    push {r0}
    bl set_speed
    pop {r0}
    b update_sound__pattern_fetch_loop
update_sound__is_set_volume_command:
    and r3, r3, #0x0f
    lsl r3, r3, #4
    orr r3, r3, #1 @ indicates that volume was explicitly set
    strb r3, [r0, #TRACK_MASTERVOL_BYTE]
    b update_sound__pattern_fetch_loop
update_sound__is_other_command:
    push {r0, r1}
    and r0, r3, #0x0f
    bl go_pattern_command @ is responsible for pop {r0, r1}
    bcs update_sound__pattern_fetch_loop
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
    b update_sound__mixer_tick
update_sound__init_slide:
    ldrb r2, [r0, #TRACK_PERIODINDEX_BYTE]
    cmp r3, r2 @ CF = slide direction (0=down, 1=up)
    strb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    ldr r2, =0x80
    adc r2, r2, #0 @ bit 7 = 1 (active), bit 0 = direction (0=down, 1=up)
    strb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    add r3, r3, r3 @ note * 2
    ldr r2, =period_table
    ldrh r2, [r2, r3]
    strh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
update_sound__mixer_tick:
    bl effect_tick
    bl envelope_tick
update_sound__next_track:
    add r0, r0, #TRACK_SIZEOF
    subs r1, r1, #1
    bne update_sound__loop
    @ write to audio hw regs
    ldr r0, =tracks
    ldr r1, =SOUND_CONTROL_REGISTERS_BASE_ADDRESS
    bl render_channel1
    bl render_channel2
    bl render_channel3
    bl render_channel4
    pop {r4, r5, lr}
    bx lr

@@@@@@@@ render state to hardware registers @@@@@@@

@ r0 = tracks pointer
@ r1 = SOUND_CONTROL_REGISTERS_BASE_ADDRESS
render_channel1:
    @ NR11
    ldrb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    tst r3, #3
    bne 1f @ if counter is non-zero, use duty from bits 6-7
    lsl r3, r3, #2 @ use duty from bits 4-5
    1:
    and r3, r3, #0xc0
    strb r3, [r1, #0x002]

    @ NR12
    ldrb r2, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    lsr r2, r2, #4
    ldrb r4, [r0, #TRACK_MASTERVOL_BYTE]
    orr r2, r2, r4
    ldr r4, =volume_table
    ldrb r2, [r4, r2] @ envelope volume scaled according to track volume (0..F)
    ldr r5, =master_vol
    ldrb r5, [r5]
    orr r2, r2, r5
    ldrb r2, [r4, r2] @ computed track volume scaled according to master volume (0..F)
    ldrb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    tst r3, #0x80 @ check trigger flag
    ldr r3, =shadow_nr12
    beq render_channel1__adjust_volume
    @ thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    strb r2, [r3]
    lsl r2, r2, #4 @ initial channel volume in upper 4 bits
    orr r2, r2, #8
    strb r2, [r1, #0x003]
    b render_channel1__write_nr13
render_channel1__adjust_volume:
    ldrb r4, [r3] @ old volume
    cmp r2, r4
    strb r2, [r3] @ new volume
    beq render_channel1__write_nr13 @ jump if no change in volume
    bcc render_channel1__decrease_volume @ old volume > new volume
    @ increase volume
    sub r2, r2, r4 @ new volume - old volume
    mov r3, #8
    5: @ inc_volume_loop
    strb r3, [r1, #0x003]
    subs r2, r2, #1
    bne 5b @ inc_volume_loop
    b render_channel1__write_nr13
render_channel1__decrease_volume:
    sub r2, r2, r4 @ new volume - old volume
    add r2, r2, #16
    mov r3, #8
    6: @ dec_volume_loop
    strb r3, [r1, #0x003]
    subs r2, r2, #1
    bne 6b @ dec_volume_loop
render_channel1__write_nr13:
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #1
    beq render_channel1__not_muted
    ldr r2, =0x7fff
    strh r2, [r1, #SOUND1CNT_X]
    b render_channel1__update_square_duty @ TODO: change GB sound engine to match behavior
render_channel1__not_muted:
    ldrh r2, [r0, #TRACK_PERIOD_HWORD]
    ldrb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    2: @ no_trigger
    strh r2, [r1, #SOUND1CNT_X]
render_channel1__update_square_duty:
    ldrb r2, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    tst r2, #3
    beq 3f @ skip_duty_update
    sub r2, r2, #1
    strb r2, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    3: @ skip_duty_update
    bx lr

@ r0 = tracks pointer
@ r1 = SOUND_CONTROL_REGISTERS_BASE_ADDRESS
render_channel2:
    @ NR21
    ldrb r3, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    tst r3, #3
    bne 1f @ if counter is non-zero, use duty from bits 6-7
    lsl r3, r3, #2 @ use duty from bits 4-5
    1:
    and r3, r3, #0xc0
    strb r3, [r1, #0x008]

    @ NR22
    ldrb r2, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*1)]
    lsr r2, r2, #4
    ldrb r4, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*1)]
    orr r2, r2, r4
    ldr r4, =volume_table
    ldrb r2, [r4, r2] @ envelope volume scaled according to track volume (0..F)
    ldr r5, =master_vol
    ldrb r5, [r5]
    orr r2, r2, r5
    ldrb r2, [r4, r2] @ computed track volume scaled according to master volume (0..F)
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*1)]
    tst r3, #0x80 @ check trigger flag
    ldr r3, =shadow_nr22
    beq render_channel2__adjust_volume
    @ thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    strb r2, [r3]
    lsl r2, r2, #4 @ initial channel volume in upper 4 bits
    orr r2, r2, #8
    strb r2, [r1, #0x009]
    b render_channel2__write_nr23
render_channel2__adjust_volume:
    ldrb r4, [r3] @ old volume
    cmp r2, r4
    strb r2, [r3] @ new volume
    beq render_channel2__write_nr23 @ jump if no change in volume
    bcc render_channel2__decrease_volume @ old volume > new volume
    @ increase volume
    sub r2, r2, r4 @ new volume - old volume
    mov r3, #8
    5: @ inc_volume_loop
    strb r3, [r1, #0x009]
    subs r2, r2, #1
    bne 5b @ inc_volume_loop
    b render_channel2__write_nr23
render_channel2__decrease_volume:
    sub r2, r2, r4 @ new volume - old volume
    add r2, r2, #16
    mov r3, #8
    6: @ dec_volume_loop
    strb r3, [r1, #0x009]
    subs r2, r2, #1
    bne 6b @ dec_volume_loop
render_channel2__write_nr23:
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #2
    beq render_channel2__not_muted
    ldr r2, =0x7fff
    strh r2, [r1, #SOUND2CNT_H]
    b render_channel2__update_square_duty @ TODO: change GB sound engine to match behavior
render_channel2__not_muted:
    ldrh r2, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*1)]
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*1)]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*1)]
    2: @ no_trigger
    strh r2, [r1, #SOUND2CNT_H]
render_channel2__update_square_duty:
    ldrb r2, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    tst r2, #3
    beq 3f @ skip_duty_update
    sub r2, r2, #1
    strb r2, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    3: @ skip_duty_update
    bx lr

@ r0 = tracks pointer
@ r1 = SOUND_CONTROL_REGISTERS_BASE_ADDRESS
render_channel3:
    @ NR32
    ldrb r2, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*2)]
    lsr r2, r2, #4
    ldrb r3, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*2)]
    orr r2, r2, r3
    ldr r4, =volume_table
    ldrb r2, [r4, r2] @ envelope volume scaled according to track volume (0..F)
    ldr r3, =master_vol
    ldrb r3, [r3]
    orr r2, r2, r3
    ldrb r2, [r4, r2] @ computed track volume scaled according to master volume (0..F)
    ldr r3, =shadow_nr32
    strb r2, [r3]
    lsl r2, r2, #11 @ volume in bits 14-13
    ands r2, r2, #0x6000
    beq render_channel3__write_nr32 @ mute (no sound)
    tst r2, #0x2000
    beq render_channel3__write_nr32 @ 50% volume
    eor r2, r2, #0x4000 @ 100% or 25% volume
render_channel3__write_nr32:
    strh r2, [r1, #SOUND3CNT_H]
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #4
    beq render_channel3__not_muted
    ldr r2, =0x7fff
    strh r2, [r1, #SOUND3CNT_X]
    bx lr
render_channel3__not_muted:
    @ NR33 and NR34
    ldrh r2, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*2)]
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*2)]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*2)]
    2: @ no_trigger
    strh r2, [r1, #SOUND3CNT_X]
    ldr r2, =0xc0
    strh r2, [r1, #SOUND3CNT_L]
    bx lr

render_channel4:
    @ NR42
    ldrb r2, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*3)]
    lsr r2, r2, #4
    ldrb r4, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*3)]
    orr r2, r2, r4
    ldr r4, =volume_table
    ldrb r2, [r4, r2] @ envelope volume scaled according to track volume (0..F)
    ldr r5, =master_vol
    ldrb r5, [r5]
    orr r2, r2, r5
    ldrb r2, [r4, r2] @ computed track volume scaled according to master volume (0..F)
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    tst r3, #0x80 @ check trigger flag
    ldr r3, =shadow_nr42
    beq render_channel4__adjust_volume
    @ thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    strb r2, [r3]
    lsl r2, r2, #12 @ initial channel volume in upper 4 bits
    orr r2, r2, #0x800
    strh r2, [r1, #SOUND4CNT_L]
    b render_channel4__write_nr43
render_channel4__adjust_volume:
    ldrb r4, [r3] @ old volume
    cmp r2, r4
    strb r2, [r3] @ new volume
    beq render_channel4__write_nr43 @ jump if no change in volume
    bcc render_channel4__decrease_volume @ old volume > new volume
    @ increase volume
    sub r2, r2, r4 @ new volume - old volume
    mov r3, #0x800
    5: @ inc_volume_loop
    strh r3, [r1, #SOUND4CNT_L]
    subs r2, r2, #1
    bne 5b @ inc_volume_loop
    b render_channel4__write_nr43
render_channel4__decrease_volume:
    sub r2, r2, r4 @ new volume - old volume
    add r2, r2, #16
    mov r3, #0x800
    6: @ dec_volume_loop
    strh r3, [r1, #SOUND4CNT_L]
    subs r2, r2, #1
    bne 6b @ dec_volume_loop
render_channel4__write_nr43:
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #8
    beq render_channel4__not_muted
    ldr r2, =0x7fff
    strh r2, [r1, #SOUND4CNT_H]
    bx lr
render_channel4__not_muted:
    ldrh r2, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*3)]
    lsr r2, r2, #5 @ divide by 32
    ldr r3, =NR43_values
    ldrb r2, [r3, r2]
    ldrb r3, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*3)]
    tst r3, #0x80 @ LFSR width
    beq 1f @ no_regular_output
    orr r2, r2, #8 @ 7-bit output
    1: @ no_regular_output
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    2: @ no_trigger
    strh r2, [r1, #SOUND4CNT_H]
    bx lr

@@@@@@@@ effects @@@@@@@

effect_tick:
    push {r0, r1}
    ldrb r0, [r0, #TRACK_EFFECT_KIND_BYTE]
    ldr r1, =1f
    b jump_table
.align 4
    1:
.word null_effect_tick @ 0
.word slide_up_effect_tick @ 1
.word slide_down_effect_tick @ 2
.word portamento_effect_tick @ 3
.word vibrato_effect_tick @ 4
.word arpeggio_effect_tick @ 5
.word volume_slide_effect_tick @ 6
.word tremolo_effect_tick @ 7
.word cut_effect_tick @ 8
.word pulsemod_effect_tick @ 9

null_effect_tick:
    pop {r0, r1}
    bx lr

slide_up_effect_tick:
    @ slide up by adding slide amount to period value
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    add r3, r3, r2
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr

slide_down_effect_tick:
    @ slide down by subtracting slide amount from period value
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    sub r3, r3, r2
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr

portamento_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    tst r2, #0x80 @ active?
    beq 1f @ portamento_exit
    tst r2, #1 @ direction (0=down, 1=up)
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    beq 2f @ portamento_down
    @ slide up (add delta to current period value)
    add r3, r3, r2
    @ check if target period has been reached (current period >= target period)
    ldrh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    cmp r3, r2
    bcs 3f @ portamento_done
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr
    2: @portamento_down
    @ slide down (subtract delta from current period value)
    sub r3, r3, r2
    @ check if target period has been reached (current period <= target period)
    ldrh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    cmp r2, r3
    bcs 3f @ portamento_done
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr
    3: @ portamento_done
    @ set final period
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ halt
    eor r2, r2, r2
    strb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    1: @portamento_exit
    bx lr

vibrato_effect_tick:
    pop {r0, r1}
    @ reset period value
    ldrb r2, [r0, #TRACK_PERIODINDEX_BYTE]
    bic r2, r2, #0x80 @ remove trigger flag
    add r2, r2, r2
    ldr r3, =period_table
    ldrh r2, [r2, r3]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ get sine value
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    and r2, r2, #0x1f
    ldr r3, =vibrato_table
    ldrb r2, [r3, r2]
    @ *** convert sine value to real delta freq, according to vibrato depth ***
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    and r3, r3, #0x0f @ VibratoDepth in lower 4 bits
    eor r4, r4, r4
    @ this loop performs SineValue*VibratoDepth, putting result in r4
    1:
    add r4, r2
    subs r3, r3, #1
    bne 1b
    @ compute (SineValue*VibratoDepth)/128
    lsr r3, r4, #7
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    tst r2, #0x20
    ldrh r2, [r0, #TRACK_PERIOD_HWORD]
    beq 2f @ vib_add
    @ subtract from period
    sub r2, r2, r3
    b 3f @ vib_done
    2: @ vib_add
    @ add to period
    add r2, r2, r3
    3: @ vib_done
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ increment pos
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    lsr r3, r3, #4 @ vibrato speed
    add r2, r2, r3
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    bx lr

arpeggio_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    add r3, r2, #1
    cmp r3, #6 @ TODO: update GB sound engine to match behavior
    bcc 1f
    eor r3, r3, r3
    1:
    strb r3, [r0, #TRACK_EFFECT_POS_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    lsrs r2, r2, #1
    beq 2f @ set_period - use base note
    subs r2, r2, #1
    beq 3f @ use_mid_note
    @ use top note
    and r2, r3, #0x0f
    b 2f @ set_period
    3: @ use_mid_note
    lsr r2, r3, #4
    2: @ set_period
    ldrb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    bic r3, r3, #0x80 @ remove trigger flag
    add r2, r2, r3
    add r2, r2, r2
    ldr r3, =period_table
    ldrh r2, [r3, r2]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    bx lr

volume_slide_effect_tick:
    pop {r0, r1}
    @ TODO: implement volume slide
    bx lr

tremolo_effect_tick:
    pop {r0, r1}
    @ TODO: implement tremolo
    bx lr

cut_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_POS_BYTE]
    @ TODO: update GB sound engine to do increment _after_ compare
    cmp r3, r2
    bcs 1f
    add r2, r3, #1
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    bx lr
    1: @ cut! (set volume to 0)
    eor r2, r2, r2
    strb r2, [r0, #TRACK_MASTERVOL_BYTE]
    bx lr

pulsemod_effect_tick:
    pop {r0, r1}
    @ TODO: implement pulsemod
    bx lr

@@@@@@@@ volume envelopes @@@@@@@

envelope_tick:
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    tst r2, #ENV_RESET
    bne envelope_init
    tst r2, #ENV_PROCESS
    bne envelope_process
    tst r2, #ENV_SUSTAIN
    bne envelope_sustain
    bx lr

envelope_init:
    lsr r2, r2, #1 @ ENV_PROCESS
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    ldr r2, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r4, [r2] @ 1st byte = start volume
    strb r4, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    ldr r3, =1
envelope_point_init:
    ldrb r4, [r2, r3] @ fetch envelope byte
    add r3, r3, #1
    cmp r4, #0xff @ end of envelope reached?
    beq 1f @ env_end
    @ point OK, set 3-tuple (step, dest, hold)
    strb r4, [r0, #TRACK_ENVELOPE_STEP_BYTE]
    ldrb r4, [r2, r3]
    add r3, r3, #1
    strb r4, [r0, #TRACK_ENVELOPE_DEST_BYTE]
    ldrb r4, [r2, r3]
    add r3, r3, #1
    strb r4, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    strb r3, [r0, #TRACK_ENVELOPE_POS_BYTE]
    bx lr @ b envelope_process @ TODO: update GB sound engine to match behavior

    1: @ env_end
    ldrb r3, [r2, r3]
    cmp r3, #0xff @ definitely end?
    bne envelope_point_init @ loop the envelope from the given offset
    eor r3, r3, r3
    strb r3, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    bx lr

envelope_process:
    ldrb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    ldrb r2, [r0, #TRACK_ENVELOPE_DEST_BYTE]
    ldrb r4, [r0, #TRACK_ENVELOPE_STEP_BYTE]
    cmp r2, r3
    bcc 1f @ dest < current --> sub_volume
    @ add step to vol
    add r3, r3, r4
    cmp r3, r2
    bcs 2f @ reached_dest
    strb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    bx lr
    1: @ sub_volume
    @ subtract step from volume
    subs r3, r3, r4
    bcc 2f @ reached_dest
    cmp r3, r2
    beq 2f @ reached_dest
    strb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    bx lr
    2: @ reached_dest
    strb r2, [r0, #TRACK_ENVELOPE_VOL_BYTE] @ dest
    ldrb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    orrs r2, r2, r2
    beq envelope_next_point
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    lsr r2, r2, #1 @ phase = sustain
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    bx lr
envelope_next_point:
    ldr r2, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r3, [r0, #TRACK_ENVELOPE_POS_BYTE]
    b envelope_point_init

envelope_sustain:
    ldrb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    cmp r2, #0xff @ hold forever?
    beq 1f @ keep_sustaining
    subs r2, r2, #1
    strb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    bne 1f @ keep_sustaining
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    lsl r2, r2, #1 @ ENV_PROCESS
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    b envelope_next_point
    1: @ keep_sustaining
    bx lr

@ r3 = new instrument
@ r4 is destroyed
set_instrument:
    lsl r3, r3, #3 @ each instrument is 8 bytes long
    ldr r4, =instrument_table_ptr
    ldr r4, [r4]
    add r4, r4, r3
    ldr r3, [r4, #INSTRUMENT_ENVELOPE_PTR_WORD]
    str r3, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r3, [r4, #INSTRUMENT_EFFECT_KIND_BYTE]
    strb r3, [r0, #TRACK_EFFECT_KIND_BYTE]
    ldrb r3, [r4, #INSTRUMENT_EFFECT_PARAM_BYTE]
    strb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrb r3, [r4, #INSTRUMENT_SQUARE_DUTYCTRL_BYTE]
    strb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    bx lr

@ r3 = new speed
@ r0 is destroyed
set_speed:
    ldr r0, =tracks
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*0)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*1)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*2)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*3)]
    bx lr

@@@@@@ pattern commands @@@@@@

go_pattern_command:
    ldr r1, =1f
    b jump_table
.align 4
    1:
.word set_instr_command
.word release_command
.word set_speed_command
.word end_row_command
.word pan_left_command
.word pan_center_command
.word pan_right_command

set_instr_command:
    pop {r0, r1}
    ldrb r3, [r2], #1 @ instrument
    push {lr}
    bl set_instrument
    pop {lr}
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

release_command:
    pop {r0, r1}
    ldrb r3, =1
    strb r3, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

set_speed_command:
    ldrb r3, [r2], #1 @ new speed
    push {lr}
    bl set_speed
    pop {lr}
    pop {r0, r1}
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

end_row_command:
    pop {r0, r1}
    ldrb r3, [r0, #TRACK_MASTERVOL_BYTE]
    bic r3, r3, #0x01 @ clear explicit set volume bit
    strb r3, [r0, #TRACK_MASTERVOL_BYTE]
    eor r3, r3, r3
    adds r3, r3, r3 @ clear carry flag to signal end of pattern data processing
    bx lr

pan_left_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

pan_center_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

pan_right_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr
