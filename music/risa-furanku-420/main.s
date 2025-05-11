.INCLUDE "hardware.inc"

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
.define CHAR_UNDERSCORE $19
.define CHAR_SLASH $1A
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
.define CHAR_u_HAT $31
.define CHAR_x $32
.define CHAR_y $33
.define CHAR_4 $34
.define CHAR_2 $35
.define CHAR_0 $36
.define CHAR_@ $37

.MEMORYMAP
    DEFAULTSLOT 0
    SLOT 0 START $0000 SIZE $4000  ; Fixed ROM Bank 0
    SLOT 1 START $4000 SIZE $4000  ; Switchable ROM Banks (MBC)
    SLOT 2 START $8000 SIZE $2000  ; Video RAM (VRAM)
    SLOT 3 START $A000 SIZE $2000  ; Switchable RAM Banks (Cartridge SRAM)
    SLOT 4 START $C000 SIZE $1000  ; Work RAM (WRAM Bank 0)
    SLOT 5 START $D000 SIZE $1000  ; Switchable WRAM Banks (CGB only)
    SLOT 6 START $E000 SIZE $1E00  ; ECHO RAM (DO NOT USE)
    SLOT 7 START $FE00 SIZE $00A0  ; Object Attribute Memory (OAM)
    SLOT 8 START $FF00 SIZE $0080  ; I/O Registers
    SLOT 9 START $FF80 SIZE $007F  ; High RAM (HRAM)
    SLOT 10 START $FFFF SIZE $0001 ; Interrupt Enable Register
.ENDME

.banksize $4000
.rombanks 2
;.nintendologo
.computegbcomplementcheck
.computegbchecksum

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

.RAMSECTION Hram0_ff80

hOamDmaFunction: ds $0a

hOamOffset: db

hButtonsHeld: db

hButtonsPressed: db

hProcessingVBlank: db

hMainState: db

hVramBufferOffset: db

hScrollX: db

hScrollY: db

hFrameCounter: db

hRandom: db

hTextScrollerScrollX: db
hTextScrollerStringOffset: db

hBustPosXFrac: db
hBustPosXInt: db
hBustPosYFrac: db
hBustPosYInt: db
hBustSpeedXFrac: db
hBustSpeedXInt: db
hBustSpeedYFrac: db
hBustSpeedYInt: db
hBustAccelXFrac: db
hBustAccelXInt: db
hBustAccelYFrac: db
hBustAccelYInt: db

; --- Begin Sound engine

hInstrumentTable: dw

hPatternTable: dw

hOrder: dw

hMasterVol: db

hShadowNR12: db
hShadowNR22: db
hShadowNR32: db
hShadowNR42: db

; bits 4..0: whether channel is muted (1=yes)
; bit 5: paused (1=yes)
hSoundStatus: db

; --- End Sound engine

.ENDS

.RAMSECTION Wram0_c000

wOam:
    ds OAM_COUNT*4

wVramBuffer:
    ds 128

; --- Begin Sound engine

wTracks INSTANCEOF Track NUM_TRACKS

; --- End Sound engine

.ENDS

.bank 0 slot 0

.org $0
.orga $0

; --- Begin courtesy of https://github.com/vinheim3/tetris-gb-disasm/ ---

RST_00:
	jp   Begin2

@Padding:
    .ds ($08 - @Padding) $00

RST_08:
	jp   Begin2

@Padding
    .ds ($28 - @Padding) $ff

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

@Padding:
    .ds ($40 - @Padding) $ff

VBlankInterrupt:
	jp   VBlankInterruptHandler

@Padding:
    .ds ($48 - @Padding) $ff

LCDCInterrupt:
	jp   LCDCInterruptHandler

@Padding:
    .ds ($50 - @Padding) $ff

TimerOverflowInterrupt:
	jp   StubInterruptHandler

@Padding:
    .ds ($58 - @Padding) $ff

SerialTransferCompleteInterrupt:
	jp   StubInterruptHandler

@Padding:
    .ds ($100 - @Padding) $ff

; SECTION "Header", ROM0[$100]

Boot:
	nop
	jp   Begin

NintendoLogo:
NINTENDO_LOGO

HeaderTitle:
    .db   "SNOWBRO 017", $00, $00, $00, $00

HeaderCGBFlag:
    .db   $80

HeaderNewLicenseeCode:
    .db   $00, $00

HeaderSGBFlag:
    .db   $00

HeaderCartridgeType:
    .db   $00

HeaderROMSize:
    .db   $00

HeaderRAMSize:
    .db   $00

HeaderDestinationCode:
    .db   $00

HeaderOldLicenseeCode:
    .db   $00

HeaderMaskROMVersion:
    .db   $01

HeaderChecksum:
    .db   $00

HeaderGlobalChecksum:
    .dw   $0000

; SECTION "Begin", ROM0[$150]

Begin:
	jp   Begin2

StubInterruptHandler:
	reti

VBlankInterruptHandler:
; preserve regs
	push af
	push bc
	push de
	push hl

    ldh a, [<hFrameCounter]
    inc a
    ldh [<hFrameCounter], a

    ldh a,[<hProcessingVBlank]
    or a
    jr nz, .skipVBlankProcessing
    inc a
    ldh [<hProcessingVBlank], a

    call FlushVramBuffer
    call hOamDmaFunction
    ldh a, [<hScrollX]
    ldh [<rSCX], a
    ldh a, [<hScrollY]
    ldh [<rSCY], a
    call PollInput
    call UpdateSound
    call GoMainFunction

    ld hl, hProcessingVBlank
    dec [hl]

    .skipVBlankProcessing:
; restore regs
	pop  hl
	pop  de
	pop  bc
	pop  af
	reti

LCDCInterruptHandler:
; preserve regs
    push af

    ldh a, [<hTextScrollerScrollX]
    ldh [<rSCX], a

; restore regs
    pop  af
    reti

OamDmaFunction:
	ld   a, >wOam
	ldh  [<rDMA], a
	ld   a, OAM_COUNT
.wait:
	dec  a
	jr   nz, .wait
	ret

PollInput:
	ld   a, $20
	ldh  [<rP1], a
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	cpl
	and  $0f
	swap a
	ld   b, a
	ld   a, $10
	ldh  [<rP1], a
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	ldh  a, [<rP1]
	cpl
	and  $0f
	or   b
	ld   b, a
	ldh  a, [<hButtonsHeld]
	xor  b
	and  b
	ldh  [<hButtonsPressed], a
	ld   a, b
	ldh  [<hButtonsHeld], a
	ld   a, $30
	ldh  [<rP1], a
	ret

Begin2:
	xor  a
	ld   hl, $dfff

; clear $d000-$dfff
	ld   c, $10
	ld   b, $00

.clear2ndWram:
	ld   [hl-], a
	dec  b
	jr   nz, .clear2ndWram

	dec  c
	jr   nz, .clear2ndWram

Reset:
; allow vblank and not serial
	ld   a, IEF_VBLANK
	di
	ldh  [<rIF], a
	ldh  [<rIE], a

; clear hw regs
	xor  a
	ldh  [<rSCY], a
	ldh  [<rSCX], a
	ldh  [<rSTAT], a
	ldh  [<rSB], a
	ldh  [<rSC], a
	ldh  [<rNR52], a

; turn on LCD, and wait until in vblank area (specifically line $94)
	ld   a, LCDCF_ON
	ldh  [<rLCDC], a

.waitUntilVBlank:
	ldh  a, [<rLY]
	cp   $94
	jr   nz, .waitUntilVBlank

; turn off lcd again
	ld   a, LCDCF_OFF|LCDCF_OBJON|LCDCF_BGON
	ldh  [<rLCDC], a

; standard palettes
	ld   a, %00011011
	ldh  [<rBGP], a
	ldh  [<rOBP0], a
	ldh  [<rOBP1], a

; all sound on
	ld   a, $80
	ldh  [<rAUDENA], a

; channels outputted to all sound S01 and S02
	ld   a, %11111111
	ldh  [<rAUDTERM], a

; vol max without setting vin
    ld   a, $77
    ldh  [<rAUDVOL], a

; set rom bank for some reason, and set SP
	ld   a, $01
	ld   [rROMB0], a
	ld   sp, $d000

; clear last page of wram
	xor  a
	ld   hl, $dfff
	ld   b, $00

.clearLastPage:
	ld   [hl-], a
	dec  b
	jr   nz, .clearLastPage

; clear 1st bank of wram
	ld   hl, $cfff
	ld   c, $10
	ld   b, $00

.clear1stWram:
	ld   [hl-], a
	dec  b
	jr   nz, .clear1stWram

	dec  c
	jr   nz, .clear1stWram

; clear all vram bank 1
	ld   hl, $9fff
	ld   c, $20
	ld   a, 1
    ldh [<rVBK], a ; select bank 1
    dec  a
	ld   b, $00

.clearVramBank1:
	ld   [hl-], a
	dec  b
	jr   nz, .clearVramBank1

	dec  c
	jr   nz, .clearVramBank1

; clear all vram bank 0
	ld   hl, $9fff
	ld   c, $20
	xor  a
    ldh [<rVBK], a ; select bank 0
	ld   b, $00

.clearVramBank0:
	ld   [hl-], a
	dec  b
	jr   nz, .clearVramBank0

	dec  c
	jr   nz, .clearVramBank0

; clear oam, and some unusable space
	ld   hl, $feff
	ld   b, $00

.clearOam:
	ld   [hl-], a
	dec  b
	jr   nz, .clearOam

; clear all hram
	ld   hl, $fffe
	ld   b, $7f

.clearHram:
	ld   [hl-], a
	dec  b
	jr   nz, .clearHram

; copy OAM DMA function, plus 2 extra bytes
	ld   c, <hOamDmaFunction
;	ld   b, hOamDmaFunction.end-hOamDmaFunction+2
    ld   b, hOamOffset-hOamDmaFunction+2
	ld   hl, OamDmaFunction

.copyOamDmaFunc:
	ld   a, [hl+]
	ldh  [c], a
	inc  c
	dec  b
	jr   nz, .copyOamDmaFunc

; configure STAT interrupt
    ld a, 128
    ldh [<rLYC], a
    ld a, STATF_LYC
    ldh [<rSTAT], a

; clear some hw regs
	ei
	xor  a
	ldh  [<rIF], a
	ldh  [<rWY], a
	ldh  [<rWX], a
	ldh  [<rTMA], a
        jp Genesis

CopyFromHLIntoWav3Ram:
	push bc
	ld   c, <_AUD3WAVERAM
@loop:
	ld   a, [hl+]
	ldh  [c], a
	inc  c
	ld   a, c
	cp   <_AUD3WAVERAM + 16
	jr   nz, @loop
	pop  bc
	ret

; === End courtesy of https://github.com/vinheim3/tetris-gb-disasm/ ===

; --- Begin gfx-related procedures ---

FlushVramBuffer:
    ldh a, [<hVramBufferOffset]
    or a, a
    ret z
    xor a
    ldh [<hVramBufferOffset], a
    ldh [<rVBK], a ; select bank 0
    ld hl, wVramBuffer
    jp WriteVramStrings

WriteVramStrings:
    ; hl = address of data
    ld a, [hli]
    or a, a
    ret z
    ld d, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld b, a
    @loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, @loop
    jr WriteVramStrings

; DE = start address
; C = count
; returns HL = vram buffer pointer
BeginVramString:
    ld hl, wVramBuffer
    ldh a, [<hVramBufferOffset]
    push bc
    ld b, 0
    ld c, a
    add hl, bc
    ld a, d
    ld [hli], a ; high address
    ld a, e
    ld [hli], a ; low address
    pop bc
    ld a, c
    ld [hli], a ; count
    ret

EndVramString:
    xor a
    ld [hl], a
    ld a, l
    sub a, <wVramBuffer
    ldh [<hVramBufferOffset], a
    ret

HideAllSprites:
    ld hl, wOam
    xor a
    ldh [<hOamOffset], a
    ld b, OAM_COUNT
    @loop:
    ld [hli], a
    inc l
    inc l
    inc l
    dec b
    jr nz, @loop
    ret

; Out: hl=address of sprite
BeginDrawSprites:
    ld hl, wOam
    ldh a, [<hOamOffset]
    ld b, 0
    ld c, a
    add hl, bc
    ret

EndDrawSprites:
    ld a, l
    sub a, <wOam
    ldh [<hOamOffset], a
    ret

; --- End gfx-related procedures ---

; --- Begin sound engine ---

; HL = pointer to song
StartSong:
    ld b, NUM_TRACKS
    ld de, wTracks + Track.Order_Pos
    @loop:
    ld a, [hli] ; order pos
    ld [de], a ; Order_Pos
    cp a, $ff ; channel not in use?
    jr z, @skip
    ld a, [hli] ; speed
    ; slow it down by 8x - useful for debugging
    ; sla a
    ; sla a
    ; sla a
    @skip:
    ld c, a
    inc de ; Effect_Kind
    xor a, a
    ld [de], a ; Effect_Kind
    dec de ; Order_Pos
    dec de ; Pattern_Ptr (hi)
    dec de ; Pattern_Ptr (lo)
    dec de ; Pattern_RowStatus
    dec de ; Pattern_Row
    xor a, a
    ld [de], a ; Pattern_Row
    dec de ; Pattern_RowCount
    inc a ; 1
    ld [de], a ; Pattern_RowCount
    dec de ; Tick
    ld a, c ; speed
    dec a
    ld [de], a ; Tick
    dec de ; Speed
    inc a
    ld [de], a ; Speed
    ld a, e
    add a, Track.MasterVol - Track.Speed
    ld e, a
    ld a, $f0
    ld [de], a ; MasterVol
    inc de
    xor a, a
    ld [de], a ; PeriodIndex
    inc de
    ld [de], a ; PeriodLo
    inc de
    ld [de], a ; PeriodHi
    inc de ; Square_DutyCtrl
    inc de ; Envelope_Phase
    ld [de], a ; Envelope_Phase
    ld a, e
    add a, _sizeof_Track - Track.Envelope_Phase + Track.Order_Pos
    ld e, a
    dec b
    jr nz, @loop
    ; Instrument table
    ld a, [hli]
    ldh [<hInstrumentTable], a
    ld a, [hli]
    ldh [<hInstrumentTable+1], a
    ; Pattern table
    ld a, [hli]
    ldh [<hPatternTable], a
    ld a, [hli]
    ldh [<hPatternTable+1], a
    ; HL now points to order data
    ld a, l
    ldh [<hOrder], a
    ld a, h
    ldh [<hOrder+1], a

    ld a, $f0
    ldh [<hMasterVol], a
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
    ld hl, wTracks; + SIZEOF
    @loop:
    ld a, [hli] ; Speed
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
    ld [hli], a ; Tick
    ld a, [hli] ; Pattern_RowCount
    inc [hl]    ; Pattern_Row
    cp a, [hl]  ; rowCount == row?
    jr z, @end_of_pattern
    jr @no_new_pattern
    @end_of_pattern:
    push hl ; Pattern_Row
    xor a, a
    ld [hli], a ; Pattern_Row = 0
    inc l ; Pattern_Ptr (lo)
    inc l ; Pattern_Ptr (hi)
    inc l ; Order_Pos
    @pre_order_loop:
    ld a, [hl] ; Order_Pos
    ld c, a
    ldh a, [<hOrder]
    add a, c
    ld e, a
    ldh a, [<hOrder+1]
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
    ldh a, [<hPatternTable+1]
    adc a, 0
    ld d, a
    ldh a, [<hPatternTable]
    add a, c
    ld e, a
    jr nc, @skip_inc_d
    inc d
    @skip_inc_d:
    ld a, [de]
    dec l ; Pattern_Ptr (hi)
    dec l ; Pattern_Ptr (lo)
    ld [hli], a ; Pattern_Ptr (lo)
    inc de
    ld c, a
    ld a, [de]
    ld [hl-], a ; Pattern_Ptr (hi)
    ld e, c
    ld d, a
    ld a, [de] ; row count
    inc de
    call IncPatternPtr
    pop hl ; Pattern_Row
    dec l ; Pattern_RowCount
    ld [hli], a ; Pattern_RowCount
    inc l ; Pattern_RowStatus
    jr @fetch_row_status
    @order_special:
    ; TODO: implement order commands. Assume $fe for now
    ld a, [de] ; order byte
    ld [hl], a ; Order_Pos
    jr @pre_order_loop
    @no_new_pattern:
    ld a, [hli] ; Pattern_Row
    and a, 7
    jr nz, @check_row_status
    ; prepare to fetch row status
    inc l ; Pattern_Ptr (lo)
    ld a, [hli] ; Pattern_Ptr (lo)
    ld e, a
    ld a, [hl-] ; Pattern_Ptr (hi)
    ld d, a
    dec l ; Pattern_RowStatus
    @fetch_row_status:
    ; HL = Pattern_RowStatus
    ; DE = pattern data ptr
    ; fetch row status for upcoming 8 rows
    ld a, [de] ; pattern byte
    inc de
    ld [hli], a ; Pattern_RowStatus
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
    ld a, [hli] ; Pattern_Row
    inc l ; Pattern_Ptr (lo)
    and a, 7
    jr z, @pattern_fetch_loop
    ; for rows not multiple of 8, DE does not yet contain pattern data ptr because we didn't fetch row status byte
    ld a, [hli] ; Pattern_Ptr (lo)
    ld e, a
    ld a, [hl-] ; Pattern_Ptr (hi)
    ld d, a
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
    ld [hli], a ; Effect_Kind
    or a, a
    jr z, @skip_effect_init
    ld a, [de] ; pattern byte: effect param
    inc de
    ld [hl], a ; Effect_Param
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
    and a, $f
    swap a ; new volume in upper 4 bits
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
    ld a, [hli] ; Effect_Kind
    ld d, a
    inc l ; skip Effect_Param
    ; clear effect state
    xor a, a
    ld [hli], a ; Effect_Pos
    ld [hli], a ; Effect_Portamento_TargetPeriodLo
    ld [hli], a ; Effect_Portamento_TargetPeriodHi
    ld a, [hl] ; MasterVol
    srl a
    jr c, @skip ; CF=1 if the volume has been overridden by a previous volume command
    ld a, $78
    @skip:
    sla a
    ld [hli], a ; MasterVol
    inc l ; PeriodLo
    inc l ; PeriodHi
    inc l ; Square_DutyCtrl
    inc l ; Envelope_Phase
    ld a, ENV_RESET
    ld [hl-], a ; Envelope_Phase
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
    ld a, [hli] ; period lo
    ld d, a
    ld a, [hl] ; period hi
    pop hl ; Square_DutyCtrl
    dec l ; PeriodHi
    ld [hl-], a ; PeriodHi
    ld a, d
    ld [hl-], a ; PeriodLo
    ld a, c
    or a, $80 ; trigger channel
    ld [hli], a ; PeriodIndex
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
    ld a, [hli] ; period lo
    ld d, a
    ld a, [hl] ; period hi
    pop hl ; PeriodIndex
    dec l ; MasterVol
    dec l ; Effect_Portamento_TargetPeriodHi
    ld [hl-], a ; Effect_Portamento_TargetPeriodHi
    ld a, d
    ld [hl-], a ; Effect_Portamento_TargetPeriodLo
    ld a, c
    ld [hl], a ; Effect_Portamento_Ctrl
    pop hl ; Pattern_Ptr (lo)
    dec l ; Pattern_RowStatus
    @mixer_tick:
    ; hl points to Pattern_RowStatus
    ; update effect
    ld de, Track.Effect_Kind - Track.Pattern_RowStatus
    add hl, de
    ld a, [hli] ; Effect_Kind
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
    ; NR11
    ld hl, wTracks + Track.Square_DutyCtrl
    ld a, [hl] ; Square_DutyCtrl
    and a, $03
    ld a, [hl] ; Square_DutyCtrl
    jr nz, .write_nr11 ; if counter is non-zero, use duty from bits 6-7
    ; use duty from bits 4-5
    sla a
    sla a
    .write_nr11:
    and $c0
    ldh [<rNR11], a

    ; NR12
    ld hl, wTracks + Track.Envelope_Vol
    ld a, [hl] ; Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track.MasterVol
    or a, [hl] ; MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [<hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track.PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [<hShadowNR12], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [<rNR12], a
    jr .write_nr13
    @adjust_volume:
    ld b, a ; new volume
    ldh a, [<hShadowNR12] ; old volume
    cp a, b
    jr z, .write_nr13 ; jump if no change in volume
    jr nc, @decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR12], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    @inc_volume_loop:
    ldh [<rNR12], a
    dec b
    jr nz, @inc_volume_loop
    jr .write_nr13
    @decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR12], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    @dec_volume_loop:
    ldh [<rNR12], a
    dec b
    jr nz, @dec_volume_loop
    .write_nr13:
    ldh a, [<hSoundStatus]
    bit 0, a
    jr z, @not_muted
    ld a, $ff
    ldh [<rNR13], a
    ld a, $7f
    ldh [<rNR14], a
    jr @update_square_duty
    @not_muted:
    ; NR13
    ld hl, wTracks + Track.PeriodLo
    ld a, [hli] ; PeriodLo
    ldh [<rNR13], a
    ; NR14
    ld a, [hl-] ; PeriodHi
    dec l ; PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    or a, $80
    res 7, [hl] ; PeriodIndex - reset trigger flag
    @no_trigger:
    ldh [<rNR14], a

    @update_square_duty:
    ld hl, wTracks + Track.Square_DutyCtrl
    ld a, [hl] ; Square_DutyCtrl
    and a, $03
    jr z, @skip_duty_update
    dec a ; decrement counter
    ld c, a
    ld a, [hl] ; Square_DutyCtrl
    and a, $fc
    or a, c ; update counter
    ld [hl], a ; Square_DutyCtrl
    @skip_duty_update:
    ret

RenderChannel3:
    ; NR32
    ld hl, wTracks + Track.Envelope_Vol + _sizeof_Track*2
    ld a, [hl] ; Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track.MasterVol + _sizeof_Track*2
    or a, [hl] ; MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [<hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ldh [<hShadowNR32], a
    swap a
    srl a ; volume in bits 6-5
    and a, $60
    jr z, .write_nr32 ; mute (no sound)
    bit 5, a
    jr z, .write_nr32 ; 50% volume
    xor a, $40 ; 100% or 25% volume
    .write_nr32:
    ldh [<rNR32], a
    ldh a, [<hSoundStatus]
    bit 2, a
    jr z, @not_muted
    ld a, $ff
    ldh [<rNR33], a
    ld a, $7f
    ldh [<rNR34], a
    ret
    @not_muted:
    ; NR33
    ld hl, wTracks + Track.PeriodLo + _sizeof_Track*2
    ld a, [hli] ; PeriodLo
    ldh [<rNR33], a
    ; NR34
    ld a, [hl-] ; PeriodHi
    dec l ; PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    or a, $80
    res 7, [hl] ; PeriodIndex - reset trigger flag
    @no_trigger:
    ldh [<rNR34], a
    ret

RenderChannel2:
    ; NR21
    ld hl, wTracks + Track.Square_DutyCtrl + _sizeof_Track
    ld a, [hl] ; Square_DutyCtrl
    and a, $03
    ld a, [hl] ; Square_DutyCtrl
    jr nz, .write_nr21 ; if counter is non-zero, use duty from bits 6-7
    ; use duty from bits 4-5
    sla a
    sla a
    .write_nr21:
    and $c0
    ldh [<rNR21], a

    ; NR22
    ld hl, wTracks + Track.Envelope_Vol + _sizeof_Track
    ld a, [hl] ; Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track.MasterVol + _sizeof_Track
    or a, [hl] ; MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [<hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track.PeriodIndex + _sizeof_Track
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [<hShadowNR22], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [<rNR22], a
    jr .write_nr23
    @adjust_volume:
    ld b, a ; new volume
    ldh a, [<hShadowNR22] ; old volume
    cp a, b
    jr z, .write_nr23 ; jump if no change in volume
    jr nc, @decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR22], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    @inc_volume_loop:
    ldh [<rNR22], a
    dec b
    jr nz, @inc_volume_loop
    jr .write_nr23
    @decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR22], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    @dec_volume_loop:
    ldh [<rNR22], a
    dec b
    jr nz, @dec_volume_loop
    .write_nr23:
    ldh a, [<hSoundStatus]
    bit 1, a
    jr z, @not_muted
    ld a, $ff
    ldh [<rNR23], a
    ld a, $7f
    ldh [<rNR24], a
    jr @update_square_duty
    @not_muted:
    ; NR23
    ld hl, wTracks + Track.PeriodLo + _sizeof_Track
    ld a, [hli] ; PeriodLo
    ldh [<rNR23], a
    ; NR24
    ld a, [hl-] ; PeriodHi
    dec l ; PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, @no_trigger
    or a, $80
    res 7, [hl] ; PeriodIndex - reset trigger flag
    @no_trigger:
    ldh [<rNR24], a

    @update_square_duty:
    ld hl, wTracks + Track.Square_DutyCtrl + _sizeof_Track
    ld a, [hl] ; Square_DutyCtrl
    and a, $03
    jr z, @skip_duty_update
    dec a ; decrement counter
    ld c, a
    ld a, [hl] ; Square_DutyCtrl
    and a, $fc
    or a, c ; update counter
    ld [hl], a ; Square_DutyCtrl
    @skip_duty_update:
    ret

RenderChannel4:
    ; NR42
    ld hl, wTracks + Track.Envelope_Vol + _sizeof_Track*3
    ld a, [hl] ; Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track.MasterVol + _sizeof_Track*3
    or a, [hl] ; MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [<hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track.PeriodIndex + _sizeof_Track*3
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, .adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [<hShadowNR42], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [<rNR42], a
    jr .write_nr43
    .adjust_volume:
    ld b, a ; new volume
    ldh a, [<hShadowNR42] ; old volume
    cp a, b
    jr z, .write_nr43 ; jump if no change in volume
    jr nc, .decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR42], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    .inc_volume_loop:
    ldh [<rNR42], a
    dec b
    jr nz, .inc_volume_loop
    jr .write_nr43
    .decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [<hShadowNR42], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    .dec_volume_loop:
    ldh [<rNR42], a
    dec b
    jr nz, .dec_volume_loop
    .write_nr43:
    ldh a, [<hSoundStatus]
    bit 3, a
    jr z, .not_muted
    ld a, $ff
    ldh [<rNR43], a
    ld a, $7f
    ldh [<rNR44], a
    ret
    .not_muted:
    ; NR43
    ld hl, wTracks + Track.PeriodLo + _sizeof_Track*3
    ld a, [hli] ; PeriodLo
    ld c, a
    ld a, [hli] ; PeriodHi
    sla c
    rla
    sla c
    rla
    sla c
    rla
    add a, <NR43Values
    ld e, a
    ld d, >NR43Values
    ld a, [de]
    bit 7, [hl] ; Square_DutyCtrl (LFSR width)
    jr z, .no_regular_output
    or a, 8 ; 1 = 7-bit
    .no_regular_output:
    ldh [<rNR43], a
    ; NR44
    xor a, a
    dec l ; PeriodHi
    dec l ; PeriodLo
    dec l ; PeriodIndex
    bit 7, [hl] ; PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [<rNR44], a
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
.dw .set_global_vol ; 7

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
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_0_left
    dec a
    jr z, .pan_1_left
    dec a
    jr z, .pan_2_left
    ; pan track 3 left
    res 3, [hl]
    set 7, [hl]
    jr .done_panning
    .pan_0_left:
    res 0, [hl]
    set 4, [hl]
    jr .done_panning
    .pan_1_left:
    res 1, [hl]
    set 5, [hl]
    jr .done_panning
    .pan_2_left:
    res 2, [hl]
    set 6, [hl]
    .done_panning:
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .pan_center:
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_0_center
    dec a
    jr z, .pan_1_center
    dec a
    jr z, .pan_2_center
    ; pan track 3 center
    set 3, [hl]
    set 7, [hl]
    jr .done_panning
    .pan_0_center:
    set 0, [hl]
    set 4, [hl]
    jr .done_panning
    .pan_1_center:
    set 1, [hl]
    set 5, [hl]
    jr .done_panning
    .pan_2_center:
    set 2, [hl]
    set 6, [hl]
    jr .done_panning

    .pan_right:
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_0_right
    dec a
    jr z, .pan_1_right
    dec a
    jr z, .pan_2_right
    ; pan track 3 right
    res 7, [hl]
    set 3, [hl]
    jr .done_panning
    .pan_0_right:
    res 4, [hl]
    set 0, [hl]
    jr .done_panning
    .pan_1_right:
    res 5, [hl]
    set 1, [hl]
    jr .done_panning
    .pan_2_right:
    res 6, [hl]
    set 2, [hl]
    jr .done_panning

.set_global_vol:
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; new global vol (0..F)
    inc de
    swap a ; new volume in upper 4 bits
    ldh [<hMasterVol], a
    call IncPatternPtr
    scf ; CF=1 signals keep processing pattern data
    ret

; A = instrument
; preserves DE and HL
SetInstrument:
    push de
    push hl ; Pattern_Ptr (lo)
    sla a
    sla a
    sla a ; each instrument is 8 bytes long
    ld c, a
    ldh a, [<hInstrumentTable]
    add a, c
    ld e, a
    ldh a, [<hInstrumentTable+1]
    adc a, 0
    ld d, a
    ld a, l
    add a, Track.Envelope_Ptr - Track.Pattern_Ptr
    ld l, a
    ld a, [de] ; 0 - envelope lo
    inc de
    ld [hli], a ; Envelope_Ptr (lo)
    ld a, [de] ; 1 - envelope hi
    inc de
    ld [hl], a ; Envelope_Ptr (hi)
    ld a, l
    sub a, Track.Envelope_Ptr+1 - Track.Effect_Kind
    ld l, a
    inc de ; 2 - unused
    ld a, [de] ; 3 - effect kind
    inc de
    ld [hli], a ; Effect_Kind
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
    ld hl, wTracks + Track.Speed
    ld de, _sizeof_Track
    ld [hl], a ; Speed
    add hl, de
    ld [hl], a ; Speed
    add hl, de
    ld [hl], a ; Speed
    add hl, de
    ld [hl], a ; Speed
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
    ld a, [hl] ; Effect_Param
    ld c, a
    ld a, l ; Effect_Param
    add a, Track.PeriodLo - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodLo
    add a, c
    ld [hli], a ; PeriodLo
    jr nc, .slide_skip_inc
    inc [hl] ; PeriodHi
    .slide_skip_inc:
    pop hl ; Effect_Param
    ret

    .slide_down_tick:
; slide up by subtracting slide amount from period value
    pop hl ; Effect_Param
    push hl
    ld a, [hl] ; Effect_Param
    ld c, a
    ld a, l ; Effect_Param
    add a, Track.PeriodLo - Track.Effect_Param
    ld l, a
    ld a, [hl] ; PeriodLo
    sub a, c
    ld [hli], a ; PeriodLo
    jr nc, .slide_skip_dec
    dec [hl] ; PeriodHi
    .slide_skip_dec:
    pop hl ; Effect_Param
    ret

    .portamento_tick:
    pop hl ; Effect_Param
    push hl
    ld a, [hli] ; Effect_Param
    ld c, a
    ld a, [hli] ; Effect_Portamento_Ctrl
    bit 7, a
    jr z, .portamento_exit
    srl a ; CF = direction (0=down, 1=up)
    ld a, [hli] ; Effect_Portamento_TargetPeriodLo
    ld e, a ; save target period lo
    ld a, [hli] ; Effect_Portamento_TargetPeriodHi
    ld d, a
    inc l ; PeriodIndex
    inc l ; PeriodLo
    ld a, [hl] ; PeriodLo
    jr nc, .portamento_down
    ; slide up (add delta to current period value)
    add a, c
    ld [hli], a ; PeriodLo
    ld a, [hl] ; PeriodHi
    adc a, 0
    ld [hl-], a ; PeriodHi
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
    ld [hli], a ; PeriodLo
    ld a, [hl] ; PeriodHi
    sbc a, 0
    ld [hl-], a ; PeriodHi
    ld c, a ; save periodhi
    ; check if target period has been reached (current period <= target period)
    ld a, [hl] ; PeriodLo
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_exit
    .portamento_done:
    ; set final period
    ld a, e
    ld [hli], a ; PeriodLo
    ld a, d
    ld [hl], a ; PeriodHi
    ; halt
    pop hl ; Effect_Param
    inc l ; Effect_Portamento_Ctrl
    xor a, a
    ld [hl-], a ; Effect_Portamento_Ctrl
    ret

    .vibrato_tick:
    pop hl ; Effect_Param
    push hl
    ; reset period value
    ld a, l
    add a, Track.PeriodIndex - Track.Effect_Param
    ld l, a
    ld a, [hli] ; PeriodIndex
    add a, a ; note * 2
    add a, <PeriodTable
    ld e, a
    ld d, >PeriodTable
    ld a, [de]
    ld [hli], a ; PeriodLo
    inc de
    ld a, [de]
    ld [hl], a ; PeriodHi
    pop hl ; Effect_Param
    inc l ; Effect_Pos
    ; get sine value
    ld a, [hl-] ; Effect_Pos
    and a, $1f
    ld de, VibratoTable
    add a, e
    ld e, a
    ld a, [de] ; sine value
    ld c, a
    ; *** convert sine value to real delta freq, according to vibrato depth ***
    ld a, [hli] ; Effect_Param
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
    ld [hli], a ; PeriodLo
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
    ld [hli], a ; PeriodLo
    jr nc, .vib_done
    inc [hl] ; PeriodHi
    .vib_done:
    ; increment pos
    pop hl ; Effect_Pos
    ld a, [hl-] ; Effect_Pos
    ld c, a
    ld a, [hli] ; Effect_Param
    swap a
    and a, $f ; vibrato speed
    add a, c
    ld [hl-], a ; Effect_Pos
    ret

    .arpeggio_tick:
    pop hl ; Effect_Param
    push hl
    ld a, [hli] ; Effect_Param
    ld c, a
    ld a, [hl] ; Effect_Pos
    ld d, a
    inc a
    cp a, 6
    jr c, .skip
    xor a, a
    .skip:
    ld [hli], a ; Effect_Pos
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
    swap a
    and $0f
    .set_period:
    add a, [hl] ; PeriodIndex
    inc l
    add a, a ; note * 2
    add a, <PeriodTable
    ld e, a
    ld d, >PeriodTable
    ld a, [de]
    ld [hli], a ; PeriodLo
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
    swap a
    and a, $f
    sla a
    sla a ; delta * 4
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
    ld a, [hli] ; Effect_Param
    ld c, a
    ld a, [hl] ; Effect_Pos
    cp a, c
    inc a
    ld [hl-], a ; Effect_Pos
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
    ld a, [hli] ; Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Envelope_Ptr (hi)
    ld d, a
    xor a, a
    ld [hl], a ; Envelope_Pos = 0
    .init_vol:
    ; HL = Envelope_Pos
    ld a, [de] ; 1st byte = start volume
    inc de
    inc [hl] ; Envelope_Pos
    inc l ; Envelope_Vol
    ld [hli], a ; Envelope_Vol
    .point_init:
    ; HL = Envelope_Step
    ld a, [de] ; fetch envelope byte
    inc de
    cp a, $ff ; end of envelope reached?
    jr z, .env_end
    ; point OK, set 3-tuple (step, dest, hold)
    ld [hli], a ; Envelope_Step
    ld a, [de]
    inc de
    ld [hli], a ; Envelope_Dest
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
    ld a, [hli] ; Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Envelope_Ptr (hi)
    ld d, a
    ld a, c
    ld [hli], a ; Envelope_Pos
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
    ld a, [hli] ; Envelope_Vol
    push af ; save vol
    ld a, [hli] ; Envelope_Step
    ld c, a ; save step
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
    ld a, [hl-] ; Envelope_Dest
    dec l ; Envelope_Vol
    ld [hli], a ; Envelope_Vol = dest
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
    ld a, [hli] ; Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Envelope_Ptr (hi)
    ld d, a
    ld a, [hli] ; Envelope_Pos
    add a, e
    ld e, a
    jr nc, .skip_inc
    inc d
    .skip_inc:
    inc l ; Envelope_Step
    jp .point_init

.align 256
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

NR43Values:
.db $f7,$f3,$e5,$d7,$e3,$d5,$e2,$c7 ; 0-7
.db $d3,$c5,$d2,$b7,$b6,$b5,$d1,$a7 ; 8-15
.db $a6,$a5,$c1,$97,$a3,$95,$a2,$87 ; 16-23
.db $86,$85,$92,$77,$76,$75,$74,$67 ; 24-31
.db $66,$65,$81,$57,$63,$55,$71,$47 ; 32-39
.db $53,$45,$52,$37,$43,$35,$60,$27 ; 40-47
.db $33,$25,$41,$17,$16,$15,$14,$07 ; 48-55
.db $13,$05,$04,$03,$02,$01,$00,$00 ; 56-63

; ProTracker sine table
VibratoTable:
.db $00,$18,$31,$4A,$61,$78,$8D,$A1
.db $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
.db $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
.db $B4,$A1,$8D,$78,$61,$4A,$31,$18

PeriodTable:
.dw $02d,$09d,$107,$16b,$1ca,$223,$277,$2c7,$312,$359,$39c,$3db ; 0-11
.dw $417,$44f,$484,$4b6,$4e5,$512,$53c,$564,$589,$5ad,$5ce,$5ee ; 12-23
.dw $60c,$628,$642,$65b,$673,$689,$69e,$6b2,$6c5,$6d7,$6e7,$6f7 ; 24-35
.dw $706,$714,$721,$72e,$73a,$745,$74f,$759,$763,$76c,$774,$77c ; 36-47
.dw $783,$78a,$791,$797,$79d,$7a3,$7a8,$7ad,$7b2,$7b6,$7ba,$7be ; 48-59
.dw $7c2,$7c5,$7c9,$7cc,$7cf,$7d2,$7d4,$7d7,$7d9,$7db,$7dd,$7df ; 60-71

DefaultWavRam:
.db $11, $22, $33, $44
.db $55, $66, $77, $88
.db $99, $aa, $bb, $cc
.db $dd, $ee, $ff, $ff

; --- End sound engine ---

; --- Sound data

.INCLUDE "song.s"

; --- Program-specific code: Our game starts here! ---

Genesis:
	; Copy tile data
	ld de, Tiles
	ld hl, $8000
	ld bc, TilesEnd - Tiles
    .copyTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, .copyTiles

    ; copy bg palette data
    ld a, BCPSF_AUTOINC | 0
    ldh [<rBCPS], a
    ld hl, BGPalettes
    ld c, BGPalettesEnd - BGPalettes
    .copyBgPalettes:
    ld a, [hli]
    ldh [<rBCPD], a
    dec c
    jr nz, .copyBgPalettes

    ; copy obj palette data
    ld a, OCPSF_AUTOINC | 0
    ldh [<rOCPS], a
    ld hl, OBJPalettes
    ld c, OBJPalettesEnd - OBJPalettes
    .copyObjPalettes:
    ld a, [hli]
    ldh [<rOCPD], a
    dec c
    jr nz, .copyObjPalettes

    ld a, 0
    ldh [<rVBK], a ; select bank 0
    ld hl, HelloGameBoyTileMapData
    call WriteVramStrings
    ldh a, [<rSVBK]
    cp a, $ff ; are we on DMG or CGB?
    jr z, .loadDMGTileMap
    ; load CGB attributes
    ld a, 1
    ldh [<rVBK], a ; select bank 1
    ld hl, HelloGameBoyTileMapAttributeData
    call WriteVramStrings
    jr .doneLoadingTileMap

    .loadDMGTileMap:
    ld hl, HelloGameBoyDMGTileMapData
    call WriteVramStrings

    .doneLoadingTileMap:
    call InitializeBust
    call InitializeTextScroller

    ; initialize seed
    ld a, 137
    ldh [<hRandom], a

    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld hl, song_song
    call StartSong
    ld a, $0
    ldh [<hSoundStatus], a ; unmute all channels

    ld a, $80
    ldh [<rAUD3ENA], a ; DAC on

; enable interrupts now
	ld   a, IEF_VBLANK | IEF_STAT
	ldh  [<rIE], a

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000 | LCDCF_BG9800
	ldh [<rLCDC], a

Done:
    halt
    jp Done

; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [<hMainState]
    rst JumpTable
.dw MainFunc0

MainFunc0:
    call HideAllSprites
    call UpdateBust
    call UpdateTextScroller
    call UpdatePatronPalette
    call DrawChannelIndicators
    ; check if channels should be (un)muted
    ldh  a, [<hButtonsPressed]
    ld b, a
    ldh a, [<hSoundStatus]
    bit PADB_UP, b
    jr z, .upNotPressed
    ; toggle channel 1
    xor a, 1
    .upNotPressed:
    bit PADB_DOWN, b
    jr z, .downNotPressed
    ; toggle channel 2
    xor a, 2
    .downNotPressed:
    bit PADB_LEFT, b
    jr z, .leftNotPressed
    ; toggle channel 3
    xor a, 4
    .leftNotPressed:
    bit PADB_RIGHT, b
    jr z, .rightNotPressed
    ; toggle channel 4
    xor a, 8
    .rightNotPressed:
    ldh [<hSoundStatus], a
    ret

DrawChannelIndicators:
    ; upper half
    ld de, $9805
    ld c, 11 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ldh a, [<hSoundStatus]
    bit 0, a
    jr z, .channel1_not_muted_top
    ld a, 0
    jr .draw_channel1_top
    .channel1_not_muted_top:
    ldh a, [<hShadowNR12]
    and a, $0e
    .draw_channel1_top:
    or a, a
    jr z, .draw_channel1_blank_top
    sla a ; ball size (0..7) * 4
    add a, $36
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel1_channel2_separator_top
    .draw_channel1_blank_top:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel1_channel2_separator_top:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 2
    ldh a, [<hSoundStatus]
    bit 1, a
    jr z, .channel2_not_muted_top
    ld a, 0
    jr .draw_channel2_top
    .channel2_not_muted_top:
    ldh a, [<hShadowNR22]
    and a, $0e
    .draw_channel2_top:
    or a, a
    jr z, .draw_channel2_blank_top
    sla a ; ball size (0..7) * 4
    add a, $36
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel2_channel3_separator_top
    .draw_channel2_blank_top:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel2_channel3_separator_top:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 3
    ldh a, [<hSoundStatus]
    bit 2, a
    jr z, .channel3_not_muted_top
    ld a, 0
    jr .draw_channel3_top
    .channel3_not_muted_top:
    ldh a, [<hShadowNR32]
    and a, $0e
    .draw_channel3_top:
    or a, a
    jr z, .draw_channel3_blank_top
    sla a ; ball size (0..7) * 4
    add a, $36
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel3_channel4_separator_top
    .draw_channel3_blank_top:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel3_channel4_separator_top:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 4
    ldh a, [<hSoundStatus]
    bit 3, a
    jr z, .channel4_not_muted_top
    ld a, 0
    jr .draw_channel4_top
    .channel4_not_muted_top:
    ldh a, [<hShadowNR42]
    and a, $0e
    .draw_channel4_top:
    or a, a
    jr z, .draw_channel4_blank_top
    sla a ; ball size (0..7) * 4
    add a, $36
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .top_half_done
    .draw_channel4_blank_top:
    ; space
    ld [hli], a
    ld [hli], a
    .top_half_done:
    call EndVramString

    ; lower half
    ld de, $9825
    ld c, 11 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ldh a, [<hSoundStatus]
    bit 0, a
    jr z, .channel1_not_muted_bottom
    ld a, 0
    jr .draw_channel1_bottom
    .channel1_not_muted_bottom:
    ldh a, [<hShadowNR12]
    and a, $0e
    .draw_channel1_bottom:
    or a, a
    jr z, .draw_channel1_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $37
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel1_channel2_separator_bottom
    .draw_channel1_blank_bottom:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel1_channel2_separator_bottom:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 2
    ldh a, [<hSoundStatus]
    bit 1, a
    jr z, .channel2_not_muted_bottom
    ld a, 0
    jr .draw_channel2_bottom
    .channel2_not_muted_bottom:
    ldh a, [<hShadowNR22]
    and a, $0e
    .draw_channel2_bottom:
    or a, a
    jr z, .draw_channel2_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $37
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel2_channel3_separator_bottom
    .draw_channel2_blank_bottom:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel2_channel3_separator_bottom:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 3
    ldh a, [<hSoundStatus]
    bit 2, a
    jr z, .channel3_not_muted_bottom
    ld a, 0
    jr .draw_channel3_bottom
    .channel3_not_muted_bottom:
    ldh a, [<hShadowNR32]
    and a, $0e
    .draw_channel3_bottom:
    or a, a
    jr z, .draw_channel3_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $37
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .draw_channel3_channel4_separator_bottom
    .draw_channel3_blank_bottom:
    ; space
    ld [hli], a
    ld [hli], a
    .draw_channel3_channel4_separator_bottom:
    ; space
    ld a, 0
    ld [hli], a

    ; channel 4
    ldh a, [<hSoundStatus]
    bit 3, a
    jr z, .channel4_not_muted_bottom
    ld a, 0
    jr .draw_channel4_bottom
    .channel4_not_muted_bottom:
    ldh a, [<hShadowNR42]
    and a, $0e
    .draw_channel4_bottom:
    or a, a
    jr z, .draw_channel4_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $37
    ld [hli], a
    add a, 2
    ld [hli], a
    jr .bottom_half_done
    .draw_channel4_blank_bottom:
    ; space
    ld [hli], a
    ld [hli], a
    .bottom_half_done:
    jp EndVramString

InitializeBust:
    ld a, 0
    ldh [<hBustPosXFrac], a
    ldh [<hBustPosYFrac], a
    ldh [<hBustSpeedXFrac], a
    ldh [<hBustSpeedXInt], a
    ldh [<hBustSpeedYFrac], a
    ldh [<hBustSpeedYInt], a
    ldh [<hBustAccelXFrac], a
    ldh [<hBustAccelYFrac], a
    ld a, 160/2
    ldh [<hBustPosXInt], a
    ld a, 144/2
    ldh [<hBustPosYInt], a
    ld a, $04
    ldh [<hBustAccelXFrac], a
    ld a, $04
    ldh [<hBustAccelYFrac], a
    ret

UpdateBust:
    ldh a, [<hBustAccelXInt]
    bit 7, a
    ldh a, [<hBustPosXInt]
    jr nz, .checkLeftCollision
    cp a, 140
    jr c, .checkVerticalCollision
    .invertXAccel:
    ldh a, [<hBustAccelXFrac]
    xor a, $ff
    scf
    adc a, 0
    ldh [<hBustAccelXFrac], a
    ldh a, [<hBustAccelXInt]
    xor a, $ff
    adc a, 0
    ldh [<hBustAccelXInt], a
    jr .checkVerticalCollision
    .checkLeftCollision:
    cp a, 40
    jr c, .invertXAccel
    .checkVerticalCollision:
    ldh a, [<hBustAccelYInt]
    bit 7, a
    ldh a, [<hBustPosYInt]
    jr nz, .checkTopCollision
    cp a, 104
    jr c, .applyXAccel
    .invertYAccel:
    ldh a, [<hBustAccelYFrac]
    xor a, $ff
    scf
    adc a, 0
    ldh [<hBustAccelYFrac], a
    ldh a, [<hBustAccelYInt]
    xor a, $ff
    adc a, 0
    ldh [<hBustAccelYInt], a
    jr .applyXAccel
    .checkTopCollision:
    cp a, 40
    jr c, .invertYAccel
    .applyXAccel:
    ldh a, [<hBustAccelXFrac]
    ld b, a
    ldh a, [<hBustSpeedXFrac]
    add a, b
    ldh [<hBustSpeedXFrac], a
    ldh a, [<hBustAccelXInt]
    ld b, a
    ldh a, [<hBustSpeedXInt]
    adc a, b
    ldh [<hBustSpeedXInt], a
    bit 7, a
    jr nz, .clipNegativeXSpeed
    cp a, 1
    jr c, .applyXSpeed
    ld a, 1
    ldh [<hBustSpeedXInt], a
    ld a, 0
    ldh [<hBustSpeedXFrac], a
    jr .applyXSpeed
    .clipNegativeXSpeed:
    cp a, $ff
    jr nc, .applyXSpeed
    ld a, $ff
    ldh [<hBustSpeedXInt], a
    ld a, 0
    ldh [<hBustSpeedXFrac], a
    .applyXSpeed:
    ldh a, [<hBustPosXFrac]
    ld b, a
    ldh a, [<hBustSpeedXFrac]
    add a, b
    ldh [<hBustPosXFrac], a
    ldh a, [<hBustPosXInt]
    ld b, a
    ldh a, [<hBustSpeedXInt]
    adc a, b
    ldh [<hBustPosXInt], a

    ; apply y accel and speed
    ldh a, [<hBustAccelYFrac]
    ld b, a
    ldh a, [<hBustSpeedYFrac]
    add a, b
    ldh [<hBustSpeedYFrac], a
    ldh a, [<hBustAccelYInt]
    ld b, a
    ldh a, [<hBustSpeedYInt]
    adc a, b
    ldh [<hBustSpeedYInt], a
    bit 7, a
    jr nz, .clipNegativeYSpeed
    cp a, 1
    jr c, .applyYSpeed
    ld a, 1
    ldh [<hBustSpeedYInt], a
    ld a, 0
    ldh [<hBustSpeedYFrac], a
    jr .applyYSpeed
    .clipNegativeYSpeed:
    cp a, $ff
    jr nc, .applyYSpeed
    ld a, $ff
    ldh [<hBustSpeedYInt], a
    ld a, 0
    ldh [<hBustSpeedYFrac], a
    .applyYSpeed:
    ldh a, [<hBustPosYFrac]
    ld b, a
    ldh a, [<hBustSpeedYFrac]
    add a, b
    ldh [<hBustPosYFrac], a
    ldh a, [<hBustPosYInt]
    ld b, a
    ldh a, [<hBustSpeedYInt]
    adc a, b
    ldh [<hBustPosYInt], a

    jp DrawBustFrame0

.define BUST_START_TILE $aa

DrawBustFrame0:
    call BeginDrawSprites
    ; (0, 0)
    ldh a, [<hBustPosYInt]
    sub a, 32
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 16
    ld [hli], a ; x
    ld a, BUST_START_TILE + $00
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (0, 1)
    ldh a, [<hBustPosYInt]
    sub a, 32
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $02
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (0, 2)
    ldh a, [<hBustPosYInt]
    sub a, 32
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    ld [hli], a ; x
    ld a, BUST_START_TILE + $04
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (0, 3)
    ldh a, [<hBustPosYInt]
    sub a, 32
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    add a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $06
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes

    ; (1, 0)
    ldh a, [<hBustPosYInt]
    sub a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 16
    ld [hli], a ; x
    ld a, BUST_START_TILE + $08
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (1, 1)
    ldh a, [<hBustPosYInt]
    sub a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $0a
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (1, 2)
    ldh a, [<hBustPosYInt]
    sub a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    ld [hli], a ; x
    ld a, BUST_START_TILE + $0c
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (1, 3)
    ldh a, [<hBustPosYInt]
    sub a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    add a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $0e
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes

    ; (2, 0)
    ldh a, [<hBustPosYInt]
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 16
    ld [hli], a ; x
    ld a, BUST_START_TILE + $10
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (2, 1)
    ldh a, [<hBustPosYInt]
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $12
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (2, 2)
    ldh a, [<hBustPosYInt]
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    ld [hli], a ; x
    ld a, BUST_START_TILE + $14
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (2, 3)
    ldh a, [<hBustPosYInt]
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    add a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $16
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes

    ; (3, 0)
    ldh a, [<hBustPosYInt]
    add a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 16
    ld [hli], a ; x
    ld a, BUST_START_TILE + $18
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (3, 1)
    ldh a, [<hBustPosYInt]
    add a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    sub a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $1a
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (3, 2)
    ldh a, [<hBustPosYInt]
    add a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    ld [hli], a ; x
    ld a, BUST_START_TILE + $1c
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes
    ; (3, 3)
    ldh a, [<hBustPosYInt]
    add a, 16
    ld [hli], a ; y
    ldh a, [<hBustPosXInt]
    add a, 8
    ld [hli], a ; x
    ld a, BUST_START_TILE + $1e
    ld [hli], a ; tile
    ld a, 0 ; palette
    ld [hli], a  ; attributes

    jp EndDrawSprites

InitializeTextScroller:
    ld a, 0
    ldh [<hTextScrollerScrollX], a
    ldh [<hTextScrollerStringOffset], a
    ld hl, KatakanaText
.drawCharactersLoop:
    push af
    ld c, a
    ld a, [hli]
    ld b, a
    push hl
    call DrawKatakanaCharacter
    call FlushVramBuffer
    pop hl
    pop af
    inc a
    cp a, 16
    jr nz, .drawCharactersLoop
    ldh [<hTextScrollerStringOffset], a
    ret

UpdateTextScroller:
    ldh a, [<hFrameCounter]
    and a, 7
    ret nz
    ldh a, [<hTextScrollerScrollX]
    inc a
    ldh [<hTextScrollerScrollX], a
    and a, 15
    ret nz
    ldh a, [<hTextScrollerScrollX]
    swap a
    dec a
    and a, 15
    ld c, a ; column
    ld d, 0
    ldh a, [<hTextScrollerStringOffset]
    @again:
    ld hl, KatakanaText
    ld e, a
    inc a
    ldh [<hTextScrollerStringOffset], a
    add hl, de
    ld a, [hl]
    cp a, $ff
    jr nz, @not_eos
    ld a, 0
    jr @again
    @not_eos:
    ld b, a ; character index
    jp DrawKatakanaCharacter

.define KATAKANA_START_TILE $5a

; B = character index
; C = column (0..31)
DrawKatakanaCharacter:
    ; upper half
    ld a, c
    add a, a
    ld e, a
    ld d, $9a
    push de
    ld c, 2
    call BeginVramString
    ld a, b
    add a, a
    add a, KATAKANA_START_TILE
    ld [hli], a
    inc a
    ld [hli], a
    call EndVramString
    ; bottom half
    pop de
    ld a, e
    add a, $20
    ld e, a
    ld c, 2
    call BeginVramString
    ld a, b
    add a, a
    add a, KATAKANA_START_TILE + 40
    ld [hli], a
    inc a
    ld [hli], a
    jp EndVramString

UpdatePatronPalette:
    ldh a, [<hFrameCounter]
    and a, 15
    ret nz
    ld a, BCPSF_AUTOINC | 15*2
    ldh [<rBCPS], a
    call Prng
    ldh [<rBCPD], a
    call Prng
    ldh [<rBCPD], a
    ret

Prng:
    ldh a, [<hRandom]
    srl a
    jr nc, .noXor
    xor $B4
    .noXor:
    ldh [<hRandom], a
    ret

; SECTION "Tile data", ROM0

Tiles:
; BG
.incbin "font.bin"     ; $00 - 56 tiles
.incbin "flag.bin"     ; $38 - 2 tiles
.incbin "ball.bin"     ; $3A - 32 tiles
.incbin "katakana.bin" ; $5A - 80 tiles
; OBJ
.incbin "bust.bin"     ; $AA - 32 tiles
TilesEnd:

; SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
; Risa Furanku 420
.db $98, $42, 16, CHAR_R, CHAR_i, CHAR_s, CHAR_a, CHAR_SPACE, CHAR_F, CHAR_u, CHAR_r, CHAR_a, CHAR_n, CHAR_k, CHAR_u, CHAR_SPACE, CHAR_4, CHAR_2, CHAR_0
; / Gendai no Konpyū
.db $98, $61, 18, CHAR_SLASH, CHAR_SPACE, CHAR_G, CHAR_e, CHAR_n, CHAR_d, CHAR_a, CHAR_i, CHAR_SPACE, CHAR_n, CHAR_o, CHAR_SPACE, CHAR_K, CHAR_o, CHAR_n, CHAR_p, CHAR_y, CHAR_u_HAT
; by Macintosh Plus
.db $98, $a1, 17, CHAR_b, CHAR_y, CHAR_SPACE, CHAR_M, CHAR_a, CHAR_c, CHAR_i, CHAR_n, CHAR_t, CHAR_o, CHAR_s, CHAR_h, CHAR_SPACE, CHAR_P, CHAR_l, CHAR_u, CHAR_s,
.db $98, $e3, 10, CHAR_R, CHAR_e, CHAR_m, CHAR_i, CHAR_x, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_i, CHAR_n
.db $98, $EE, 2, $38,$39 ; flag
; as requested by
.db $99, $22, 15, CHAR_a, CHAR_s, CHAR_SPACE, CHAR_r, CHAR_e, CHAR_q, CHAR_u, CHAR_e, CHAR_s, CHAR_t, CHAR_e, CHAR_d, CHAR_SPACE, CHAR_b, CHAR_y
; @Tornado_Mang
.db $99, $63, 13, CHAR_@, CHAR_T, CHAR_o, CHAR_r, CHAR_n, CHAR_a, CHAR_d, CHAR_o, CHAR_UNDERSCORE, CHAR_M, CHAR_a, CHAR_n, CHAR_g
; Use D-pad to
.db $99, $a4, 12, CHAR_U, CHAR_s, CHAR_e, CHAR_SPACE, CHAR_D, CHAR_MINUS, CHAR_p, CHAR_a, CHAR_d, CHAR_SPACE, CHAR_t, CHAR_o
; toggle channels
.db $99, $c2, 15, CHAR_t, CHAR_o, CHAR_g, CHAR_g, CHAR_l, CHAR_e, CHAR_SPACE, CHAR_c, CHAR_h, CHAR_a, CHAR_n, CHAR_n, CHAR_e, CHAR_l, CHAR_s
.db 0

HelloGameBoyDMGTileMapData:
.db $98, $EE, 3, CHAR_N, CHAR_O, CHAR_R
.db 0

HelloGameBoyTileMapAttributeData:
; flag
.db $98, $EE, 2, $01,$01
; orbs
.db $98, $05, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
.db $98, $25, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
; text highlight
.db $99, $63, 14, $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
.db 0

KatakanaText:
.db 0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 5, 14, 15, 16, 17, 18, 5, 6, 19, $ff

; SECTION "Palette data", rom0

.macro rgb
.dw (\3 << 10) | (\2 << 5) | \1
.endm

BGPalettes:
; 0 - background and text
    rgb 28, 13, 16
    rgb 3, 11, 7
    rgb 8, 27, 16
    rgb 10, 31, 18
; 1 - flag
    rgb 28, 13, 16
.dw %0000000000011111
.dw %0101000000000000
.dw %0111111111111111
; 2 - orb
    rgb 28, 13, 16
    rgb 9, 4, 3
    rgb 31, 12, 22
    rgb 31, 22, 31
; 3 - text highlight
    rgb 28, 13, 16
    rgb 4, 12, 9
    rgb 0, 0, 0
    rgb 17, 31, 25
BGPalettesEnd:

OBJPalettes:
; 0 - bust
    rgb 28, 13, 16
    rgb 11, 10, 9
    rgb 18, 16, 14
    rgb 31, 29, 26
OBJPalettesEnd:
