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

hShadowBGP: db
hShadowOBP0: db
hShadowLCDC: db

hTimerHi: db
hTimerLo: db
hTimerCallback: dw
def TIMER_SPEED equ 4

def HIT_CUE_DELAY_WIDTH equ 3
def HIT_CUE_PAYLOAD_WIDTH equ 4

def HIT_START_Y equ 139
def HIT_EXTENT equ 13

hHitCueStream: dw
hHitCueStreamBitCtr: db
hHitCueStreamBits: db
hHitCueTimer: db
hHitCueProcessingPending: db

; linked lists
hFreeTargetsList: db
hActiveTargetsHead: db
hActiveTargetsTail: db
hHitTargetsHead: db
hHitTargetsTail: db
hMissedTargetsHead: db
hMissedTargetsTail: db
hPrev: db
def ZILCH_ITEM equ $ff

hLaneInput: db
hLaneInputPosedge: db
hCheckedLanes: db
hHittableLanes: db
hHitLanes: db
hErrorLanes: db

rsreset
def Target_Next rb 1                    ; 00
def Target_State rb 1                   ; 01
def Target_PosY_Frac rb 1               ; 02
def Target_PosY_Int  rb 1               ; 03
def Target_SIZEOF    rb 0               ; 04

def MAX_TARGETS equ 32

; --- Begin Sound engine

hInstrumentTable: dw

hPatternTable: dw

hOrder: dw

hPatternRowCallback: dw

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
    ds 96

wTargetsArena:
    ds Target_SIZEOF * MAX_TARGETS

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
	db   "SNOWBRO 026", $00, $00, $00, $00

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
    ld de, Track_SIZEOF
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
    push hl
    call PatternRowCallbackTrampoline
    pop hl
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

; HL = callback address
; The callback will receive the channel number in register B.
; The callback must preserve registers BC, DE.
SetPatternRowCallback:
    ld a, l
    ldh [hPatternRowCallback], a
    ld a, h
    ldh [hPatternRowCallback+1], a
    ret

PatternRowCallbackTrampoline:
    ldh a, [hPatternRowCallback]
    ld l, a
    ldh a, [hPatternRowCallback+1]
    ld h, a
    or a, l
    ret z ; exit if no callback is set
    jp hl

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

; --- Program-specific code: Our game starts here! ---

Genesis:
    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

    call MainFunc_TitleInit

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

.InfiniteLoop:
    halt
    jp .InfiniteLoop

GameInit:
    ld de, GameTiles
    ld hl, $8000
    ld bc, GameTilesEnd - GameTiles
    call CopyData

    ; Clear tilemap
    ld e, 0
    ld hl, $9800
    ld bc, $240
    call SetMemory

    ld hl, GameScreenTilemap
    call WriteVramStrings

    ld hl, song_song
    call StartSong
    ld a, $0
    ldh [hSoundStatus], a ; unmute all channels

    call InitializeTargetLists

    ; Initialize hit cue
    ld a, HIGH(SongHitCueStream)
    ldh [hHitCueStream+1], a
    ld a, LOW(SongHitCueStream)
    ldh [hHitCueStream], a
    xor a
    ldh [hHitCueProcessingPending], a
    inc a
    ldh [hHitCueTimer], a
    ldh [hHitCueStreamBitCtr], a

    ld hl, OnPatternRowChange
    jp SetPatternRowCallback

OnPatternRowChange:
    ld a, b
    cp a, 3 ; last channel?
    ret nz
    ldh a, [hHitCueTimer]
    dec a
    ldh [hHitCueTimer], a
    ret nz ; exit if timer not yet expired
    ld a, 1
    ldh [hHitCueProcessingPending], a
    ret

InitializeTargetLists:
    ld a, ZILCH_ITEM
    ldh [hActiveTargetsHead], a
    ldh [hActiveTargetsTail], a
    ldh [hHitTargetsHead], a
    ldh [hHitTargetsTail], a
    ldh [hMissedTargetsHead], a
    ldh [hMissedTargetsTail], a
    ; put all targets on the free list
    xor a
    ldh [hFreeTargetsList], a
    ld hl, wTargetsArena
    ld b, MAX_TARGETS - 1
    .loop:
    add a, Target_SIZEOF ; address of next target
    ld [hli], a ; Target_Next
    assert Target_SIZEOF == 4
    inc l
    inc l
    inc l
    dec b
    jr nz, .loop
    ld a, ZILCH_ITEM
    ld [hl], a ; Target_Next
    ret

; A = high timer value
; B = next main state
; destroys A, D, E
SetTimerWithNextStateTimeout:
    ld de, MainFunc_Delay_TimerTimeout
    call SetTimer
    ld a, b
    ldh [hNextMainState], a
    ld a, 6
    ldh [hMainState], a ; delay
    ret

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

; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc_NoOp        ; 0
dw MainFunc_TitleInit   ; 1
dw MainFunc_TitleScreen ; 2
dw MainFunc_GameInit    ; 3
dw MainFunc_Gameplay    ; 4
dw MainFunc_WaitForAllClear ; 5
dw MainFunc_Delay       ; 6
dw MainFunc_GameFinished ; 7

MainFunc_NoOp:
    ret

; wait for timer to expire, then go to next state
MainFunc_Delay:
    jp TickTimer

MainFunc_Delay_TimerTimeout:
    ldh a, [hNextMainState]
    ldh [hMainState], a
    ret

MainFunc_TitleInit:
    ; standard palettes
    ld  a, %00011011
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ld de, TitleScreenTiles
    ld hl, $8000
    ld bc, TitleScreenTilesEnd - TitleScreenTiles
    call CopyData

    ; Clear tilemap
    ld e, 0
    ld hl, $9800
    ld bc, $240
    call SetMemory

    ld hl, TitleScreenTilemap
    call WriteVramStrings

    call HideAllSprites

    ld hl, silent_song
    call StartSong
    ld a, $f
    ldh [hSoundStatus], a ; mute all channels

    ld a, 2
    ldh [hMainState], a ; wait for Start
    call TurnOnLCD

MainFunc_TitleScreen:
    ldh a, [hButtonsPressed]
    and a, PADF_START
    ret z ; exit if not pressed
    ld a, 3
    ldh [hMainState], a ; game init
    jp TurnOffLCD

MainFunc_GameInit:
    ld hl, GameScreenTilemap
    call WriteVramStrings

    ; initialize seed
    ldh a, [hFrameCounter]
    ldh [hRandom], a

    call GameInit

    ld a, 4
    ldh [hMainState], a ; gameplay

    jp TurnOnLCD

MainFunc_Gameplay:
    call HideAllSprites
    call GetLaneInputsFromButtons
    call ProcessHitCues
    call ProcessActiveTargets
    call ProcessHitTargets
    jp ProcessMissedTargets

MainFunc_WaitForAllClear:
    call MainFunc_Gameplay
    ldh a, [hActiveTargetsHead]
    cp ZILCH_ITEM ; any active targets?
    ret nz ; exit if so
    ldh a, [hHitTargetsHead]
    cp ZILCH_ITEM ; any hit targets?
    ret nz ; exit if so
    ldh a, [hMissedTargetsHead]
    cp ZILCH_ITEM ; any missed targets?
    ret nz ; exit if so
    ld a, 30 ; timer
    ld b, 7 ; game finished
    jp SetTimerWithNextStateTimeout

MainFunc_GameFinished:
    ld a, 1
    ldh [hMainState], a ; back to title init
    jp TurnOffLCD

MACRO Align8
ds ((@ + 7) & $fff8) - @
ENDM

ProcessHitCues:
    ldh a, [hHitCueProcessingPending]
    or a
    ret z ; exit if no processing pending
    dec a
    ldh [hHitCueProcessingPending], a
    ; process hit cue entry
    ld a, HIT_CUE_PAYLOAD_WIDTH
    call ReadHitCueStreamBits
    cp a, 15 ; end of stream?
    jr z, .endOfStream
    or a
    jr z, .20
    ; TODO: respect the type bits
    call Prng
    and a, 15
    or a
    jr nz, .10
    inc a
    .10:
    cp a, 12
    jr c, .20
    sub a, 4
    .20:
    add a, LOW(.LanesSpecifierMasks)
    ld l, a
    ld h, HIGH(.LanesSpecifierMasks)
    ld a, [hl] ; lane bits
    ld b, a
    xor a ; lane
    .laneLoop:
    srl b ; lane bit into carry
    jr nc, .nextLane
    push af ; save lane
    push bc ; save lane bits
    call AddTarget
    pop bc ; restore lane bits
    pop af ; restore lane
    .nextLane:
    inc a
    cp 4    ; done all lanes?
    jr nz, .laneLoop

    ; set next timer
    ld a, HIT_CUE_DELAY_WIDTH
    call ReadHitCueStreamBits
    ; map value to timer
    or a, LOW(.HitCueTimerTable)
    ld l, a
    ld h, HIGH(.HitCueTimerTable)
    ld a, [hl]
    ldh [hHitCueTimer], a
    ret

    .endOfStream:
    ld hl, 0
    call SetPatternRowCallback
    ld a, 5
    ldh [hMainState], a ; wait for all clear
    ret

MACRO Align16
ds ((@ + $f) & $fff0) - @
ENDM

Align16
.LanesSpecifierMasks:
db %0000 ; 0 - none
db %0001 ; 1 - left
db %0010 ; 2 - right
db %0100 ; 3 - B
db %1000 ; 4 - A
db %0101 ; 5 - left + B
db %1001 ; 6 - left + A
db %0110 ; 7 - right + B
db %1010 ; 8 - right + A
db %1100 ; 9 - B + A
db %1101 ; 10 - left + B + A
db %1110 ; 11 - right + B + A

Align8
.HitCueTimerTable:
db 1,2,4,8,12,16,24,32

; A = lane (bits 1..0)
; Destroys: A, B, HL
AddTarget:
    push af ; save lane
; grab target from free list
    ldh a, [hFreeTargetsList]
    cp ZILCH_ITEM ; empty list?
    jr nz, .10
    ; fatal, no more free targets
    jp Reset
    .10:
    ld h, HIGH(wTargetsArena)
    ld l, a
    ld a, [hl] ; Target_Next (new head of free list)
    ldh [hFreeTargetsList], a
    ld a, ZILCH_ITEM
    ld [hli], a ; Target_Next (this will become the new tail)
; initialize the target
    pop af ; restore lane
    ld [hli], a ; Target_State
; TODO: set duration
;    tya
;    sta targets_2.duration,x
    xor a
    ld [hli], a ; Target_PosY_Frac
    ld a, 0 ; initial Y position
    ld [hl-], a ; Target_PosY_Int
    dec l ; Target_State
    dec l ; Target_Next
; append to active targets list
    ldh a, [hActiveTargetsTail] ; old tail
    cp a, ZILCH_ITEM ; empty list?
    jr nz, .20
    ; initialize the list
    ld a, l
    ldh [hActiveTargetsHead], a
    ldh [hActiveTargetsTail], a
    ret
    .20:
    ld b, l ; this target
    ld l, a ; old tail
    ld a, b
    ld [hl], a ; old tail's Target_Next = new target
    ldh [hActiveTargetsTail], a
    ret

; A = number of bits to read (max 8)
; Returns: A = bits read
; Destroys: B, C, D, H, L
ReadHitCueStreamBits:
    ld d, a ; bit counter
    ldh a, [hHitCueStreamBitCtr]
    ld b, a
    ldh a, [hHitCueStreamBits]
    ld c, 0 ; output will be shifted into here
    .readOneBit:
    dec b
    jr nz, .10
    ; reset counter, read next byte from stream
    ld b, 8
    ldh a, [hHitCueStream]
    ld l, a
    ldh a, [hHitCueStream+1]
    ld h, a
    ld a, [hli] ; next data byte
    push af
    ; write back stream pointer
    ld a, l
    ldh [hHitCueStream], a
    ld a, h
    ldh [hHitCueStream+1], a
    pop af ; restore next data byte
    .10:
    sla a ; top bit into carry
    rl c ; shift it into result
    dec d ; one bit done
    jr nz, .readOneBit
    ldh [hHitCueStreamBits], a
    ld a, b
    ldh [hHitCueStreamBitCtr], a
    ld a, c ; final result
    ret

; Computes hLaneInputPosedge and hLaneInput from hButtonsPressed and hButtonsHeld
; Destroys: A, B
GetLaneInputsFromButtons:
    ; compute hLaneInputPosedge
    xor a
    ld b, a
    ldh a, [hButtonsPressed]
    bit PADB_LEFT, a
    jr z, .10
    set 0, b
    .10:
    bit PADB_RIGHT, a
    jr z, .20
    set 1, b
    .20:
    bit PADB_B, a
    jr z, .30
    set 2, b
    .30:
    bit PADB_A, a
    jr z, .40
    set 3, b
    .40:
    ld a, b
    ldh [hLaneInputPosedge], a
    ; compute hLaneInput
    xor a
    ld b, a
    ldh a, [hButtonsHeld]
    bit PADB_LEFT, a
    jr z, .50
    set 0, b
    .50:
    bit PADB_RIGHT, a
    jr z, .60
    set 1, b
    .60:
    bit PADB_B, a
    jr z, .70
    set 2, b
    .70:
    bit PADB_A, a
    jr z, .80
    set 3, b
    .80:
    ld a, b
    ldh [hLaneInput], a
    ret

ProcessActiveTargets:
    xor a
    ldh [hCheckedLanes], a
    ldh [hHittableLanes], a
    ldh [hHitLanes], a
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hActiveTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    jr nz, .doTarget

    call CheckForErrors
    jp SweepActiveTargets

    .doTarget:
    ld l, a ; Target_Next
    inc l ; Target_State
    ; check for hit/miss
    ld a, [hl] ; Target_State
    ; compute bit mask for lane in C
    ld c, 1
    and a, 3 ; lane
    jr z, .10
    .20:
    sla c
    dec a
    jr nz, .20

    .10:
    ldh a, [hCheckedLanes]
    and c
    jr nz, .moveAndDraw ; we already checked this lane, target can't possible be within hit range

    ldh a, [hCheckedLanes]
    or c ; set lane bit
    ldh [hCheckedLanes], a
    ; not hittable, hittable or missed?
    inc l ; Target_PosY_Frac
    inc l ; Target_PosY_Int
    ld a, [hl-] ; Target_PosY_Int
    dec l ; Target_State
    sub HIT_START_Y
    jr c, .moveAndDraw ; not hittable
    sub HIT_EXTENT
    jr nc, .missed

    ; it's hittable
    ldh a, [hHittableLanes]
    or c ; set lane bit
    ldh [hHittableLanes], a
    ; is it actually hit?
    ldh a, [hLaneInputPosedge]
    and c
    jr z, .moveAndDraw ; not hit

    ; direct hit!
    ldh a, [hHitLanes]
    or c ; set lane bit
    ldh [hHitLanes], a
    jr .next ; don't draw. It will be moved to hit list and processed by ProcessHitTargets

    ; hl should point to Target_State
    .moveAndDraw:
    call MoveTarget
    call DrawNormalTarget

    .next:
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    ld l, a
    ld a, [hl] ; Target_Next
    jr .loop

    .missed:
    ; missing a normal target is punished - if player(s) alive
    ; TODO:
;  + jsr inc_missed_count
;    jsr reset_points_level
;    jsr reset_streak
;    jsr dec_vu_level
;  + lda miss_damage
;    jsr sub_energy_with_pain

; turn off the square wave channels
    ldh [hSoundStatus], a
    or a, 3
    ldh [hSoundStatus], a

; move active target to missed list
    ld a, l
    and a, ~3 ; Target_Next
    ld l, a
    ld a, [hl] ; old Target_Next
    ld b, a ; save Target_Next
    ld a, ZILCH_ITEM
    ld [hl], a ; Target_Next (end of list)
    ldh a, [hMissedTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hMissedTargetsTail], a ; make this the new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .30
    ld a, l
    ldh [hMissedTargetsHead], a
    jr .40
    .30:
    ld a, l
    push af ; save this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    pop af ; restore this target
    ld l, a
    .40:
    ldh a, [hActiveTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .50
    ldh [hActiveTargetsTail], a ; yes. Previous becomes new tail
    .50:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .60
    ld a, b ; old Target_Next
    ldh [hActiveTargetsHead], a ; yes. Next becomes new head
    jp .loop
    .60:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    jp .loop

; HL = pointer to Target_State
MoveTarget:
    inc l ; Target_PosY_Frac
    ; TODO: can we drop frac part?
    inc l ; Target_PosY_Int
    ld a, [hl] ; Target_PosY_Int
    inc a
    ld [hl-], a ; Target_PosY_Int
    ret

; HL = pointer to Target_PosY_Frac
DrawNormalTarget:
    push hl ; Target_PosY_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc e ; Target_PosY_Int
    ld a, [de] ; Target_PosY_Int
    ld b, a
    dec e ; Target_PosY_Frac
    dec e ; Target_State
    ld a, [de] ; Target_State
    and a, 3 ; lane
    sla a
    sla a ; lane * 4
    push af
    sla a
    sla a ; lane * 16 (0, 16, 32, 48)
    bit 5, a ; is it lane 2 or 3 (B or A)?
    jr z, .10
    add 16 ; middle gap
    .10:
    add a, 40 ; left offset
    ld c, a ; x
    ; left half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    pop af ; lane * 4
    push af
    add a, $76
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    add a, 8
    ld [hli], a ; x
    pop af ; lane * 2
    add a, $76+2
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosY_Frac
    ret

; HL = pointer to Target_PosY_Frac
; Destroys: AF, BC, DE
DrawExplodedTarget:
    push hl ; Target_PosY_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc e ; Target_PosY_Int
    ld a, [de] ; Target_PosY_Int
    ld b, a
    dec e ; Target_PosY_Frac
    dec e ; Target_State
    ld a, [de] ; Target_State
    and a, 3 ; lane
    sla a
    sla a
    sla a
    sla a ; lane * 16 (0, 16, 32, 48)
    bit 5, a ; is it lane 2 or 3 (B or A)?
    jr z, .10
    add 16 ; middle gap
    .10:
    add a, 40 ; left offset
    ld c, a ; x
    ; left half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, [de] ; Target_State
    and $38
    srl a
    add a, $86 ; exploded tile base
    push af
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    add a, 8
    ld [hli], a ; x
    pop af
    add a, 2
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosY_Frac
    ret

; ProcessActiveTargets() helper function.
CheckForErrors:
    ldh a, [hLaneInputPosedge]
    ld b, a
    ldh a, [hHittableLanes]
    xor a, b
    and a, b
    ldh [hErrorLanes], a
    ret z ; exit if no errors
    ; TODO
;    jsr deal_error_pain
;    jsr inc_error_count
;    jsr reset_points_level
;    jsr reset_streak
;    jsr dec_vu_level
    ret

; ProcessActiveTargets() helper function.
; Explodes active targets that were hit and moves them to the hit list.
SweepActiveTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hActiveTargetsHead]
    ld l, a
    ld h, HIGH(wTargetsArena)
    .loop:
    ldh a, [hHitLanes]
    or a
    ret z ; exit if no more hits to process

    ld a, [hli] ; Target_Next
    ld b, a
    ld a, [hl] ; Target_State
    ; compute bit mask for lane in C
    ld c, 1
    and a, 3 ; lane
    jr z, .10
    .20:
    sla c
    dec a
    jr nz, .20

    .10:
    ldh a, [hHitLanes]
    and a, c ; is this lane hit?
    jr nz, .hitTarget
    ld a, l
    dec a ; Target_Next
    ldh [hPrev], a
    ld l, b ; Target_Next
    jr .loop

    .hitTarget:
    ld a, c ; lane mask
    xor $ff ; invert
    ld c, a
    ldh a, [hHitLanes]
    and a, c ; mask off this lane
    ldh [hHitLanes], a

;   TODO: jsr on_normal_target_hit
    ; turn on the sound channels
    ldh a, [hSoundStatus]
    and ~3
    ldh [hSoundStatus], a

    inc l ; Target_PosY_Frac
    inc l ; Target_PosY_Int
    ld a, 143 ; lock to grid
    ld [hl-], a ; Target_PosY_Int
    dec l ; Target_State
    dec l ; Target_Next
    call MoveActiveTargetToHitList
    ld l, b ; Target_Next
    jr .loop

; HL = pointer to Target_Next
; B = Target_Next
MoveActiveTargetToHitList:
    ld a, ZILCH_ITEM
    ld [hl], a ; Target_Next
    ldh a, [hHitTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hHitTargetsTail], a ; this target becomes new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hHitTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hActiveTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hActiveTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; Target_Next
    ldh [hActiveTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

ProcessHitTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hHitTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    ret z
    ld l, a
    ld a, [hli] ; Target_Next
    push af ; save Target_Next
    ld a, [hl] ; Target_State
    and a, $3C ; counter bits (5..2)
    cp $3C
    jr z, .evaporated
    ld a, [hl] ; Target_State
    add a, 4 ; increment counter
    ld [hli], a ; Target_State
    call DrawExplodedTarget
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    pop af ; restore Target_Next
    jr .loop

    .evaporated:
    ; put on free list
    dec l ; Target_Next
    ldh a, [hFreeTargetsList] ; old head of free list
    ld [hl], a ; Target_Next
    ld a, l ; this target
    ldh [hFreeTargetsList], a ; make new head of list
    ; remove from hit targets list
    ldh a, [hHitTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .10
    ldh [hHitTargetsTail], a ; yes. Previous becomes new tail
    .10:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .20
    pop af ; restore Target_Next
    ldh [hHitTargetsHead], a ; yes. Next becomes new head
    jr .loop
    .20:
    ld l, a ; previous
    pop af ; restore Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    jr .loop

ProcessMissedTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hMissedTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    ret z ; exit if so
    ld l, a
    ld a, [hli] ; Target_Next
    push af ; save Target_Next
    call MoveTarget
    inc l ; Target_PosY_Int
    ld a, [hl] ; Target_PosY_Int
    cp 160 ; fell off screen?
    jr nc, .fell_off
    ; still visible
    dec l ; Target_PosY_Frac
    call DrawNormalTarget
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    pop af ; restore Target_Next
    jr .loop

    .fell_off:
    ; put on free list
    ld a, l
    and a, ~3 ; Target_Next
    ld l, a
    ldh a, [hFreeTargetsList] ; old head of free list
    ld [hl], a ; Target_Next
    ld a, l ; this target
    ldh [hFreeTargetsList], a ; make new head of list
    ; remove from missed targets list
    ldh a, [hMissedTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .10
    ldh [hMissedTargetsTail], a ; yes. Previous becomes new tail
    .10:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .20
    pop af ; restore Target_Next
    ldh [hMissedTargetsHead], a ; yes. Next becomes new head
    jr .loop
    .20:
    ld l, a ; previous
    pop af ; restore Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    jr .loop

Prng:
    ldh a, [hRandom]
    srl a
    jr nc, .noXor
    xor $B4
    .noXor:
    ldh [hRandom], a
    ret

SECTION "Tile data", ROM0

TitleScreenTiles:
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; blank tile
incbin "pushstarttiles.bin"
TitleScreenTilesEnd:

GameTiles:
incbin "gamescreentiles.bin"
incbin "buttonsprites.bin"
incbin "explosionsprites.bin"
GameTilesEnd:

SECTION "VRAM strings", ROM0

TitleScreenTilemap:
db $99, $05, 10, $01, $02, $03, $04, $00, $03, $05, $06, $07, $05
db 0

GameScreenTilemap:
incbin "gamescreentilemap.bin"

SECTION "Hit cue streams", ROM0

SongHitCueStream:
db $0C,$2C,$58,$B1,$A1,$85,$8B,$16,$34,$30,$B1,$62,$C6,$86,$16,$2C
db $58,$D1,$83,$47,$02,$16,$30,$68,$E0,$42,$C6,$0D,$16,$34,$10,$B1
db $83,$47,$04,$18,$30,$78,$B1,$83,$07,$8B,$18,$30,$78,$B1,$83,$45
db $8E,$04,$18,$58,$B1,$63,$43,$0B,$16,$2C,$68,$61,$62,$C5,$8D,$0C
db $2C,$58,$B1,$A3,$06,$8E,$04,$2C,$60,$D1,$C0,$85,$8C,$1A,$2C,$68
db $21,$63,$06,$8E,$08,$30,$60,$F1,$63,$06,$0F,$16,$30,$60,$F1,$63
db $06,$8B,$1C,$08,$68,$C1,$C1,$01,$8B,$18,$2C,$58,$D0,$40,$C5,$8C
db $16,$2C,$60,$B0,$43,$06,$0E,$08,$2C,$58,$B1,$62,$C5,$8B,$16,$2C
db $58,$B1,$62,$C5,$8B,$16,$2C,$58,$B1,$62,$C5,$8B,$16,$2C,$58,$B1
db $62,$C5,$8B,$16,$34,$60,$E0,$80,$C5,$8C,$16,$2C,$68,$20,$62,$C6
db $0B,$16,$30,$58,$21,$83,$07,$04,$04,$30,$60,$C1,$62,$3C

SECTION "Song data", ROM0

INCLUDE "song.s"
INCLUDE "silentsong.s"
