.include "hardware.inc"

.sdsctag 1.0, "Live and Learn remix", "Original music by Crush40", "@notube4me"
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
.define CHAR_4 $19
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
.define CHAR_X $34
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
    Square_DutyCtrl db                        ; 11
    Envelope_Phase db                         ; 12
    Envelope_Ptr dw                           ; 13
    Envelope_Pos db                           ; 15
    Envelope_Vol db                           ; 16
    Envelope_Step db                          ; 17
    Envelope_Dest db                          ; 18
    Envelope_Hold db                          ; 19
    EffectiveVol db                           ; 1A
    Status db                                 ; 1B
    Pad0 db                                   ; 1C
    Pad1 db                                   ; 1D
    Pad2 db                                   ; 1E
    Pad3 db                                   ; 1F
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
    and %11000000  ; Mask out unused bits
    cpl            ; Flip bits (1 = pressed)
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
    ld de, tracks + Track.Order_Pos
    @loop:
    xor a, a
    ld [de], a ; Order_Pos
    inc e ; Effect_Kind
    ld [de], a ; Effect_Kind
    dec e ; Order_Pos
    dec e ; Pattern_Ptr (hi)
    dec e ; Pattern_Ptr (lo)
    dec e ; Pattern_RowStatus
    dec e ; Pattern_Row
    ld [de], a ; Pattern_Row
    dec e ; Pattern_RowCount
    inc a ; 1
    ld [de], a ; Pattern_RowCount
    dec e ; Tick
    ld a, [hl] ; order table (lo)
    inc hl
    or a, [hl] ; order table (hi)
    ld a, c ; speed
    jr nz, @2 ; is channel in use?
    ld a, $ff ; speed ff signals to play routine that track is unused
    @2:
    dec a ; speed - 1
    ld [de], a ; Tick
    dec e ; Speed
    inc a ; speed
    ld [de], a ; Speed
    ld a, e
    add a, Track.MasterVol - Track.Speed
    ld e, a
    ld a, $f0
    ld [de], a ; MasterVol
    inc e
    xor a, a
    ld [de], a ; PeriodIndex
    inc e
    ld [de], a ; PeriodLo
    inc e
    ld [de], a ; PeriodHi
    inc e ; Square_DutyCtrl
    inc e ; Envelope_Phase
    ld [de], a ; Envelope_Phase
    ld a, e
    add a, _sizeof_Track - Track.Envelope_Phase + Track.Order_Pos
    ld e, a
    jr nc, @1
    inc d
    @1:
    ld a, l
    add a, _sizeof_TrackHeader - 1
    ld l, a
    jr nc, @3
    inc h
    @3:
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
    ld hl, tracks; + SIZEOF
    @loop:
    ld a, [hl] ; Speed
    cp a, $ff   ; is track used?
    jr nz, @process_track
    ld de, _sizeof_Track
    add hl, de
    jp @next_track
    @process_track:
    inc l ; Tick
    inc [hl]    ; Tick
    cp a, [hl]  ; speed == tick?
    jr z, @next_row
    inc l ; Pattern_RowCount
    inc l ; Pattern_Row
    inc l ; Pattern_RowStatus
    jp @mixer_tick
    @next_row:
    xor a, a
    ld [hl], a ; Tick
    inc l ; Pattern_RowCount
    ld a, [hl] ; Pattern_RowCount
    inc l ; Pattern_Row
    inc [hl]    ; Pattern_Row
    cp a, [hl]  ; rowCount == row?
    jr z, @end_of_pattern
    jr @no_new_pattern
    @end_of_pattern:
    push hl ; Pattern_Row
    xor a, a
    ld [hl], a ; Pattern_Row = 0
    inc l ; Pattern_RowStatus
    inc l ; Pattern_Ptr (lo)
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
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
    ld a, [hl] ; Order_Pos
    add a, e
    ld e, a
    jr nc, @order_fetch_loop
    inc d
    @order_fetch_loop:
    ld a, [de] ; order byte
    inc de
    inc [hl] ; Order_Pos
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
    dec l ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ld [hl], a ; Pattern_Ptr (lo)
    inc l ; Pattern_Ptr (hi)
    inc de
    ld c, a
    ld a, [de] ; pattern ptr (hi)
    ld [hl], a ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ld e, c
    ld d, a
    ld a, [de] ; row count
    inc de
    call IncPatternPtr
    pop hl ; Pattern_Row
    dec l ; Pattern_RowCount
    ld [hl], a ; Pattern_RowCount
    inc l ; Pattern_Row
    inc l ; Pattern_RowStatus
    jr @fetch_row_status
    @order_special:
    ; TODO: implement order commands. Assume $fe for now
    ld a, [de] ; order byte
    ld [hl], a ; Order_Pos
    jr @pre_order_loop
    @no_new_pattern:
    ld a, [hl] ; Pattern_Row
    inc l
    and a, 7
    jr nz, @check_row_status
    ; prepare to fetch row status
    inc l ; Pattern_Ptr (lo)
    ld e, [hl] ; Pattern_Ptr (lo)
    inc l
    ld d, [hl] ; Pattern_Ptr (hi)
    dec l
    dec l ; Pattern_RowStatus
    @fetch_row_status:
    ; HL = Pattern_RowStatus
    ; DE = pattern data ptr
    ; fetch row status for upcoming 8 rows
    ld a, [de] ; pattern byte
    inc de
    ld [hl], a ; Pattern_RowStatus
    inc l ; Pattern_Ptr (lo)
    call IncPatternPtr
    dec l ; Pattern_RowStatus
    @check_row_status:
    ; HL = Pattern_RowStatus
    srl [hl] ; Pattern_RowStatus
    jr c, @process_pattern_data
    jp @mixer_tick
    @process_pattern_data:
    ; HL = Pattern_RowStatus
    dec l ; Pattern_Row
    ld a, [hl] ; Pattern_Row
    inc l ; Pattern_RowStatus
    inc l ; Pattern_Ptr (lo)
    and a, 7
    jr z, @pattern_fetch_loop
    ; for rows not multiple of 8, DE does not yet contain pattern data ptr because we didn't fetch row status byte
    ld e, [hl] ; Pattern_Ptr (lo)
    inc l ; Pattern_Ptr (hi)
    ld d, [hl] ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    @pattern_fetch_loop:
    ; HL = Pattern_Ptr (lo)
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
    push hl ; Pattern_Ptr (lo)
    jr z, @skip_inc ; effect = 0 --> no parameter byte
    call IncPatternPtr
    @skip_inc:
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
    inc l ; Effect_Kind
    ld [hl], a ; Effect_Kind
    inc l
    or a, a
    jr z, @skip_effect_init
    ld a, [de] ; pattern byte: effect param
    inc de
    ld [hl], a ; Effect_Param
    inc l
    ; clear effect state
    xor a, a
    ld [hl], a ; Effect_Pos
    @skip_effect_init:
    pop hl ; Pattern_Ptr (lo)
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
    push hl ; Pattern_Ptr (lo)
    push de
    ld de, Track.MasterVol - Track.Pattern_Ptr
    add hl, de
    ld [hl], a ; MasterVol
    pop de ; pattern data ptr
    pop hl ; Pattern_Ptr (lo)
    jr @pattern_fetch_loop
    @is_other_command:
    and a, $f
    call GoPatternCommand
    jr c, @pattern_fetch_loop
    dec l ; Pattern_RowStatus
    jp @mixer_tick
    @is_note:
    push hl ; Pattern_Ptr (lo)
    ld c, a ; save note
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
    inc l ; Effect_Kind
    ld d, [hl] ; Effect_Kind
    inc l ; Effect_Param
    inc l ; Effect_Pos
    ; clear effect state
    xor a, a
    ld [hl], a ; Effect_Pos
    inc l
    ld [hl], a ; Effect_Portamento_TargetPeriodLo
    inc l
    ld [hl], a ; Effect_Portamento_TargetPeriodHi
    inc l
    ld a, [hl] ; MasterVol
    srl a
    jr c, @skip ; CF=1 if the volume has been overridden by a previous volume command
    ld a, $78
    @skip:
    sla a
    ld [hl], a ; MasterVol
    inc l ; PeriodIndex
    inc l ; PeriodLo
    inc l ; PeriodHi
    inc l ; Square_DutyCtrl
    inc l ; Envelope_Phase
    ld a, ENV_RESET
    ld [hl], a ; Envelope_Phase
    dec l ; Square_DutyCtrl
    ld a, d ; effect kind
    cp a, PORTAMENTO_EFFECT
    jr z, @init_slide
    ; no slide, set new period immediately
    push hl ; Square_DutyCtrl
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
    pop hl ; Square_DutyCtrl
    dec l ; PeriodHi
    ld [hl], a ; PeriodHi
    dec l ; PeriodLo
    ld [hl], d ; PeriodLo
    dec l ; PeriodIndex
    ld a, c
    or a, $80 ; trigger channel
    ld [hl], a ; PeriodIndex
    pop hl ; Pattern_Ptr (lo)
    dec l ; Pattern_RowStatus
    jp @mixer_tick
    @init_slide:
    dec l ; PeriodHi
    dec l ; PeriodLo
    dec l ; PeriodIndex
    ld a, [hl] ; PeriodIndex
    cp a, c ; CF = slide direction (0=down,1=up)
    push af ; save flags
    ld [hl], c ; PeriodIndex
    push hl ; PeriodIndex
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
    pop hl ; PeriodIndex
    dec l ; MasterVol
    dec l ; Effect_Portamento_TargetPeriodHi
    ld [hl], a ; Effect_Portamento_TargetPeriodHi
    dec l
    ld [hl], d ; Effect_Portamento_TargetPeriodLo
    dec l
    pop af ; restore flags
    ld a, $40
    rl a ; bit 7 = 1 (active), bit 0 = direction
    ld [hl], a ; Effect_Portamento_Ctrl
    pop hl ; Pattern_Ptr (lo)
    dec l ; Pattern_RowStatus
    @mixer_tick:
    ; hl points to Pattern_RowStatus
    ; update effect
    ld de, Track.Effect_Kind - Track.Pattern_RowStatus
    add hl, de
    ld a, [hl] ; Effect_Kind
    inc l ; Effect_Param
    call EffectTick
    ; update envelope
    ld de, Track.Envelope_Phase - Track.Effect_Param
    add hl, de ; Envelope_Phase
    call EnvelopeTick
    ld de, _sizeof_Track - Track.Envelope_Phase
    add hl, de ; next track
    @next_track:
    inc b
    ld a, b
    cp a, MAX_TRACKS
    jp nz, @loop
    jr RenderChannels

RenderChannels:
    call RenderPSGChannels
    jp RenderFMChannels

RenderPSGChannels:
    call RenderPSGChannel1
    call RenderPSGChannel2
    call RenderPSGChannel3
    jp RenderPSGChannel4

RenderPSGChannel1:
    ld hl, tracks + Track.PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $9f ; tone 1 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld hl, tracks + Track.Envelope_Vol
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld hl, tracks + Track.MasterVol
    or a, [hl] ; MasterVol
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
    ld hl, tracks + Track.EffectiveVol
    ld [hl], a ; EffectiveVol
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $90 ; tone 1 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo
    ld e, [hl] ; PeriodLo
    inc hl ; PeriodHi
    ld d, [hl] ; PeriodHi
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

RenderPSGChannel3:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track*2
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $df ; tone 3 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld hl, tracks + Track.Envelope_Vol + _sizeof_Track*2
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld hl, tracks + Track.MasterVol + _sizeof_Track*2
    or a, [hl] ; MasterVol
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
    ld hl, tracks + Track.EffectiveVol + _sizeof_Track*2
    ld [hl], a ; EffectiveVol
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $d0 ; tone 3 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo + _sizeof_Track*2
    ld e, [hl] ; PeriodLo
    inc hl ; PeriodHi
    ld d, [hl] ; PeriodHi
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

RenderPSGChannel2:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $bf ; tone 2 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld hl, tracks + Track.Envelope_Vol + _sizeof_Track
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld hl, tracks + Track.MasterVol + _sizeof_Track
    or a, [hl] ; MasterVol
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
    ld hl, tracks + Track.EffectiveVol + _sizeof_Track
    ld [hl], a ; EffectiveVol
    ld e, a
    ld hl, PSGToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $b0 ; tone 2 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo + _sizeof_Track
    ld e, [hl] ; PeriodLo
    inc hl ; PeriodHi
    ld d, [hl] ; PeriodHi
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

RenderPSGChannel4:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track*3
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $ff ; noise attenuation
    out ($7f), a ; mute
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    ld hl, tracks + Track.Envelope_Vol + _sizeof_Track*3
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld hl, tracks + Track.MasterVol + _sizeof_Track*3
    or a, [hl] ; MasterVol
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
    ld hl, tracks + Track.EffectiveVol + _sizeof_Track*3
    ld [hl], a ; EffectiveVol
    ld e, a
    ld hl, PSGNoiseAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $f0 ; noise attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodHi + _sizeof_Track*3
    ld e, [hl] ; PeriodHi (0..7)
    ld a, 7
    sub a, e
    srl a
    and a, 3
    cp a, 3
    jr nz, @no_clamp
    dec a
    @no_clamp:
    set 2, a ; white noise is default
    inc l ; Square_DutyCtrl
    bit 7, [hl] ; Square_DutyCtrl (LFSR width)
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
    ld hl, tracks + (4 * _sizeof_Track) ; skip PSG tracks
    @loop:
    call RenderMelodicFMChannel
    ld de, _sizeof_Track
    add hl, de ; next track
    inc b
    ld a, b
    cp a, 6 ; number of melodic channels
    jr nz, @loop
    ret

RenderRhythmFMChannels:
    ld b, 6 ; FM channel index
    ld hl, tracks + ((4 + 6) * _sizeof_Track) ; skip PSG tracks and melodic FM tracks
    @loop:
    ld a, [hl] ; Speed
    cp a, $ff ; is track used?
    jr z, @skip
    call RenderRhythmFMChannel
    @skip:
    ld de, _sizeof_Track
    add hl, de ; next track
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

; HL = Pattern_Ptr (lo)
IncPatternPtr:
    inc [hl] ; Pattern_Ptr (lo)
    ret nz
    inc l ; Pattern_Ptr (hi)
    inc [hl] ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ret

; HL = address of track
; B = FM channel index (0..5)
; Destroys: A, C, DE
RenderMelodicFMChannel:
    push hl
    ld de, Track.PeriodIndex
    add hl, de
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, b ; channel
    or a, $20   ; Select Channel N Frequency High Bit, Block, and Key On
    out ($f0), a
    ld a, 0 ; key off (bit 4 = 0)
    out ($f1), a
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    push hl ; PeriodIndex
    ; calculate effective volume
    ld de, Track.Envelope_Vol - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld de, Track.MasterVol - Track.Envelope_Vol
    add hl, de
    or a, [hl] ; MasterVol
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
    pop hl ; PeriodIndex
    @set_volume:
    push hl ; PeriodIndex
    ld de, Track.EffectiveVol - Track.PeriodIndex
    add hl, de
    ld [hl], a ; EffectiveVol
    ld e, a
    push hl ; EffectiveVol
    ld hl, FMAttenuationTable
    add hl, de
    ld a, b ; channel
    or a, $30   ; Select Channel N Instrument and Volume
    out ($f0), a
    ld a, [hl] ; map volume to attenuation
    ld c, a
    pop hl ; EffectiveVol
    ld de, Track.Square_DutyCtrl - Track.EffectiveVol
    add hl, de
    ld a, [hl] ; Square_DutyCtrl
    and a, $f0 ; instrument in upper 4 bits
    or a, c
    out ($f1), a
    pop hl ; PeriodIndex
    inc l ; PeriodLo
    ld e, [hl] ; PeriodLo
    inc l ; PeriodHi
    ld d, [hl] ; PeriodHi
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
    pop hl
    ret

; HL = address of track
; B = FM channel index (6..8)
; Destroys: A, C, DE
RenderRhythmFMChannel:
    push hl
    ld de, Track.PeriodIndex
    add hl, de
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $0e
    out ($f0), a
    push hl ; PeriodIndex
    ld de, Track.Square_DutyCtrl - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Square_DutyCtrl
    cpl
    ld c, a
    ld a, [shadowRhythmControlReg]
    and a, c ; clear instrument bits
    or a, $20
    ld c, a
    out ($f1), a ; clear instrument bits
    ld a, $0e
    out ($f0), a
    ld a, [hl] ; Square_DutyCtrl
    or a, c
    out ($f1), a ; set instrument bits
    ld [shadowRhythmControlReg], a
    pop hl ; PeriodIndex
    @no_trigger:
    ; check if channel is muted
    push hl ; PeriodIndex
    ld de, Track.Status - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Status
    pop hl ; PeriodIndex
    or a, a
    jr z, @not_muted
    xor a
    jr @set_volume
    @not_muted:
    push hl ; PeriodIndex
    ; calculate effective volume
    ld de, Track.Envelope_Vol - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Envelope_Vol
    srl a
    srl a
    srl a
    srl a
    ld de, Track.MasterVol - Track.Envelope_Vol
    add hl, de
    or a, [hl] ; MasterVol
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
    pop hl ; PeriodIndex
    @set_volume:
    push hl ; PeriodIndex
    ld de, Track.EffectiveVol - Track.PeriodIndex
    add hl, de
    ld [hl], a ; EffectiveVol
    ld d, 0
    ld e, a
    ld hl, FMAttenuationTable
    add hl, de
    ld c, [hl] ; map volume to attenuation
    pop hl ; PeriodIndex
    ld de, Track.Square_DutyCtrl - Track.PeriodIndex
    add hl, de
    ld a, [hl] ; Square_DutyCtrl
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
    pop hl
    ret
@table:
.db 1 | 4 ; $37 D7-D4
.db 2 | 0 ; $38 D3-D0
.db 2 | 4 ; $38 D7-D4
.db 1 | 0 ; $37 D3-D0
.db 0 | 0 ; $36 D3-D0

GoPatternCommand:
    push de
    push hl
    rst JumpTable
.dw .set_instr     ; 0
.dw .release       ; 1
.dw .set_speed     ; 2
.dw .end_row       ; 3
.dw .pan_left      ; 4
.dw .pan_center    ; 5
.dw .pan_right     ; 6

    .set_instr:
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; instrument
    inc de
    call IncPatternPtr
    call SetInstrument
    scf ; CF=1 signals keep processing pattern data
    ret

    .release:
    pop hl ; Pattern_Ptr (lo)
    push hl
    ld de, Track.Envelope_Hold - Track.Pattern_Ptr
    add hl, de
    ld a, 1
    ld [hl], a ; Envelope_Hold
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .set_speed:
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; new speed
    inc de
    call IncPatternPtr
    call SetSpeed
    scf ; CF=1 signals keep processing pattern data
    ret

    .end_row: ; this command is used when there is no note for the row, only commands
    pop hl ; Pattern_Ptr (lo)
    push hl
    ld de, Track.MasterVol - Track.Pattern_Ptr
    add hl, de
    ld a, [hl] ; MasterVol
    and $fe
    ld [hl], a ; MasterVol
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf
    ccf ; CF=0 signals end of pattern data processing
    ret

    .pan_left:
    ; TODO: implement panning
    .done_panning:
    pop hl ; Pattern_Ptr (lo)
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
; preserves DE and HL
SetInstrument:
    push de
    push hl ; Pattern_Ptr (lo)
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
    ld a, l
    add a, Track.Envelope_Ptr - Track.Pattern_Ptr
    ld l, a
    ld a, [de] ; 0 - envelope lo
    inc de
    ld [hl], a ; Envelope_Ptr (lo)
    inc l
    ld a, [de] ; 1 - envelope hi
    inc de
    ld [hl], a ; Envelope_Ptr (hi)
    ld a, l
    sub a, Track.Envelope_Ptr+1 - Track.Effect_Kind
    ld l, a
    inc de ; 2 - unused
    ld a, [de] ; 3 - effect kind
    inc de
    ld [hl], a ; Effect_Kind
    inc l
    ld a, [de] ; 4 - effect param
    inc de
    ld [hl], a ; Effect_Param
    ld a, l
    add a, Track.Square_DutyCtrl - Track.Effect_Param
    ld l, a
    ld a, [de] ; 5 - duty
    ld [hl], a ; Square_DutyCtrl
    pop hl ; Pattern_Ptr (lo)
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
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ret

; A = effect kind, HL = Effect_Param
EffectTick:
    push hl ; Effect_Param
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
    pop hl ; Effect_Param
    ret

    .slide_up_tick:
; slide up by adding slide amount to period value
    pop hl ; Effect_Param
    push hl
    ld c, [hl] ; Effect_Param
    ld a, l ; Effect_Param
    add a, Track.PeriodLo - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodLo
    add a, c
    ld [hl], a ; PeriodLo
    inc l
    jr nc, @slide_skip_inc
    ld a, [hl] ; PeriodHi
    cp a, 7
    jr z, @clamp_slide_up
    inc [hl] ; PeriodHi
    @slide_skip_inc:
    pop hl ; Effect_Param
    ret
    @clamp_slide_up:
    dec l ; PeriodLo
    ld a, $ff
    ld [hl], a ; PeriodLo
    pop hl ; Effect_Param
    ret

    .slide_down_tick:
; slide down by subtracting slide amount from period value
    pop hl ; Effect_Param
    push hl
    ld c, [hl] ; Effect_Param
    ld a, l ; Effect_Param
    add a, Track.PeriodLo - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodLo
    sub a, c
    ld [hl], a ; PeriodLo
    inc l
    jr nc, @slide_skip_dec
    ld a, [hl] ; PeriodLo
    or a
    jr z, @clamp_slide_up
    dec [hl] ; PeriodHi
    @slide_skip_dec:
    pop hl ; Effect_Param
    ret
    @clamp_slide_up:
    dec l ; PeriodLo
    xor a
    ld [hl], a ; PeriodLo
    pop hl ; Effect_Param
    ret

    .portamento_tick:
    pop hl ; Effect_Param
    push hl
    ld c, [hl] ; Effect_Param
    inc l
    ld a, [hl] ; Effect_Portamento_Ctrl
    inc l
    bit 7, a
    jr z, .portamento_exit
    srl a ; CF = direction (0=down, 1=up)
    ld e, [hl] ; Effect_Portamento_TargetPeriodLo
    inc l
    ld d, [hl] ; Effect_Portamento_TargetPeriodHi
    inc l
    inc l ; PeriodIndex
    inc l ; PeriodLo
    ld a, [hl] ; PeriodLo
    jr nc, .portamento_down
    ; slide up (add delta to current period value)
    add a, c
    ld [hl], a ; PeriodLo
    inc l
    ld a, [hl] ; PeriodHi
    adc a, 0
    ld [hl], a ; PeriodHi
    dec l
    ld c, a ; save periodhi
    ; check if target period has been reached (current period >= target period)
    ld a, [hl] ; PeriodLo
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_done
    .portamento_exit:
    pop hl ; Effect_Param
    ret
    .portamento_down:
    ; slide down (subtract delta from current period value)
    sub a, c
    ld [hl], a ; PeriodLo
    inc l
    ld a, [hl] ; PeriodHi
    sbc a, 0
    ld [hl], a ; PeriodHi
    dec l
    ld c, a ; save periodhi
    ; check if target period has been reached (current period <= target period)
    ld a, [hl] ; PeriodLo
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_exit
    .portamento_done:
    ; set final period
    ld [hl], e ; PeriodLo
    inc l
    ld [hl], d ; PeriodHi
    ; halt
    pop hl ; Effect_Param
    inc l ; Effect_Portamento_Ctrl
    xor a, a
    ld [hl], a ; Effect_Portamento_Ctrl
    dec l
    ret

    .vibrato_tick:
    pop hl ; Effect_Param
    push hl
    ; reset period value
    ld a, l
    add a, Track.PeriodIndex - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodIndex
    inc l ; PeriodLo
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
    ld [hl], a ; PeriodLo
    inc l ; PeriodHi
    inc de
    ld a, [de]
    ld [hl], a ; PeriodHi
    pop hl ; Effect_Param
    inc l ; Effect_Pos
    ; get sine value
    ld a, [hl] ; Effect_Pos
    dec l
    and a, $1f
    ld de, VibratoTable
    add a, e
    ld e, a
    ld a, [de] ; sine value
    ld c, a
    ; *** convert sine value to real delta freq, according to vibrato depth ***
    ld a, [hl] ; Effect_Param
    inc l
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
    ld a, [hl] ; Effect_Pos
    push hl
    and a, $20
    jr z, .vib_add
    ; subtract c from period
    ld a, l
    add a, Track.PeriodLo - Track.Effect_Pos
    ld l, a
    ld a, [hl] ; PeriodLo
    sub a, c
    ld [hl], a ; PeriodLo
    inc l
    jr nc, .vib_done
    dec [hl] ; PeriodHi
    jr .vib_done
    .vib_add:
    ; add c to period
    ld a, l
    add a, Track.PeriodLo - Track.Effect_Pos
    ld l, a
    ld a, [hl] ; PeriodLo
    add a, c
    ld [hl], a ; PeriodLo
    inc l
    jr nc, .vib_done
    inc [hl] ; PeriodHi
    .vib_done:
    ; increment pos
    pop hl ; Effect_Pos
    ld a, [hl] ; Effect_Pos
    dec l
    ld c, a
    ld a, [hl] ; Effect_Param
    inc l
    srl a
    srl a
    srl a
    srl a ; vibrato speed
    add a, c
    ld [hl], a ; Effect_Pos
    dec l
    ret

    .arpeggio_tick:
    pop hl ; Effect_Param
    push hl
    ld c, [hl] ; Effect_Param
    inc l
    ld a, [hl] ; Effect_Pos
    ld d, a
    inc a
    cp a, 6
    jr c, .skip
    xor a, a
    .skip:
    ld [hl], a ; Effect_Pos
    inc l
    inc l ; Effect_VibratoCounter
    inc l ; Effect_MasterVol
    inc l ; PeriodIndex
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
    add a, [hl] ; PeriodIndex
    inc l ; PeriodLo
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
    ld [hl], a ; PeriodLo
    inc l
    inc de
    ld a, [de]
    ld [hl], a ; PeriodHi
    pop hl ; Effect_Param
    ret

    .volume_slide_tick:
    pop hl ; Effect_Param
    ld a, [hl] ; Effect_Param
    cp a, $10
    jr c, @sub_volume
    ; add to volume
    srl a
    srl a
    and a, $3c ; delta * 4
    ld c, a
    push hl ; Effect_Param
    ld de, Track.MasterVol - Track.Effect_Param
    add hl, de
    ld a, [hl] ; MasterVol
    add a, c
    jr nc, @set_volume
    ld a, $fc ; max volume
    jr @set_volume
    @sub_volume:
    sla a
    sla a ; delta * 4
    ld c, a
    push hl ; Effect_Param
    ld de, Track.MasterVol - Track.Effect_Param
    add hl, de
    ld a, [hl] ; MasterVol
    sub a, c
    jr nc, @set_volume
    xor a, a
    @set_volume:
    ld [hl], a ; MasterVol
    pop hl ; Effect_Param
    ret

    .tremolo_tick:
    pop hl ; Effect_Param
    ; TODO: implement tremolo
    ret

    .cut_tick:
    pop hl ; Effect_Param
    ld c, [hl] ; Effect_Param
    inc l
    ld a, [hl] ; Effect_Pos
    cp a, c
    inc a
    ld [hl], a ; Effect_Pos
    dec l
    ret c
    ; cut! (set volume to 0)
    push hl ; Effect_Param
    ld a, l ; Effect_Param
    add a, Track.MasterVol - Track.Effect_Param
    ld l, a ; MasterVol
    xor a, a
    ld [hl], a ; MasterVol
    pop hl ; Effect_Param
    ret

    .pulsemod_tick:
    pop hl ; Effect_Param
    ; TODO: implement pulsemod
    ret

; HL = Envelope_Phase
EnvelopeTick:
    ld a, [hl] ; Envelope_Phase
    rla
    jr c, .init    ; $80
    rla
    jr c, .process ; $40
    rla
    jr c, .sustain ; $20
    ret

    .init:
    push hl ; Envelope_Phase
    srl [hl] ; Envelope_Phase = $40
    inc l ; Envelope_Ptr (lo)
    ld e, [hl] ; Envelope_Ptr (lo)
    inc l
    ld d, [hl] ; Envelope_Ptr (hi)
    inc l
    xor a, a
    ld [hl], a ; Envelope_Pos = 0
    .init_vol:
    ; HL = Envelope_Pos
    ld a, [de] ; 1st byte = start volume
    inc de
    inc [hl] ; Envelope_Pos
    inc l ; Envelope_Vol
    ld [hl], a ; Envelope_Vol
    inc l ; Envelope_Step
    .point_init:
    ; HL = Envelope_Step
    ld a, [de] ; fetch envelope byte
    inc de
    cp a, $ff ; end of envelope reached?
    jr z, .env_end
    ; point OK, set 3-tuple (step, dest, hold)
    ld [hl], a ; Envelope_Step
    inc l
    ld a, [de]
    inc de
    ld [hl], a ; Envelope_Dest
    inc l
    ld a, [de]
    inc de
    ld [hl], a ; Envelope_Hold
    ld a, l
    sub a, Track.Envelope_Hold - Track.Envelope_Pos
    ld l, a
    inc [hl] ; Envelope_Pos
    inc [hl] ; Envelope_Pos
    inc [hl] ; Envelope_Pos
    pop hl ; Envelope_Phase
    jr .process
    .env_end:
    ld a, [de]
    cp a, $ff ; definitely end?
    jr z, .env_stop
    ; loop the envelope from the given offset
    ld c, a
    ld a, l
    sub a, Track.Envelope_Step - Track.Envelope_Ptr
    ld l, a
    ld e, [hl] ; Envelope_Ptr (lo)
    inc l
    ld d, [hl] ; Envelope_Ptr (hi)
    inc l
    ld a, c
    ld [hl], a ; Envelope_Pos
    inc l
    inc l ; Envelope_Step
    add a, e
    ld e, a
    jr nc, .point_init
    inc d
    jr .point_init
    .env_stop:
    pop hl ; Envelope_Phase
    xor a, a
    ld [hl], a ; Envelope_Phase
    ret

    .sustain:
    push hl ; Envelope_Phase
    sla [hl] ; Envelope_Phase = process (speculative)
    ld a, l
    add a, Track.Envelope_Hold - Track.Envelope_Phase
    ld l, a
    ld a, [hl] ; Envelope_Hold
    cp a, $ff ; hold forever?
    jr z, .keep_sustaining
    dec [hl] ; Envelope_Hold -= 1
    jr nz, .keep_sustaining
    jr .next_point
    .keep_sustaining:
    pop hl ; Envelope_Phase
    srl [hl] ; Envelope_Phase = sustain
    ret

    .process:
    push hl ; Envelope_Phase
    ld a, l
    add a, Track.Envelope_Vol - Track.Envelope_Phase
    ld l, a
    ld a, [hl] ; Envelope_Vol
    inc l
    push af ; save vol
    ld c, [hl] ; Envelope_Step
    inc l ; Envelope_Dest
    pop af ; vol
    cp a, [hl] ; Envelope_Dest > Vol?
    jr nc, .sub_volume
    ; add step to vol
    add a, c
    jr c, .reached_dest
    cp a, [hl] ; Envelope_Dest > new vol?
    jr z, .reached_dest
    jr nc, .reached_dest
    dec l ; Envelope_Step
    dec l ; Envelope_Vol
    ld [hl], a ; Envelope_Vol
    pop hl ; Envelope_Phase
    ret
    .sub_volume:
    ; subtract step from volume
    sub a, c
    jr c, .reached_dest
    cp a, [hl] ; Envelope_Dest > new vol?
    jr z, .reached_dest
    jr c, .reached_dest
    dec l ; Envelope_Step
    dec l ; Envelope_Vol
    ld [hl], a ; Envelope_Vol
    pop hl ; Envelope_Phase
    ret
    .reached_dest:
    ld a, [hl] ; Envelope_Dest
    dec l ; Envelope_Step
    dec l ; Envelope_Vol
    ld [hl], a ; Envelope_Vol = dest
    inc l ; Envelope_Step
    inc l ; Envelope_Dest
    inc l ; Envelope_Hold
    ld a, [hl] ; Envelope_Hold
    or a, a
    jr z, .next_point
    pop hl ; Envelope_Phase
    srl [hl] ; phase = sustain
    ret
    .next_point:
    ; HL = Envelope_Hold
    ld a, l ; Envelope_Hold
    sub a, Track.Envelope_Hold - Track.Envelope_Ptr
    ld l, a
    ld e, [hl] ; Envelope_Ptr (lo)
    inc l
    ld d, [hl] ; Envelope_Ptr (hi)
    inc l
    ld a, [hl] ; Envelope_Pos
    inc l
    add a, e
    ld e, a
    jr nc, .skip_inc
    inc d
    .skip_inc:
    inc l ; Envelope_Step
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
.dw $00e,$080,$0ec,$151,$1b1,$20c,$261,$2b2,$2fe,$346,$38a,$3ca,$407,$440,$476,$4a8
.dw $4d8,$506,$530,$559,$57f,$5a3,$5c5,$5e5,$603,$620,$63b,$654,$66c,$683,$698,$6ac
.dw $6bf,$6d1,$6e2,$6f2,$701,$710,$71d,$72a,$736,$741,$74c,$756,$75f,$768,$771,$779
.dw $780,$788,$78e,$795,$79b,$7a0,$7a6,$7ab,$7af,$7b4,$7b8,$7bc,$7c0,$7c4,$7c7,$7ff

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
.dw $1b0,$1b1,$1b2,$1b3,$1b4,$1b5,$1b6,$1b7,$1b8,$1b9,$1ba,$1bb,$1bc,$1bd,$1be,$1bf
.dw $1c0,$1c1,$1c2,$1c3,$1c4,$1c5,$1c6,$1c7,$1c8,$1c9,$1ca,$1cb,$1cc,$1ce,$1cf,$1d0
.dw $1d1,$1d2,$1d3,$1d4,$1d5,$1d6,$1d7,$1d8,$1da,$1db,$1dc,$1dd,$1de,$1df,$1e0,$1e1
.dw $1e2,$1e3,$1e4,$1e6,$1e7,$1e8,$1e9,$1ea,$1eb,$1ed,$1ee,$1ef,$1f0,$1f1,$1f2,$1f3
.dw $1f5,$1f6,$1f7,$1f8,$1f9,$1fa,$1fc,$1fd,$1fe,$1ff,$300,$300,$301,$302,$302,$303
.dw $303,$304,$305,$305,$306,$307,$307,$308,$308,$309,$30a,$30a,$30b,$30b,$30c,$30d
.dw $30d,$30e,$30e,$30f,$310,$310,$311,$312,$312,$313,$314,$314,$315,$315,$316,$317
.dw $317,$318,$319,$319,$31a,$31b,$31b,$31c,$31d,$31d,$31e,$31f,$31f,$320,$321,$321
.dw $322,$323,$323,$324,$325,$325,$326,$327,$327,$328,$329,$329,$32a,$32b,$32c,$32c
.dw $32d,$32e,$32e,$32f,$330,$330,$331,$332,$332,$333,$334,$335,$335,$336,$337,$338
.dw $338,$339,$33a,$33a,$33b,$33c,$33d,$33d,$33e,$33f,$340,$340,$341,$342,$342,$343
.dw $344,$345,$346,$346,$347,$348,$349,$349,$34a,$34b,$34c,$34c,$34d,$34e,$34f,$350
.dw $350,$351,$352,$353,$353,$354,$355,$356,$356,$357,$358,$359,$35a,$35b,$35b,$35c
.dw $35d,$35e,$35f,$35f,$360,$361,$362,$363,$363,$364,$365,$366,$367,$368,$368,$369
.dw $36a,$36b,$36c,$36d,$36d,$36e,$36f,$370,$371,$372,$373,$373,$374,$375,$376,$377
.dw $378,$379,$37a,$37a,$37b,$37c,$37d,$37e,$37f,$380,$380,$381,$382,$383,$384,$385
.dw $386,$387,$388,$389,$38a,$38a,$38b,$38c,$38d,$38e,$38f,$390,$391,$392,$393,$394
.dw $395,$395,$396,$397,$398,$399,$39a,$39b,$39c,$39d,$39e,$39f,$3a0,$3a1,$3a2,$3a3
.dw $3a4,$3a5,$3a6,$3a7,$3a8,$3a9,$3aa,$3ab,$3ac,$3ad,$3ae,$3af,$3b0,$3b1,$3b2,$3b3
.dw $3b4,$3b5,$3b6,$3b7,$3b8,$3b9,$3ba,$3bb,$3bc,$3bd,$3be,$3bf,$3c0,$3c1,$3c2,$3c3
.dw $3c4,$3c5,$3c6,$3c7,$3c8,$3c9,$3ca,$3cb,$3cd,$3ce,$3cf,$3d0,$3d1,$3d2,$3d3,$3d4
.dw $3d5,$3d6,$3d7,$3d8,$3da,$3db,$3dc,$3dd,$3de,$3df,$3e0,$3e1,$3e2,$3e3,$3e4,$3e6
.dw $3e7,$3e8,$3e9,$3ea,$3eb,$3ed,$3ee,$3ef,$3f0,$3f1,$3f2,$3f3,$3f5,$3f6,$3f7,$3f8
.dw $3f9,$3fa,$3fc,$3fd,$3fe,$3ff,$500,$500,$501,$502,$502,$503,$503,$504,$505,$505
.dw $506,$507,$507,$508,$508,$509,$50a,$50a,$50b,$50b,$50c,$50d,$50d,$50e,$50e,$50f
.dw $510,$510,$511,$512,$512,$513,$514,$514,$515,$516,$516,$517,$517,$518,$519,$519
.dw $51a,$51b,$51b,$51c,$51d,$51d,$51e,$51f,$51f,$520,$521,$521,$522,$523,$523,$524
.dw $525,$525,$526,$527,$527,$528,$529,$529,$52a,$52b,$52c,$52c,$52d,$52e,$52e,$52f
.dw $530,$530,$531,$532,$532,$533,$534,$535,$535,$536,$537,$538,$538,$539,$53a,$53a
.dw $53b,$53c,$53d,$53d,$53e,$53f,$540,$540,$541,$542,$542,$543,$544,$545,$545,$546
.dw $547,$548,$549,$549,$54a,$54b,$54c,$54c,$54d,$54e,$54f,$54f,$550,$551,$552,$553
.dw $553,$554,$555,$556,$556,$557,$558,$559,$55a,$55a,$55b,$55c,$55d,$55e,$55f,$55f
.dw $560,$561,$562,$563,$563,$564,$565,$566,$567,$568,$568,$569,$56a,$56b,$56c,$56d
.dw $56d,$56e,$56f,$570,$571,$572,$573,$573,$574,$575,$576,$577,$578,$579,$579,$57a
.dw $57b,$57c,$57d,$57e,$57f,$580,$580,$581,$582,$583,$584,$585,$586,$587,$588,$589
.dw $58a,$58a,$58b,$58c,$58d,$58e,$58f,$590,$591,$592,$593,$594,$595,$595,$596,$597
.dw $598,$599,$59a,$59b,$59c,$59d,$59e,$59f,$5a0,$5a1,$5a2,$5a3,$5a4,$5a5,$5a6,$5a7
.dw $5a8,$5a9,$5aa,$5ab,$5ac,$5ad,$5ae,$5af,$5b0,$5b1,$5b2,$5b3,$5b4,$5b5,$5b6,$5b7
.dw $5b8,$5b9,$5ba,$5bb,$5bc,$5bd,$5be,$5bf,$5c0,$5c1,$5c2,$5c3,$5c4,$5c5,$5c6,$5c7
.dw $5c8,$5c9,$5ca,$5cb,$5cc,$5ce,$5cf,$5d0,$5d1,$5d2,$5d3,$5d4,$5d5,$5d6,$5d7,$5d8
.dw $5da,$5db,$5dc,$5dd,$5de,$5df,$5e0,$5e1,$5e2,$5e3,$5e4,$5e6,$5e7,$5e8,$5e9,$5ea
.dw $5eb,$5ed,$5ee,$5ef,$5f0,$5f1,$5f2,$5f3,$5f5,$5f6,$5f7,$5f8,$5f9,$5fa,$5fc,$5fd
.dw $5fe,$5ff,$700,$700,$701,$702,$702,$703,$703,$704,$705,$705,$706,$707,$707,$708
.dw $708,$709,$70a,$70a,$70b,$70b,$70c,$70d,$70d,$70e,$70e,$70f,$710,$710,$711,$712
.dw $712,$713,$714,$714,$715,$715,$716,$717,$717,$718,$719,$719,$71a,$71b,$71b,$71c
.dw $71d,$71d,$71e,$71f,$71f,$720,$721,$721,$722,$723,$723,$724,$725,$725,$726,$727
.dw $727,$728,$729,$729,$72a,$72b,$72c,$72c,$72d,$72e,$72e,$72f,$730,$730,$731,$732
.dw $732,$733,$734,$735,$735,$736,$737,$738,$738,$739,$73a,$73a,$73b,$73c,$73d,$73d
.dw $73e,$73f,$740,$740,$741,$742,$742,$743,$744,$745,$745,$746,$747,$748,$749,$749
.dw $74a,$74b,$74c,$74c,$74d,$74e,$74f,$74f,$750,$751,$752,$753,$753,$754,$755,$756
.dw $756,$757,$758,$759,$75a,$75b,$75b,$75c,$75d,$75e,$75f,$75f,$760,$761,$762,$763
.dw $763,$764,$765,$766,$767,$768,$768,$769,$76a,$76b,$76c,$76d,$76d,$76e,$76f,$770
.dw $771,$772,$773,$773,$774,$775,$776,$777,$778,$779,$779,$77a,$77b,$77c,$77d,$77e
.dw $77f,$780,$780,$781,$782,$783,$784,$785,$786,$787,$788,$789,$78a,$78a,$78b,$78c
.dw $78d,$78e,$78f,$790,$791,$792,$793,$794,$795,$795,$796,$797,$798,$799,$79a,$79b
.dw $79c,$79d,$79e,$79f,$7a0,$7a1,$7a2,$7a3,$7a4,$7a5,$7a6,$7a7,$7a8,$7a9,$7aa,$7ab
.dw $7ac,$7ad,$7ae,$7af,$7b0,$7b1,$7b2,$7b3,$7b4,$7b5,$7b6,$7b7,$7b8,$7b9,$7ba,$7bb
.dw $7bc,$7bd,$7be,$7bf,$7c0,$7c1,$7c2,$7c3,$7c4,$7c5,$7c6,$7c7,$7c8,$7c9,$7ca,$7cb
.dw $7cd,$7ce,$7cf,$7d0,$7d1,$7d2,$7d3,$7d4,$7d5,$7d6,$7d7,$7d8,$7da,$7db,$7dc,$7dd
.dw $7de,$7df,$7e0,$7e1,$7e2,$7e3,$7e4,$7e6,$7e7,$7e8,$7e9,$7ea,$7eb,$7ed,$7ee,$7ef
.dw $7f0,$7f1,$7f2,$7f3,$7f5,$7f6,$7f7,$7f8,$7f9,$7fa,$7fc,$7fd,$7fe,$7ff,$900,$900
.dw $901,$902,$902,$903,$903,$904,$905,$905,$906,$907,$907,$908,$908,$909,$90a,$90a
.dw $90b,$90b,$90c,$90d,$90d,$90e,$90e,$90f,$910,$910,$911,$912,$912,$913,$914,$914
.dw $915,$915,$916,$917,$917,$918,$919,$919,$91a,$91b,$91b,$91c,$91d,$91d,$91e,$91f
.dw $91f,$920,$921,$921,$922,$923,$923,$924,$925,$925,$926,$927,$927,$928,$929,$929
.dw $92a,$92b,$92c,$92c,$92d,$92e,$92e,$92f,$930,$930,$931,$932,$932,$933,$934,$935
.dw $935,$936,$937,$938,$938,$939,$93a,$93a,$93b,$93c,$93d,$93d,$93e,$93f,$940,$940
.dw $941,$942,$942,$943,$944,$945,$945,$946,$947,$948,$949,$949,$94a,$94b,$94c,$94c
.dw $94d,$94e,$94f,$94f,$950,$951,$952,$953,$953,$954,$955,$956,$956,$957,$958,$959
.dw $95a,$95a,$95b,$95c,$95d,$95e,$95f,$95f,$960,$961,$962,$963,$963,$964,$965,$966
.dw $967,$968,$968,$969,$96a,$96b,$96c,$96d,$96d,$96e,$96f,$970,$971,$972,$973,$973
.dw $974,$975,$976,$977,$978,$979,$97a,$97a,$97b,$97c,$97d,$97e,$97f,$980,$980,$981
.dw $982,$983,$984,$985,$986,$987,$988,$989,$98a,$98a,$98b,$98c,$98d,$98e,$98f,$990
.dw $991,$992,$993,$994,$995,$995,$996,$997,$998,$999,$99a,$99b,$99c,$99d,$99e,$99f
.dw $9a0,$9a1,$9a2,$9a3,$9a4,$9a5,$9a6,$9a7,$9a8,$9a9,$9aa,$9ab,$9ac,$9ad,$9ae,$9af
.dw $9b0,$9b1,$9b2,$9b3,$9b4,$9b5,$9b6,$9b7,$9b8,$9b9,$9ba,$9bb,$9bc,$9bd,$9be,$9bf
.dw $9c0,$9c1,$9c2,$9c3,$9c4,$9c5,$9c6,$9c7,$9c8,$9c9,$9ca,$9cb,$9cd,$9ce,$9cf,$9d0
.dw $9d1,$9d2,$9d3,$9d4,$9d5,$9d6,$9d7,$9d8,$9da,$9db,$9dc,$9dd,$9de,$9df,$9e0,$9e1
.dw $9e2,$9e3,$9e4,$9e6,$9e7,$9e8,$9e9,$9ea,$9eb,$9ed,$9ee,$9ef,$9f0,$9f1,$9f2,$9f3
.dw $9f5,$9f6,$9f7,$9f8,$9f9,$9fa,$9fc,$9fd,$9fe,$9ff,$b00,$b00,$b01,$b02,$b02,$b03
.dw $b03,$b04,$b05,$b05,$b06,$b07,$b07,$b08,$b08,$b09,$b0a,$b0a,$b0b,$b0b,$b0c,$b0d
.dw $b0d,$b0e,$b0e,$b0f,$b10,$b10,$b11,$b12,$b12,$b13,$b14,$b14,$b15,$b16,$b16,$b17
.dw $b17,$b18,$b19,$b19,$b1a,$b1b,$b1b,$b1c,$b1d,$b1d,$b1e,$b1f,$b1f,$b20,$b21,$b21
.dw $b22,$b23,$b23,$b24,$b25,$b25,$b26,$b27,$b27,$b28,$b29,$b29,$b2a,$b2b,$b2c,$b2c
.dw $b2d,$b2e,$b2e,$b2f,$b30,$b30,$b31,$b32,$b32,$b33,$b34,$b35,$b35,$b36,$b37,$b38
.dw $b38,$b39,$b3a,$b3a,$b3b,$b3c,$b3d,$b3d,$b3e,$b3f,$b40,$b40,$b41,$b42,$b42,$b43
.dw $b44,$b45,$b45,$b46,$b47,$b48,$b49,$b49,$b4a,$b4b,$b4c,$b4c,$b4d,$b4e,$b4f,$b4f
.dw $b50,$b51,$b52,$b53,$b53,$b54,$b55,$b56,$b56,$b57,$b58,$b59,$b5a,$b5a,$b5b,$b5c
.dw $b5d,$b5e,$b5f,$b5f,$b60,$b61,$b62,$b63,$b63,$b64,$b65,$b66,$b67,$b68,$b68,$b69
.dw $b6a,$b6b,$b6c,$b6d,$b6d,$b6e,$b6f,$b70,$b71,$b72,$b73,$b73,$b74,$b75,$b76,$b77
.dw $b78,$b79,$b79,$b7a,$b7b,$b7c,$b7d,$b7e,$b7f,$b80,$b80,$b81,$b82,$b83,$b84,$b85
.dw $b86,$b87,$b88,$b89,$b8a,$b8a,$b8b,$b8c,$b8d,$b8e,$b8f,$b90,$b91,$b92,$b93,$b94
.dw $b95,$b95,$b96,$b97,$b98,$b99,$b9a,$b9b,$b9c,$b9d,$b9e,$b9f,$ba0,$ba1,$ba2,$ba3
.dw $ba4,$ba5,$ba6,$ba7,$ba8,$ba9,$baa,$bab,$bac,$bad,$bae,$baf,$bb0,$bb1,$bb2,$bb3
.dw $bb4,$bb5,$bb6,$bb7,$bb8,$bb9,$bba,$bbb,$bbc,$bbd,$bbe,$bbf,$bc0,$bc1,$bc2,$bc3
.dw $bc4,$bc5,$bc6,$bc7,$bc8,$bc9,$bca,$bcb,$bcd,$bce,$bcf,$bd0,$bd1,$bd2,$bd3,$bd4
.dw $bd5,$bd6,$bd7,$bd8,$bda,$bdb,$bdc,$bdd,$bde,$bdf,$be0,$be1,$be2,$be3,$be4,$be6
.dw $be7,$be8,$be9,$bea,$beb,$bed,$bee,$bef,$bf0,$bf1,$bf2,$bf3,$bf5,$bf6,$bf7,$bf8
.dw $bf9,$bfa,$bfc,$bfd,$bfe,$bff,$d00,$d00,$d01,$d02,$d02,$d03,$d03,$d04,$d05,$d05
.dw $d06,$d07,$d07,$d08,$d08,$d09,$d0a,$d0a,$d0b,$d0b,$d0c,$d0d,$d0d,$d0e,$d0e,$d0f
.dw $d10,$d10,$d11,$d12,$d12,$d13,$d14,$d14,$d15,$d16,$d16,$d17,$d17,$d18,$d19,$d19
.dw $d1a,$d1b,$d1b,$d1c,$d1d,$d1d,$d1e,$d1f,$d1f,$d20,$d21,$d21,$d22,$d23,$d23,$d24
.dw $d25,$d25,$d26,$d27,$d27,$d28,$d29,$d29,$d2a,$d2b,$d2c,$d2c,$d2d,$d2e,$d2e,$d2f
.dw $d30,$d30,$d31,$d32,$d32,$d33,$d34,$d35,$d35,$d36,$d37,$d38,$d38,$d39,$d3a,$d3a
.dw $d3b,$d3c,$d3d,$d3d,$d3e,$d3f,$d40,$d40,$d41,$d42,$d42,$d43,$d44,$d45,$d45,$d46
.dw $d47,$d48,$d49,$d49,$d4a,$d4b,$d4c,$d4c,$d4d,$d4e,$d4f,$d4f,$d50,$d51,$d52,$d53
.dw $d53,$d54,$d55,$d56,$d56,$d57,$d58,$d59,$d5a,$d5a,$d5b,$d5c,$d5d,$d5e,$d5f,$d5f
.dw $d60,$d61,$d62,$d63,$d63,$d64,$d65,$d66,$d67,$d68,$d68,$d69,$d6a,$d6b,$d6c,$d6d
.dw $d6d,$d6e,$d6f,$d70,$d71,$d72,$d73,$d73,$d74,$d75,$d76,$d77,$d78,$d79,$d79,$d7a
.dw $d7b,$d7c,$d7d,$d7e,$d7f,$d80,$d80,$d81,$d82,$d83,$d84,$d85,$d86,$d87,$d88,$d89
.dw $d8a,$d8a,$d8b,$d8c,$d8d,$d8e,$d8f,$d90,$d91,$d92,$d93,$d94,$d95,$d95,$d96,$d97
.dw $d98,$d99,$d9a,$d9b,$d9c,$d9d,$d9e,$d9f,$da0,$da1,$da2,$da3,$da4,$da5,$da6,$da7
.dw $da8,$da9,$daa,$dab,$dac,$dad,$dae,$daf,$db0,$db1,$db2,$db3,$db4,$db5,$db6,$db7
.dw $db8,$db9,$dba,$dbb,$dbc,$dbd,$dbe,$dbf,$dc0,$dc1,$dc2,$dc3,$dc4,$dc5,$dc6,$dc7
.dw $dc8,$dc9,$dca,$dcb,$dcd,$dce,$dcf,$dd0,$dd1,$dd2,$dd3,$dd4,$dd5,$dd6,$dd7,$dd8
.dw $dda,$ddb,$ddc,$ddd,$dde,$ddf,$de0,$de1,$de2,$de3,$de4,$de6,$de7,$de8,$de9,$dea
.dw $deb,$ded,$dee,$def,$df0,$df1,$df2,$df3,$df5,$df6,$df7,$df8,$df9,$dfa,$dfc,$dfd
.dw $dfe,$dff,$f00,$f00,$f01,$f02,$f02,$f03,$f03,$f04,$f05,$f05,$f06,$f07,$f07,$f08
.dw $f08,$f09,$f0a,$f0a,$f0b,$f0b,$f0c,$f0d,$f0d,$f0e,$f0e,$f0f,$f10,$f10,$f11,$f12
.dw $f12,$f13,$f14,$f14,$f15,$f16,$f16,$f17,$f17,$f18,$f19,$f19,$f1a,$f1b,$f1b,$f1c
.dw $f1d,$f1d,$f1e,$f1f,$f1f,$f20,$f21,$f21,$f22,$f23,$f23,$f24,$f25,$f25,$f26,$f27
.dw $f27,$f28,$f29,$f29,$f2a,$f2b,$f2c,$f2c,$f2d,$f2e,$f2e,$f2f,$f30,$f30,$f31,$f32
.dw $f32,$f33,$f34,$f35,$f35,$f36,$f37,$f38,$f38,$f39,$f3a,$f3a,$f3b,$f3c,$f3d,$f3d
.dw $f3e,$f3f,$f40,$f40,$f41,$f42,$f42,$f43

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
    ; check if channels should be (un)muted
; TODO
;    ld  a, [buttonsPressed]
;    ld b, a
;    ld a, [soundStatus]
;    bit PADB_UP, b
;    jr z, @upNotPressed
    ; toggle channel 1
;    xor a, 1
;    @upNotPressed:
;    bit PADB_DOWN, b
;    jr z, @downNotPressed
    ; toggle channel 2
;    xor a, 2
;    @downNotPressed:
;    bit PADB_LEFT, b
;    jr z, @leftNotPressed
    ; toggle channel 3
;    xor a, 4
;    @leftNotPressed:
;    bit PADB_RIGHT, b
;    jr z, @rightNotPressed
    ; toggle channel 4
;    xor a, 8
;    @rightNotPressed:
;    ld [soundStatus], a
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
    ld a, [ix + Track.Status]
    or a, a
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
    ld a, [ix + Track.Status]
    or a, a
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
RGB 1, 1, 2
RGB 0, 0, 0
RGB 0, 0, 0
RGB 3, 3, 3
; 1 - flag
RGB 3, 2, 3
RGB 3, 0, 0
RGB 0, 0, 3
RGB 3, 3, 3
; 2 - orb
RGB 3, 2, 3
RGB 3, 2, 0
RGB 2, 1, 1
RGB 1, 0, 0
PaletteDataEnd:

BGTiles:
.incbin "font.bin"  ; $00 - 56 tiles
.incbin "flag.bin"  ; $38 - 2 tiles
.incbin "ball.bin"  ; $3A - 32 tiles
BGTilesEnd:

TilemapData:
.db $3A, $92, 28
.dw CHAR_L, CHAR_i, CHAR_v, CHAR_e, CHAR_SPACE, CHAR_a, CHAR_n, CHAR_d, CHAR_SPACE, CHAR_L, CHAR_e, CHAR_a, CHAR_r, CHAR_n
.db $3B, $4E, 34
.dw CHAR_O, CHAR_r, CHAR_i, CHAR_g, CHAR_i, CHAR_n, CHAR_a, CHAR_l, CHAR_SPACE, CHAR_m, CHAR_u, CHAR_s, CHAR_i, CHAR_c, CHAR_SPACE, CHAR_b, CHAR_y
.db $3B, $D8, 16
.dw CHAR_C, CHAR_r, CHAR_u, CHAR_s, CHAR_h, CHAR_SPACE, CHAR_4, CHAR_0
.db $3C, $52, 20
.dw CHAR_R, CHAR_e, CHAR_m, CHAR_i, CHAR_x, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_i, CHAR_n
.db $3C, $68, 4
.dw $38,$39 ; flag
.db $3D, $14, 24
.dw CHAR_U, CHAR_s, CHAR_e, CHAR_SPACE, CHAR_D, CHAR_MINUS, CHAR_p, CHAR_a, CHAR_d, CHAR_SPACE, CHAR_t, CHAR_o
.db $3D, $50, 30
.dw CHAR_t, CHAR_o, CHAR_g, CHAR_g, CHAR_l, CHAR_e, CHAR_SPACE, CHAR_c, CHAR_h, CHAR_a, CHAR_n, CHAR_n, CHAR_e, CHAR_l, CHAR_s
.db 0
TilemapDataEnd:

.ends
