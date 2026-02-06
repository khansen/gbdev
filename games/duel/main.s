INCLUDE "hardware.inc"

SECTION "HRAM", HRAM[$ff80]

hOamDmaFunction:
    ds $0a
.end:

hOamOffset: db

hButtonsHeld: db

hButtonsPressed: db

hProcessingVBlank: db

hMainState: db
hNextMainState: db

hVramBufferOffset: db

hScrollX: db

hScrollY: db

hFrameCounter: db

hRandom: db

hTimerHi: db

def TIMER_SPEED equ 4

hTimerLo: db

hTimerCallback: dw

hQuickTimeEventKind: db

hQuickTimeEventTimer: db

hQuickTimeEventHalfTime: db

hQuickTimeEventButtons: db

hQuickTimeEventButtonsSatisfied: db

def QUICK_TIME_EVENT_BUTTON_INDICATORS_TIMER_SPEED equ 14

hQuickTimeEventButtonIndicatorsTimer: db

hShadowBGP: db
hShadowOBP0: db
hShadowLCDC: db

hPlayerGunJitterIndex: db

hPlayerWon: db

def MAX_LEVEL equ 50

hCurrentLevel: db

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

SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4

wVramBuffer:
    ds 128

; --- Begin Sound engine

rsreset
def Track_Speed rb 1                                ; 00
def Track_Tick rb 1                                 ; 01
def Track_Pattern_RowCount rb 1                     ; 02
def Track_Pattern_Row rb 1                          ; 03
def Track_Pattern_RowStatus rb 1                    ; 04
def Track_Pattern_Ptr rw 1                          ; 05
def Track_Order_Pos rb 1                            ; 07
def Track_Effect_Kind rb 1                          ; 08
def Track_Effect_Param rb 1                         ; 09
def Track_Effect_Pos rb 1                           ; 0A
rsset Track_Effect_Pos
def Track_Effect_Portamento_Ctrl rb 1 ; bit 7: done if zero. bit 0: direction ; 0A
def Track_Effect_Portamento_TargetPeriodLo rb 1     ; 0B
def Track_Effect_Portamento_TargetPeriodHi rb 1     ; 0C
def Track_MasterVol rb 1                            ; 0D
def Track_PeriodIndex rb 1                          ; 0E
def Track_PeriodLo rb 1                             ; 0F
def Track_PeriodHi rb 1                             ; 10
def Track_Square_DutyCtrl rb 1                      ; 11
def Track_Envelope_Phase rb 1                       ; 12
def Track_Envelope_Ptr rw 1                         ; 13
def Track_Envelope_Pos rb 1                         ; 15
def Track_Envelope_Vol rb 1                         ; 16
def Track_Envelope_Step rb 1                        ; 17
def Track_Envelope_Dest rb 1                        ; 18
def Track_Envelope_Hold rb 1                        ; 19
def Track_SIZEOF rb 0                               ; 1A

assert Track_Effect_Pos == $a
assert Track_SIZEOF == $1a

def NUM_TRACKS equ 4

wTracks:
  ds Track_SIZEOF * NUM_TRACKS

; --- End Sound engine

SECTION "ROM Bank $000", ROM0[$0]

; --- Begin courtesy of https://github.com/vinheim3/tetris-gb-disasm/ ---

RST_00:
	jp   Begin2

ds $08-@, $00

RST_08:
	jp   Begin2

ds $28-@, $ff

SECTION "RST $28", ROM0[$28]

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

ds $40-@, $ff

VBlankInterrupt:
	jp   VBlankInterruptHandler

ds $48-@, $ff

LCDCInterrupt:
	jp   StubInterruptHandler

ds $50-@, $ff

TimerOverflowInterrupt:
	jp   StubInterruptHandler

ds $58-@, $ff

SerialTransferCompleteInterrupt:
	jp   StubInterruptHandler

ds $100-@, $ff

SECTION "Header", ROM0[$100]

Boot:
	nop
	jp   Begin

ds $134-@, 0 ; reserve space for Nintendo logo

	setcharmap main

HeaderTitle:
	db   "SNOWBRO 017", $00, $00, $00, $00

HeaderCGBFlag:
    db   $00

HeaderNewLicenseeCode:
	db   $00, $00

HeaderSGBFlag:
	db   $00

HeaderCartridgeType:
	db   $00

HeaderROMSize:
	db   $00

HeaderRAMSize:
	db   $00

HeaderDestinationCode:
	db   $00

HeaderOldLicenseeCode:
	db   $00

HeaderMaskROMVersion:
	db   $01


SECTION "Begin", ROM0[$150]

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

        ldh a, [hProcessingVBlank]
        or a
        jr nz, .skipVBlankProcessing
        inc a
        ldh [hProcessingVBlank], a

        ldh a, [hFrameCounter]
        inc a
        ldh [hFrameCounter], a
    
        call FlushVramBuffer
	    call hOamDmaFunction
        ldh a, [hScrollX]
        ldh [rSCX], a
        ldh a, [hScrollY]
        ldh [rSCY], a
        ldh a, [hShadowBGP]
        ldh [rBGP], a
        ldh a, [hShadowOBP0]
        ldh [rOBP0], a
        ldh a, [hShadowLCDC]
        ldh [rLCDC], a

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

OamDmaFunction:
	ld   a, HIGH(wOam)
	ldh  [rDMA], a
	ld   a, OAM_COUNT
.wait:
	dec  a
	jr   nz, .wait
	ret

PollInput:
	ld   a, $20
	ldh  [rP1], a
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	cpl
	and  $0f
	swap a
	ld   b, a
	ld   a, $10
	ldh  [rP1], a
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	ldh  a, [rP1]
	cpl
	and  $0f
	or   b
	ld   b, a
	ldh  a, [hButtonsHeld]
	xor  b
	and  b
	ldh  [hButtonsPressed], a
	ld   a, b
	ldh  [hButtonsHeld], a
	ld   a, $30
	ldh  [rP1], a
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
	ldh  [rIF], a
	ldh  [rIE], a

; clear hw regs
	xor  a
	ldh  [rSCY], a
	ldh  [rSCX], a
	ldh  [rSTAT], a
	ldh  [rSB], a
	ldh  [rSC], a
	ldh  [rNR52], a

; turn on LCD, and wait until in vblank area (specifically line $94)
	ld   a, LCDCF_ON
	ldh  [rLCDC], a

.waitUntilVBlank:
	ldh  a, [rLY]
	cp   $94
	jr   nz, .waitUntilVBlank

; turn off lcd again
	ld   a, LCDCF_OFF|LCDCF_OBJON|LCDCF_BGON
	ldh  [rLCDC], a

; all sound on
	ld   a, $80
	ldh  [rAUDENA], a

; channels outputted to all sound S01 and S02
	ld   a, %11111111
	ldh  [rAUDTERM], a

; vol max without setting vin
    ld   a, $77
    ldh  [rAUDVOL], a

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

; clear all vram bank 0
	ld   hl, $9fff
	ld   c, $20
	xor  a
    ldh [rVBK], a ; select bank 0
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
	ld   c, LOW(hOamDmaFunction)
	ld   b, hOamDmaFunction.end-hOamDmaFunction+2
	ld   hl, OamDmaFunction

.copyOamDmaFunc:
	ld   a, [hl+]
	ldh  [c], a
	inc  c
	dec  b
	jr   nz, .copyOamDmaFunc

; clear some hw regs
	ei
	xor  a
	ldh  [rIF], a
	ldh  [rWY], a
	ldh  [rWX], a
	ldh  [rTMA], a
        jp Genesis

CopyFromHLIntoWav3Ram:
	push bc
	ld   c, LOW(_AUD3WAVERAM)
.loop:
	ld   a, [hl+]
	ldh  [c], a
	inc  c
	ld   a, c
	cp   LOW(_AUD3WAVERAM) + 16
	jr   nz, .loop
	pop  bc
	ret

; === End courtesy of https://github.com/vinheim3/tetris-gb-disasm/ ===

; --- Begin gfx-related procedures ---

FlushVramBuffer:
    ldh a, [hVramBufferOffset]
    or a, a
    ret z
    xor a
    ldh [hVramBufferOffset], a
    ld hl, wVramBuffer
    jp WriteVramStrings

; HL = Address of data (zero-terminated)
WriteVramStrings:
    ld a, [hli]
    or a, a
    ret z
    ld d, a ; high VRAM address
    ld a, [hli]
    ld e, a ; low VRAM address
    ld a, [hli]
    bit 6, a ; is data RLE?
    jr nz, .isRle
    ld b, a ; count
    .nonRleLoop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .nonRleLoop
    jr WriteVramStrings
    .isRle:
    res 6, a ; count in lower 5 bits
    ld b, a
    ld a, [hli] ; data
    .rleLoop:
    ld [de], a
    inc de
    dec b
    jr nz, .rleLoop
    jr WriteVramStrings

; DE = start address
; C = count
; returns HL = vram buffer pointer
BeginVramString:
    ld hl, wVramBuffer
    ldh a, [hVramBufferOffset]
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
    sub a, LOW(wVramBuffer)
    ldh [hVramBufferOffset], a
    ret

; DE = Address of string
CopyStringToVramBuffer:
    ld hl, wVramBuffer
    ldh a, [hVramBufferOffset]
    ld c, a
    ld b, 0
    add hl, bc
    ld a, [de] ; high address
    inc de
    ld [hli], a
    ld a, [de] ; high address
    inc de
    ld [hli], a
    ld a, [de] ; count
    inc de
    ld [hli], a
    bit 6, a ; is RLE?
    jr nz, .isRle
    ld b, a
    .loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    jp EndVramString
    .isRle:
    ld a, [de] ; data
    ld [hli], a
    jp EndVramString

; DE = Address of data
; A = number of bytes
CopyBytesToVramBuffer:
    push af
    ld hl, wVramBuffer
    ldh a, [hVramBufferOffset]
    ld c, a
    ld b, 0
    add hl, bc
    pop af
    ld b, a
    .loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    jp EndVramString

HideAllSprites:
    ld hl, wOam
    xor a
    ldh [hOamOffset], a
    ld b, OAM_COUNT
    .loop:
    ld [hli], a
    inc l
    inc l
    inc l
    dec b
    jr nz, .loop
    ret

; Out: hl=address of sprite
; destroys bc
BeginDrawSprites:
    ld hl, wOam
    ldh a, [hOamOffset]
    ld b, 0
    ld c, a
    add hl, bc
    ret

EndDrawSprites:
    ld a, l
    sub a, LOW(wOam)
    ldh [hOamOffset], a
    ret

; --- End gfx-related procedures ---

; --- Begin sound engine ---

; HL = pointer to song
StartSong:
    ld b, NUM_TRACKS
    ld de, wTracks + Track_Order_Pos
    .loop:
    ld a, [hli] ; order pos
    ld [de], a ; Track_Order_Pos
    cp a, $ff ; channel not in use?
    jr z, .skip
    ld a, [hli] ; speed
    ; slow it down by 8x - useful for debugging
    ; sla a
    ; sla a
    ; sla a
    .skip:
    ld c, a
    inc de ; Track_Effect_Kind
    xor a, a
    ld [de], a ; Track_Effect_Kind
    dec de ; Track_Order_Pos
    dec de ; Track_Pattern_Ptr (hi)
    dec de ; Track_Pattern_Ptr (lo)
    dec de ; Track_Pattern_RowStatus
    dec de ; Track_Pattern_Row
    xor a, a
    ld [de], a ; Track_Pattern_Row
    dec de ; Track_Pattern_RowCount
    inc a ; 1
    ld [de], a ; Track_Pattern_RowCount
    dec de ; Track_Tick
    ld a, c ; speed
    dec a
    ld [de], a ; Track_Tick
    dec de ; Track_Speed
    inc a
    ld [de], a ; Track_Speed
    ld a, e
    add a, Track_MasterVol - Track_Speed
    ld e, a
    ld a, $f0
    ld [de], a ; Track_MasterVol
    inc de
    xor a, a
    ld [de], a ; Track_PeriodIndex
    inc de
    ld [de], a ; Track_PeriodLo
    inc de
    ld [de], a ; Track_PeriodHi
    inc de ; Track_Square_DutyCtrl
    inc de ; Track_Envelope_Phase
    ld [de], a ; Track_Envelope_Phase
    ld a, e
    add a, Track_SIZEOF - Track_Envelope_Phase + Track_Order_Pos
    ld e, a
    dec b
    jr nz, .loop
    ; Instrument table
    ld a, [hli]
    ldh [hInstrumentTable], a
    ld a, [hli]
    ldh [hInstrumentTable+1], a
    ; Pattern table
    ld a, [hli]
    ldh [hPatternTable], a
    ld a, [hli]
    ldh [hPatternTable+1], a
    ; HL now points to order data
    ld a, l
    ldh [hOrder], a
    ld a, h
    ldh [hOrder+1], a

    ld a, $f0
    ldh [hMasterVol], a
    ret

; Volume envelope states
def ENV_RESET equ $80
def ENV_PROCESS equ $40
def ENV_SUSTAIN equ $20

; Effect kinds
def NO_EFFECT equ 0
def SLIDE_UP_EFFECT equ 1
def SLIDE_DOWN_EFFECT equ 2
def PORTAMENTO_EFFECT equ 3
def VIBRATO_EFFECT equ 4
def ARPEGGIO_EFFECT equ 5
def VOLUME_SLIDE_EFFECT equ 6
def CUT_EFFECT equ 7

UpdateSound:
;    call UpdateSampleData
    ld b, 0 ; track index
    ld hl, wTracks; + Track_SIZEOF
    .loop:
    ld a, [hli] ; Track_Speed
    cp a, $ff   ; is track used?
    jr nz, .process_track
    ld de, Track_SIZEOF - 1
    add hl, de
    jp .next_track
    .process_track:
    inc [hl]    ; Track_Tick
    cp a, [hl]  ; speed == tick?
    jr z, .next_row
    inc l ; Track_Pattern_RowCount
    inc l ; Track_Pattern_Row
    inc l ; Track_Pattern_RowStatus
    jp .mixer_tick
    .next_row:
    xor a, a
    ld [hli], a ; Track_Tick
    ld a, [hli] ; Track_Pattern_RowCount
    inc [hl]    ; Track_Pattern_Row
    cp a, [hl]  ; rowCount == row?
    jr z, .end_of_pattern
    jr .no_new_pattern
    .end_of_pattern:
    push hl ; Track_Pattern_Row
    xor a, a
    ld [hli], a ; Track_Pattern_Row = 0
    inc l ; Track_Pattern_Ptr (lo)
    inc l ; Track_Pattern_Ptr (hi)
    inc l ; Track_Order_Pos
    .pre_order_loop:
    ld a, [hl] ; Track_Order_Pos
    ld c, a
    ldh a, [hOrder]
    add a, c
    ld e, a
    ldh a, [hOrder+1]
    adc a, 0
    ld d, a
    .order_fetch_loop:
    ld a, [de] ; order byte
    inc de
    inc [hl] ; Track_Order_Pos
    cp a, $f0 ; $f0 > a?
    jr nc, .order_special
    ; pattern number
    add a, a ; pattern number * 2
    ld c, a
    ldh a, [hPatternTable+1]
    adc a, 0
    ld d, a
    ldh a, [hPatternTable]
    add a, c
    ld e, a
    jr nc, .skip_inc_d
    inc d
    .skip_inc_d:
    ld a, [de]
    dec l ; Track_Pattern_Ptr (hi)
    dec l ; Track_Pattern_Ptr (lo)
    ld [hli], a ; Track_Pattern_Ptr (lo)
    inc de
    ld c, a
    ld a, [de]
    ld [hl-], a ; Track_Pattern_Ptr (hi)
    ld e, c
    ld d, a
    ld a, [de] ; row count
    inc de
    call IncPatternPtr
    pop hl ; Track_Pattern_Row
    dec l ; Track_Pattern_RowCount
    ld [hli], a ; Track_Pattern_RowCount
    inc l ; Track_Pattern_RowStatus
    jr .fetch_row_status
    .order_special:
    ; TODO: implement order commands. Assume $fe for now
    ld a, [de] ; order byte
    ld [hl], a ; Track_Order_Pos
    jr .pre_order_loop
    .no_new_pattern:
    ld a, [hli] ; Track_Pattern_Row
    and a, 7
    jr nz, .check_row_status
    ; prepare to fetch row status
    inc l ; Track_Pattern_Ptr (lo)
    ld a, [hli] ; Track_Pattern_Ptr (lo)
    ld e, a
    ld a, [hl-] ; Track_Pattern_Ptr (hi)
    ld d, a
    dec l ; Track_Pattern_RowStatus
    .fetch_row_status:
    ; HL = Track_Pattern_RowStatus
    ; DE = pattern data ptr
    ; fetch row status for upcoming 8 rows
    ld a, [de] ; pattern byte
    inc de
    ld [hli], a ; Track_Pattern_RowStatus
    call IncPatternPtr
    dec l ; Track_Pattern_RowStatus
    .check_row_status:
    ; HL = Track_Pattern_RowStatus
    srl [hl] ; Track_Pattern_RowStatus
    jr c, .process_pattern_data
    jp .mixer_tick
    .process_pattern_data:
    ; HL = Track_Pattern_RowStatus
    dec l ; Track_Pattern_Row
    ld a, [hli] ; Track_Pattern_Row
    inc l ; Track_Pattern_Ptr (lo)
    and a, 7
    jr z, .pattern_fetch_loop
    ; for rows not multiple of 8, DE does not yet contain pattern data ptr because we didn't fetch row status byte
    ld a, [hli] ; Track_Pattern_Ptr (lo)
    ld e, a
    ld a, [hl-] ; Track_Pattern_Ptr (hi)
    ld d, a
    .pattern_fetch_loop:
    ; HL = Track_Pattern_Ptr (lo)
    ; DE = pattern data ptr
    ld a, [de] ; pattern byte
    inc de
    call IncPatternPtr
    cp a, $b0 ; $b0 > a? (is it an effect or a command?)
    jr c, .is_note
    cp a, $c0 ; a < $c0? (is it a set instrument command?)
    jr c, .is_set_instrument_command
    cp a, $d0 ; a < $d0? (is it a set speed command?)
    jr c, .is_set_speed_command
    cp a, $e0 ; a < $e0? (is it a set volume command?)
    jr c, .is_set_volume_command
    cp a, $f0 ; $f0 > a? (is it a command ( >= $f0)?)
    jr nc, .is_other_command
    ; set effect and param
    and a, $f
    push hl ; Track_Pattern_Ptr (lo)
    jr z, .skip_inc ; effect = 0 --> no parameter byte
    call IncPatternPtr
    .skip_inc:
    inc l ; Track_Pattern_Ptr (hi)
    inc l ; Track_Order_Pos
    inc l ; Track_Effect_Kind
    ld [hli], a ; Track_Effect_Kind
    or a, a
    jr z, .skip_effect_init
    ld a, [de] ; pattern byte: effect param
    inc de
    ld [hli], a ; Track_Effect_Param
    ; clear effect state
    xor a, a
    ld [hl], a ; Track_Effect_Pos
    .skip_effect_init:
    pop hl ; Track_Pattern_Ptr (lo)
    jr .pattern_fetch_loop
    .is_set_instrument_command:
    and a, $f ; instrument in lower 4 bits
    call SetInstrument
    jr .pattern_fetch_loop
    .is_set_speed_command:
    and a, $f ; new speed - 1 in lower 4 bits
    inc a
    call SetSpeed
    jr .pattern_fetch_loop
    .is_set_volume_command:
    and a, $f
    swap a ; new volume in upper 4 bits
    or a, 1 ; indicates that volume was explicitly set
    push hl ; Track_Pattern_Ptr (lo)
    push de
    ld de, Track_MasterVol - Track_Pattern_Ptr
    add hl, de
    ld [hl], a ; Track_MasterVol
    pop de ; pattern data ptr
    pop hl ; Track_Pattern_Ptr (lo)
    jr .pattern_fetch_loop
    .is_other_command:
    and a, $f
    call GoPatternCommand
    jr c, .pattern_fetch_loop
    dec l ; Track_Pattern_RowStatus
    jr .mixer_tick
    .is_note:
    push hl ; Track_Pattern_Ptr (lo)
    ld c, a ; save note
    inc l ; Track_Pattern_Ptr (hi)
    inc l ; Track_Order_Pos
    inc l ; Track_Effect_Kind
    ld a, [hli] ; Track_Effect_Kind
    ld d, a
    inc l ; skip Track_Effect_Param
    ; clear effect state
    xor a, a
    ld [hli], a ; Track_Effect_Pos
    ld [hli], a ; Track_Effect_Portamento_TargetPeriodLo
    ld [hli], a ; Track_Effect_Portamento_TargetPeriodHi
    ld a, [hl] ; Track_MasterVol
    srl a
    jr c, .skip ; CF=1 if the volume has been overridden by a previous volume command
    ld a, $78
    .skip:
    sla a
    ld [hli], a ; Track_MasterVol
    inc l ; Track_PeriodLo
    inc l ; Track_PeriodHi
    inc l ; Track_Square_DutyCtrl
    inc l ; Track_Envelope_Phase
    ld a, ENV_RESET
    ld [hl-], a ; Track_Envelope_Phase
    ld a, d ; effect kind
    cp a, PORTAMENTO_EFFECT
    jr z, .init_slide
    ; no slide, set new period immediately
    push hl ; Track_Square_DutyCtrl
    ld hl, PeriodTable
    ld a, c
    add a, a ; note * 2
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli] ; period lo
    ld d, a
    ld a, [hl] ; period hi
    pop hl ; Track_Square_DutyCtrl
    dec l ; Track_PeriodHi
    ld [hl-], a ; Track_PeriodHi
    ld a, d
    ld [hl-], a ; Track_PeriodLo
    ld a, c
    or a, $80 ; trigger channel
    ld [hli], a ; Track_PeriodIndex
    inc l ; Track_PeriodHi
    inc l ; Track_Square_DutyCtrl
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $0c ; initial counter
    srl a
    srl a
    ld c, a
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $fc
    or a, c ; copy initial counter to current counter
    ld [hl], a ; Track_Square_DutyCtrl
    pop hl ; Track_Pattern_Ptr (lo)
    dec l ; Track_Pattern_RowStatus
    jp .mixer_tick
    .init_slide:
    dec l ; Track_PeriodHi
    dec l ; Track_PeriodLo
    dec l ; Track_PeriodIndex
    ld a, [hl] ; Track_PeriodIndex
    cp a, c ; CF = slide direction (0=down,1=up)
    ld a, c
    ld [hl], a ; Track_PeriodIndex
    ld c, $40
    rl c ; bit 7 = 1 (active), bit 0 = direction
    push hl ; Track_PeriodIndex
    ld hl, PeriodTable
    add a, a ; note * 2
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli] ; period lo
    ld d, a
    ld a, [hl] ; period hi
    pop hl ; Track_PeriodIndex
    dec l ; Track_MasterVol
    dec l ; Track_Effect_Portamento_TargetPeriodHi
    ld [hl-], a ; Track_Effect_Portamento_TargetPeriodHi
    ld a, d
    ld [hl-], a ; Track_Effect_Portamento_TargetPeriodLo
    ld a, c
    ld [hl], a ; Track_Effect_Portamento_Ctrl
    pop hl ; Track_Pattern_Ptr (lo)
    dec l ; Track_Pattern_RowStatus
    .mixer_tick:
    ; hl points to Track_Pattern_RowStatus
    ; update effect
    ld de, Track_Effect_Kind - Track_Pattern_RowStatus
    add hl, de
    ld a, [hli] ; Track_Effect_Kind
    call EffectTick
    ; update envelope
    ld de, Track_Envelope_Phase - Track_Effect_Param
    add hl, de ; Track_Envelope_Phase
    call EnvelopeTick
    ld de, Track_SIZEOF - Track_Envelope_Phase
    add hl, de ; next track
    .next_track:
    inc b
    ld a, b
    cp a, NUM_TRACKS
    jp nz, .loop

    ; write to audio hw regs
    call RenderChannel1
    call RenderChannel2
    call RenderChannel3
    jp RenderChannel4

; HL = Track_Pattern_Ptr (lo)
IncPatternPtr:
    inc [hl] ; Track_Pattern_Ptr (lo)
    ret nz
    inc l ; Track_Pattern_Ptr (hi)
    inc [hl] ; Track_Pattern_Ptr (hi)
    dec l ; Track_Pattern_Ptr (lo)
    ret

RenderChannel1:
    ; NR11
    ld hl, wTracks + Track_Square_DutyCtrl
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $03
    ld a, [hl] ; Track_Square_DutyCtrl
    jr nz, .write_nr11 ; if counter is non-zero, use duty from bits 6-7
    ; use duty from bits 4-5
    sla a
    sla a
    .write_nr11:
    and $c0
    ldh [rNR11], a

    ; NR12
    ld hl, wTracks + Track_Envelope_Vol
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track_MasterVol
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track_PeriodIndex
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [hShadowNR12], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [rNR12], a
    jr .write_nr13
    .adjust_volume:
    ld b, a ; new volume
    ldh a, [hShadowNR12] ; old volume
    cp a, b
    jr z, .write_nr13 ; jump if no change in volume
    jr nc, .decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR12], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    .inc_volume_loop:
    ldh [rNR12], a
    dec b
    jr nz, .inc_volume_loop
    jr .write_nr13
    .decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR12], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    .dec_volume_loop:
    ldh [rNR12], a
    dec b
    jr nz, .dec_volume_loop
    .write_nr13:
    ldh a, [hSoundStatus]
    bit 0, a
    jr z, .not_muted
    ld a, $ff
    ldh [rNR13], a
    ld a, $7f
    ldh [rNR14], a
    jr .update_square_duty
    .not_muted:
    ; NR13
    ld hl, wTracks + Track_PeriodLo
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR13], a
    ; NR14
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR14], a

    .update_square_duty:
    ld hl, wTracks + Track_Square_DutyCtrl
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $03
    jr z, .skip_duty_update
    dec a ; decrement counter
    ld c, a
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $fc
    or a, c ; update counter
    ld [hl], a ; Track_Square_DutyCtrl
    .skip_duty_update:
    ret

RenderChannel3:
    ; NR32
    ld hl, wTracks + Track_Envelope_Vol + Track_SIZEOF*2
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track_MasterVol + Track_SIZEOF*2
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ldh [hShadowNR32], a
    swap a
    srl a ; volume in bits 6-5
    and a, $60
    jr z, .write_nr32 ; mute (no sound)
    bit 5, a
    jr z, .write_nr32 ; 50% volume
    xor a, $40 ; 100% or 25% volume
    .write_nr32:
    ldh [rNR32], a
    ldh a, [hSoundStatus]
    bit 2, a
    jr z, .not_muted
    ld a, $ff
    ldh [rNR33], a
    ld a, $7f
    ldh [rNR34], a
    ret
    .not_muted:
    ; NR33
    ld hl, wTracks + Track_PeriodLo + Track_SIZEOF*2
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR33], a
    ; NR34
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR34], a
    ret

RenderChannel2:
    ; NR21
    ld hl, wTracks + Track_Square_DutyCtrl + Track_SIZEOF
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $03
    ld a, [hl] ; Track_Square_DutyCtrl
    jr nz, .write_nr21 ; if counter is non-zero, use duty from bits 6-7
    ; use duty from bits 4-5
    sla a
    sla a
    .write_nr21:
    and $c0
    ldh [rNR21], a

    ; NR22
    ld hl, wTracks + Track_Envelope_Vol + Track_SIZEOF
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track_MasterVol + Track_SIZEOF
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track_PeriodIndex + Track_SIZEOF
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [hShadowNR22], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [rNR22], a
    jr .write_nr23
    .adjust_volume:
    ld b, a ; new volume
    ldh a, [hShadowNR22] ; old volume
    cp a, b
    jr z, .write_nr23 ; jump if no change in volume
    jr nc, .decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR22], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    .inc_volume_loop:
    ldh [rNR22], a
    dec b
    jr nz, .inc_volume_loop
    jr .write_nr23
    .decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR22], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    .dec_volume_loop:
    ldh [rNR22], a
    dec b
    jr nz, .dec_volume_loop
    .write_nr23:
    ldh a, [hSoundStatus]
    bit 1, a
    jr z, .not_muted
    ld a, $ff
    ldh [rNR23], a
    ld a, $7f
    ldh [rNR24], a
    jr .update_square_duty
    .not_muted:
    ; NR23
    ld hl, wTracks + Track_PeriodLo + Track_SIZEOF
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR23], a
    ; NR24
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR24], a

    .update_square_duty:
    ld hl, wTracks + Track_Square_DutyCtrl + Track_SIZEOF
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $03
    jr z, .skip_duty_update
    dec a ; decrement counter
    ld c, a
    ld a, [hl] ; Track_Square_DutyCtrl
    and a, $fc
    or a, c ; update counter
    ld [hl], a ; Track_Square_DutyCtrl
    .skip_duty_update:
    ret

RenderChannel4:
    ; NR42
    ld hl, wTracks + Track_Envelope_Vol + Track_SIZEOF*3
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    ld hl, wTracks + Track_MasterVol + Track_SIZEOF*3
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; envelope volume scaled according to track volume (0..F)
    ld b, a
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    ld hl, wTracks + Track_PeriodIndex + Track_SIZEOF*3
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .adjust_volume
    ; thanks to https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware
    ldh [hShadowNR42], a
    swap a ; initial channel volume in upper 4 bits
    or a, $8
    ldh [rNR42], a
    jr .write_nr43
    .adjust_volume:
    ld b, a ; new volume
    ldh a, [hShadowNR42] ; old volume
    cp a, b
    jr z, .write_nr43 ; jump if no change in volume
    jr nc, .decrease_volume ; old volume > new volume
    ; increase volume
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR42], a ; new volume
    sub a, c ; new volume - old volume
    ld b, a ; number of increments
    ld a, $8
    .inc_volume_loop:
    ldh [rNR42], a
    dec b
    jr nz, .inc_volume_loop
    jr .write_nr43
    .decrease_volume:
    ld c, a ; old volume
    ld a, b ; new volume
    ldh [hShadowNR42], a ; new volume
    sub a, c ; new volume - old volume
    add a, 16
    ld b, a ; number of increments
    ld a, $8
    .dec_volume_loop:
    ldh [rNR42], a
    dec b
    jr nz, .dec_volume_loop
    .write_nr43:
    ldh a, [hSoundStatus]
    bit 3, a
    jr z, .not_muted
    ld a, $ff
    ldh [rNR43], a
    ld a, $7f
    ldh [rNR44], a
    ret
    .not_muted:
    ; NR43
    ld hl, wTracks + Track_PeriodLo + Track_SIZEOF*3
    ld a, [hli] ; Track_PeriodLo
    ld c, a
    ld a, [hli] ; Track_PeriodHi
    sla c
    rla
    sla c
    rla
    sla c
    rla
    add a, LOW(NR43Values)
    ld e, a
    ld d, HIGH(NR43Values)
    ld a, [de]
    bit 7, [hl] ; Track_Square_DutyCtrl (LFSR width)
    jr z, .no_regular_output
    or a, 8 ; 1 = 7-bit
    .no_regular_output:
    ldh [rNR43], a
    ; NR44
    xor a, a
    dec l ; Track_PeriodHi
    dec l ; Track_PeriodLo
    dec l ; Track_PeriodIndex
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR44], a
    ret

GoPatternCommand:
    push de
    push hl
    rst JumpTable
dw .set_instr     ; 0
dw .release       ; 1
dw .set_speed     ; 2
dw .end_row       ; 3
dw .pan_left      ; 4
dw .pan_center    ; 5
dw .pan_right     ; 6

    .set_instr:
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; instrument
    inc de
    call IncPatternPtr
    call SetInstrument
    scf ; CF=1 signals keep processing pattern data
    ret

    .release:
    pop hl ; Track_Pattern_Ptr (lo)
    push hl
    ld de, Track_Envelope_Hold - Track_Pattern_Ptr
    add hl, de
    ld a, 1
    ld [hl], a ; Track_Envelope_Hold
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .set_speed:
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; new speed
    inc de
    call IncPatternPtr
    call SetSpeed
    scf ; CF=1 signals keep processing pattern data
    ret

    .end_row: ; this command is used when there is no note for the row, only commands
    pop hl ; Track_Pattern_Ptr (lo)
    push hl
    ld de, Track_MasterVol - Track_Pattern_Ptr
    add hl, de
    ld a, [hl] ; Track_MasterVol
    and $fe
    ld [hl], a ; Track_MasterVol
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf
    ccf ; CF=0 signals end of pattern data processing
    ret

    .pan_left:
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_track_0_left
    dec a
    jr z, .pan_track_1_left
    dec a
    jr z, .pan_track_2_left
    ; pan track 3 left
    res 3, [hl]
    set 7, [hl]
    jr .done_panning
    .pan_track_0_left:
    res 0, [hl]
    set 4, [hl]
    jr .done_panning
    .pan_track_1_left:
    res 1, [hl]
    set 5, [hl]
    jr .done_panning
    .pan_track_2_left:
    res 2, [hl]
    set 6, [hl]
    .done_panning:
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    scf ; CF=1 signals keep processing pattern data
    ret

    .pan_center:
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_track_0_center
    dec a
    jr z, .pan_track_1_center
    dec a
    jr z, .pan_track_2_center
    ; pan track 3 center
    set 3, [hl]
    set 7, [hl]
    jr .done_panning
    .pan_track_0_center:
    set 0, [hl]
    set 4, [hl]
    jr .done_panning
    .pan_track_1_center:
    set 1, [hl]
    set 5, [hl]
    jr .done_panning
    .pan_track_2_center:
    set 2, [hl]
    set 6, [hl]
    jr .done_panning

    .pan_right:
    ld hl, rAUDTERM
    ld a, b
    or a
    jr z, .pan_track_0_right
    dec a
    jr z, .pan_track_1_right
    dec a
    jr z, .pan_track_2_right
    ; pan track 3 right
    res 7, [hl]
    set 3, [hl]
    jr .done_panning
    .pan_track_0_right:
    res 4, [hl]
    set 0, [hl]
    jr .done_panning
    .pan_track_1_right:
    res 5, [hl]
    set 1, [hl]
    jr .done_panning
    .pan_track_2_right:
    res 6, [hl]
    set 2, [hl]
    jr .done_panning

; A = instrument
; preserves DE and HL
SetInstrument:
    push de
    push hl ; Track_Pattern_Ptr (lo)
    sla a
    sla a
    sla a ; each instrument is 8 bytes long
    ld c, a
    ldh a, [hInstrumentTable]
    add a, c
    ld e, a
    ldh a, [hInstrumentTable+1]
    adc a, 0
    ld d, a
    ld a, l
    add a, Track_Envelope_Ptr - Track_Pattern_Ptr
    ld l, a
    ld a, [de] ; 0 - envelope lo
    inc de
    ld [hli], a ; Track_Envelope_Ptr (lo)
    ld a, [de] ; 1 - envelope hi
    inc de
    ld [hl], a ; Track_Envelope_Ptr (hi)
    ld a, l
    sub a, Track_Envelope_Ptr+1 - Track_Effect_Kind
    ld l, a
    inc de ; 2 - unused
    ld a, [de] ; 3 - effect kind
    inc de
    ld [hli], a ; Track_Effect_Kind
    ld a, [de] ; 4 - effect param
    inc de
    ld [hl], a ; Track_Effect_Param
    ld a, l
    add a, Track_Square_DutyCtrl - Track_Effect_Param
    ld l, a
    ld a, [de] ; 5 - duty
    ld [hl], a ; Track_Square_DutyCtrl
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ret

; A = new speed
; preserves DE and HL
SetSpeed:
    push de
    push hl
    ld hl, wTracks + Track_Speed
    ld de, Track_SIZEOF
    ld [hl], a ; Track_Speed
    add hl, de
    ld [hl], a ; Track_Speed
    add hl, de
    ld [hl], a ; Track_Speed
    add hl, de
    ld [hl], a ; Track_Speed
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ret

; A = effect kind, HL = Track_Effect_Param
EffectTick:
    push hl ; Track_Effect_Param
    rst JumpTable
dw .null_tick         ; 0
dw .slide_up_tick     ; 1
dw .slide_down_tick   ; 2
dw .portamento_tick   ; 3
dw .vibrato_tick      ; 4
dw .arpeggio_tick     ; 5
dw .volume_slide_tick ; 6
dw .tremolo_tick      ; 7
dw .cut_tick          ; 8
dw .pulsemod_tick     ; 9

    .null_tick:
    pop hl ; Track_Effect_Param
    ret

    .slide_up_tick:
; slide up by adding slide amount to period value
    pop hl ; Track_Effect_Param
    push hl
    ld a, [hl] ; Track_Effect_Param
    ld c, a
    ld a, l ; Track_Effect_Param
    add a, Track_PeriodLo - Track_Effect_Param
    ld l, a
    ld a, [hl] ; Track_PeriodLo
    add a, c
    ld [hli], a ; Track_PeriodLo
    jr nc, .slide_skip_inc
    inc [hl] ; Track_PeriodHi
    .slide_skip_inc:
    pop hl ; Track_Effect_Param
    ret

    .slide_down_tick:
; slide up by subtracting slide amount from period value
    pop hl ; Track_Effect_Param
    push hl
    ld a, [hl] ; Track_Effect_Param
    ld c, a
    ld a, l ; Track_Effect_Param
    add a, Track_PeriodLo - Track_Effect_Param
    ld l, a
    ld a, [hl] ; Track_PeriodLo
    sub a, c
    ld [hli], a ; Track_PeriodLo
    jr nc, .slide_skip_dec
    dec [hl] ; Track_PeriodHi
    .slide_skip_dec:
    pop hl ; Track_Effect_Param
    ret

    .portamento_tick:
    pop hl ; Track_Effect_Param
    push hl
    ld a, [hli] ; Track_Effect_Param
    ld c, a
    ld a, [hli] ; Track_Effect_Portamento_Ctrl
    bit 7, a
    jr z, .portamento_exit
    srl a ; CF = direction (0=down, 1=up)
    ld a, [hli] ; Track_Effect_Portamento_TargetPeriodLo
    ld e, a ; save target period lo
    ld a, [hli] ; Track_Effect_Portamento_TargetPeriodHi
    ld d, a
    inc l ; Track_PeriodIndex
    inc l ; Track_PeriodLo
    ld a, [hl] ; Track_PeriodLo
    jr nc, .portamento_down
    ; slide up (add delta to current period value)
    add a, c
    ld [hli], a ; Track_PeriodLo
    ld a, [hl] ; Track_PeriodHi
    adc a, 0
    ld [hl-], a ; Track_PeriodHi
    ld c, a ; save periodhi
    ; check if target period has been reached (current period >= target period)
    ld a, [hl] ; Track_PeriodLo
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_done
    .portamento_exit:
    pop hl ; Track_Effect_Param
    ret
    .portamento_down:
    ; slide down (subtract delta from current period value)
    sub a, c
    ld [hli], a ; Track_PeriodLo
    ld a, [hl] ; Track_PeriodHi
    sbc a, 0
    ld [hl-], a ; Track_PeriodHi
    ld c, a ; save periodhi
    ; check if target period has been reached (current period <= target period)
    ld a, [hl] ; Track_PeriodLo
    sub a, e ; subtract targetperiodlo
    ld a, c ; periodhi
    sbc a, d ; subtract targetperiodhi
    jr nc, .portamento_exit
    .portamento_done:
    ; set final period
    ld a, e
    ld [hli], a ; Track_PeriodLo
    ld a, d
    ld [hl], a ; Track_PeriodHi
    ; halt
    pop hl ; Track_Effect_Param
    inc l ; Track_Effect_Portamento_Ctrl
    xor a, a
    ld [hl-], a ; Track_Effect_Portamento_Ctrl
    ret

    .vibrato_tick:
    pop hl ; Track_Effect_Param
    push hl
    ; reset period value
    ld a, l
    add a, Track_PeriodIndex - Track_Effect_Param
    ld l, a
    ld a, [hli] ; Track_PeriodIndex
    add a, a ; note * 2
    add a, LOW(PeriodTable)
    ld e, a
    ld d, HIGH(PeriodTable)
    ld a, [de]
    ld [hli], a ; Track_PeriodLo
    inc de
    ld a, [de]
    ld [hl], a ; Track_PeriodHi
    pop hl ; Track_Effect_Param
    inc l ; Track_Effect_Pos
    ; get sine value
    ld a, [hl-] ; Track_Effect_Pos
    and a, $1f
    ld de, VibratoTable
    add a, e
    ld e, a
    ld a, [de] ; sine value
    ld c, a
    ; *** convert sine value to real delta freq, according to vibrato depth ***
    ld a, [hli] ; Track_Effect_Param
    and a, $0f ; VibratoDepth in lower 4 bits
    ld e, a
    ld d, 0
    xor a, a
    ; this loop performs SineValue*VibratoDepth, putting result in DA
    .loop:
    add a, c
    jr nc, .skip_inc
    inc d
    .skip_inc:
    dec e
    jr nz, .loop
    ; compute (SineValue*VibratoDepth)/128
    sla a
    ld a, d
    rla
    ld c, a
    ld a, [hl] ; Track_Effect_Pos
    push hl
    and a, $20
    jr z, .vib_add
    ; subtract c from period
    ld a, l
    add a, Track_PeriodLo - Track_Effect_Pos
    ld l, a
    ld a, [hl] ; Track_PeriodLo
    sub a, c
    ld [hli], a ; Track_PeriodLo
    jr nc, .vib_done
    dec [hl] ; Track_PeriodHi
    jr .vib_done
    .vib_add:
    ; add c to period
    ld a, l
    add a, Track_PeriodLo - Track_Effect_Pos
    ld l, a
    ld a, [hl] ; Track_PeriodLo
    add a, c
    ld [hli], a ; Track_PeriodLo
    jr nc, .vib_done
    inc [hl] ; Track_PeriodHi
    .vib_done:
    ; increment pos
    pop hl ; Track_Effect_Pos
    ld a, [hl-] ; Track_Effect_Pos
    ld c, a
    ld a, [hli] ; Track_Effect_Param
    swap a
    and a, $f ; vibrato speed
    add a, c
    ld [hl-], a ; Track_Effect_Pos
    ret

    .arpeggio_tick:
    pop hl ; Track_Effect_Param
    push hl
    ld a, [hli] ; Track_Effect_Param
    ld c, a
    ld a, [hl] ; Track_Effect_Pos
    ld d, a
    inc a
    cp a, 6
    jr c, .skip
    xor a, a
    .skip:
    ld [hli], a ; Track_Effect_Pos
    inc l ; Track_Effect_VibratoCounter
    inc l ; Track_Effect_MasterVol
    inc l ; Track_PeriodIndex
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
    add a, [hl] ; Track_PeriodIndex
    inc l
    add a, a ; note * 2
    add a, LOW(PeriodTable)
    ld e, a
    ld d, HIGH(PeriodTable)
    ld a, [de]
    ld [hli], a ; Track_PeriodLo
    inc de
    ld a, [de]
    ld [hl], a ; Track_PeriodHi
    pop hl ; Track_Effect_Param
    ret

    .volume_slide_tick:
    pop hl ; Track_Effect_Param
    ld a, [hl] ; Track_Effect_Param
    cp a, $10
    jr c, .sub_volume
    ; add to volume
    swap a
    and a, $f
    sla a
    sla a ; delta * 4
    ld c, a
    push hl ; Track_Effect_Param
    ld de, Track_MasterVol - Track_Effect_Param
    add hl, de
    ld a, [hl] ; Track_MasterVol
    add a, c
    jr nc, .set_volume
    ld a, $fc ; max volume
    jr .set_volume
    .sub_volume:
    sla a
    sla a ; delta * 4
    ld c, a
    push hl ; Track_Effect_Param
    ld de, Track_MasterVol - Track_Effect_Param
    add hl, de
    ld a, [hl] ; Track_MasterVol
    sub a, c
    jr nc, .set_volume
    xor a, a
    .set_volume:
    ld [hl], a ; Track_MasterVol
    pop hl ; Track_Effect_Param
    ret

    .tremolo_tick:
    pop hl ; Track_Effect_Param
    ; TODO: implement tremolo
    ret

    .cut_tick:
    pop hl ; Track_Effect_Param
    ld a, [hli] ; Track_Effect_Param
    ld c, a
    ld a, [hl] ; Track_Effect_Pos
    cp a, c
    inc a
    ld [hl-], a ; Track_Effect_Pos
    ret c
    ; cut! (set volume to 0)
    push hl ; Track_Effect_Param
    ld a, l ; Track_Effect_Param
    add a, Track_MasterVol - Track_Effect_Param
    ld l, a ; Track_MasterVol
    xor a, a
    ld [hl], a ; Track_MasterVol
    pop hl ; Track_Effect_Param
    ret

    .pulsemod_tick:
    pop hl ; Track_Effect_Param
    ; TODO: implement pulsemod
    ret

; HL = Track_Envelope_Phase
EnvelopeTick:
    ld a, [hl] ; Track_Envelope_Phase
    rla
    jr c, .init    ; $80
    rla
    jr c, .process ; $40
    rla
    jr c, .sustain ; $20
    ret

    .init:
    push hl ; Track_Envelope_Phase
    srl [hl] ; Track_Envelope_Phase = $40
    inc l ; Track_Envelope_Ptr (lo)
    ld a, [hli] ; Track_Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Track_Envelope_Ptr (hi)
    ld d, a
    xor a, a
    ld [hl], a ; Track_Envelope_Pos = 0
    .init_vol:
    ; HL = Track_Envelope_Pos
    ld a, [de] ; 1st byte = start volume
    inc de
    inc [hl] ; Track_Envelope_Pos
    inc l ; Track_Envelope_Vol
    ld [hli], a ; Track_Envelope_Vol
    .point_init:
    ; HL = Track_Envelope_Step
    ld a, [de] ; fetch envelope byte
    inc de
    cp a, $ff ; end of envelope reached?
    jr z, .env_end
    ; point OK, set 3-tuple (step, dest, hold)
    ld [hli], a ; Track_Envelope_Step
    ld a, [de]
    inc de
    ld [hli], a ; Track_Envelope_Dest
    ld a, [de]
    inc de
    ld [hl], a ; Track_Envelope_Hold
    ld a, l
    sub a, Track_Envelope_Hold - Track_Envelope_Pos
    ld l, a
    inc [hl] ; Track_Envelope_Pos
    inc [hl] ; Track_Envelope_Pos
    inc [hl] ; Track_Envelope_Pos
    pop hl ; Track_Envelope_Phase
    jr .process
    .env_end:
    ld a, [de]
    cp a, $ff ; definitely end?
    jr z, .env_stop
    ; loop the envelope from the given offset
    ld c, a
    ld a, l
    sub a, Track_Envelope_Step - Track_Envelope_Ptr
    ld l, a
    ld a, [hli] ; Track_Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Track_Envelope_Ptr (hi)
    ld d, a
    ld a, c
    ld [hli], a ; Track_Envelope_Pos
    inc l ; Track_Envelope_Step
    add a, e
    ld e, a
    jr nc, .point_init
    inc d
    jr .point_init
    .env_stop:
    pop hl ; Track_Envelope_Phase
    xor a, a
    ld [hl], a ; Track_Envelope_Phase
    ret

    .sustain:
    push hl ; Track_Envelope_Phase
    sla [hl] ; Track_Envelope_Phase = process (speculative)
    ld a, l
    add a, Track_Envelope_Hold - Track_Envelope_Phase
    ld l, a
    ld a, [hl] ; Track_Envelope_Hold
    cp a, $ff ; hold forever?
    jr z, .keep_sustaining
    dec [hl] ; Track_Envelope_Hold -= 1
    jr nz, .keep_sustaining
    jr .next_point
    .keep_sustaining:
    pop hl ; Track_Envelope_Phase
    srl [hl] ; Track_Envelope_Phase = sustain
    ret

    .process:
    push hl ; Track_Envelope_Phase
    ld a, l
    add a, Track_Envelope_Vol - Track_Envelope_Phase
    ld l, a
    ld a, [hli] ; Track_Envelope_Vol
    push af ; save vol
    ld a, [hli] ; Track_Envelope_Step
    ld c, a ; save step
    pop af ; vol
    cp a, [hl] ; Track_Envelope_Dest > Vol?
    jr nc, .sub_volume
    ; add step to vol
    add a, c
    jr c, .reached_dest
    cp a, [hl] ; Track_Envelope_Dest > new vol?
    jr z, .reached_dest
    jr nc, .reached_dest
    dec l ; Track_Envelope_Step
    dec l ; Track_Envelope_Vol
    ld [hl], a ; Track_Envelope_Vol
    pop hl ; Track_Envelope_Phase
    ret
    .sub_volume:
    ; subtract step from volume
    sub a, c
    jr c, .reached_dest
    cp a, [hl] ; Track_Envelope_Dest > new vol?
    jr z, .reached_dest
    jr c, .reached_dest
    dec l ; Track_Envelope_Step
    dec l ; Track_Envelope_Vol
    ld [hl], a ; Track_Envelope_Vol
    pop hl ; Track_Envelope_Phase
    ret
    .reached_dest:
    ld a, [hl-] ; Track_Envelope_Dest
    dec l ; Track_Envelope_Vol
    ld [hli], a ; Track_Envelope_Vol = dest
    inc l ; Track_Envelope_Dest
    inc l ; Track_Envelope_Hold
    ld a, [hl] ; Track_Envelope_Hold
    or a, a
    jr z, .next_point
    pop hl ; Track_Envelope_Phase
    srl [hl] ; phase = sustain
    ret
    .next_point:
    ; HL = Track_Envelope_Hold
    ld a, l ; Track_Envelope_Hold
    sub a, Track_Envelope_Hold - Track_Envelope_Ptr
    ld l, a
    ld a, [hli] ; Track_Envelope_Ptr (lo)
    ld e, a
    ld a, [hli] ; Track_Envelope_Ptr (hi)
    ld d, a
    ld a, [hli] ; Track_Envelope_Pos
    add a, e
    ld e, a
    jr nc, .skip_inc
    inc d
    .skip_inc:
    inc l ; Track_Envelope_Step
    jp .point_init

MACRO Align256
ds ((@ + $ff) & $ff00) - @
ENDM

        Align256
VolumeTable:
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00      ; MasterVol = 0
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01      ; 1
db $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02      ; 2
db $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03      ; 3
db $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$04      ; ..
db $00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05
db $00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06
db $00,$00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07
db $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$08
db $00,$00,$01,$01,$02,$03,$03,$04,$04,$05,$06,$06,$07,$07,$08,$09
db $00,$00,$01,$02,$02,$03,$04,$04,$05,$06,$06,$07,$08,$08,$09,$0A
db $00,$00,$01,$02,$02,$03,$04,$05,$05,$06,$07,$08,$08,$09,$0A,$0B
db $00,$00,$01,$02,$03,$04,$04,$05,$06,$07,$08,$08,$09,$0A,$0B,$0C
db $00,$00,$01,$02,$03,$04,$05,$06,$06,$07,$08,$09,$0A,$0B,$0C,$0D
db $00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F

NR43Values:
db $f7,$f3,$e5,$d7,$e3,$d5,$e2,$c7 ; 0-7
db $d3,$c5,$d2,$b7,$b6,$b5,$d1,$a7 ; 8-15
db $a6,$a5,$c1,$97,$a3,$95,$a2,$87 ; 16-23
db $86,$85,$92,$77,$76,$75,$74,$67 ; 24-31
db $66,$65,$81,$57,$63,$55,$71,$47 ; 32-39
db $53,$45,$52,$37,$43,$35,$60,$27 ; 40-47
db $33,$25,$41,$17,$16,$15,$14,$07 ; 48-55
db $13,$05,$04,$03,$02,$01,$00,$00 ; 56-63

; ProTracker sine table
VibratoTable:
db $00,$18,$31,$4A,$61,$78,$8D,$A1
db $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
db $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
db $B4,$A1,$8D,$78,$61,$4A,$31,$18

PeriodTable:
dw $02d,$09d,$107,$16b,$1ca,$223,$277,$2c7,$312,$359,$39c,$3db ; 0-11
dw $417,$44f,$484,$4b6,$4e5,$512,$53c,$564,$589,$5ad,$5ce,$5ee ; 12-23
dw $60c,$628,$642,$65b,$673,$689,$69e,$6b2,$6c5,$6d7,$6e7,$6f7 ; 24-35
dw $706,$714,$721,$72e,$73a,$745,$74f,$759,$763,$76c,$774,$77c ; 36-47
dw $783,$78a,$791,$797,$79d,$7a3,$7a8,$7ad,$7b2,$7b6,$7ba,$7be ; 48-59
dw $7c2,$7c5,$7c9,$7cc,$7cf,$7d2,$7d4,$7d7,$7d9,$7db,$7dd,$7df ; 60-71

DefaultWavRam:
db $11, $11, $11, $11
db $88, $88, $88, $88
db $cc, $cc, $ff, $ff
db $ff, $ff, $ff, $ff

; --- End sound engine ---

; --- Sound data

INCLUDE "duelsong.s"
INCLUDE "drawsong.s"
INCLUDE "drewsong.s"
INCLUDE "shootsong.s"
INCLUDE "youdiesong.s"
INCLUDE "youwinsong.s"
INCLUDE "silentsong.s"

; --- Program-specific code: Our game starts here! ---

Genesis:
    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

.InfiniteLoop:
    halt
    jp .InfiniteLoop

QuickTimeEventButtons:
db PADF_A              ; 0
db PADF_B              ; 1
db PADF_RIGHT          ; 2
db PADF_LEFT           ; 3
db PADF_UP             ; 4
db PADF_DOWN           ; 5
db PADF_A | PADF_B     ; 6
db PADF_A | PADF_RIGHT ; 7
db PADF_A | PADF_LEFT  ; 8
db PADF_A | PADF_UP    ; 9
db PADF_A | PADF_DOWN  ; 10
db PADF_B | PADF_RIGHT ; 11
db PADF_B | PADF_LEFT  ; 12
db PADF_B | PADF_UP    ; 13
db PADF_B | PADF_DOWN  ; 14
db PADF_A | PADF_B | PADF_RIGHT ; 15
db PADF_A | PADF_B | PADF_LEFT ; 16
db PADF_A | PADF_B | PADF_UP ; 17
db PADF_A | PADF_B | PADF_DOWN ; 18

def MAX_QUICK_TIME_EVENT_KIND equ 18

QuickTimeValidSuccessorEvents:
dw QTE_A_ValidSuccessorEvents           ; 0
dw QTE_B_ValidSuccessorEvents           ; 1
dw QTE_Right_ValidSuccessorEvents       ; 2
dw QTE_Left_ValidSuccessorEvents        ; 3
dw QTE_Up_ValidSuccessorEvents          ; 4
dw QTE_Down_ValidSuccessorEvents        ; 5
dw QTE_A_B_ValidSuccessorEvents         ; 6
dw QTE_A_Right_ValidSuccessorEvents     ; 7
dw QTE_A_Left_ValidSuccessorEvents      ; 8
dw QTE_A_Up_ValidSuccessorEvents        ; 9
dw QTE_A_Down_ValidSuccessorEvents      ; 10
dw QTE_B_Right_ValidSuccessorEvents     ; 11
dw QTE_B_Left_ValidSuccessorEvents      ; 12
dw QTE_B_Up_ValidSuccessorEvents        ; 13
dw QTE_B_Down_ValidSuccessorEvents      ; 14
dw QTE_A_B_Right_ValidSuccessorEvents   ; 15
dw QTE_A_B_Left_ValidSuccessorEvents    ; 16
dw QTE_A_B_Up_ValidSuccessorEvents      ; 17
dw QTE_A_B_Down_ValidSuccessorEvents    ; 18

QTE_A_ValidSuccessorEvents:
db 9 ; count
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 3 ; PAD_LEFT
db 4 ; PAD_UP
db 5 ; PAD_DOWN
db 11 ; PADF_B | PADF_RIGHT
db 12 ; PADF_B | PADF_LEFT
db 13 ; PADF_B | PADF_UP
db 14 ; PADF_B | PADF_DOWN

QTE_B_ValidSuccessorEvents:
db 9 ; count
db 0 ; PADF_A
db 2 ; PADF_RIGHT
db 3 ; PAD_LEFT
db 4 ; PAD_UP
db 5 ; PAD_DOWN
db 7 ; PADF_A | PADF_RIGHT
db 8 ; PADF_A | PADF_LEFT
db 9 ; PADF_A | PADF_UP
db 10 ; PADF_A | PADF_DOWN

QTE_Right_ValidSuccessorEvents:
db 15 ; count
db 0 ; PADF_A
db 1 ; PADF_B
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 6 ; PADF_A | PADF_B
db 8 ; PADF_A | PADF_LEFT
db 9 ; PADF_A | PADF_UP
db 10 ; PADF_A | PADF_DOWN
db 12 ; PADF_B | PADF_LEFT
db 13 ; PADF_B | PADF_UP
db 14 ; PADF_B | PADF_DOWN
db 16 ; PADF_A | PADF_B | PADF_LEFT
db 17 ; PADF_A | PADF_B | PADF_UP
db 18 ; PADF_A | PADF_B | PADF_DOWN

QTE_Left_ValidSuccessorEvents:
db 15
db 0 ; PADF_A
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 6 ; PADF_A | PADF_B
db 7 ; PADF_A | PADF_RIGHT
db 9 ; PADF_A | PADF_UP
db 10 ; PADF_A | PADF_DOWN
db 11 ; PADF_B | PADF_RIGHT
db 13 ; PADF_B | PADF_UP
db 14 ; PADF_B | PADF_DOWN
db 15 ; PADF_A | PADF_B | PADF_RIGHT
db 17 ; PADF_A | PADF_B | PADF_UP
db 18 ; PADF_A | PADF_B | PADF_DOWN

QTE_Up_ValidSuccessorEvents:
db 15 ; count
db 0 ; PADF_A
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 5 ; PADF_DOWN
db 6 ; PADF_A | PADF_B
db 7 ; PADF_A | PADF_RIGHT
db 8 ; PADF_A | PADF_LEFT
db 10 ; PADF_A | PADF_DOWN
db 11 ; PADF_B | PADF_RIGHT
db 12 ; PADF_B | PADF_LEFT
db 14 ; PADF_B | PADF_DOWN
db 15 ; PADF_A | PADF_B | PADF_RIGHT
db 16 ; PADF_A | PADF_B | PADF_LEFT
db 18 ; PADF_A | PADF_B | PADF_DOWN

QTE_Down_ValidSuccessorEvents:
db 15 ; count
db 0 ; PADF_A
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 6 ; PADF_A | PADF_B
db 7 ; PADF_A | PADF_RIGHT
db 8 ; PADF_A | PADF_LEFT
db 9 ; PADF_A | PADF_UP
db 11 ; PADF_B | PADF_RIGHT
db 12 ; PADF_B | PADF_LEFT
db 13 ; PADF_B | PADF_UP
db 15 ; PADF_A | PADF_B | PADF_RIGHT
db 16 ; PADF_A | PADF_B | PADF_LEFT
db 17 ; PADF_A | PADF_B | PADF_UP

QTE_A_B_ValidSuccessorEvents:
db 4 ; count
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 5 ; PADF_DOWN

QTE_A_Right_ValidSuccessorEvents:
db 7 ; count
db 1 ; PADF_B
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 12 ; PADF_B | PADF_LEFT
db 13 ; PADF_B | PADF_UP
db 14 ; PADF_B | PADF_DOWN

QTE_A_Left_ValidSuccessorEvents:
db 7 ; count
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 11 ; PADF_B | PADF_RIGHT
db 13 ; PADF_B | PADF_UP
db 14 ; PADF_B | PADF_DOWN

QTE_A_Up_ValidSuccessorEvents:
db 7 ; count
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 5 ; PADF_DOWN
db 11 ; PADF_B | PADF_RIGHT
db 12 ; PADF_B | PADF_LEFT
db 14 ; PADF_B | PADF_DOWN

QTE_A_Down_ValidSuccessorEvents:
db 7 ; count
db 1 ; PADF_B
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 11 ; PADF_B | PADF_RIGHT
db 12 ; PADF_B | PADF_LEFT
db 13 ; PADF_B | PADF_UP

QTE_B_Right_ValidSuccessorEvents:
db 7 ; count
db 0 ; PADF_A
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 8 ; PADF_A | PADF_LEFT
db 9 ; PADF_A | PADF_UP
db 10 ; PADF_A | PADF_DOWN

QTE_B_Left_ValidSuccessorEvents:
db 7 ; count
db 0 ; PADF_A
db 2 ; PADF_RIGHT
db 4 ; PADF_UP
db 5 ; PADF_DOWN
db 7 ; PADF_A | PADF_RIGHT
db 9 ; PADF_A | PADF_UP
db 10 ; PADF_A | PADF_DOWN

QTE_B_Up_ValidSuccessorEvents:
db 7 ; count
db 0 ; PADF_A
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 5 ; PADF_DOWN
db 7 ; PADF_A | PADF_RIGHT
db 8 ; PADF_A | PADF_LEFT
db 10 ; PADF_A | PADF_DOWN

QTE_B_Down_ValidSuccessorEvents:
db 7 ; count
db 0 ; PADF_A
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 7 ; PADF_A | PADF_RIGHT
db 8 ; PADF_A | PADF_LEFT
db 9 ; PADF_A | PADF_UP

QTE_A_B_Right_ValidSuccessorEvents:
db 3 ; count
db 3 ; PADF_LEFT
db 4 ; PADF_UP
db 5 ; PADF_DOWN

QTE_A_B_Left_ValidSuccessorEvents:
db 3 ; count
db 2 ; PADF_RIGHT
db 4 ; PADF_UP
db 5 ; PADF_DOWN

QTE_A_B_Up_ValidSuccessorEvents:
db 3 ; count
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 5 ; PADF_DOWN

QTE_A_B_Down_ValidSuccessorEvents:
db 3 ; count
db 2 ; PADF_RIGHT
db 3 ; PADF_LEFT
db 4 ; PADF_UP


; A = high timer value
; DE = timeout callback
; destroys A
SetTimer:
    ldh [hTimerHi], a
    ld a, TIMER_SPEED
    ldh [hTimerLo], a
    ld a, e
    ldh [hTimerCallback], a
    ld a, d
    ldh [hTimerCallback+1], a
    ret

; A = high timer value
; B = next main state
; destroys A, D, E
SetTimerWithNextStateTimeout:
    ld de, MainFunc6_TimerTimeout
    call SetTimer
    ld a, b
    ldh [hNextMainState], a
    ld a, 6
    ldh [hMainState], a ; delay
    ret

TickTimer:
    ldh a, [hTimerLo]
    dec a
    jr nz, .noTimeoutLo
    ldh a, [hTimerHi]
    dec a
    jr nz, .noTimeoutHi
    ld a, [hTimerCallback]
    ld l, a
    ld a, [hTimerCallback+1]
    ld h, a
    jp hl
    .noTimeoutHi:
    ldh [hTimerHi], a
    ld a, TIMER_SPEED
    ldh [hTimerLo], a
    ret
    .noTimeoutLo:
    ldh [hTimerLo], a
    ret

; DE = source address
; BC = count
; HL = destination address
CopyData:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jr nz, CopyData
    ret

; HL = destination address
; BC = count
; E = value
SetMemory:
    ld a, e
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jr nz, SetMemory
    ret

PrintWantedPosterSum:
    ld a, [hCurrentLevel]
    cp a, MAX_LEVEL
    jr c, .noClamp
    ld a, MAX_LEVEL - 1
    .noClamp:
    sla a
    ld e, a
    ld d, 0
    ld hl, .WantedPosterSumStrings
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ld a, [de]
    push de
    ld c, a
    ld de, $99cd
    call BeginVramString
    pop de
    push de
    inc de
    ld b, 0
    call CopyData
    call EndVramString
    pop de
    ld a, [de]
    push de
    ld c, a
    ld de, $99ed
    call BeginVramString
    pop de
.CopyData:
    inc de
    ld a, [de]
    add a, 11
    ld [hli], a
    dec c
    jr nz, .CopyData
    jp EndVramString

NEWCHARMAP bucks
CHARMAP " ", $00
CHARMAP "1", $a9
CHARMAP "2", $aa
CHARMAP "3", $ab
CHARMAP "4", $ac
CHARMAP "5", $ad
CHARMAP "6", $ae
CHARMAP "7", $af
CHARMAP "8", $b0
CHARMAP "9", $b1
CHARMAP "0", $b2
setcharmap bucks

.WantedPosterSumStrings:
dw .WantedPosterSumString0  
dw .WantedPosterSumString1  
dw .WantedPosterSumString2  
dw .WantedPosterSumString3  
dw .WantedPosterSumString4  
dw .WantedPosterSumString5  
dw .WantedPosterSumString6  
dw .WantedPosterSumString7  
dw .WantedPosterSumString8  
dw .WantedPosterSumString9  
dw .WantedPosterSumString10  
dw .WantedPosterSumString11  
dw .WantedPosterSumString12  
dw .WantedPosterSumString13  
dw .WantedPosterSumString14  
dw .WantedPosterSumString15  
dw .WantedPosterSumString16  
dw .WantedPosterSumString17  
dw .WantedPosterSumString18  
dw .WantedPosterSumString19  
dw .WantedPosterSumString20  
dw .WantedPosterSumString21  
dw .WantedPosterSumString22  
dw .WantedPosterSumString23  
dw .WantedPosterSumString24  
dw .WantedPosterSumString25  
dw .WantedPosterSumString26  
dw .WantedPosterSumString27  
dw .WantedPosterSumString28  
dw .WantedPosterSumString29  
dw .WantedPosterSumString30  
dw .WantedPosterSumString31  
dw .WantedPosterSumString32  
dw .WantedPosterSumString33  
dw .WantedPosterSumString34  
dw .WantedPosterSumString35  
dw .WantedPosterSumString36  
dw .WantedPosterSumString37  
dw .WantedPosterSumString38  
dw .WantedPosterSumString39  
dw .WantedPosterSumString40  
dw .WantedPosterSumString41  
dw .WantedPosterSumString42  
dw .WantedPosterSumString43  
dw .WantedPosterSumString44  
dw .WantedPosterSumString45  
dw .WantedPosterSumString46  
dw .WantedPosterSumString47  
dw .WantedPosterSumString48  
dw .WantedPosterSumString49  
.WantedPosterSumString0:
db 1, "1"
.WantedPosterSumString1:
db 1, "2"
.WantedPosterSumString2:
db 1, "5"
.WantedPosterSumString3:
db 2, "10"
.WantedPosterSumString4:
db 2, "25"
.WantedPosterSumString5:
db 2, "50"
.WantedPosterSumString6:
db 2, "75"
.WantedPosterSumString7:
db 3, "100"
.WantedPosterSumString8:
db 3, "150"
.WantedPosterSumString9:
db 3, "200"
.WantedPosterSumString10:
db 3, "300"
.WantedPosterSumString11:
db 3, "400"
.WantedPosterSumString12:
db 3, "500"
.WantedPosterSumString13:
db 3, "600"
.WantedPosterSumString14:
db 3, "750"
.WantedPosterSumString15:
db 3, "900"
.WantedPosterSumString16:
db 4, "1000"
.WantedPosterSumString17:
db 4, "1200"
.WantedPosterSumString18:
db 4, "1400"
.WantedPosterSumString19:
db 4, "1600"
.WantedPosterSumString20:
db 4, "1800"
.WantedPosterSumString21:
db 4, "2000"
.WantedPosterSumString22:
db 4, "2250"
.WantedPosterSumString23:
db 4, "2500"
.WantedPosterSumString24:
db 4, "2750"
.WantedPosterSumString25:
db 4, "3000"
.WantedPosterSumString26:
db 4, "3250"
.WantedPosterSumString27:
db 4, "3500"
.WantedPosterSumString28:
db 4, "3750"
.WantedPosterSumString29:
db 4, "4000"
.WantedPosterSumString30:
db 4, "4250"
.WantedPosterSumString31:
db 4, "4500"
.WantedPosterSumString32:
db 4, "4750"
.WantedPosterSumString33:
db 4, "5000"
.WantedPosterSumString34:
db 4, "5250"
.WantedPosterSumString35:
db 4, "5500"
.WantedPosterSumString36:
db 4, "5750"
.WantedPosterSumString37:
db 4, "6000"
.WantedPosterSumString38:
db 4, "6500"
.WantedPosterSumString39:
db 4, "7000"
.WantedPosterSumString40:
db 4, "7500"
.WantedPosterSumString41:
db 4, "8000"
.WantedPosterSumString42:
db 4, "8200"
.WantedPosterSumString43:
db 4, "8400"
.WantedPosterSumString44:
db 4, "8600"
.WantedPosterSumString45:
db 4, "8800"
.WantedPosterSumString46:
db 4, "9000"
.WantedPosterSumString47:
db 4, "9100"
.WantedPosterSumString48:
db 4, "9300"
.WantedPosterSumString49:
db 4, "9500"

PrintWantedPosterName:
    ld a, [hCurrentLevel]
    cp a, MAX_LEVEL
    jr c, .noClamp
    ld a, MAX_LEVEL - 1
    .noClamp:
    sla a
    ld e, a
    ld d, 0
    ld hl, .WantedPosterNameStrings
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    push de
    ld de, $99a3
    ld c, 14
    call BeginVramString
    pop de
    ld b, 0
    call CopyData
    jp EndVramString

NEWCHARMAP new
CHARMAP " ", $00
CHARMAP "A", $be
CHARMAP "B", $bf
CHARMAP "C", $c0
CHARMAP "D", $c1
CHARMAP "E", $c2
CHARMAP "F", $c3
CHARMAP "G", $c4
CHARMAP "H", $c5
CHARMAP "I", $c6
CHARMAP "J", $c7
CHARMAP "K", $c8
CHARMAP "L", $c9
CHARMAP "M", $ca
CHARMAP "N", $cb
CHARMAP "O", $cc
CHARMAP "P", $cd
CHARMAP "Q", $ce
CHARMAP "R", $cf
CHARMAP "S", $d0
CHARMAP "T", $d1
CHARMAP "U", $d2
CHARMAP "V", $d3
CHARMAP "W", $d4
CHARMAP "X", $d5
CHARMAP "Y", $d6
CHARMAP "Z", $d7
setcharmap new

.WantedPosterNameStrings:
dw .WantedPosterNameString0  
dw .WantedPosterNameString1  
dw .WantedPosterNameString2  
dw .WantedPosterNameString3  
dw .WantedPosterNameString4  
dw .WantedPosterNameString5  
dw .WantedPosterNameString6  
dw .WantedPosterNameString7  
dw .WantedPosterNameString8  
dw .WantedPosterNameString9  
dw .WantedPosterNameString10  
dw .WantedPosterNameString11  
dw .WantedPosterNameString12  
dw .WantedPosterNameString13  
dw .WantedPosterNameString14  
dw .WantedPosterNameString15  
dw .WantedPosterNameString16  
dw .WantedPosterNameString17  
dw .WantedPosterNameString18  
dw .WantedPosterNameString19  
dw .WantedPosterNameString20  
dw .WantedPosterNameString21  
dw .WantedPosterNameString22  
dw .WantedPosterNameString23  
dw .WantedPosterNameString24  
dw .WantedPosterNameString25  
dw .WantedPosterNameString26  
dw .WantedPosterNameString27  
dw .WantedPosterNameString28  
dw .WantedPosterNameString29  
dw .WantedPosterNameString30  
dw .WantedPosterNameString31  
dw .WantedPosterNameString32  
dw .WantedPosterNameString33  
dw .WantedPosterNameString34  
dw .WantedPosterNameString35  
dw .WantedPosterNameString36  
dw .WantedPosterNameString37  
dw .WantedPosterNameString38  
dw .WantedPosterNameString39  
dw .WantedPosterNameString40  
dw .WantedPosterNameString41  
dw .WantedPosterNameString42  
dw .WantedPosterNameString43  
dw .WantedPosterNameString44  
dw .WantedPosterNameString45  
dw .WantedPosterNameString46  
dw .WantedPosterNameString47  
dw .WantedPosterNameString48  
dw .WantedPosterNameString49  
.WantedPosterNameString0:
db "  JED CROWE   "
.WantedPosterNameString1:
db "  BART SLADE  "
.WantedPosterNameString2:
db "  ZEKE NASH   "
.WantedPosterNameString3:
db "  CHET BOONE  "
.WantedPosterNameString4:
db "  HANK DOOLIN "
.WantedPosterNameString5:
db "  ROY CUTTER  "
.WantedPosterNameString6:
db "  WADE GRADY  "
.WantedPosterNameString7:
db "  LUKE HARLAN "
.WantedPosterNameString8:
db "  JESSE VANCE "
.WantedPosterNameString9:
db "  CLAY MORLAN "
.WantedPosterNameString10:
db "  DUKE CARSON "
.WantedPosterNameString11:
db " FLOYD BAXTER "
.WantedPosterNameString12:
db " SILAS REEVES "
.WantedPosterNameString13:
db " BOONE TANNER "
.WantedPosterNameString14:
db "  GUS RAWLINS "
.WantedPosterNameString15:
db "  RUFUS CLAY  "
.WantedPosterNameString16:
db "  LEVI HUNTER "
.WantedPosterNameString17:
db "  AMOS GRAVES "
.WantedPosterNameString18:
db "  WES MCGRAW  "
.WantedPosterNameString19:
db "  COLE RANSOM "
.WantedPosterNameString20:
db " VIRGIL STONE "
.WantedPosterNameString21:
db " JEB CALLOWAY "
.WantedPosterNameString22:
db " TUCKER BRIGGS"
.WantedPosterNameString23:
db " CLYDE JARVIS "
.WantedPosterNameString24:
db " HARLAN WOLFE "
.WantedPosterNameString25:
db " SAUL CANTRELL"
.WantedPosterNameString26:
db " FESTER DURHAM"
.WantedPosterNameString27:
db " BLADE MADDOX "
.WantedPosterNameString28:
db " JETHRO SNYDER"
.WantedPosterNameString29:
db "  CORBIN KANE "
.WantedPosterNameString30:
db "  OTIS LANGLEY"
.WantedPosterNameString31:
db "  QUINN DALTON"
.WantedPosterNameString32:
db "  MORGAN YATES"
.WantedPosterNameString33:
db " STERLING WADE"
.WantedPosterNameString34:
db "  CASH RYDER  "
.WantedPosterNameString35:
db "  BO RUTLEDGE "
.WantedPosterNameString36:
db " WYATT STRONG "
.WantedPosterNameString37:
db "  RANGER KNOX "
.WantedPosterNameString38:
db "  TEX HOLLAND "
.WantedPosterNameString39:
db " JOSIAH BURNS "
.WantedPosterNameString40:
db "  DEACON SHAW "
.WantedPosterNameString41:
db "  LUTHER GRANT"
.WantedPosterNameString42:
db "  MERLE WESTON"
.WantedPosterNameString43:
db " RAY BOUDREAUX"
.WantedPosterNameString44:
db "  SAMSON CROFT"
.WantedPosterNameString45:
db "  ORSON TATE  "
.WantedPosterNameString46:
db "CLINT MAVERICK"
.WantedPosterNameString47:
db "BUCK HAWTHORNE"
.WantedPosterNameString48:
db "  DALLAS GREER"
.WantedPosterNameString49:
db "  JACKSON COLE"

PrintCurrentLevel:
    ld de, $990c
    ld c, 2
    call BeginVramString
    ldh a, [hCurrentLevel]
    inc a
    srl a
    srl a
    srl a
    srl a
    add a, 1
    ld [hli], a
    ldh a, [hCurrentLevel]
    inc a
    and a, $f
    add a, 1
    ld [hli], a
    call EndVramString
    jp FlushVramBuffer

TurnOnLCD:
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000 | LCDCF_BG9800
    ldh [hShadowLCDC], a
    ldh [rLCDC], a ; TODO: why must it be done immediately?
    ret

; https://gbdev.io/pandocs/LCDC.html#lcdc7--lcd-enable
; CAUTION: Stopping LCD operation (Bit 7 from 1 to 0) may be performed during VBlank ONLY,
; disabling the display outside of the VBlank period may damage the hardware by burning in a
; black horizontal line similar to that which appears when the GB is turned off. This appears
; to be a serious issue. Nintendo is reported to reject any games not following this rule.
TurnOffLCD:
    ldh a, [hShadowLCDC]
    and a, ~LCDCF_ON
    ldh [hShadowLCDC], a
    ret


def PLAYER_GUN_START_X equ 100
def PLAYER_GUN_START_Y equ 64
def PLAYER_GUN_START_TILE equ $d2

DrawPlayerGunWithRecoil:
    ldh a, [hPlayerGunJitterIndex]
    cp a, 38
    jr c, .recoil
    ld b, PLAYER_GUN_START_Y
    ld c, PLAYER_GUN_START_X
    jp DrawPlayerGun
    .recoil:
    inc a
    ldh [hPlayerGunJitterIndex], a
    add a, LOW(.recoilDelta)
    ld c, a
    ld b, HIGH(.recoilDelta)
    jr nc, .skipInc
    inc b
    .skipInc:
    ld a, [bc]
    add a, PLAYER_GUN_START_Y
    ld b, a
    sub a, PLAYER_GUN_START_Y
    add a, PLAYER_GUN_START_X
    ld c, a
    jp DrawPlayerGun
.recoilDelta:
db 0, 5, 7, 6, 3, 0, -4, -5, -5, -2, 1, 3, 4, 3, 1, -1, -3, -3, -3, -1, 1, 2, 3, 2, 1, -1, -2, -2, -1, 0, 1, 1, 1, 1, 0, -1, -1, -1, -1, 0

DrawPlayerGunWithHorizontalJitter:
    ldh a, [hPlayerGunJitterIndex]
    inc a
    ldh [hPlayerGunJitterIndex], a
    srl a
    srl a
    and a, 63
    add a, LOW(.HorizontalJitter)
    ld c, a
    ld b, HIGH(.HorizontalJitter)
    jr nc, .skipInc
    inc b
    .skipInc:
    ld a, [bc]
    add a, PLAYER_GUN_START_X
    ld c, a
    ld b, PLAYER_GUN_START_Y
    jp DrawPlayerGun
.HorizontalJitter:
db 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 2, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 2, 2, 1, 1, 0, 0, 0, 0, 0, 1, 2, 1, 1, 2, 1, 1, 0, 0, 0, 0, 1, 1

; B = top left Y
; C = top left X
DrawPlayerGun:
    push bc
    call BeginDrawSprites
    pop bc
    ; 0, 0
    ld a, b
    ld [hli], a ; y
    ld a, c
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 1, 0
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 8
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+2
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 2, 0
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 16
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+4
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; next row
    ld a, b
    add a, 16
    ld b, a
    ; 1, 1
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 8
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+6
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 2, 1
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 16
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+8
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 3, 1
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 24
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+10
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; next row
    ld a, b
    add a, 16
    ld b, a
    ; 0, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+12
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 1, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 8
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+14
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 2, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 16
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+16
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 3, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 24
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+18
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 4, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 32
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+20
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 5, 2
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 40
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+22
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; next row
    ld a, b
    add a, 16
    ld b, a
    ; 1, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 8
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+24
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 2, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 16
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+26
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 3, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 24
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+28
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 4, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 32
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+30
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 5, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 40
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+32
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; 6, 3
    ld a, b
    ld [hli], a ; y
    ld a, c
    add a, 48
    ld [hli], a ; x
    ld a, PLAYER_GUN_START_TILE+34
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    ret


; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc0  ; setup level start
dw MainFunc1  ; wait for Start button to be pushed
dw MainFunc2  ; setup game
dw MainFunc3  ; countdown to quick time event
dw MainFunc4  ; quick time event 1: Draw gun
dw MainFunc5  ; quick time event 2: Shoot
dw MainFunc6  ; delay
dw MainFunc7  ; player died
dw MainFunc8  ; fade out step 1
dw MainFunc9  ; fade out step 2
dw MainFunc10 ; fade out step 3
dw MainFunc11 ; game over
dw MainFunc12 ; fade to white step 1
dw MainFunc13 ; fade to white step 2
dw MainFunc14 ; fade to white step 3
dw MainFunc15 ; fade from white step 1
dw MainFunc16 ; fade from white step 2
dw MainFunc17 ; fade from white step 3
dw MainFunc18 ; check if player died or won
dw MainFunc19 ; player won
dw MainFunc20 ; setup game over screen
dw MainFunc21 ; game over screen done

MainFunc0: ; setup level start
    ; standard palettes
    ld  a, %00011011
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ld de, LevelStartTiles
    ld hl, $8000
    ld bc, LevelStartTilesEnd - LevelStartTiles
    call CopyData

    ld e, 0
    ld hl, $9800
    ld bc, $200
    call SetMemory

; start on highest level
;    ld a, MAX_LEVEL - 1
;    ldh [hCurrentLevel], a

    ld hl, LevelStartTileMapData
    call WriteVramStrings

    call PrintWantedPosterName
    call PrintWantedPosterSum

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 1
    ldh [hMainState], a ; wait for Start

    jp TurnOnLCD

; wait for Start
MainFunc1:
    call FlashPushStartButtonText
    ldh a, [hButtonsPressed]
    and a, PADF_START
    jr nz, .startDuel
    ret
    .startDuel:
    ld a, 2
    ldh [hMainState], a ; setup game
    jp TurnOffLCD

FlashPushStartButtonText:
    ldh a, [hFrameCounter]
    and a, $1c
    jr nz, .printPushStartButton
    ld de, ErasePushStartButtonString
    jp CopyStringToVramBuffer
    .printPushStartButton:
    ld de, PushStartButtonString
    jp CopyStringToVramBuffer

MainFunc2: ; setup game
    ld de, GameTiles
    ld hl, $8000
    ld bc, GameTilesEnd - GameTiles
    call CopyData

    ld hl, GameTileMapData
    call WriteVramStrings

    ; initialize seed
    ldh a, [hFrameCounter]
    ldh [hRandom], a

    or a, $20
;    ld a, $10
    cp a, 160
    jr c, .noClamp
    ld a, 160
    .noClamp:
    ld de, MainFunc3_TimerTimeout
    call SetTimer

    ld a, 3 ; countdown to quick time event
    ldh [hMainState], a
    ld hl, duel_song
    call StartSong

    jp TurnOnLCD

MainFunc3_TimerTimeout:
    ; time to draw!
    call Prng
    and a, 31
    cp a, MAX_QUICK_TIME_EVENT_KIND+1
    jr c, .noClampEventKind
    sub a, MAX_QUICK_TIME_EVENT_KIND
    .noClampEventKind:
;    ld a, 6
    ldh [hQuickTimeEventKind], a
    ld e, a
    ld d, 0
    ld hl, QuickTimeEventButtons
    add hl, de
    ld a, [hl]
    ldh [hQuickTimeEventButtons], a
    ld a, 0
    ldh [hQuickTimeEventButtonsSatisfied], a
    ldh a, [hCurrentLevel]
    cp a, MAX_LEVEL
    jr c, .noClampLevel
    ld a, MAX_LEVEL - 1
    .noClampLevel:
    sla a
    sla a
    ld b, a ; current level times 4
    ld a, 200 ; maximum timer (slowest/easiest)
    sub a, b
    ldh [hQuickTimeEventTimer], a
    srl a
    ldh [hQuickTimeEventHalfTime], a
    call DrawQuickTimeEventButtonIndicators
    ld a, QUICK_TIME_EVENT_BUTTON_INDICATORS_TIMER_SPEED - 1
    ldh [hQuickTimeEventButtonIndicatorsTimer], a
    ld hl, draw_song
    call StartSong
    ld a, 4
    ldh [hMainState], a ; time to draw!
    ret

; countdown to quick time event
MainFunc3:
    call HideAllSprites
    ; TODO: maybe draw some tumbleweed?
    ldh a, [hButtonsPressed]
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN | PADF_B | PADF_A
    jr nz, .drewTooFast
    jp TickTimer
    .drewTooFast:
    ; oops, the opponent shoots you
    call CopyOpponentDrawGunStringsToVramBuffer
    jp PlayerGotSniped

; time to draw!
MainFunc4:
    call HideAllSprites
    ldh a, [hButtonsPressed]
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN | PADF_B | PADF_A
    jr nz, .validateButtonPresses
    .updateTimer:
    ldh a, [hQuickTimeEventTimer]
    dec a
    jr z, .drewTooSlow
    ldh [hQuickTimeEventTimer], a
    ld b, a
    ldh a, [hQuickTimeEventHalfTime]
    cp a, b
    jr nz, .noOpponentDrawGun
    ; Opponent draws gun
    call CopyOpponentDrawGunStringsToVramBuffer
    .noOpponentDrawGun:
    call UpdateQuickTimeEventButtonIndicators
    ret
    .validateButtonPresses:
    ld b, a
    ldh a, [hQuickTimeEventButtons]
    xor a, $ff
    and a, b
    jr nz, .wrongButtonsPressed
    ldh a, [hQuickTimeEventButtonsSatisfied]
    or a, b
    ldh [hQuickTimeEventButtonsSatisfied], a
    ld b, a
    ldh a, [hQuickTimeEventButtons]
    xor a, b
    jr z, .drawGunSuccess
    jr .updateTimer
    .drewTooSlow:
    ; opponent shoots
    jp PlayerGotSniped
    .wrongButtonsPressed:
    call CopyOpponentDrawGunStringsToVramBuffer
    jr .drewTooSlow
    .drawGunSuccess:
    ld hl, drew_song
    call StartSong
    ; time to shoot!
    call EraseQuickTimeEventButtonIndicators
    ldh a, [hQuickTimeEventKind]
    add a, a
    ld e, a
    ld d, 0
    ld hl, QuickTimeValidSuccessorEvents
    add hl, de
    ld a, [hli] ; low pointer to successor events
    ld e, a
    ld a, [hli] ; high pointer to successor events
    ld d, a
    ld a, [de] ; count of valid successor events
    inc de
    ld b, a
    call Prng
    and a, 15
    .loop:
    cp a, b
    jr c, .done
    sub a, b
    jr .loop
    .done:
    ld l, a
    ld h, 0
    add hl, de
    ld a, [hl] ; successor event kind
    ldh [hQuickTimeEventKind], a
    ld e, a
    ld d, 0
    ld hl, QuickTimeEventButtons
    add hl, de
    ld a, [hl] ; event buttons
    ldh [hQuickTimeEventButtons], a
    ld a, 0
    ldh [hQuickTimeEventButtonsSatisfied], a

    call DrawQuickTimeEventButtonIndicators
    ld a, QUICK_TIME_EVENT_BUTTON_INDICATORS_TIMER_SPEED - 1
    ldh [hQuickTimeEventButtonIndicatorsTimer], a

    ld a, 5
    ldh [hMainState], a ; time to shoot!
    ret

; time to shoot!
MainFunc5:
    call HideAllSprites
    call DrawPlayerGunWithHorizontalJitter
    ldh a, [hButtonsPressed]
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN | PADF_B | PADF_A
    jr nz, .validateButtonPresses
    .updateTimer:
    ldh a, [hQuickTimeEventTimer]
    dec a
    jr z, .shotTooSlow
    ldh [hQuickTimeEventTimer], a
    ld b, a
    ldh a, [hQuickTimeEventHalfTime]
    cp a, b
    jr nz, .noOpponentDrawGun
    ; Opponent draws gun
    call CopyOpponentDrawGunStringsToVramBuffer
    .noOpponentDrawGun:
    call UpdateQuickTimeEventButtonIndicators
    ret
    .validateButtonPresses:
    ld b, a
    ldh a, [hQuickTimeEventButtons]
    xor a, $ff
    and a, b
    jr nz, .wrongButtonsPressed
    ldh a, [hQuickTimeEventButtonsSatisfied]
    or a, b
    ldh [hQuickTimeEventButtonsSatisfied], a
    ld b, a
    ldh a, [hQuickTimeEventButtons]
    xor a, b
    jr z, .shootGunSuccess
    jr .updateTimer
    .shotTooSlow:
    ; opponent shoots
    jp PlayerGotSniped
    .wrongButtonsPressed:
    ; opponent draws and shoots
    ; TODO: draw puff of smoke from player gun
    call CopyOpponentDrawGunStringsToVramBuffer
    ld hl, shoot_song
    call StartSong
    call EraseQuickTimeEventButtonIndicators
    ld a, 0
    ldh [hPlayerWon], a
    ldh [hPlayerGunJitterIndex], a
    ld a, 3
    ld de, MainFunc12_TimerTimeout
    call SetTimer
    ld a, 12
    ldh [hMainState], a ; after shot
    ret
    .shootGunSuccess:
    ; player wins
    ; TODO: draw puff of smoke from player gun
    call CopyOpponentDrawGunStringsToVramBuffer
    ld hl, shoot_song
    call StartSong
    call EraseQuickTimeEventButtonIndicators
    ld a, 0
    ldh [hPlayerGunJitterIndex], a
    ld a, 1
    ldh [hPlayerWon], a
    ld a, 3
    ld de, MainFunc12_TimerTimeout
    call SetTimer
    ld a, 12
    ldh [hMainState], a ; after shot
    ret

CopyOpponentDrawGunStringsToVramBuffer:
    ld de, .opponentDrawGunStrings
    ld a, .opponentDrawGunStringsEnd - .opponentDrawGunStrings
    jp CopyBytesToVramBuffer
.opponentDrawGunStrings:
db $98,$88,$03,$be,$bf,$c0
db $98,$a8,$03,$c3,$c4,$c5
db $98,$e7,$03,$1c,$c6,$c7
db $99,$05,$05,$c8,$c9,$ca,$cb,$cc
db $99,$25,$05,$cd,$ce,$cf,$d0,$d1
.opponentDrawGunStringsEnd:

CopyOpponentDeadStringsToVramBuffer:
    ld de, .opponentDeadStrings
    ld a, .opponentDeadStringsEnd - .opponentDeadStrings
    jp CopyBytesToVramBuffer
.opponentDeadStrings:
db $98,$69,$42,$08
db $98,$89,$42,$08
db $98,$a8,$43,$08
db $98,$c8,$04,$f8,$f9,$fa,$fb
db $98,$e8,$04,$fc,$fd,$fe,$ff
db $99,$05,$45,$1c
db $99,$25,$45,$1c
db $99,$45,$44,$1c
db $99,$65,$43,$1c
db $99,$84,$43,$1c
db $99,$a4,$43,$1c
.opponentDeadStringsEnd:

MainFunc6_TimerTimeout:
    ldh a, [hNextMainState]
    ldh [hMainState], a
    ret

; wait for timer to expire, then go to next state
MainFunc6:
    jp TickTimer

PlayerGotSniped:
    call EraseQuickTimeEventButtonIndicators
    ld hl, shoot_song
    call StartSong
    ld a, 10
    ld b, 7 ; player died
    call SetTimerWithNextStateTimeout
    ; TODO: maybe shake the screen?
    ret

MainFunc7: ; player died
    call HideAllSprites
    ld hl, youdie_song
    call StartSong
    ld a, 10
    ld b, 8 ; fade to black step 1
    jp SetTimerWithNextStateTimeout

MainFunc8: ; fade to black step 1
    ld a, %01101111
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a
    ld a, 10
    ld b, 9 ; fade to black step 2
    jp SetTimerWithNextStateTimeout

MainFunc9: ; fade to black step 2
    ld a, %10111111
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a
    ld a, 10
    ld b, 10 ; fade to black step 3
    jp SetTimerWithNextStateTimeout

MainFunc10:  ; fade to black step 3
    ld a, %11111111
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a
    ld a, 10
    ld b, 11 ; game over
    jp SetTimerWithNextStateTimeout

MainFunc11: ; game over
    ld a, 20
    ldh [hMainState], a ; setup game over screen
    jp TurnOffLCD

MainFunc12_TimerTimeout:
    ld a, 13 ; fade to white step 2
    ldh [hMainState], a
    ld a, 3
    ld de, MainFunc13_TimerTimeout
    jp SetTimer

MainFunc12: ; fade to white step 1
    ld a, %00000110
    ldh [hShadowBGP], a
    call HideAllSprites
    call DrawPlayerGunWithRecoil
    jp TickTimer

MainFunc13_TimerTimeout:
    ld a, 14 ; fade to white step 3
    ldh [hMainState], a
    ld a, 4
    ld de, MainFunc14_TimerTimeout
    jp SetTimer

MainFunc13: ; fade to white step 2
    ld a, %00000001
    ldh [hShadowBGP], a
    call HideAllSprites
    call DrawPlayerGunWithRecoil
    jp TickTimer

MainFunc14_TimerTimeout:
    ld a, 15 ; fade from white step 1
    ldh [hMainState], a
    ret

MainFunc14: ; fade to white step 3
    ld a, %00000000
    ldh [hShadowBGP], a
    call HideAllSprites
    call DrawPlayerGunWithRecoil
    jp TickTimer

MainFunc15: ; fade from white step 1
    ld a, %00000001
    ldh [hShadowBGP], a
    ld a, 3
    ld b, 16 ; fade to white step 2
    jp SetTimerWithNextStateTimeout

MainFunc16: ; fade from white step 2
    ld a, %00000110
    ldh [hShadowBGP], a
    ld a, 3
    ld b, 17 ; fade to white step 3
    jp SetTimerWithNextStateTimeout

MainFunc17: ; fade from white step 3 (back to normal intensity)
    ld a, %00011011
    ldh [hShadowBGP], a
    ld a, 8
    ld b, 18 ; check if player died or won
    jp SetTimerWithNextStateTimeout

MainFunc18:
    ldh a, [hPlayerWon]
    or a, a
    jr nz, .playerWon
    ; player died
    ld a, 7
    ldh [hMainState], a
    ret
    .playerWon:
    ; TODO: add intermediate frame for death animation
    call CopyOpponentDeadStringsToVramBuffer
    ld hl, youwin_song
    call StartSong
    ld a, 66
    ld b, 19 ; prepare for next level
    jp SetTimerWithNextStateTimeout

MainFunc19: ; advance to next level
    ldh a, [hCurrentLevel]
    inc a
    ldh [hCurrentLevel], a
    ld a, 0
    ldh [hMainState], a ; setup level start
    jp TurnOffLCD

MainFunc20: ; setup game over screen
    ; standard palettes
    ld  a, %00011011
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ld de, GameOverTiles
    ld hl, $8000
    ld bc, GameOverTilesEnd - GameOverTiles
    call CopyData

    ld e, 0
    ld hl, $9800
    ld bc, $200
    call SetMemory

    ld hl, GameOverTileMapData
    call WriteVramStrings

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 32
    ld b, 21 ; game over screen done
    call SetTimerWithNextStateTimeout

    jp TurnOnLCD

MainFunc21:
    ld a, 0
    ldh [hCurrentLevel], a
    ldh [hMainState], a ; setup level start
    jp TurnOffLCD


UpdateQuickTimeEventButtonIndicators:
    ldh a, [hQuickTimeEventButtonIndicatorsTimer]
    dec a
    jr z, .timeout
    ldh [hQuickTimeEventButtonIndicatorsTimer], a
    cp a, QUICK_TIME_EVENT_BUTTON_INDICATORS_TIMER_SPEED / 4
    jr c, .eraseButtonIndicators
    call DrawQuickTimeEventButtonIndicators
    ret
    .eraseButtonIndicators:
    call EraseQuickTimeEventButtonIndicators
    ret
    .timeout:
    ld a, QUICK_TIME_EVENT_BUTTON_INDICATORS_TIMER_SPEED
    ldh [hQuickTimeEventButtonIndicatorsTimer], a
    jr .eraseButtonIndicators

DrawQuickTimeEventButtonIndicators:
    ldh a, [hQuickTimeEventButtons]
    bit PADB_A, a
    jr z, .skipAButton
    call DrawAButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipAButton:
    bit PADB_B, a
    jr z, .skipBButton
    call DrawBButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipBButton:
    bit PADB_RIGHT, a
    jr z, .skipRightButton
    call DrawRightButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipRightButton:
    bit PADB_LEFT, a
    jr z, .skipLeftButton
    call DrawLeftButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipLeftButton:
    bit PADB_UP, a
    jr z, .skipUpButton
    call DrawUpButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipUpButton:
    bit PADB_DOWN, a
    jr z, .skipDownButton
    call DrawDownButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipDownButton:
    ret

def BUTTON_INDICATORS_BASE_TILE_INDEX equ $a6

DrawLeftButtonIndicator:
    ; top half
    ld de, $99e2
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

DrawRightButtonIndicator:
    ; top half
    ld de, $99e2+6
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+2
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+6+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+2+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

DrawUpButtonIndicator:
    ; top half
    ld de, $99c5
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+4
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99c5+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+4+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

DrawDownButtonIndicator:
    ; top half
    ld de, $9a05
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+6
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $9a05+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+6+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

DrawBButtonIndicator:
    ; top half
    ld de, $99e2+11
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+8
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+11+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+8+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

DrawAButtonIndicator:
    ; top half
    ld de, $99e2+14
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+10
    ld [hli], a
    add a, 1
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+14+32
    ld c, 2
    call BeginVramString
    ld a, BUTTON_INDICATORS_BASE_TILE_INDEX+10+12
    ld [hli], a
    add a, 1
    ld [hli], a
    jp EndVramString

EraseQuickTimeEventButtonIndicators:
    ldh a, [hQuickTimeEventButtons]
    bit PADB_A, a
    jr z, .skipAButton
    call EraseAButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipAButton:
    bit PADB_B, a
    jr z, .skipBButton
    call EraseBButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipBButton:
    bit PADB_RIGHT, a
    jr z, .skipRightButton
    call EraseRightButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipRightButton:
    bit PADB_LEFT, a
    jr z, .skipLeftButton
    call EraseLeftButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipLeftButton:
    bit PADB_UP, a
    jr z, .skipUpButton
    call EraseUpButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipUpButton:
    bit PADB_DOWN, a
    jr z, .skipDownButton
    call EraseDownButtonIndicator
    ldh a, [hQuickTimeEventButtons]
    .skipDownButton:
    ret

def BlankTileIndex equ 0

EraseLeftButtonIndicator:
    ; top half
    ld de, $99e2
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

EraseRightButtonIndicator:
    ; top half
    ld de, $99e2+6
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+6+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

EraseUpButtonIndicator:
    ; top half
    ld de, $99c5
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99c5+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

EraseDownButtonIndicator:
    ; top half
    ld de, $9a05
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $9a05+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

EraseBButtonIndicator:
    ; top half
    ld de, $99e2+11
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+11+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

EraseAButtonIndicator:
    ; top half
    ld de, $99e2+14
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    call EndVramString
    ; bottom half
    ld de, $99e2+14+32
    ld c, $42
    call BeginVramString
    ld a, BlankTileIndex
    ld [hli], a
    jp EndVramString

Prng:
    ldh a, [hRandom]
    srl a
    jr nc, .noXor
    xor $B4
    .noXor:
    ldh [hRandom], a
    ret

SECTION "Tile data", ROM0

GameTiles:
; packchr --nametable-base=0x00 --character-output=dueltiles.bin duel.chr
incbin "dueltiles.bin"   ; $00 - 166 tiles
incbin "buttontiles.bin" ; $A6 - 24 tiles
;incbin "chars.bin"       ; $B2 - 13 tiles
incbin "opponentdrawguntiles.bin" ; $BE - 20 tiles
; packchr --nametable-base=0xd2 --null-tile=0 --character-output=playerguntiles.bin playergun.chr
incbin "playerguntiles.bin" ; $D2 - 38 tiles
incbin "opponentdeadtiles.bin" ; $f8 - 8 tiles
GameTilesEnd:

LevelStartTiles:
; packchr --nametable-base=0x00 --character-output=wantedtiles.bin wanted.chr
incbin "wantedtiles.bin"    ; $00 - 168 tiles
incbin "wantedsumtiles.bin" ; $a8 - 22 tiles
incbin "wantednamefont.bin" ; $be - 27 tiles
LevelStartTilesEnd:

GameOverTiles:
; packchr --nametable-base=0x00 --character-output=gameovertiles.bin gameover.chr
incbin "gameovertiles.bin" ; $00 - 243 tiles
incbin "gameoverfont.bin"  ; $f3 - 12 tiles
GameOverTilesEnd:

SECTION "VRAM strings", ROM0

LevelStartTileMapData:
; packnam --width=20 --vram-address=0x9800 --output=wantedtilemap.bin packchr.nam
incbin "wantedtilemap.bin"
; dollar sign
db $99,$cc,$01,$a8
db $99,$ec,$01,$b3
db 0

PushStartButtonString:
db $9a,$21,17,"PUSH START BUTTON",0
ErasePushStartButtonString:
db $9a,$21,17,"                 ",0

GameTileMapData:
; black background
db $98,$00,$60,$00
db $99,$c0,$60,$00
db $99,$e0,$60,$00
db $9a,$00,$60,$00
db $9a,$20,$60,$00
; packnam --width=20 --vram-address=0x9820 --output=dueltilemap.bin packchr.nam
incbin "dueltilemap.bin"
db 0

GameOverTileMapData:
; packnam --width=20 --vram-address=0x9800 --output=gameovertilemap.bin packchr.nam
incbin "gameovertilemap.bin"
db $99,$e5,9,$f3,$f4,$f5,$f6,0,$f7,$f8,$f6,$f9 ; "GAME OVER"
db $9a,$24,12,$fa,$fb,$f4,$fa,$fc,$f6,$f9,$f7,$fe,$fd,$f7,$f5 ; "DPADHERO.COM"
db 0
