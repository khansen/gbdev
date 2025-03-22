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
.ENDST

.define NUM_TRACKS 4

.RAMSECTION Ram_c000 align 128
vramBuffer: ds 128

vramBufferOffset: db
processingVBlank: db
pauseRequested: db
shadowVDP1: db
scrollX: db
scrollY: db
buttonsHeld: db
buttonsPressed: db
mainState: db

; --- Begin Sound engine

instrumentTable: dw

patternTable: dw

orderTable: dw

masterVol: db

shadowNoiseGeneratorReg: db
channel1EffectiveVol: db
channel2EffectiveVol: db
channel3EffectiveVol: db
channel4EffectiveVol: db

; bits 4..0: whether channel is muted (1=yes)
; bit 5: paused (1=yes)
soundStatus: db

.align 128

tracks INSTANCEOF Track NUM_TRACKS

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
    ld b, a        ; Store input in B
    in a, ($DD)    ; Read Start button
    cpl            ; Flip bits
    and %10000000  ; Mask out Start button
    or b           ; Combine with other inputs
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
    jp WriteVramStrings

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
    jp nz, @loop
    ret

.ends

; --- End gfx-related procedures ---

; --- Begin sound engine ---

.section "Sound engine code" bank 0 slot 0 free

; HL = pointer to song
StartSong:
    ld b, NUM_TRACKS
    ld de, tracks + Track.Order_Pos
    @loop:
    ld a, [hl] ; order pos
    inc hl
    ld [de], a ; Order_Pos
    cp a, $ff ; channel not in use?
    jr z, @skip
    ld a, [hl] ; speed
    inc hl
    ; slow it down by 8x - useful for debugging
    ; sla a
    ; sla a
    ; sla a
    @skip:
    ld c, a ; speed
    inc e ; Effect_Kind
    xor a, a
    ld [de], a ; Effect_Kind
    dec e ; Order_Pos
    dec e ; Pattern_Ptr (hi)
    dec e ; Pattern_Ptr (lo)
    dec e ; Pattern_RowStatus
    dec e ; Pattern_Row
    xor a, a
    ld [de], a ; Pattern_Row
    dec e ; Pattern_RowCount
    inc a ; 1
    ld [de], a ; Pattern_RowCount
    dec e ; Tick
    ld a, c ; speed
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
    dec b
    jr nz, @loop
    ; Instrument table
    ld a, [hl]
    inc hl
    ld [instrumentTable], a
    ld a, [hl]
    inc hl
    ld [instrumentTable+1], a
    ; Pattern table
    ld a, [hl]
    inc hl
    ld [patternTable], a
    ld a, [hl]
    inc hl
    ld [patternTable+1], a
    ; HL now points to order data
    ld a, l
    ld [orderTable], a
    ld a, h
    ld [orderTable+1], a

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
;    call UpdateSampleData
    ld b, 0 ; track index
    ld hl, tracks; + SIZEOF
    @loop:
    ld a, [hl] ; Speed
    inc l
    cp a, $ff   ; is track used?
    jr nz, @process_track
    ld de, _sizeof_Track
    add hl, de
    jp @next_track
    @process_track:
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
    inc l
    ld a, [hl] ; Pattern_RowCount
    inc l
    inc [hl]    ; Pattern_Row
    cp a, [hl]  ; rowCount == row?
    jr z, @end_of_pattern
    jr @no_new_pattern
    @end_of_pattern:
    push hl ; Pattern_Row
    xor a, a
    ld [hl], a ; Pattern_Row = 0
    inc l
    inc l ; Pattern_Ptr (lo)
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
    @pre_order_loop:
    ld c, [hl] ; Order_Pos
    ld a, [orderTable]
    add a, c
    ld e, a
    ld a, [orderTable+1]
    adc a, 0
    ld d, a
    @order_fetch_loop:
    ld a, [de] ; order byte
    inc de
    inc [hl] ; Order_Pos
    cp a, $f0 ; $f0 > a?
    jr nc, @order_special
    ; pattern number
    add a, a ; pattern number * 2
    ld c, a
    ld a, [patternTable+1]
    adc a, 0
    ld d, a
    ld a, [patternTable]
    add a, c
    ld e, a
    jr nc, @skip_inc_d
    inc d
    @skip_inc_d:
    ld a, [de]
    dec l ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ld [hl], a ; Pattern_Ptr (lo)
    inc l
    inc de
    ld c, a
    ld a, [de]
    ld [hl], a ; Pattern_Ptr (hi)
    dec l
    ld e, c
    ld d, a
    ld a, [de] ; row count
    inc de
    call IncPatternPtr
    pop hl ; Pattern_Row
    dec l ; Pattern_RowCount
    ld [hl], a ; Pattern_RowCount
    inc l
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
    inc l
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
    inc l
    inc l ; Pattern_Ptr (lo)
    and a, 7
    jr z, @pattern_fetch_loop
    ; for rows not multiple of 8, DE does not yet contain pattern data ptr because we didn't fetch row status byte
    ld e, [hl] ; Pattern_Ptr (lo)
    inc l
    ld d, [hl] ; Pattern_Ptr (hi)
    dec l
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
    jr @mixer_tick
    @is_note:
    push hl ; Pattern_Ptr (lo)
    ld c, a ; save note
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
    inc l ; Effect_Kind
    ld d, [hl] ; Effect_Kind
    inc l
    inc l ; skip Effect_Param
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
    inc l
    inc l ; PeriodLo
    inc l ; PeriodHi
    inc l ; Square_DutyCtrl
    inc l ; Envelope_Phase
    ld a, ENV_RESET
    ld [hl], a ; Envelope_Phase
    dec l
    ld a, d ; effect kind
    cp a, PORTAMENTO_EFFECT
    jr z, @init_slide
    ; no slide, set new period immediately
    push hl ; Square_DutyCtrl
    ld hl, PeriodTable
    ld a, c
    add a, a ; note * 2
    ld e, a
    ld d, 0
    add hl, de
    ld d, [hl] ; period lo
    inc l
    ld a, [hl] ; period hi
    pop hl ; Square_DutyCtrl
    dec l ; PeriodHi
    ld [hl], a ; PeriodHi
    dec l
    ld [hl], d ; PeriodLo
    dec l
    ld a, c
    or a, $80 ; trigger channel
    ld [hl], a ; PeriodIndex
    inc l
    inc l ; PeriodHi
    inc l ; Square_DutyCtrl
    ld a, [hl] ; Square_DutyCtrl
    and a, $0c ; initial counter
    srl a
    srl a
    ld c, a
    ld a, [hl] ; Square_DutyCtrl
    and a, $fc
    or a, c ; copy initial counter to current counter
    ld [hl], a ; Square_DutyCtrl
    pop hl ; Pattern_Ptr (lo)
    dec l ; Pattern_RowStatus
    jp @mixer_tick
    @init_slide:
    dec l ; PeriodHi
    dec l ; PeriodLo
    dec l ; PeriodIndex
    ld a, [hl] ; PeriodIndex
    cp a, c ; CF = slide direction (0=down,1=up)
    ld a, c
    ld [hl], a ; PeriodIndex
    ld c, $40
    rl c ; bit 7 = 1 (active), bit 0 = direction
    push hl ; PeriodIndex
    ld hl, PeriodTable
    add a, a ; note * 2
    ld e, a
    ld d, 0
    add hl, de
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
    ld [hl], c ; Effect_Portamento_Ctrl
    pop hl ; Pattern_Ptr (lo)
    dec l ; Pattern_RowStatus
    @mixer_tick:
    ; hl points to Pattern_RowStatus
    ; update effect
    ld de, Track.Effect_Kind - Track.Pattern_RowStatus
    add hl, de
    ld a, [hl] ; Effect_Kind
    inc l
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
    cp a, NUM_TRACKS
    jp nz, @loop

    ; write to audio hw regs
    call RenderChannel1
    call RenderChannel2
    call RenderChannel3
    jp RenderChannel4

; HL = Pattern_Ptr (lo)
IncPatternPtr:
    inc [hl] ; Pattern_Ptr (lo)
    ret nz
    inc l ; Pattern_Ptr (hi)
    inc [hl] ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ret

RenderChannel1:
    ld hl, tracks + Track.PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $9f ; tone 1 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld a, [soundStatus]
    bit 0, a
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
    ld [channel1EffectiveVol], a
    ld e, a
    ld hl, ToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $90 ; tone 1 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo
    ld a, [hl] ; PeriodLo
    and a, $0f
    or a, $80 ; tone generator 1
    out ($7f), a ; write lower 4 bits of period

    ld a, [hl] ; PeriodLo
    inc l
    srl a
    srl a
    srl a
    srl a
    ld b, a
    ld a, [hl] ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, b
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderChannel3:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track*2
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $df ; tone 3 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld a, [soundStatus]
    bit 2, a
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
    ld [channel3EffectiveVol], a
    ld e, a
    ld hl, ToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $d0 ; tone 3 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo + _sizeof_Track*2
    ld a, [hl] ; PeriodLo
    and a, $0f
    or a, $c0 ; tone generator 3
    out ($7f), a ; write lower 4 bits of period

    ld a, [hl] ; PeriodLo
    inc l
    srl a
    srl a
    srl a
    srl a
    ld b, a
    ld a, [hl] ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, b
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderChannel2:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $bf ; tone 2 attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld a, [soundStatus]
    bit 1, a
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
    ld [channel2EffectiveVol], a
    ld e, a
    ld hl, ToneAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $b0 ; tone 2 attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodLo + _sizeof_Track
    ld a, [hl] ; PeriodLo
    and a, $0f
    or a, $a0 ; tone generator 2
    out ($7f), a ; write lower 4 bits of period

    ld a, [hl] ; PeriodLo
    inc l
    srl a
    srl a
    srl a
    srl a
    ld b, a
    ld a, [hl] ; PeriodHi
    sla a
    sla a
    sla a
    sla a
    or a, b
    and a, $3f
    out ($7f), a ; write upper 6 bits of period
    ret

RenderChannel4:
    ld hl, tracks + Track.PeriodIndex + _sizeof_Track*3
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    res 7, [hl] ; PeriodIndex - reset trigger flag
    ld a, $ff ; noise attenuation
    out ($7f), a ; mute
    @no_trigger:
    ld a, [soundStatus]
    bit 3, a
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
    ld [channel4EffectiveVol], a
    ld e, a
    ld hl, NoiseAttenuationTable
    add hl, de
    ld a, [hl] ; map volume to attenuation
    or a, $f0 ; noise attenuation
    out ($7f), a ; write volume

    ld hl, tracks + Track.PeriodHi + _sizeof_Track*3
    ld a, [hl] ; PeriodHi (0..3)
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
; preserves DE and HL
SetInstrument:
    push de
    push hl ; Pattern_Ptr (lo)
    sla a
    sla a
    sla a ; each instrument is 8 bytes long
    ld c, a
    ld a, [instrumentTable]
    add a, c
    ld e, a
    ld a, [instrumentTable+1]
    adc a, 0
    ld d, a
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
; preserves DE and HL
SetSpeed:
    push de
    push hl
    ld hl, tracks + Track.Speed
    ld de, _sizeof_Track
    ld [hl], a ; Speed
    .rept NUM_TRACKS - 1
    add hl, de
    ld [hl], a ; Speed
    .endr
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
; slide up by subtracting slide amount from period value
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

    .slide_down_tick:
; slide down by adding slide amount to period value
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
    cp a, 3
    jr z, @clamp_slide_down
    inc [hl] ; PeriodHi
    @slide_skip_inc:
    pop hl ; Effect_Param
    ret
    @clamp_slide_down:
    dec l ; PeriodLo
    ld a, $ff
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
    ; slide down (subtract delta from current period value)
    sub a, c
    ld [hl], a ; PeriodLo
    inc l
    ld a, [hl] ; PeriodHi
    sbc a, 0
    ld [hl], a ; PeriodHi
    dec l
    jr c, .portamento_done
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
    .portamento_down:
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

    .vibrato_tick:
    pop hl ; Effect_Param
    push hl
    ; reset period value
    ld a, l
    add a, Track.PeriodIndex - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodIndex
    inc l
    add a, a ; note * 2
    add a, <PeriodTable
    ld e, a
    ld d, >PeriodTable
    ld a, [de]
    ld [hl], a ; PeriodLo
    inc l
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
    inc l
    add a, a ; note * 2
    add a, <PeriodTable
    ld e, a
    ld d, >PeriodTable
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
    inc l
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
    inc l
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
    dec l
    dec l ; Envelope_Vol
    ld [hl], a ; Envelope_Vol = dest
    inc l
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

VolumeTable:
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

; ProTracker sine table
VibratoTable:
.db $00,$18,$31,$4A,$61,$78,$8D,$A1
.db $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
.db $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
.db $B4,$A1,$8D,$78,$61,$4A,$31,$18

PeriodTable:
.dw                                              $3f8,$3bf,$389
.dw $357,$327,$2f9,$2cf,$2a6,$280,$25c,$23a,$21a,$1fc,$1df,$1c4
.dw $1ab,$193,$17c,$167,$153,$140,$12e,$11d,$10d,$0fe,$0ef,$0e2
.dw $0d5,$0c9,$0be,$0b3,$0a9,$0a0,$097,$08e,$086,$07f,$077,$071
.dw $06a,$064,$05f,$059,$054,$050,$04b,$047,$043,$03f,$03b,$038
.dw $035,$032,$02f,$02c,$02a,$028,$025,$023,$021,$01f,$01d,$01c

ToneAttenuationTable:
.db $0f,$09,$08,$07,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00
NoiseAttenuationTable:
.db $0f,$07,$06,$05,$04,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00

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
    jp @InfiniteLoop

.macro RGB
.dw (\3 << 8) | (\2 << 4) | \1
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


MainFunc0:
    call DrawChannelIndicators
    ; check if channels should be (un)muted
    ld  a, [buttonsPressed]
    ld b, a
    ld a, [soundStatus]
    bit PADB_UP, b
    jr z, @upNotPressed
    ; toggle channel 1
    xor a, 1
    @upNotPressed:
    bit PADB_DOWN, b
    jr z, @downNotPressed
    ; toggle channel 2
    xor a, 2
    @downNotPressed:
    bit PADB_LEFT, b
    jr z, @leftNotPressed
    ; toggle channel 3
    xor a, 4
    @leftNotPressed:
    bit PADB_RIGHT, b
    jr z, @rightNotPressed
    ; toggle channel 4
    xor a, 8
    @rightNotPressed:
    ld [soundStatus], a
    ret

DrawChannelIndicators:
    ; upper half
    ld de, $3916
    ld c, 11*2 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ld a, [soundStatus]
    bit 0, a
    jr z, @channel1_not_muted_top
    ld a, 0
    jr @draw_channel1_top
    @channel1_not_muted_top:
    ld a, [channel1EffectiveVol]
    and a, $0e
    @draw_channel1_top:
    or a, a
    jr z, @draw_channel1_blank_top
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
    jr @draw_channel1_channel2_separator_top
    @draw_channel1_blank_top:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel1_channel2_separator_top:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 2
    ld a, [soundStatus]
    bit 1, a
    jr z, @channel2_not_muted_top
    ld a, 0
    jr @draw_channel2_top
    @channel2_not_muted_top:
    ld a, [channel2EffectiveVol]
    and a, $0e
    @draw_channel2_top:
    or a, a
    jr z, @draw_channel2_blank_top
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
    jr @draw_channel2_channel3_separator_top
    @draw_channel2_blank_top:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel2_channel3_separator_top:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 3
    ld a, [soundStatus]
    bit 2, a
    jr z, @channel3_not_muted_top
    ld a, 0
    jr @draw_channel3_top
    @channel3_not_muted_top:
    ld a, [channel3EffectiveVol]
    and a, $0e
    @draw_channel3_top:
    or a, a
    jr z, @draw_channel3_blank_top
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
    jr @draw_channel3_channel4_separator_top
    @draw_channel3_blank_top:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel3_channel4_separator_top:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 4
    ld a, [soundStatus]
    bit 3, a
    jr z, @channel4_not_muted_top
    ld a, 0
    jr @draw_channel4_top
    @channel4_not_muted_top:
    ld a, [channel4EffectiveVol]
    and a, $0e
    @draw_channel4_top:
    or a, a
    jr z, @draw_channel4_blank_top
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
    jr @top_half_done
    @draw_channel4_blank_top:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @top_half_done:
    call EndVramString

    ; lower half
    ld de, $3956
    ld c, 11*2 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ld a, [soundStatus]
    bit 0, a
    jr z, @channel1_not_muted_bottom
    ld a, 0
    jr @draw_channel1_bottom
    @channel1_not_muted_bottom:
    ld a, [channel1EffectiveVol]
    and a, $0e
    @draw_channel1_bottom:
    or a, a
    jr z, @draw_channel1_blank_bottom
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
    jr @draw_channel1_channel2_separator_bottom
    @draw_channel1_blank_bottom:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel1_channel2_separator_bottom:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 2
    ld a, [soundStatus]
    bit 1, a
    jr z, @channel2_not_muted_bottom
    ld a, 0
    jr @draw_channel2_bottom
    @channel2_not_muted_bottom:
    ld a, [channel2EffectiveVol]
    and a, $0e
    @draw_channel2_bottom:
    or a, a
    jr z, @draw_channel2_blank_bottom
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
    jr @draw_channel2_channel3_separator_bottom
    @draw_channel2_blank_bottom:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel2_channel3_separator_bottom:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 3
    ld a, [soundStatus]
    bit 2, a
    jr z, @channel3_not_muted_bottom
    ld a, 0
    jr @draw_channel3_bottom
    @channel3_not_muted_bottom:
    ld a, [channel3EffectiveVol]
    and a, $0e
    @draw_channel3_bottom:
    or a, a
    jr z, @draw_channel3_blank_bottom
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
    jr @draw_channel3_channel4_separator_bottom
    @draw_channel3_blank_bottom:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @draw_channel3_channel4_separator_bottom:
    ; space
    ld a, 0
    ld [hl], a
    inc l
    ld [hl], a
    inc l

    ; channel 4
    ld a, [soundStatus]
    bit 3, a
    jr z, @channel4_not_muted_bottom
    ld a, 0
    jr @draw_channel4_bottom
    @channel4_not_muted_bottom:
    ld a, [channel4EffectiveVol]
    and a, $0e
    @draw_channel4_bottom:
    or a, a
    jr z, @draw_channel4_blank_bottom
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
    jr @bottom_half_done
    @draw_channel4_blank_bottom:
    ; space
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    ld [hl], a
    inc l
    @bottom_half_done:
    jp EndVramString

.ends

.section "Main program read-only data" bank 0 slot 0 free

PaletteData:
; 0 - background and text
RGB 3, 2, 8
RGB 0, 0, 0
RGB 0, 0, 0
RGB 15, 15, 15
; 1 - flag
RGB 3, 2, 8
RGB 15, 0, 0
RGB 0, 0, 15
RGB 15, 15, 15
; 2 - orb
RGB 3, 2, 8
RGB 15, 12, 0
RGB 12, 6, 1
RGB 2, 1, 3
PaletteDataEnd:

BGTiles:
.incbin "font.bin"  ; $00 - 56 tiles
.incbin "flag.bin"  ; $38 - 2 tiles
.incbin "ball.bin"  ; $3A - 32 tiles
BGTilesEnd:

TilemapData:
.db $39, $D2, 28
.dw CHAR_L, CHAR_i, CHAR_v, CHAR_e, CHAR_SPACE, CHAR_a, CHAR_n, CHAR_d, CHAR_SPACE, CHAR_L, CHAR_e, CHAR_a, CHAR_r, CHAR_n
.db $3A, $4E, 34
.dw CHAR_O, CHAR_r, CHAR_i, CHAR_g, CHAR_i, CHAR_n, CHAR_a, CHAR_l, CHAR_SPACE, CHAR_m, CHAR_u, CHAR_s, CHAR_i, CHAR_c, CHAR_SPACE, CHAR_b, CHAR_y
.db $3A, $98, 16
.dw CHAR_C, CHAR_r, CHAR_u, CHAR_s, CHAR_h, CHAR_SPACE, CHAR_4, CHAR_0
.db $3B, $12, 20
.dw CHAR_R, CHAR_e, CHAR_m, CHAR_i, CHAR_x, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_i, CHAR_n
.db $3B, $28, 4
.dw $38,$39 ; flag
.db $3B, $90, 30
.dw CHAR_a, CHAR_s, CHAR_SPACE, CHAR_r, CHAR_e, CHAR_q, CHAR_u, CHAR_e, CHAR_s, CHAR_t, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_b, CHAR_y
.db $3C, $14, 22
.dw CHAR_@, CHAR_E, CHAR_l, CHAR_F, CHAR_a, CHAR_s, CHAR_t, CHAR_a, CHAR_s, CHAR_X, CHAR_D
.db $3C, $94, 24
.dw CHAR_U, CHAR_s, CHAR_e, CHAR_SPACE, CHAR_D, CHAR_MINUS, CHAR_p, CHAR_a, CHAR_d, CHAR_SPACE, CHAR_t, CHAR_o
.db $3C, $D0, 30
.dw CHAR_t, CHAR_o, CHAR_g, CHAR_g, CHAR_l, CHAR_e, CHAR_SPACE, CHAR_c, CHAR_h, CHAR_a, CHAR_n, CHAR_n, CHAR_e, CHAR_l, CHAR_s
.db 0
TilemapDataEnd:

.ends
