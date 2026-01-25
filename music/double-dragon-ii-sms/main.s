.include "hardware.inc"

.sdsctag 1.0, "Double Dragon II remix", "Original music Kazunaka Yamane", "@notube4me"
.COMPUTESMSCHECKSUM

.define CHAR_SPACE $00
.define CHAR_A $01
.define CHAR_B $02
.define CHAR_C $03
.define CHAR_D $04
.define CHAR_E $05
.define CHAR_F $06
.define CHAR_G $07
.define CHAR_H $08
.define CHAR_I $09
.define CHAR_J $0A
.define CHAR_K $0B
.define CHAR_L $0C
.define CHAR_M $0D
.define CHAR_N $0E
.define CHAR_O $0F
.define CHAR_P $10
.define CHAR_Q $11
.define CHAR_R $12
.define CHAR_S $13
.define CHAR_T $14
.define CHAR_U $15
.define CHAR_V $16
.define CHAR_W $17
.define CHAR_MINUS $18
.define CHAR_Y $19
.define CHAR_0 $1A
.define CHAR_a $1B
.define CHAR_b $1C
.define CHAR_c $1D
.define CHAR_d $1E
.define CHAR_e $1F
.define CHAR_f $20
.define CHAR_g $21
.define CHAR_h $22
.define CHAR_i $23
.define CHAR_j $24
.define CHAR_k $25
.define CHAR_l $26
.define CHAR_m $27
.define CHAR_n $28
.define CHAR_o $29
.define CHAR_p $2A
.define CHAR_q $2B
.define CHAR_r $2C
.define CHAR_s $2D
.define CHAR_t $2E
.define CHAR_u $2F
.define CHAR_v $30
.define CHAR_w $31
.define CHAR_x $32
.define CHAR_y $33
.define CHAR_z $34
.define CHAR_@ $37

.memorymap
defaultslot 0
slotsize $8000
slot 0 $0000
slotsize $2000
SLOT 1 START $C000 ; RAM
.endme

.rombankmap
bankstotal 1
banksize $8000
banks 1
.endro

.struct TrackHeader
    OrderTable dw
    PatternTable dw
    InstrumentTable dw
    Pad0 dw
.endst

.STRUCT Track
    Speed db                                  ; 00
    Tick db                                   ; 01
    Pattern_RowCount db                       ; 02
    Pattern_Row db                            ; 03
    Pattern_RowStatus db                      ; 04
    Pattern_Ptr dw                            ; 05
    Order_Pos db                              ; 07
    Effect_Kind db                            ; 08
    Effect_Param db                           ; 09
    .UNION
        Effect_Pos db                         ; 0A
    .NEXTU
        Effect_Portamento_Ctrl db             ; 0A - bit 7: done if zero, bit 0: direction
    .ENDU
    Effect_Portamento_TargetPeriodLo db       ; 0B
    Effect_Portamento_TargetPeriodHi db       ; 0C
    MasterVol db                              ; 0D
    PeriodIndex db                            ; 0E
    PeriodLo db                               ; 0F
    PeriodHi db                               ; 10
    InstrumentData db                         ; 11
    Envelope_Phase db                         ; 12
    Envelope_Ptr dw                           ; 13
    Envelope_Pos db                           ; 15
    Envelope_Vol db                           ; 16
    Envelope_Step db                          ; 17
    Envelope_Dest db                          ; 18
    Envelope_Hold db                          ; 19
    EffectiveVol db                           ; 1A
    Status db                                 ; 1B
.ENDST

.define MAX_TRACKS 13 ; 4 PSG + 9 FM

.RAMSECTION Ram_c000 align 256
vramBuffer: ds 256

vramBufferOffset: db
processingVBlank: db
pauseRequested: db
shadowVDP1: db
scrollX: db
scrollY: db
buttonsHeld: db
buttonsPressed: db
mainState: db
frameCounter: db
selectedTrackIndex: db

; --- Begin Sound engine

trackHeaderTable: dw

masterVol: db

shadowNoiseGeneratorReg: db

shadowRhythmControlReg: db
shadowRhythmVolumeRegs: ds 3

.align 32

tracks INSTANCEOF Track MAX_TRACKS

; --- End Sound engine
.ENDS

; --- RST area

.bank 0 slot 0
.org $0000

; RST 0
	jp   Begin

; RST 1
.org $0008
JumpTable:
	add  a
	pop  hl
	ld   e, a
	ld   d, 0
	add  hl, de
	ld   e, [hl]
	inc  hl
	ld   d, [hl]
	push de
	pop  hl
	jp   hl

; RST 7
.org $0038
VBlankInterrupt:
	jp  VBlankInterruptHandler

.org $0066
NonMaskableInterrupt:
    jp  PauseHandler

; Interrupt handlers

.section "Interrupt handlers" bank 0 slot 0 free

VBlankInterruptHandler:
    ; preserve regs
    push af
    in a, ($bf) ; satisfy interrupt
    push bc
    push de
    push hl

    ld a,[processingVBlank]
    or a
    jr nz, @skipVBlankProcessing
    inc a
    ld [processingVBlank], a

    ld a, [frameCounter]
    inc a
    ld [frameCounter], a

    call FlushVramBuffer
;    call hOamDmaFunction
    call SyncVDPRegisters
    call PollInput
    call UpdateSound
    call GoMainFunction

    ld hl, processingVBlank
    dec [hl]

    @skipVBlankProcessing:
    ; restore regs
    pop  hl
    pop  de
    pop  bc
    pop  af
    ei
    reti

PauseHandler:
    push af
    ld a, 1
    ld [pauseRequested], a
    pop af
    retn

.ends

.section "Support routines" bank 0 slot 0 free

; Destroys: a, b
PollInput:
    in a, ($DC)    ; Read D-Pad + Button 1 & 2
    cpl            ; Flip bits (1 = pressed)
    and %00111111  ; Mask out unused bits
    ld b, a
    ld a, [buttonsHeld]
	xor b
	and b
	ld [buttonsPressed], a
	ld a, b
	ld [buttonsHeld], a
    ret

GoMainFunction:
    ld a, [mainState]
    rst JumpTable
.dw MainFunc0

.ends

; --- Begin gfx-related procedures ---

.section "GFX-related routines" bank 0 slot 0 free

FlushVramBuffer:
    ld a, [vramBufferOffset]
    or a, a
    ret z
    xor a
    ld [vramBufferOffset], a
    ld hl, vramBuffer
    jr WriteVramStrings

WriteVramStrings:
    ; hl = address of data
    ld a, [hl]
    inc hl
    or a, a
    ret z
    ld d, a ; high address
    ld e, [hl] ; low address
    inc hl
    call SetVramAddress
    ld b, [hl] ; count
    inc hl
    @loop:
    ld a, [hl]
    inc hl
    out ($be), a
    dec b
    jr nz, @loop
    jr WriteVramStrings

; DE = start address
; C = count
; returns HL = vram buffer pointer
BeginVramString:
    ld hl, vramBuffer
    ld a, [vramBufferOffset]
    push bc
    ld b, 0
    ld c, a
    add hl, bc
    ld [hl], d ; high address
    inc l
    ld [hl], e ; low address
    inc l
    pop bc
    ld [hl], c ; count
    inc l
    ret

EndVramString:
    xor a
    ld [hl], a
    ld a, l
    sub a, <vramBuffer
    ld [vramBufferOffset], a
    ret

; DE = address
; destroys A
SetVramAddress:
    ld a, e
    out ($bf), a
    ld a, d
    or $40
    out ($bf), a
    ret

; HL = start address of data
; BC = count
CopyDataToVram:
    ld a,(hl)
    out ($be),a
    inc hl
    dec bc
    ld a,c
    or b
    jr nz, CopyDataToVram
    ret

TurnOnScreen:
    ld a, [shadowVDP1]
    or a, $40
    ld [shadowVDP1], a
    ret

.macro WriteVDPRegister args index
    out ($bf), a
    ld a, $80 | index
    out ($bf), a
.endm

SyncVDPRegisters:
    ld a, [shadowVDP1]
    WriteVDPRegister 1
    ld a, [scrollX]
    WriteVDPRegister 8
    ld a, [scrollY]
    WriteVDPRegister 9
    ret

SetUpVdpRegisters:
    ld a, $06
    WriteVDPRegister 0
    ld a, %10100001 ; enable vblank interrupt
    ld [shadowVDP1], a
    WriteVDPRegister 1
    ld a, $ff
    WriteVDPRegister 2 ; name table address
    ld a, $ff
    WriteVDPRegister 3 ; palette base address
    ld a, $ff
    WriteVDPRegister 4 ; pattern base address
    ld a, $ff
    WriteVDPRegister 5 ; sprite attribute table
    ld a, $ff
    WriteVDPRegister 6 ; sprite tile address
    ld a, $ff
    WriteVDPRegister 7 ; border color
    ld a, $ff
    WriteVDPRegister 10 ; no line interrupt
    ret

ClearVram:
    ld de, $4000
    call SetVramAddress
    ld bc, 1024*16 ; 16 KB
    @loop:
    xor a
    out ($be),a
    dec bc
    ld a,b
    or c
    jr nz, @loop
    ret

.ends

; --- End gfx-related procedures ---

; --- Begin sound engine ---

.section "Sound engine code" bank 0 slot 0 free

; HL = pointer to song
StartSong:
    ld a, [hl] ; channel count (unused)
    inc hl
    ld a, [hl] ; speed
    ; slow it down by 8x - useful for debugging
    ; sla a
    ; sla a
    ; sla a
    ld c, a
    inc hl
    ld [trackHeaderTable], hl
    ld b, MAX_TRACKS
    ld ix, tracks
    ld de, _sizeof_Track
    @loop:
    xor a, a
    ld [ix + Track.Order_Pos], a
    ld [ix + Track.Effect_Kind], a
    ld [ix + Track.Pattern_Row], a
    ld [ix + Track.PeriodIndex], a
    ld [ix + Track.PeriodLo], a
    ld [ix + Track.PeriodHi], a
    ld [ix + Track.Envelope_Phase], a
    inc a ; 1
    ld [ix + Track.Pattern_RowCount], a
    ld a, [hl] ; order table (lo)
    inc hl
    or a, [hl] ; order table (hi)
    ld a, c ; speed
    jr nz, @2 ; is channel in use?
    ld a, $ff ; speed ff signals to play routine that track is unused
    @2:
    dec a ; speed - 1
    ld [ix + Track.Tick], a
    inc a ; speed
    ld [ix + Track.Speed], a
    ld a, $f0
    ld [ix + Track.MasterVol], a
    ld a, l
    add a, _sizeof_TrackHeader - 1
    ld l, a
    jr nc, @3
    inc h
    @3:
    add ix, de
    dec b
    jr nz, @loop

    ld a, $f0
    ld [masterVol], a
    ret

; Volume envelope states
.define ENV_RESET $80
.define ENV_PROCESS $40
.define ENV_SUSTAIN $20

; Effect kinds
.define NO_EFFECT 0
.define SLIDE_UP_EFFECT 1
.define SLIDE_DOWN_EFFECT 2
.define PORTAMENTO_EFFECT 3
.define VIBRATO_EFFECT 4
.define ARPEGGIO_EFFECT 5
.define VOLUME_SLIDE_EFFECT 6
.define CUT_EFFECT 7

UpdateSound:
    ld b, 0 ; track index
    ld ix, tracks; + SIZEOF
    @loop:
    ld a, [ix + Track.Speed]
    cp a, $ff   ; is track used?
    jr nz, @process_track
    ld de, _sizeof_Track
    add ix, de
    jp @next_track
    @process_track:
    inc [ix + Track.Tick]
    cp a, [ix + Track.Tick] ; speed == tick?
    jr z, @next_row
    jp @mixer_tick
    @next_row:
    xor a, a
    ld [ix + Track.Tick], a
    ld a, [ix + Track.Pattern_RowCount]
    inc [ix + Track.Pattern_Row]
    cp a, [ix + Track.Pattern_Row]  ; rowCount == row?
    jr z, @end_of_pattern
    jr @no_new_pattern
    @end_of_pattern:
    xor a, a
    ld [ix + Track.Pattern_Row], a ; Pattern_Row = 0
    @pre_order_loop:
    ld de, [trackHeaderTable]
    ld a, b
    sla a
    sla a
    sla a ; track * 8
    add a, e
    ld e, a
    jr nc, @1
    inc d
    @1:
    ld a, [de] ; order table (lo)
    ld c, a
    inc de
    ld a, [de] ; order table (hi)
    ld d, a
    ld e, c
    ld a, [ix + Track.Order_Pos]
    add a, e
    ld e, a
    jr nc, @order_fetch_loop
    inc d
    @order_fetch_loop:
    ld a, [de] ; order byte
    inc de
    inc [ix + Track.Order_Pos]
    cp a, $f0 ; $f0 > a?
    jr nc, @order_special
    ; pattern number
    push af
    ld de, [trackHeaderTable]
    ld a, b
    sla a
    sla a
    sla a ; track * 8
    add a, e
    jr nc, @2
    inc d
    @2:
    add a, TrackHeader.PatternTable
    ld e, a
    jr nc, @3
    inc d
    @3:
    ld a, [de] ; pattern table (lo)
    ld c, a
    inc de
    ld a, [de] ; pattern table (hi)
    ld d, a
    ld e, c
    pop af
    add a, a ; pattern number * 2
    add a, e
    ld e, a
    jr nc, @skip_inc_d
    inc d
    @skip_inc_d:
    ld a, [de] ; pattern ptr (lo)
    ld [ix + Track.Pattern_Ptr], a
    inc de
    ld c, a
    ld a, [de] ; pattern ptr (hi)
    ld [ix + Track.Pattern_Ptr+1], a
    ld e, c
    ld d, a
    ld a, [de] ; row count
    inc de
    call IncPatternPtr
    ld [ix + Track.Pattern_RowCount], a
    jr @fetch_row_status
    @order_special:
    ; TODO: implement order commands. Assume $fe for now
    ld a, [de] ; order byte
    ld [ix + Track.Order_Pos], a
    jr @pre_order_loop
    @no_new_pattern:
    ld a, [ix + Track.Pattern_Row]
    and a, 7
    jr nz, @check_row_status
    ; prepare to fetch row status
    ld e, [ix + Track.Pattern_Ptr]
    ld d, [ix + Track.Pattern_Ptr+1]
    @fetch_row_status:
    ; DE = pattern data ptr
    ; fetch row status for upcoming 8 rows
    ld a, [de] ; pattern byte
    inc de
    ld [ix + Track.Pattern_RowStatus], a
    call IncPatternPtr
    @check_row_status:
    srl [ix + Track.Pattern_RowStatus]
    jr c, @process_pattern_data
    jp @mixer_tick
    @process_pattern_data:
    ld a, [ix + Track.Pattern_Row]
    and a, 7
    jr z, @pattern_fetch_loop
    ; for rows not multiple of 8, DE does not yet contain pattern data ptr because we didn't fetch row status byte
    ld e, [ix + Track.Pattern_Ptr]
    ld d, [ix + Track.Pattern_Ptr+1]
    @pattern_fetch_loop:
    ; DE = pattern data ptr
    ld a, [de] ; pattern byte
    inc de
    call IncPatternPtr
    cp a, $b0 ; $b0 > a? (is it an effect or a command?)
    jr c, @is_note
    cp a, $c0 ; a < $c0? (is it a set instrument command?)
    jr c, @is_set_instrument_command
    cp a, $d0 ; a < $d0? (is it a set speed command?)
    jr c, @is_set_speed_command
    cp a, $e0 ; a < $e0? (is it a set volume command?)
    jr c, @is_set_volume_command
    cp a, $f0 ; $f0 > a? (is it a command ( >= $f0)?)
    jr nc, @is_other_command
    ; set effect and param
    and a, $f
    jr z, @skip_inc ; effect = 0 --> no parameter byte
    call IncPatternPtr
    @skip_inc:
    ld [ix + Track.Effect_Kind], a
    or a, a
    jr z, @skip_effect_init
    ld a, [de] ; pattern byte: effect param
    inc de
    ld [ix + Track.Effect_Param], a
    @skip_effect_init:
    jr @pattern_fetch_loop
    @is_set_instrument_command:
    and a, $f ; instrument in lower 4 bits
    call SetInstrument
    jr @pattern_fetch_loop
    @is_set_speed_command:
    and a, $f ; new speed - 1 in lower 4 bits
    inc a
    call SetSpeed
    jr @pattern_fetch_loop
    @is_set_volume_command:
    sla a
    sla a
    sla a
    sla a ; new volume in upper 4 bits
    or a, 1 ; indicates that volume was explicitly set
    ld [ix + Track.MasterVol], a
    jr @pattern_fetch_loop
    @is_other_command:
    and a, $f
    call GoPatternCommand
    jr c, @pattern_fetch_loop
    jp @mixer_tick
    @is_note:
    ld c, a ; save note
    ld d, [ix + Track.Effect_Kind]
    ; clear effect state
    xor a, a
    ld [ix + Track.Effect_Pos], a
    ld [ix + Track.Effect_Portamento_TargetPeriodLo], a
    ld [ix + Track.Effect_Portamento_TargetPeriodHi], a
    ld a, [ix + Track.MasterVol]
    srl a
    jr c, @skip ; CF=1 if the volume has been overridden by a previous volume command
    ld a, $78
    @skip:
    sla a
    ld [ix + Track.MasterVol], a
    ld a, ENV_RESET
    ld [ix + Track.Envelope_Phase], a
    ld a, d ; effect kind
    cp a, PORTAMENTO_EFFECT
    jr z, @init_slide
    ; no slide, set new period immediately
    ld a, b ; track
    cp a, 4 ; < 4 means PSG
    ld hl, PSGPeriodTable
    jr c, @4
    ld hl, NoteToFMPeriod
    @4:
    ld a, l
    add a, c ; note
    add a, c ; note
    ld l, a
    ld d, [hl] ; period lo
    inc l
    ld a, [hl] ; period hi
    ld [ix + Track.PeriodHi], a
    ld [ix + Track.PeriodLo], d
    ld a, c
    or a, $80 ; trigger channel
    ld [ix + Track.PeriodIndex], a
    jp @mixer_tick
    @init_slide:
    ld a, [ix + Track.PeriodIndex]
    cp a, c ; CF = slide direction (0=down,1=up)
    push af ; save flags
    ld [ix + Track.PeriodIndex], c
    ld a, b ; track
    cp a, 4 ; < 4 means PSG
    ld hl, PSGPeriodTable
    jr c, @5
    ld hl, NoteToFMPeriod
    @5:
    ld a, l
    add a, c ; note
    add a, c ; note
    ld l, a
    ld d, [hl] ; period lo
    inc l
    ld a, [hl] ; period hi
    ld [ix + Track.Effect_Portamento_TargetPeriodHi], a
    ld [ix + Track.Effect_Portamento_TargetPeriodLo], d
    pop af ; restore flags
    ld a, $40
    rl a ; bit 7 = 1 (active), bit 0 = direction
    ld [ix + Track.Effect_Portamento_Ctrl], a
    @mixer_tick:
    ; update effect
    call EffectTick
    ; update envelope
    call EnvelopeTick
    @next_track:
    ld de, _sizeof_Track
    add ix, de
    inc b
    ld a, b
    cp a, MAX_TRACKS
    jp nz, @loop
    jr RenderChannels

RenderChannels:
    call RenderPSGChannels
    jp RenderFMChannels

RenderPSGChannels:
    call RenderPSGToneChannels
    jp RenderPSGNoiseChannel

RenderPSGToneChannels:
    call RenderPSGToneChannel1
    call RenderPSGToneChannel2
    jp RenderPSGToneChannel3

RenderPSGToneChannel1:
    ld ix, tracks
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, $9f ; tone 1 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld d, 0
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $90 ; tone 1 attenuation
    out ($7f), a ; write volume

    ld e, [ix + Track.PeriodLo]
    ld d, [ix + Track.PeriodHi]
    srl d
    rr e
    ld bc, $3ff
    ; subtract DE from BC
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a

    ld a, c ; PeriodLo
    and a, $0f
    or a, $80 ; tone generator 1
    out ($7f), a ; write lower 4 bits of period

    ld a, c ; PeriodLo
    srl a
    srl a
    srl a
    srl a
    ld d, a
    ld a, b ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, d
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderPSGToneChannel3:
    ld ix, tracks + _sizeof_Track*2
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, $df ; tone 3 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld d, 0
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $d0 ; tone 3 attenuation
    out ($7f), a ; write volume

    ld e, [ix + Track.PeriodLo]
    ld d, [ix + Track.PeriodHi]
    srl d
    rr e
    ld bc, $3ff
    ; subtract DE from BC
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a

    ld a, c ; PeriodLo
    and a, $0f
    or a, $c0 ; tone generator 3
    out ($7f), a ; write lower 4 bits of period

    ld a, c ; PeriodLo
    srl a
    srl a
    srl a
    srl a
    ld d, a
    ld a, b ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, d
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderPSGToneChannel2:
    ld ix, tracks + _sizeof_Track
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, $bf ; tone 2 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld d, 0
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $b0 ; tone 2 attenuation
    out ($7f), a ; write volume

    ld e, [ix + Track.PeriodLo]
    ld d, [ix + Track.PeriodHi]
    srl d
    rr e
    ld bc, $3ff
    ; subtract DE from BC
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a

    ld a, c ; PeriodLo
    and a, $0f
    or a, $a0 ; tone generator 2
    out ($7f), a ; write lower 4 bits of period

    ld a, c ; PeriodLo
    srl a
    srl a
    srl a
    srl a
    ld d, a
    ld a, b ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, d
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderPSGNoiseChannel:
    ld ix, tracks + _sizeof_Track*3
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, $ff ; noise attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld d, 0
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld e, a
    ld hl, PSGNoiseAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $f0 ; noise attenuation
    out ($7f), a ; write volume

    ld e, [ix + Track.PeriodHi] ; 0..7
    ld a, 7
    sub a, e
    srl a
    and a, 3
    cp a, 3
    jr nz, @no_clamp
    dec a
    @no_clamp:
    set 2, a ; white noise is default
    bit 7, [ix + Track.InstrumentData]; LFSR width
    jr z, @no_regular_output
    res 2, a ; synchronous noise
    @no_regular_output:
    ld b, a
    ld a, [shadowNoiseGeneratorReg]
    cp a, b
    jr z, @skip
    ld a, b
    ld [shadowNoiseGeneratorReg], a
    or a, $e0 ; noise generator
    out ($7f), a
    @skip:
    ret

RenderFMChannels:
    call RenderMelodicFMChannels
    jp RenderRhythmFMChannels

RenderMelodicFMChannels:
    ld b, 0 ; FM channel index
    ld ix, tracks + (4 * _sizeof_Track) ; skip PSG tracks
    @loop:
    call RenderMelodicFMChannel
    ld de, _sizeof_Track
    add ix, de ; next track
    inc b
    ld a, b
    cp a, 6 ; number of melodic channels
    jr nz, @loop
    ret

RenderRhythmFMChannels:
    ld b, 6 ; FM channel index
    ld ix, tracks + ((4 + 6) * _sizeof_Track) ; skip PSG tracks and melodic FM tracks
    @loop:
    ld a, [ix + Track.Speed]
    cp a, $ff ; is track used?
    jr z, @skip
    call RenderRhythmFMChannel
    @skip:
    ld de, _sizeof_Track
    add ix, de ; next track
    inc b
    ld a, b
    cp a, 9
    jr nz, @loop

    ; flush volume registers to hardware
    ld a, $36
    out ($f0), a
    ld a, [shadowRhythmVolumeRegs+0]
    out ($f1), a
    ld a, $37
    out ($f0), a
    ld a, [shadowRhythmVolumeRegs+1]
    out ($f1), a
    ld a, $38
    out ($f0), a
    ld a, [shadowRhythmVolumeRegs+2]
    out ($f1), a
    ret

; IX = track
IncPatternPtr:
    inc [ix + Track.Pattern_Ptr]
    ret nz
    inc [ix + Track.Pattern_Ptr+1]
    ret

; IX = address of track
; B = FM channel index (0..5)
; Destroys: A, C, DE, HL
RenderMelodicFMChannel:
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, b ; channel
    or a, $20   ; Select Channel N Frequency High Bit, Block, and Key On
    out ($f0), a
    ld a, 0 ; key off (bit 4 = 0)
    out ($f1), a
    @no_trigger:
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ; calculate effective volume
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld e, a
    ld hl, FMAttenuationTable
    add hl, de
    ld a, b ; channel
    or a, $30   ; Select Channel N Instrument and Volume
    out ($f0), a
    ld c, [hl] ; map volume to attenuation
    ld a, [ix + Track.InstrumentData]
    and a, $f0 ; instrument in upper 4 bits
    or a, c
    out ($f1), a
    ld e, [ix + Track.PeriodLo]
    ld d, [ix + Track.PeriodHi]
    ld hl, PeriodToFMReg1x2xValues
    add hl, de
    add hl, de
    ld a, b ; channel
    or a, $10   ; Select Channel N Frequency Low Byte
    out ($f0), a
    ld a, [hl] ; fnum lower 8 bits
    inc hl
    out ($f1), a
    ld a, b
    or a, $20   ; Select Channel N Frequency High Bit, Block, and Key On
    out ($f0), a
    ld a, [hl] ; fnum high bit and block
    or a, $10 ; key on
    out ($f1), a
    ret

; IX = address of track
; B = FM channel index (6..8)
; Destroys: A, C, DE, HL
RenderRhythmFMChannel:
    bit 7, [ix + Track.PeriodIndex] ; check trigger flag
    jr z, @no_trigger
    res 7, [ix + Track.PeriodIndex] ; reset trigger flag
    ld a, $0e
    out ($f0), a
    ld a, [ix + Track.InstrumentData]
    cpl
    ld c, a
    ld a, [shadowRhythmControlReg]
    and a, c ; clear instrument bits
    or a, $20
    ld c, a
    out ($f1), a ; clear instrument bits
    ld a, $0e
    out ($f0), a
    ld a, [ix + Track.InstrumentData]
    or a, c
    out ($f1), a ; set instrument bits
    ld [shadowRhythmControlReg], a
    @no_trigger:
    ; check if channel is muted
    bit 0, [ix + Track.Status]
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ; calculate effective volume
    ld a, [ix + Track.Envelope_Vol]
    srl a
    srl a
    srl a
    srl a
    or a, [ix + Track.MasterVol]
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [masterVol]
    or a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    @set_volume:
    ld [ix + Track.EffectiveVol], a
    ld d, 0
    ld e, a
    ld hl, FMAttenuationTable
    add hl, de
    ld c, [hl] ; map volume to attenuation
    ld a, [ix + Track.InstrumentData]
    or a, a
    jr z, @skip_volume_sync
    ld e, 0
    @find_first_set_bit:
    bit 0, a
    jr nz, @found
    srl a
    inc e
    jr @find_first_set_bit
    @found:
    ld d, 0
    ld hl, @table
    add hl, de
    ld a, [hl]
    ld hl, shadowRhythmVolumeRegs
    bit 0, a ; increment address by 1?
    jr z, @skip_inc
    inc hl
    @skip_inc:
    bit 1, a ; increment address by 2?
    jr z, @skip_inc2
    inc hl
    inc hl
    @skip_inc2:
    bit 2, a ; shift up by 4 bits?
    ld a, c ; attenuation
    ld c, $f0 ; mask
    jr z, @skip_shift
    sla a
    sla a
    sla a
    sla a
    ld c, $0f
    @skip_shift:
    ld e, a ; shifted attenuation
    ld a, [hl]
    and a, c ; mask out old bits
    or a, e  ; set new bits
    ld [hl], a
    @skip_volume_sync:
    ret
@table:
.db 1 | 4 ; $37 D7-D4
.db 2 | 0 ; $38 D3-D0
.db 2 | 4 ; $38 D7-D4
.db 1 | 0 ; $37 D3-D0
.db 0 | 0 ; $36 D3-D0

; A = command
; IX = track
GoPatternCommand:
    push de
    rst JumpTable
.dw .set_instr     ; 0
.dw .release       ; 1
.dw .set_speed     ; 2
.dw .end_row       ; 3
.dw .pan_left      ; 4
.dw .pan_center    ; 5
.dw .pan_right     ; 6

    .set_instr:
    pop de ; pattern data ptr
    ld a, [de] ; instrument
    inc de
    call IncPatternPtr
    call SetInstrument
    scf ; CF=1 signals keep processing pattern data
    ret

    .release:
    ld a, 1
    ld [ix + Track.Envelope_Hold], a
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .set_speed:
    pop de ; pattern data ptr
    ld a, [de] ; new speed
    inc de
    call IncPatternPtr
    call SetSpeed
    scf ; CF=1 signals keep processing pattern data
    ret

    .end_row: ; this command is used when there is no note for the row, only commands
    ld a, [ix + Track.MasterVol]
    and $fe
    ld [ix + Track.MasterVol], a
    pop de ; pattern data ptr
    scf
    ccf ; CF=0 signals end of pattern data processing
    ret

    .pan_left:
    ; TODO: implement panning
    .done_panning:
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .pan_center:
    ; TODO: implement panning
    jr .done_panning

    .pan_right:
    ; TODO: implement panning
    jr .done_panning

; A = instrument
; B = track number
; IX = track
; preserves DE
SetInstrument:
    push de
    push af
    ld de, [trackHeaderTable]
    ld a, b
    sla a
    sla a
    sla a ; track * 8
    add a, e
    jr nc, @1
    inc d
    @1:
    add a, TrackHeader.InstrumentTable
    jr nc, @2
    inc d
    @2:
    ld e, a
    ld a, [de] ; instrument table (lo)
    ld c, a
    inc de
    ld a, [de] ; instrument table (hi)
    ld d, a
    ld e, c
    pop af
    sla a
    sla a
    sla a ; each instrument is 8 bytes long
    add a, e
    ld e, a
    jr nc, @3
    inc d
    @3:
    ld a, [de] ; 0 - envelope lo
    inc de
    ld [ix + Track.Envelope_Ptr], a
    ld a, [de] ; 1 - envelope hi
    inc de
    ld [ix + Track.Envelope_Ptr+1], a
    inc de ; 2 - unused
    ld a, [de] ; 3 - effect kind
    inc de
    ld [ix + Track.Effect_Kind], a
    ld a, [de] ; 4 - effect param
    inc de
    ld [ix + Track.Effect_Param], a
    ld a, [de] ; 5 - instrument data
    ld [ix + Track.InstrumentData], a
    pop de ; pattern data ptr
    ret

; A = new speed
; preserves BC, DE and HL
SetSpeed:
    push de
    push hl
    push bc
    ld hl, tracks + Track.Speed
    ld de, _sizeof_Track
    ld b, MAX_TRACKS
    ld c, a
    @loop:
    ld a, [hl] ; Speed
    cp a, $ff ; is track used?
    jr z, @skip
    ld [hl], c ; Speed
    @skip:
    add hl, de
    dec b
    jr nz, @loop
    pop bc
    pop hl
    pop de
    ret

; A = effect kind, IX = track
EffectTick:
    ld a, [ix + Track.Effect_Kind]
    rst JumpTable
.dw .null_tick         ; 0
.dw .slide_up_tick     ; 1
.dw .slide_down_tick   ; 2
.dw .portamento_tick   ; 3
.dw .vibrato_tick      ; 4
.dw .arpeggio_tick     ; 5
.dw .volume_slide_tick ; 6
.dw .tremolo_tick      ; 7
.dw .cut_tick          ; 8
.dw .pulsemod_tick     ; 9

    .null_tick:
    ret

    .slide_up_tick:
; slide up by adding slide amount to period value
    ld c, [ix + Track.Effect_Param]
    ld a, [ix + Track.PeriodLo]
    add a, c
    ld [ix + Track.PeriodLo], a
    jr nc, @slide_skip_inc
    ld a, [ix + Track.PeriodHi]
    cp a, 7
    jr z, @clamp_slide_up
    inc [ix + Track.PeriodHi]
    @slide_skip_inc:
    ret
    @clamp_slide_up:
    ld a, $ff
    ld [ix + Track.PeriodLo], a
    ret

    .slide_down_tick:
; slide down by subtracting slide amount from period value
    ld c, [ix + Track.Effect_Param]
    ld a, [ix + Track.PeriodLo]
    sub a, c
    ld [ix + Track.PeriodLo], a
    jr nc, @slide_skip_dec
    ld a, [ix + Track.PeriodHi]
    or a
    jr z, @clamp_slide_down
    dec [ix + Track.PeriodHi]
    @slide_skip_dec:
    ret
    @clamp_slide_down:
    xor a
    ld [ix + Track.PeriodLo], a
    ret

    .portamento_tick:
    ld c, [ix + Track.Effect_Param]
    ld a, [ix + Track.Effect_Portamento_Ctrl]
    bit 7, a
    jr z, .portamento_exit
    srl a ; CF = direction (0=down, 1=up)
    ld e, [ix + Track.Effect_Portamento_TargetPeriodLo]
    ld d, [ix + Track.Effect_Portamento_TargetPeriodHi]
    ld a, [ix + Track.PeriodLo]
    jr nc, .portamento_down
    ; slide up (add delta to current period value)
    add a, c
    ld [ix + Track.PeriodLo], a
    ld a, [ix + Track.PeriodHi]
    adc a, 0
    ld [ix + Track.PeriodHi], a
    ld c, a ; save periodhi
    ; check if target period has been reached (current period >= target period)
    ld a, [ix + Track.PeriodLo]
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_done
    .portamento_exit:
    ret
    .portamento_down:
    ; slide down (subtract delta from current period value)
    sub a, c
    ld [ix + Track.PeriodLo], a
    ld a, [ix + Track.PeriodHi]
    sbc a, 0
    ld [ix + Track.PeriodHi], a
    ld c, a ; save periodhi
    ; check if target period has been reached (current period <= target period)
    ld a, [ix + Track.PeriodLo]
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_exit
    .portamento_done:
    ; set final period
    ld [ix + Track.PeriodLo], e
    ld [ix + Track.PeriodHi], d
    ; halt
    xor a, a
    ld [ix + Track.Effect_Portamento_Ctrl], a
    ret

    .vibrato_tick:
    ; reset period value
    ld c, [ix + Track.PeriodIndex]
    ld a, b ; track
    cp a, 4 ; < 4 means PSG
    ld de, PSGPeriodTable
    jr c, @1
    ld de, NoteToFMPeriod
    @1:
    ld a, e
    add a, c ; note
    add a, c ; note
    ld e, a
    ld a, [de]
    ld [ix + Track.PeriodLo], a
    inc de
    ld a, [de]
    ld [ix + Track.PeriodHi], a
    ; get sine value
    ld a, [ix + Track.Effect_Pos]
    and a, $1f
    ld de, VibratoTable
    add a, e
    ld e, a
    ld a, [de] ; sine value
    ld c, a
    ; *** convert sine value to real delta freq, according to vibrato depth ***
    ld a, [ix + Track.Effect_Param]
    and a, $0f ; VibratoDepth in lower 4 bits
    ld e, a
    ld d, 0
    xor a, a
    ; this loop performs SineValue*VibratoDepth, putting result in DA
    @loop:
    add a, c
    jr nc, @skip_inc
    inc d
    @skip_inc:
    dec e
    jr nz, @loop
    ; compute (SineValue*VibratoDepth)/128
    sla a
    ld a, d
    rla
    ld c, a
    ld a, [ix + Track.Effect_Pos]
    and a, $20
    jr z, .vib_add
    ; subtract c from period
    ld a, [ix + Track.PeriodLo]
    sub a, c
    ld [ix + Track.PeriodLo], a
    jr nc, .vib_done
    dec [ix + Track.PeriodHi]
    jr .vib_done
    .vib_add:
    ; add c to period
    ld a, [ix + Track.PeriodLo]
    add a, c
    ld [ix + Track.PeriodLo], a
    jr nc, .vib_done
    inc [ix + Track.PeriodHi]
    .vib_done:
    ; increment pos
    ld a, [ix + Track.Effect_Param]
    srl a
    srl a
    srl a
    srl a ; vibrato speed
    ld c, [ix + Track.Effect_Pos]
    add a, c
    ld [ix + Track.Effect_Pos], a
    ret

    .arpeggio_tick:
    ld c, [ix + Track.Effect_Param]
    ld a, [ix + Track.Effect_Pos]
    ld d, a
    inc a
    cp a, 6
    jr c, .skip
    xor a, a
    .skip:
    ld [ix + Track.Effect_Pos], a
    ld a, d ; pos (0-5)
    srl a
    or a, a
    jr z, .set_period ; use base note
    dec a
    jr z, .use_mid_note
    ; use top note
    ld a, c
    and $0f
    jr .set_period
    .use_mid_note:
    ld a, c
    srl a
    srl a
    srl a
    srl a
    .set_period:
    add a, [ix + Track.PeriodIndex]
    ld c, a ; save note
    ld a, b ; track
    cp a, 4 ; < 4 means PSG
    ld de, PSGPeriodTable
    jr c, @1
    ld de, NoteToFMPeriod
    @1:
    ld a, e
    add a, c ; note
    add a, c ; note
    ld e, a
    ld a, [de]
    ld [ix + Track.PeriodLo], a
    inc de
    ld a, [de]
    ld [ix + Track.PeriodHi], a
    ret

    .volume_slide_tick:
    ld a, [ix + Track.Effect_Param]
    cp a, $10
    jr c, @sub_volume
    ; add to volume
    srl a
    srl a
    and a, $3c ; delta * 4
    ld c, a
    ld a, [ix + Track.MasterVol]
    add a, c
    jr nc, @set_volume
    ld a, $fc ; max volume
    jr @set_volume
    @sub_volume:
    sla a
    sla a ; delta * 4
    ld c, a
    ld a, [ix + Track.MasterVol]
    sub a, c
    jr nc, @set_volume
    xor a, a
    @set_volume:
    ld [ix + Track.MasterVol], a
    ret

    .tremolo_tick:
    ; TODO: implement tremolo
    ret

    .cut_tick:
    ld c, [ix + Track.Effect_Param]
    ld a, [ix + Track.Effect_Pos]
    cp a, c
    inc a
    ld [ix + Track.Effect_Pos], a
    ret c
    ; cut! (set volume to 0)
    xor a, a
    ld [ix + Track.MasterVol], a
    ret

    .pulsemod_tick:
    ; TODO: implement pulsemod
    ret

; IX = track
EnvelopeTick:
    ld a, [ix + Track.Envelope_Phase]
    rla
    jr c, .init    ; $80
    rla
    jr c, .process ; $40
    rla
    jr c, .sustain ; $20
    ret

    .init:
    srl [ix + Track.Envelope_Phase] ; Envelope_Phase = $40
    ld e, [ix + Track.Envelope_Ptr]
    ld d, [ix + Track.Envelope_Ptr+1]
    xor a, a
    ld [ix + Track.Envelope_Pos], a
    .init_vol:
    ld a, [de] ; 1st byte = start volume
    inc de
    inc [ix + Track.Envelope_Pos]
    ld [ix + Track.Envelope_Vol], a
    .point_init:
    ld a, [de] ; fetch envelope byte
    inc de
    cp a, $ff ; end of envelope reached?
    jr z, .env_end
    ; point OK, set 3-tuple (step, dest, hold)
    ld [ix + Track.Envelope_Step], a
    ld a, [de]
    inc de
    ld [ix + Track.Envelope_Dest], a
    ld a, [de]
    inc de
    ld [ix + Track.Envelope_Hold], a
    inc [ix + Track.Envelope_Pos]
    inc [ix + Track.Envelope_Pos]
    inc [ix + Track.Envelope_Pos]
    jr .process
    .env_end:
    ld a, [de]
    cp a, $ff ; definitely end?
    jr z, .env_stop
    ; loop the envelope from the given offset
    ld e, [ix + Track.Envelope_Ptr]
    ld d, [ix + Track.Envelope_Ptr+1]
    ld a, c
    ld [ix + Track.Envelope_Pos], a
    add a, e
    ld e, a
    jr nc, .point_init
    inc d
    jr .point_init
    .env_stop:
    xor a, a
    ld [ix + Track.Envelope_Phase], a
    ret

    .sustain:
    sla [ix + Track.Envelope_Phase] ; Envelope_Phase = process (speculative)
    ld a, [ix + Track.Envelope_Hold]
    cp a, $ff ; hold forever?
    jr z, .keep_sustaining
    dec [ix + Track.Envelope_Hold]
    jr nz, .keep_sustaining
    jr .next_point
    .keep_sustaining:
    srl [ix + Track.Envelope_Phase] ; Envelope_Phase = sustain
    ret

    .process:
    ld a, [ix + Track.Envelope_Vol]
    ld c, [ix + Track.Envelope_Step]
    cp a, [ix + Track.Envelope_Dest] ; Envelope_Dest > Vol?
    jr nc, .sub_volume
    ; add step to vol
    add a, c
    jr c, .reached_dest
    cp a, [ix + Track.Envelope_Dest] ; Envelope_Dest > new vol?
    jr z, .reached_dest
    jr nc, .reached_dest
    ld [ix + Track.Envelope_Vol], a
    ret
    .sub_volume:
    ; subtract step from volume
    sub a, c
    jr c, .reached_dest
    cp a, [ix + Track.Envelope_Dest] ; Envelope_Dest > new vol?
    jr z, .reached_dest
    jr c, .reached_dest
    ld [ix + Track.Envelope_Vol], a
    ret
    .reached_dest:
    ld a, [ix + Track.Envelope_Dest]
    ld [ix + Track.Envelope_Vol], a
    ld a, [ix + Track.Envelope_Hold]
    or a, a
    jr z, .next_point
    srl [ix + Track.Envelope_Phase] ; phase = sustain
    ret
    .next_point:
    ld e, [ix + Track.Envelope_Ptr]
    ld d, [ix + Track.Envelope_Ptr+1]
    ld a, [ix + Track.Envelope_Pos]
    add a, e
    ld e, a
    jr nc, .skip_inc
    inc d
    .skip_inc:
    jp .point_init

.ends

.section "Sound engine read-only data" bank 0 slot 0 align 256 free

VolumeTable: ; 256 bytes
.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00      ; MasterVol = 0
.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01      ; 1
.db $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02      ; 2
.db $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03      ; 3
.db $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$04      ; ..
.db $00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05
.db $00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06
.db $00,$00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07
.db $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$08
.db $00,$00,$01,$01,$02,$03,$03,$04,$04,$05,$06,$06,$07,$07,$08,$09
.db $00,$00,$01,$02,$02,$03,$04,$04,$05,$06,$06,$07,$08,$08,$09,$0A
.db $00,$00,$01,$02,$02,$03,$04,$05,$05,$06,$07,$08,$08,$09,$0A,$0B
.db $00,$00,$01,$02,$03,$04,$04,$05,$06,$07,$08,$08,$09,$0A,$0B,$0C
.db $00,$00,$01,$02,$03,$04,$05,$06,$06,$07,$08,$09,$0A,$0B,$0C,$0D
.db $00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
.db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F

PSGPeriodTable: ; 128 bytes
.dw $00d,$07f,$0eb
.dw $151,$1b1,$20b,$261,$2b1,$2fd,$345,$389,$3c9,$407,$43f,$475
.dw $4a7,$4d7,$505,$52f,$559,$57f,$5a3,$5c5,$5e5,$603,$61f,$63b
.dw $653,$66b,$683,$697,$6ab,$6bf,$6d1,$6e1,$6f1,$701,$70f,$71d
.dw $729,$735,$741,$74b,$755,$75f,$767,$771,$779,$77f,$787,$78d
.dw $795,$79b,$79f,$7a5,$7ab,$7af,$7b3,$7b7,$7bb,$7bf,$7c3,$7c7

; ProTracker sine table (32 bytes)
VibratoTable:
.db $00,$18,$31,$4A,$61,$78,$8D,$A1
.db $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
.db $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
.db $B4,$A1,$8D,$78,$61,$4A,$31,$18

PSGToneAttenuationTable: ; 16 bytes
.db $0f,$09,$08,$07,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00
PSGNoiseAttenuationTable: ; 16 bytes
.db $0f,$07,$06,$05,$04,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00
FMAttenuationTable: ; 16 bytes
.db $0f,$09,$08,$07,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00

.align 256
NoteToFMPeriod: ; 160 bytes
.dw 0,25,50,75,100,125,150,175,200,225,250,275,300,325,350,375
.dw 400,425,450,475,500,525,550,575,600,625,650,675,700,725,750,775
.dw 800,825,850,875,900,925,950,975,1000,1025,1050,1075,1100,1125,1150,1175
.dw 1200,1225,1250,1275,1300,1325,1350,1375,1400,1425,1450,1475,1500,1525,1550,1575
.dw 1600,1625,1650,1675,1700,1725,1750,1775,1800,1825,1850,1875,1900,1925,1950,1975

PeriodToFMReg1x2xValues:
.dw $1b3,$1b4,$1b5,$1b6,$1b7,$1b8,$1b9,$1ba,$1bb,$1bc,$1bd,$1be,$1bf,$1c0,$1c1,$1c2
.dw $1c3,$1c4,$1c5,$1c6,$1c7,$1c8,$1c9,$1ca,$1cb,$1cc,$1cd,$1cf,$1d0,$1d1,$1d2,$1d3
.dw $1d4,$1d5,$1d6,$1d7,$1d8,$1d9,$1db,$1dc,$1dd,$1de,$1df,$1e0,$1e1,$1e2,$1e3,$1e4
.dw $1e6,$1e7,$1e8,$1e9,$1ea,$1eb,$1ec,$1ee,$1ef,$1f0,$1f1,$1f2,$1f3,$1f4,$1f6,$1f7
.dw $1f8,$1f9,$1fa,$1fb,$1fd,$1fe,$1ff,$300,$301,$301,$302,$302,$303,$304,$304,$305
.dw $305,$306,$307,$307,$308,$309,$309,$30a,$30a,$30b,$30c,$30c,$30d,$30d,$30e,$30f
.dw $30f,$310,$311,$311,$312,$312,$313,$314,$314,$315,$316,$316,$317,$318,$318,$319
.dw $31a,$31a,$31b,$31b,$31c,$31d,$31d,$31e,$31f,$31f,$320,$321,$321,$322,$323,$323
.dw $324,$325,$325,$326,$327,$328,$328,$329,$32a,$32a,$32b,$32c,$32c,$32d,$32e,$32e
.dw $32f,$330,$330,$331,$332,$333,$333,$334,$335,$335,$336,$337,$338,$338,$339,$33a
.dw $33b,$33b,$33c,$33d,$33d,$33e,$33f,$340,$340,$341,$342,$343,$343,$344,$345,$346
.dw $346,$347,$348,$349,$349,$34a,$34b,$34c,$34c,$34d,$34e,$34f,$350,$350,$351,$352
.dw $353,$353,$354,$355,$356,$357,$357,$358,$359,$35a,$35b,$35b,$35c,$35d,$35e,$35f
.dw $35f,$360,$361,$362,$363,$364,$364,$365,$366,$367,$368,$368,$369,$36a,$36b,$36c
.dw $36d,$36d,$36e,$36f,$370,$371,$372,$373,$373,$374,$375,$376,$377,$378,$379,$37a
.dw $37a,$37b,$37c,$37d,$37e,$37f,$380,$381,$381,$382,$383,$384,$385,$386,$387,$388
.dw $389,$38a,$38a,$38b,$38c,$38d,$38e,$38f,$390,$391,$392,$393,$394,$395,$396,$396
.dw $397,$398,$399,$39a,$39b,$39c,$39d,$39e,$39f,$3a0,$3a1,$3a2,$3a3,$3a4,$3a5,$3a6
.dw $3a7,$3a8,$3a9,$3aa,$3ab,$3ac,$3ad,$3ae,$3af,$3b0,$3b1,$3b2,$3b3,$3b4,$3b5,$3b6
.dw $3b7,$3b8,$3b9,$3ba,$3bb,$3bc,$3bd,$3be,$3bf,$3c0,$3c1,$3c2,$3c3,$3c4,$3c5,$3c6
.dw $3c7,$3c8,$3c9,$3ca,$3cb,$3cc,$3cd,$3cf,$3d0,$3d1,$3d2,$3d3,$3d4,$3d5,$3d6,$3d7
.dw $3d8,$3d9,$3db,$3dc,$3dd,$3de,$3df,$3e0,$3e1,$3e2,$3e3,$3e4,$3e6,$3e7,$3e8,$3e9
.dw $3ea,$3eb,$3ec,$3ee,$3ef,$3f0,$3f1,$3f2,$3f3,$3f4,$3f6,$3f7,$3f8,$3f9,$3fa,$3fb
.dw $3fd,$3fe,$3ff,$500,$501,$501,$502,$502,$503,$504,$504,$505,$505,$506,$507,$507
.dw $508,$509,$509,$50a,$50a,$50b,$50c,$50c,$50d,$50d,$50e,$50f,$50f,$510,$511,$511
.dw $512,$512,$513,$514,$514,$515,$516,$516,$517,$518,$518,$519,$51a,$51a,$51b,$51b
.dw $51c,$51d,$51d,$51e,$51f,$51f,$520,$521,$521,$522,$523,$523,$524,$525,$525,$526
.dw $527,$528,$528,$529,$52a,$52a,$52b,$52c,$52c,$52d,$52e,$52e,$52f,$530,$530,$531
.dw $532,$533,$533,$534,$535,$535,$536,$537,$538,$538,$539,$53a,$53b,$53b,$53c,$53d
.dw $53d,$53e,$53f,$540,$540,$541,$542,$543,$543,$544,$545,$546,$546,$547,$548,$549
.dw $549,$54a,$54b,$54c,$54c,$54d,$54e,$54f,$550,$550,$551,$552,$553,$553,$554,$555
.dw $556,$557,$557,$558,$559,$55a,$55b,$55b,$55c,$55d,$55e,$55f,$55f,$560,$561,$562
.dw $563,$564,$564,$565,$566,$567,$568,$568,$569,$56a,$56b,$56c,$56d,$56d,$56e,$56f
.dw $570,$571,$572,$573,$573,$574,$575,$576,$577,$578,$579,$57a,$57a,$57b,$57c,$57d
.dw $57e,$57f,$580,$581,$581,$582,$583,$584,$585,$586,$587,$588,$589,$58a,$58a,$58b
.dw $58c,$58d,$58e,$58f,$590,$591,$592,$593,$594,$595,$596,$596,$597,$598,$599,$59a
.dw $59b,$59c,$59d,$59e,$59f,$5a0,$5a1,$5a2,$5a3,$5a4,$5a5,$5a6,$5a7,$5a8,$5a9,$5aa
.dw $5ab,$5ac,$5ad,$5ae,$5af,$5b0,$5b1,$5b2,$5b3,$5b4,$5b5,$5b6,$5b7,$5b8,$5b9,$5ba
.dw $5bb,$5bc,$5bd,$5be,$5bf,$5c0,$5c1,$5c2,$5c3,$5c4,$5c5,$5c6,$5c7,$5c8,$5c9,$5ca
.dw $5cb,$5cc,$5cd,$5cf,$5d0,$5d1,$5d2,$5d3,$5d4,$5d5,$5d6,$5d7,$5d8,$5d9,$5db,$5dc
.dw $5dd,$5de,$5df,$5e0,$5e1,$5e2,$5e3,$5e4,$5e6,$5e7,$5e8,$5e9,$5ea,$5eb,$5ec,$5ee
.dw $5ef,$5f0,$5f1,$5f2,$5f3,$5f4,$5f6,$5f7,$5f8,$5f9,$5fa,$5fb,$5fd,$5fe,$5ff,$700
.dw $701,$701,$702,$702,$703,$704,$704,$705,$705,$706,$707,$707,$708,$709,$709,$70a
.dw $70a,$70b,$70c,$70c,$70d,$70d,$70e,$70f,$70f,$710,$711,$711,$712,$712,$713,$714
.dw $714,$715,$716,$716,$717,$718,$718,$719,$71a,$71a,$71b,$71b,$71c,$71d,$71d,$71e
.dw $71f,$71f,$720,$721,$721,$722,$723,$723,$724,$725,$725,$726,$727,$728,$728,$729
.dw $72a,$72a,$72b,$72c,$72c,$72d,$72e,$72e,$72f,$730,$730,$731,$732,$733,$733,$734
.dw $735,$735,$736,$737,$738,$738,$739,$73a,$73b,$73b,$73c,$73d,$73d,$73e,$73f,$740
.dw $740,$741,$742,$743,$743,$744,$745,$746,$746,$747,$748,$749,$749,$74a,$74b,$74c
.dw $74c,$74d,$74e,$74f,$750,$750,$751,$752,$753,$753,$754,$755,$756,$757,$757,$758
.dw $759,$75a,$75b,$75b,$75c,$75d,$75e,$75f,$75f,$760,$761,$762,$763,$764,$764,$765
.dw $766,$767,$768,$768,$769,$76a,$76b,$76c,$76d,$76d,$76e,$76f,$770,$771,$772,$773
.dw $773,$774,$775,$776,$777,$778,$779,$77a,$77a,$77b,$77c,$77d,$77e,$77f,$780,$781
.dw $781,$782,$783,$784,$785,$786,$787,$788,$789,$78a,$78a,$78b,$78c,$78d,$78e,$78f
.dw $790,$791,$792,$793,$794,$795,$796,$796,$797,$798,$799,$79a,$79b,$79c,$79d,$79e
.dw $79f,$7a0,$7a1,$7a2,$7a3,$7a4,$7a5,$7a6,$7a7,$7a8,$7a9,$7aa,$7ab,$7ac,$7ad,$7ae
.dw $7af,$7b0,$7b1,$7b2,$7b3,$7b4,$7b5,$7b6,$7b7,$7b8,$7b9,$7ba,$7bb,$7bc,$7bd,$7be
.dw $7bf,$7c0,$7c1,$7c2,$7c3,$7c4,$7c5,$7c6,$7c7,$7c8,$7c9,$7ca,$7cb,$7cc,$7cd,$7cf
.dw $7d0,$7d1,$7d2,$7d3,$7d4,$7d5,$7d6,$7d7,$7d8,$7d9,$7db,$7dc,$7dd,$7de,$7df,$7e0
.dw $7e1,$7e2,$7e3,$7e4,$7e6,$7e7,$7e8,$7e9,$7ea,$7eb,$7ec,$7ee,$7ef,$7f0,$7f1,$7f2
.dw $7f3,$7f4,$7f6,$7f7,$7f8,$7f9,$7fa,$7fb,$7fd,$7fe,$7ff,$900,$901,$901,$902,$902
.dw $903,$904,$904,$905,$905,$906,$907,$907,$908,$909,$909,$90a,$90a,$90b,$90c,$90c
.dw $90d,$90d,$90e,$90f,$90f,$910,$911,$911,$912,$912,$913,$914,$914,$915,$916,$916
.dw $917,$918,$918,$919,$91a,$91a,$91b,$91b,$91c,$91d,$91d,$91e,$91f,$91f,$920,$921
.dw $921,$922,$923,$923,$924,$925,$925,$926,$927,$928,$928,$929,$92a,$92a,$92b,$92c
.dw $92c,$92d,$92e,$92e,$92f,$930,$930,$931,$932,$933,$933,$934,$935,$935,$936,$937
.dw $938,$938,$939,$93a,$93b,$93b,$93c,$93d,$93d,$93e,$93f,$940,$940,$941,$942,$943
.dw $943,$944,$945,$946,$946,$947,$948,$949,$949,$94a,$94b,$94c,$94c,$94d,$94e,$94f
.dw $950,$950,$951,$952,$953,$953,$954,$955,$956,$957,$957,$958,$959,$95a,$95b,$95b
.dw $95c,$95d,$95e,$95f,$95f,$960,$961,$962,$963,$964,$964,$965,$966,$967,$968,$968
.dw $969,$96a,$96b,$96c,$96d,$96d,$96e,$96f,$970,$971,$972,$973,$973,$974,$975,$976
.dw $977,$978,$979,$97a,$97a,$97b,$97c,$97d,$97e,$97f,$980,$981,$981,$982,$983,$984
.dw $985,$986,$987,$988,$989,$98a,$98a,$98b,$98c,$98d,$98e,$98f,$990,$991,$992,$993
.dw $994,$995,$996,$996,$997,$998,$999,$99a,$99b,$99c,$99d,$99e,$99f,$9a0,$9a1,$9a2
.dw $9a3,$9a4,$9a5,$9a6,$9a7,$9a8,$9a9,$9aa,$9ab,$9ac,$9ad,$9ae,$9af,$9b0,$9b1,$9b2
.dw $9b3,$9b4,$9b5,$9b6,$9b7,$9b8,$9b9,$9ba,$9bb,$9bc,$9bd,$9be,$9bf,$9c0,$9c1,$9c2
.dw $9c3,$9c4,$9c5,$9c6,$9c7,$9c8,$9c9,$9ca,$9cb,$9cc,$9cd,$9cf,$9d0,$9d1,$9d2,$9d3
.dw $9d4,$9d5,$9d6,$9d7,$9d8,$9d9,$9db,$9dc,$9dd,$9de,$9df,$9e0,$9e1,$9e2,$9e3,$9e4
.dw $9e6,$9e7,$9e8,$9e9,$9ea,$9eb,$9ec,$9ee,$9ef,$9f0,$9f1,$9f2,$9f3,$9f4,$9f6,$9f7
.dw $9f8,$9f9,$9fa,$9fb,$9fd,$9fe,$9ff,$b00,$b01,$b01,$b02,$b02,$b03,$b04,$b04,$b05
.dw $b05,$b06,$b07,$b07,$b08,$b09,$b09,$b0a,$b0a,$b0b,$b0c,$b0c,$b0d,$b0d,$b0e,$b0f
.dw $b0f,$b10,$b11,$b11,$b12,$b12,$b13,$b14,$b14,$b15,$b16,$b16,$b17,$b18,$b18,$b19
.dw $b1a,$b1a,$b1b,$b1b,$b1c,$b1d,$b1d,$b1e,$b1f,$b1f,$b20,$b21,$b21,$b22,$b23,$b23
.dw $b24,$b25,$b25,$b26,$b27,$b28,$b28,$b29,$b2a,$b2a,$b2b,$b2c,$b2c,$b2d,$b2e,$b2e
.dw $b2f,$b30,$b30,$b31,$b32,$b33,$b33,$b34,$b35,$b35,$b36,$b37,$b38,$b38,$b39,$b3a
.dw $b3b,$b3b,$b3c,$b3d,$b3d,$b3e,$b3f,$b40,$b40,$b41,$b42,$b43,$b43,$b44,$b45,$b46
.dw $b46,$b47,$b48,$b49,$b49,$b4a,$b4b,$b4c,$b4c,$b4d,$b4e,$b4f,$b50,$b50,$b51,$b52
.dw $b53,$b53,$b54,$b55,$b56,$b57,$b57,$b58,$b59,$b5a,$b5b,$b5b,$b5c,$b5d,$b5e,$b5f
.dw $b5f,$b60,$b61,$b62,$b63,$b64,$b64,$b65,$b66,$b67,$b68,$b68,$b69,$b6a,$b6b,$b6c
.dw $b6d,$b6d,$b6e,$b6f,$b70,$b71,$b72,$b73,$b73,$b74,$b75,$b76,$b77,$b78,$b79,$b7a
.dw $b7a,$b7b,$b7c,$b7d,$b7e,$b7f,$b80,$b81,$b81,$b82,$b83,$b84,$b85,$b86,$b87,$b88
.dw $b89,$b8a,$b8a,$b8b,$b8c,$b8d,$b8e,$b8f,$b90,$b91,$b92,$b93,$b94,$b95,$b96,$b96
.dw $b97,$b98,$b99,$b9a,$b9b,$b9c,$b9d,$b9e,$b9f,$ba0,$ba1,$ba2,$ba3,$ba4,$ba5,$ba6
.dw $ba7,$ba8,$ba9,$baa,$bab,$bac,$bad,$bae,$baf,$bb0,$bb1,$bb2,$bb3,$bb4,$bb5,$bb6
.dw $bb7,$bb8,$bb9,$bba,$bbb,$bbc,$bbd,$bbe,$bbf,$bc0,$bc1,$bc2,$bc3,$bc4,$bc5,$bc6
.dw $bc7,$bc8,$bc9,$bca,$bcb,$bcc,$bcd,$bcf,$bd0,$bd1,$bd2,$bd3,$bd4,$bd5,$bd6,$bd7
.dw $bd8,$bd9,$bdb,$bdc,$bdd,$bde,$bdf,$be0,$be1,$be2,$be3,$be4,$be6,$be7,$be8,$be9
.dw $bea,$beb,$bec,$bee,$bef,$bf0,$bf1,$bf2,$bf3,$bf4,$bf6,$bf7,$bf8,$bf9,$bfa,$bfb
.dw $bfd,$bfe,$bff,$d00,$d01,$d01,$d02,$d02,$d03,$d04,$d04,$d05,$d05,$d06,$d07,$d07
.dw $d08,$d09,$d09,$d0a,$d0a,$d0b,$d0c,$d0c,$d0d,$d0d,$d0e,$d0f,$d0f,$d10,$d11,$d11
.dw $d12,$d12,$d13,$d14,$d14,$d15,$d16,$d16,$d17,$d18,$d18,$d19,$d1a,$d1a,$d1b,$d1b
.dw $d1c,$d1d,$d1d,$d1e,$d1f,$d1f,$d20,$d21,$d21,$d22,$d23,$d23,$d24,$d25,$d25,$d26
.dw $d27,$d28,$d28,$d29,$d2a,$d2a,$d2b,$d2c,$d2c,$d2d,$d2e,$d2e,$d2f,$d30,$d30,$d31
.dw $d32,$d33,$d33,$d34,$d35,$d35,$d36,$d37,$d38,$d38,$d39,$d3a,$d3b,$d3b,$d3c,$d3d
.dw $d3d,$d3e,$d3f,$d40,$d40,$d41,$d42,$d43,$d43,$d44,$d45,$d46,$d46,$d47,$d48,$d49
.dw $d49,$d4a,$d4b,$d4c,$d4c,$d4d,$d4e,$d4f,$d50,$d50,$d51,$d52,$d53,$d53,$d54,$d55
.dw $d56,$d57,$d57,$d58,$d59,$d5a,$d5b,$d5b,$d5c,$d5d,$d5e,$d5f,$d5f,$d60,$d61,$d62
.dw $d63,$d64,$d64,$d65,$d66,$d67,$d68,$d68,$d69,$d6a,$d6b,$d6c,$d6d,$d6d,$d6e,$d6f
.dw $d70,$d71,$d72,$d73,$d73,$d74,$d75,$d76,$d77,$d78,$d79,$d7a,$d7a,$d7b,$d7c,$d7d
.dw $d7e,$d7f,$d80,$d81,$d81,$d82,$d83,$d84,$d85,$d86,$d87,$d88,$d89,$d8a,$d8a,$d8b
.dw $d8c,$d8d,$d8e,$d8f,$d90,$d91,$d92,$d93,$d94,$d95,$d96,$d96,$d97,$d98,$d99,$d9a
.dw $d9b,$d9c,$d9d,$d9e,$d9f,$da0,$da1,$da2,$da3,$da4,$da5,$da6,$da7,$da8,$da9,$daa
.dw $dab,$dac,$dad,$dae,$daf,$db0,$db1,$db2,$db3,$db4,$db5,$db6,$db7,$db8,$db9,$dba
.dw $dbb,$dbc,$dbd,$dbe,$dbf,$dc0,$dc1,$dc2,$dc3,$dc4,$dc5,$dc6,$dc7,$dc8,$dc9,$dca
.dw $dcb,$dcc,$dcd,$dcf,$dd0,$dd1,$dd2,$dd3,$dd4,$dd5,$dd6,$dd7,$dd8,$dd9,$ddb,$ddc
.dw $ddd,$dde,$ddf,$de0,$de1,$de2,$de3,$de4,$de6,$de7,$de8,$de9,$dea,$deb,$dec,$dee
.dw $def,$df0,$df1,$df2,$df3,$df4,$df6,$df7,$df8,$df9,$dfa,$dfb,$dfd,$dfe,$dff,$f00
.dw $f01,$f01,$f02,$f02,$f03,$f04,$f04,$f05,$f05,$f06,$f07,$f07,$f08,$f09,$f09,$f0a
.dw $f0a,$f0b,$f0c,$f0c,$f0d,$f0d,$f0e,$f0f,$f0f,$f10,$f11,$f11,$f12,$f12,$f13,$f14
.dw $f14,$f15,$f16,$f16,$f17,$f18,$f18,$f19,$f1a,$f1a,$f1b,$f1b,$f1c,$f1d,$f1d,$f1e
.dw $f1f,$f1f,$f20,$f21,$f21,$f22,$f23,$f23,$f24,$f25,$f25,$f26,$f27,$f28,$f28,$f29
.dw $f2a,$f2a,$f2b,$f2c,$f2c,$f2d,$f2e,$f2e,$f2f,$f30,$f30,$f31,$f32,$f33,$f33,$f34
.dw $f35,$f35,$f36,$f37,$f38,$f38,$f39,$f3a,$f3b,$f3b,$f3c,$f3d,$f3d,$f3e,$f3f,$f40
.dw $f40,$f41,$f42,$f43,$f43,$f44,$f45,$f46

.ends

; --- End sound engine ---

; --- Sound data

.section "Song data" bank 0 slot 0 free

.INCLUDE "song.s"

.ends

; --- Main program

.section "Main program code" bank 0 slot 0 free

Begin:
    di
    im 1
    ld sp, $dff0

    ; clear RAM
    ld hl, $C000
    ld de, $C001
    ld bc, $1FFF
    ld (hl), $00
    ldir

    call SetUpVdpRegisters
    call SetUpFMRegisters
    call ClearVram
    call LoadPalette
    call loadBGTiles
    call LoadTilemap

    ld hl, song_song
    call StartSong
    ; Set first track to be selected (for muting/unmuting)
    ld ix, tracks
    set 1, [ix + Track.Status]

    call TurnOnScreen
    ei
@InfiniteLoop:
    halt
    jr @InfiniteLoop

.macro RGB
.db (\3 << 4) | (\2 << 2) | \1
.endm

LoadPalette:
    ld de, $c000
    call SetVramAddress

    ld hl, PaletteData
    ld bc, PaletteDataEnd - PaletteData
    jp CopyDataToVram

loadBGTiles:
	ld de, $4000
    call SetVramAddress
	ld hl, BGTiles
	ld bc, BGTilesEnd - BGTiles
    jp CopyDataToVram

LoadTilemap:
	ld hl, TilemapData
    jp WriteVramStrings

SetUpFMRegisters:
    ; set up rhythm channel registers as advised by Yamaha
    ld a, $16
    out ($f0), a
    ld a, $20
    out ($f1), a
    ld a, $17
    out ($f0), a
    ld a, $50
    out ($f1), a
    ld a, $18
    out ($f0), a
    ld a, $c0
    out ($f1), a
    ld a, $26
    out ($f0), a
    ld a, $05
    out ($f1), a
    ld a, $27
    out ($f0), a
    ld a, $05
    out ($f1), a
    ld a, $28
    out ($f0), a
    ld a, $01
    out ($f1), a

    ld a, 1    ; Enable YM2413 FM Sound
    out ($F2), a
    ret

MainFunc0:
    call DrawAllChannelIndicators
    ; check if tracks should be (un)muted
    ld a, [buttonsPressed]
    or a
    ret z
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN
    jr z, @skipSelectedTrackIndexUpdate
    ; calculate new selectedTrackIndex from D-pad
    ld b, a
    ld a, [selectedTrackIndex]
    bit PADB_UP, b
    jr z, @upNotPressed
    dec a
    @upNotPressed:
    bit PADB_LEFT, b
    jr z, @leftNotPressed
    dec a
    @leftNotPressed:
    bit PADB_DOWN, b
    jr z, @downNotPressed
    inc a
    @downNotPressed:
    bit PADB_RIGHT, b
    jr z, @rightNotPressed
    inc a
    @rightNotPressed:
    bit 7, a
    jr z, @noWraparoundLow
    ld a, MAX_TRACKS-1
    @noWraparoundLow:
    cp a, MAX_TRACKS
    jr c, @noWraparoundHigh
    xor a
    @noWraparoundHigh:
    ld [selectedTrackIndex], a
    ld b, a
    ; update selected flags
    ld ix, tracks
    ld de, _sizeof_Track
    xor a
    @loop:
    cp a, b ; track == selectedTrackIndex?
    res 1, [ix + Track.Status] ; speculatively reset
    jr nz, @notSelected
    set 1, [ix + Track.Status]
    @notSelected:
    add ix, de
    inc a
    cp a, MAX_TRACKS
    jr nz, @loop
    @skipSelectedTrackIndexUpdate:
    ; check if selected track should be muted or unmuted
    ld a, [buttonsPressed]
    and a, PADF_A | PADF_B
    ret z
    ld ix, tracks
    ld de, _sizeof_Track
    ld a, [selectedTrackIndex]
    ld b, a
    xor a
    @loop2:
    cp a, b ; track == selectedTrackIndex?
    jr z, @foundSelectedTrack
    add ix, de
    inc a
    jr @loop2
    @foundSelectedTrack:
    ld a, [ix + Track.Status]
    xor a, 1
    ld [ix + Track.Status], a
    ret

DrawAllChannelIndicators:
    call DrawPSGChannelIndicators
    jp DrawFMChannelIndicators

DrawPSGChannelIndicators:
    ld ix, tracks
    ld c, 4
    ld de, $3896
    jp DrawChannelIndicators

DrawFMChannelIndicators:
    call DrawMelodicFMChannelIndicators
    jp DrawRhythmFMChannelIndicators

DrawMelodicFMChannelIndicators:
    ld ix, tracks + 4*_sizeof_Track ; skip PSG tracks
    ld c, 6
    ld de, $3910
    jp DrawChannelIndicators

DrawRhythmFMChannelIndicators:
    ld ix, tracks + (4+6)*_sizeof_Track ; skip PSG tracks and melodic FM tracks
    ld c, 3
    ld de, $3996
    jp DrawChannelIndicators

; IX = tracks
; DE = VRAM address
; C = count
DrawChannelIndicators:
    push ix
    ; upper half
    ld a, c
    sla a
    add a, c
    dec a
    sla a
    push bc
    ld c, a
    call BeginVramString
    pop bc
    push de
    call DrawChannelIndicatorsTop
    pop de
    ; lower half
    ld a, e
    add a, $40 ; next row
    ld e, a
    jr nc, @1
    inc d
    @1:
    ld a, c
    sla a
    add a, c
    dec a
    sla a
    push bc
    ld c, a
    call BeginVramString
    pop bc
    pop ix
    jp DrawChannelIndicatorsBottom

; IX = tracks
; C = count
; HL = VRAM buffer
DrawChannelIndicatorsTop:
    ld b, 0
    ld de, _sizeof_Track
    @loop_top:
    ld a, b
    or a ; first channel?
    jr z, @skip_separator_top
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @skip_separator_top:
    bit 0, [ix + Track.Status]
    jr z, @not_muted_top
    ld a, 0
    jr @draw_top
    @not_muted_top:
    ld a, [ix + Track.EffectiveVol]
    and a, $0e
    @draw_top:
    or a, a
    jr z, @draw_blank_top
    sla a ; ball size (0..7) * 4
    add a, $36
    bit 1, [ix + Track.Status] ; should track be highlighted?
    jr z, @skip_highlight
    add a, $20
    @skip_highlight:
    ld [hl], a
    inc l
    push af
    xor a
    ld [hl], a
    inc l
    pop af
    add a, 2
    ld [hl], a
    inc l
    xor a
    ld [hl], a
    inc l
    jr @done_top
    @draw_blank_top:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @done_top:
    add ix, de
    inc b
    ld a, b
    cp a, c
    jr nz, @loop_top
    jp EndVramString

; IX = tracks
; C = count
; HL = VRAM buffer
DrawChannelIndicatorsBottom:
    ld b, 0
    ld de, _sizeof_Track
    @loop_bottom:
    ld a, b
    or a ; first channel?
    jr z, @skip_separator_bottom
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @skip_separator_bottom:
    bit 0, [ix + Track.Status]
    jr z, @not_muted_bottom
    ld a, 0
    jr @draw_bottom
    @not_muted_bottom:
    ld a, [ix + Track.EffectiveVol]
    and a, $0e
    @draw_bottom:
    or a, a
    jr z, @draw_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $37
    bit 1, [ix + Track.Status] ; should track be highlighted?
    jr z, @skip_highlight
    add a, $20
    @skip_highlight:
    ld [hl], a
    inc l
    push af
    xor a
    ld [hl], a
    inc l
    pop af
    add a, 2
    ld [hl], a
    inc l
    xor a
    ld [hl], a
    inc l
    jr @done_bottom
    @draw_blank_bottom:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @done_bottom:
    add ix, de
    inc b
    ld a, b
    cp a, c
    jr nz, @loop_bottom
    jp EndVramString

.ends

.section "Main program read-only data" bank 0 slot 0 free

PaletteData:
; 0 - background and text
RGB 0, 0, 0
RGB 0, 0, 0
RGB 0, 0, 0
RGB 3, 3, 3
; 1 - flag
RGB 0, 0, 0
RGB 3, 0, 0
RGB 0, 0, 3
RGB 3, 3, 3
; 2 - orb
RGB 0, 0, 0
RGB 0, 3, 1
RGB 0, 2, 1
RGB 0, 1, 0
; 3 - highlighted orb
RGB 0, 0, 0
RGB 2, 3, 3
RGB 1, 2, 2
RGB 0, 1, 1
PaletteDataEnd:

BGTiles:
.incbin "font.bin"  ; $00 - 56 tiles
.incbin "flag.bin"  ; $38 - 2 tiles
.incbin "ball.bin"  ; $3A - 64 tiles
BGTilesEnd:

TilemapData:
.db $3A, $90, 32
.dw CHAR_D, CHAR_o, CHAR_u, CHAR_b, CHAR_l, CHAR_e, CHAR_SPACE, CHAR_D, CHAR_r, CHAR_a, CHAR_g, CHAR_o, CHAR_n, CHAR_SPACE, CHAR_I, CHAR_I
.db $3B, $4E, 34
.dw CHAR_O, CHAR_r, CHAR_i, CHAR_g, CHAR_i, CHAR_n, CHAR_a, CHAR_l, CHAR_SPACE, CHAR_m, CHAR_u, CHAR_s, CHAR_i, CHAR_c, CHAR_SPACE, CHAR_b, CHAR_y
.db $3B, $D0, 30
.dw CHAR_K, CHAR_a, CHAR_z, CHAR_u, CHAR_n, CHAR_a, CHAR_k, CHAR_a, CHAR_SPACE, CHAR_Y, CHAR_a, CHAR_m, CHAR_a, CHAR_n, CHAR_e
.db $3C, $52, 20
.dw CHAR_R, CHAR_e, CHAR_m, CHAR_i, CHAR_x, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_i, CHAR_n
.db $3C, $68, 4
.dw $38,$39 ; flag
.db $3D, $12, 26
.dw CHAR_U, CHAR_s, CHAR_e, CHAR_SPACE, CHAR_j, CHAR_o, CHAR_y, CHAR_p, CHAR_a, CHAR_d, CHAR_SPACE, CHAR_t, CHAR_o
.db $3D, $50, 30
.dw CHAR_t, CHAR_o, CHAR_g, CHAR_g, CHAR_l, CHAR_e, CHAR_SPACE, CHAR_c, CHAR_h, CHAR_a, CHAR_n, CHAR_n, CHAR_e, CHAR_l, CHAR_s
.db 0
TilemapDataEnd:

.ends
