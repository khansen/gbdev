INCLUDE "hardware.inc"

NEWCHARMAP new
CHARMAP " ", $0
CHARMAP "A", $B7
CHARMAP "B", $B8
CHARMAP "C", $B9
CHARMAP "D", $BA
CHARMAP "E", $BB
CHARMAP "F", $BC
CHARMAP "G", $BD
CHARMAP "H", $BE
CHARMAP "I", $BF
CHARMAP "J", $C0
CHARMAP "K", $C1
CHARMAP "L", $C2
CHARMAP "M", $C3
CHARMAP "N", $C4
CHARMAP "O", $C5
CHARMAP "P", $C6
CHARMAP "Q", $C7
CHARMAP "R", $C8
CHARMAP "S", $C9
CHARMAP "T", $CA
CHARMAP "U", $CB
CHARMAP "V", $CC
CHARMAP "1", $CD
CHARMAP "-", $CE
CHARMAP "@", $CF
CHARMAP "a", $D0
CHARMAP "b", $D1
CHARMAP "c", $D2
CHARMAP "d", $D3
CHARMAP "e", $D4
CHARMAP "f", $D5
CHARMAP "g", $D6
CHARMAP "h", $D7
CHARMAP "i", $D8
CHARMAP "j", $D9
CHARMAP "k", $DA
CHARMAP "l", $DB
CHARMAP "m", $DC
CHARMAP "n", $DD
CHARMAP "o", $DE
CHARMAP "p", $DF
CHARMAP "q", $E0
CHARMAP "r", $E1
CHARMAP "s", $E2
CHARMAP "t", $E3
CHARMAP "u", $E4
CHARMAP "v", $E5
CHARMAP "x", $E6
CHARMAP "y", $E7

SECTION "HRAM", HRAM[$ff80]

hOamDmaFunction:
    ds $0a
.end:

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
	db   "SNOWBRO 020", $00, $00, $00, $00

HeaderCGBFlag:
    db   $80

	setcharmap new

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

        call FlushVramBuffer
	    call hOamDmaFunction
        ldh a, [hScrollX]
        ldh [rSCX], a
        ldh a, [hScrollY]
        ldh [rSCY], a
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
	ld   c, a
	ldh  a, [hButtonsHeld]
	xor  c
	and  c
	ldh  [hButtonsPressed], a
	ld   a, c
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

; standard palettes
	ld   a, %00101101
	ldh  [rBGP], a
	ldh  [rOBP0], a
	ldh  [rOBP1], a

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

; clear all vram bank 1
	ld   hl, $9fff
	ld   c, $20
	ld   a, 1
    ldh [rVBK], a ; select bank 1
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
    ldh [rVBK], a ; select bank 0
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
    bit 6, a
    jr nz, .is_rle
    ld b, a
    .loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    jr WriteVramStrings
    .is_rle:
    and a, $3f
    ld b, a
    ld a, [hli]
    .rle_loop:
    ld [de], a
    inc de
    dec b
    jr nz, .rle_loop
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
    ld [hl], a ; Track_Effect_Param
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
dw .set_global_vol ; 7

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

.set_global_vol:
    pop hl ; Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ld a, [de] ; new global vol (0..F)
    inc de
    swap a ; new volume in upper 4 bits
    ldh [hMasterVol], a
    call IncPatternPtr
    scf ; CF=1 signals keep processing pattern data
    ret

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
    ld a, [hl] ; Track_PeriodHi
    cp a, 7
    jr z, .clamp_slide_up
    inc [hl] ; Track_PeriodHi
    .slide_skip_inc:
    pop hl ; Track_Effect_Param
    ret
    .clamp_slide_up:
    dec l ; Track_PeriodLo
    ld a, $ff
    ld [hl], a ; Track_PeriodLo
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
    ld a, [hl] ; Track_PeriodHi
    or a, a
    jr z, .clamp_slide_down
    dec [hl] ; Track_PeriodHi
    .slide_skip_dec:
    pop hl ; Track_Effect_Param
    ret
    .clamp_slide_down:
    dec l ; Track_PeriodLo
    ld [hl], a ; Track_PeriodLo
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
db $11, $23, $56, $78, $99, $98, $76, $67
db $9a, $df, $fe, $c9, $85, $42, $11, $31

;db $11, $22, $33, $44
;db $55, $66, $77, $88
;db $99, $aa, $bb, $cc
;db $dd, $ee, $ff, $ff

;db $11, $11, $11, $11
;db $88, $88, $88, $88
;db $cc, $cc, $cc, $cc
;db $cc, $cc, $cc, $cc

; --- End sound engine ---

; --- Sound data

INCLUDE "song.s"

; --- Program-specific code: Our game starts here! ---

Genesis:
	; Copy the background tile data
	ld de, BGTiles
	ld hl, $8000
	ld bc, BGTilesEnd - BGTiles
        .copyBgTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, .copyBgTiles

    ; copy bg palette data
    ld a, BCPSF_AUTOINC | 0
    ldh [rBCPS], a
    ld hl, BGPalettes
    ld c, BGPalettesEnd - BGPalettes
    .copyBgPalettes:
    ld a, [hli]
    ldh [rBCPD], a
    dec c
    jr nz, .copyBgPalettes

    ld a, 0
    ldh [rVBK], a ; select bank 0
    ld hl, HelloGameBoyTileMapData
    call WriteVramStrings
    ldh a, [rSVBK]
    cp a, $ff ; are we on DMG or CGB?
    jr z, .loadDMGTileMap
    ; load CGB attributes
    ld a, 1
    ldh [rVBK], a ; select bank 1
    ld hl, HelloGameBoyTileMapAttributeData
    call WriteVramStrings
    jr .doneLoadingTileMap

    .loadDMGTileMap:
    ld hl, HelloGameBoyDMGTileMapData
    call WriteVramStrings

    .doneLoadingTileMap:
    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld hl, song_song
    call StartSong
    ld a, $0
    ldh [hSoundStatus], a ; unmute all channels

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

	; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000 | LCDCF_BG9800
	ld [rLCDC], a

Done:
    halt
    jp Done

; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc0

MainFunc0:
    call HideAllSprites

    ldh a, [hFrameCounter]
    inc a
    ldh [hFrameCounter], a
    and a, 15
    jr nz, .no_scroll
    ldh a, [hScrollY]
    inc a
    ldh [hScrollY], a
    .no_scroll:

    ; check if channels should be (un)muted
    ldh  a, [hButtonsPressed]
    ld b, a
    ldh a, [hSoundStatus]
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
    ldh [hSoundStatus], a
    ret

SECTION "Tile data", ROM0

BGTiles:
; packchr --nametable-base=0x00 --character-output=titletiles.bin title.bin
incbin "titletiles.bin"
incbin "font.bin"
incbin "flag.bin"
BGTilesEnd:

SECTION "Palette data", rom0

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

BGPalettes:
; 0 - title
rgb 16, 8, 28
rgb 0, 0, 0
rgb 8, 4, 14
rgb 28, 28, 28
; 1 - flag
rgb 16, 8, 28
rgb 20, 0, 0
rgb 0, 0, 31
rgb 31, 31, 31
; 2 - text
rgb 16, 8, 28
rgb 16, 10, 2
rgb 0, 0, 0
rgb 31, 24, 10
; 3 - highlight
rgb 16, 8, 28
rgb 0, 12, 8
rgb 0, 0, 0
rgb 8, 31, 16
BGPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
; packnam --width=20 --vram-address=0x9800 --output=titletilemap.bin packchr.nam
incbin "titletilemap.bin"
db $9A, $42, 15, "Smooth Criminal"
db $9A, $81, 17, "Original music by"
db $9A, $C2, 15, "Michael Jackson"
db $9B, $03, 10, "Remixed in"
db $9B, $0E, 2, $E8,$E9 ; flag
db $9B, $42, 15, "as requested by"
db $9B, $85, 9, "@RiDDD111"
db $9B, $C4, 12, "Use D-pad to"
db $9B, $E2, 15, "toggle channels"
db 0

HelloGameBoyDMGTileMapData:
db $9B, $0E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
; flag
db $9B, $0E, 2, $01,$01
; text
db $9A, $42, $40 | 15, 2
db $9A, $81, $40 | 17, 2
db $9A, $C2, $40 | 15, 2
db $9B, $03, $40 | 10, 2
db $9B, $42, $40 | 15, 2
db $9B, $85, $40 | 9, 3
db $9B, $C4, $40 | 12, 2
db $9B, $E2, $40 | 15, 2
db 0
