INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

NEWCHARMAP new
CHARMAP " ", $00
CHARMAP "!", $01
CHARMAP "\"", $02
CHARMAP "#", $03
CHARMAP "$", $04
CHARMAP "%", $05
CHARMAP "&", $06
CHARMAP "'", $07
CHARMAP "(", $08
CHARMAP ")", $09
CHARMAP "*", $0A
CHARMAP "+", $0B
CHARMAP ",", $0C
CHARMAP "-", $0D
CHARMAP ".", $0E
CHARMAP "/", $0F
CHARMAP "0", $10
CHARMAP "1", $11
CHARMAP "2", $12
CHARMAP "3", $13
CHARMAP "4", $14
CHARMAP "5", $15
CHARMAP "6", $16
CHARMAP "7", $17
CHARMAP "8", $18
CHARMAP "9", $19
CHARMAP "A", $21
CHARMAP "B", $22
CHARMAP "C", $23
CHARMAP "D", $24
CHARMAP "E", $25
CHARMAP "F", $26
CHARMAP "G", $27
CHARMAP "H", $28
CHARMAP "I", $29
CHARMAP "J", $2A
CHARMAP "K", $2B
CHARMAP "L", $2C
CHARMAP "M", $2D
CHARMAP "N", $2E
CHARMAP "O", $2F
CHARMAP "P", $30
CHARMAP "Q", $31
CHARMAP "R", $32
CHARMAP "S", $33
CHARMAP "T", $34
CHARMAP "U", $35
CHARMAP "V", $36
CHARMAP "W", $37
CHARMAP "X", $38
CHARMAP "Y", $39
CHARMAP "Z", $3A
CHARMAP "a", $41
CHARMAP "b", $42
CHARMAP "c", $43
CHARMAP "d", $44
CHARMAP "e", $45
CHARMAP "f", $46
CHARMAP "g", $47
CHARMAP "h", $48
CHARMAP "i", $49
CHARMAP "j", $4A
CHARMAP "k", $4B
CHARMAP "l", $4C
CHARMAP "m", $4D
CHARMAP "n", $4E
CHARMAP "o", $4F
CHARMAP "p", $50
CHARMAP "q", $51
CHARMAP "r", $52
CHARMAP "s", $53
CHARMAP "t", $54
CHARMAP "u", $55
CHARMAP "v", $56
CHARMAP "w", $57
CHARMAP "x", $58
CHARMAP "y", $59
CHARMAP "z", $5A

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

hMuteChannelsMask: db

SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4
.end:

wVramBuffer:
    ds 128


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
	db   "SNOWBRO 004", $00, $00, $00, $00, $00

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
	ld   a, %11100100
	ldh  [rBGP], a
	ldh  [rOBP0], a

; palette with white as non-transparent, eg for jumping dancers
	ld   a, %11000100
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

; clear all vram
	ld   hl, $9fff
	ld   c, $20
	xor  a
	ld   b, $00

.clearVram:
	ld   [hl-], a
	dec  b
	jr   nz, .clearVram

	dec  c
	jr   nz, .clearVram

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
    .loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
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
    ld [hl], 0
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


; --- Sound data

DefaultWavRam:
db $11, $22, $33, $44
db $55, $66, $77, $88
db $99, $aa, $bb, $cc
db $dd, $ee, $ff, $ff
;db $11, $23, $56, $78, $99, $98, $76, $67
;db $9a, $df, $fe, $c9, $85, $42, $11, $31

; triangle
db $11, $23, $45, $67
db $89, $ab, $cd, $ef
db $ff, $ee, $dc, $ba
db $98, $76, $54, $32

; sine
;db $89, $bc, $de, $ef
;db $ff, $ee, $dc, $b9
;db $87, $54, $32, $21
;db $11, $22, $34, $57

; sawtooth
;db $11, $22, $33, $44
;db $55, $66, $77, $88
;db $99, $aa, $bb, $cc
;db $dd, $ee, $ff, $ff

; sawtooth
;db $11, $23, $45, $67
;db $89, $ab, $cd, $ef
;db $11, $23, $45, $67
;db $89, $ab, $cd, $ef

; square
;db $11, $11, $11, $11
;db $11, $11, $11, $11
;db $ff, $ff, $ff, $ff
;db $ff, $ff, $ff, $ff

INCLUDE "song.s"

; --- Program-specific code: Our game starts here! ---

Genesis:
	; Copy the background tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
        .copyBgTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, .copyBgTiles

	; Copy the object tile data
	ld de, Tiles
	ld hl, $8000
	ld bc, TilesEnd - Tiles
        .copyObjTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, .copyObjTiles

    ld hl, HelloGameBoy
    call WriteVramStrings

    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld hl, song_song
    call StartSong

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG9800
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
    ; check if channels should be (un)muted
    ldh  a, [hButtonsPressed]
    ld b, a
    call GetMutedChannelsMask
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
    ldh [hMuteChannelsMask], a
    call DrawChannel1Indicator
    call DrawChannel2Indicator
    call DrawChannel3Indicator
    call DrawChannel4Indicator
    ldh a, [hMuteChannelsMask]
    jp SetMutedChannelsMask

DrawChannel1Indicator:
    ldh a, [hMuteChannelsMask]
    bit 0, a
    jr z, .not_muted
    ret
    .not_muted:
    ldh a, [hShadowNR12]
    or a, a
    jr nz, .draw_it
    ret
    .draw_it:
    and a, $0e
    sla a ; ball size (0..7) * 4
    ld d, a
    ld e, 36 + 8
    jp DrawBall

DrawChannel2Indicator:
    ldh a, [hMuteChannelsMask]
    bit 1, a
    jr z, .not_muted
    ret
    .not_muted:
    ldh a, [hShadowNR22]
    or a, a
    jr nz, .draw_it
    ret
    .draw_it:
    and a, $0e
    sla a ; ball size (0..7) * 4
    ld d, a
    ld e, 36 + 24 + 8
    jp DrawBall

DrawChannel3Indicator:
    ldh a, [hMuteChannelsMask]
    bit 2, a
    jr z, .not_muted
    ret
    .not_muted:
    ldh a, [hShadowNR32]
    or a, a
    jr nz, .draw_it
    ret
    .draw_it:
    and a, $0e
    sla a ; ball size (0..7) * 4
    ld d, a
    ld e, 36 + 24 + 24 + 8
    jp DrawBall

DrawChannel4Indicator:
    ldh a, [hMuteChannelsMask]
    bit 3, a
    jr z, .not_muted
    ret
    .not_muted:
    ldh a, [hShadowNR42]
    or a, a
    jr nz, .draw_it
    ret
    .draw_it:
    and a, $0e
    sla a ; ball size (0..7) * 4
    ld d, a
    ld e, 36 + 24 + 24 + 24 + 8
    jp DrawBall

DrawBall:
    ; D = ball size * 4
    ; E = X pos
    ; left half
    call BeginDrawSprites
    ld a, 96 + 16
    ld [hli], a ; y
    ld a, e
    ld [hli], a ; x
    ld a, d
    add a, $60
    ld [hli], a ; tile
    xor a
    ld [hli], a  ; attributes
    call EndDrawSprites
    ; right half
    call BeginDrawSprites
    ld a, 96 + 16
    ld [hli], a ; y
    ld a, e
    add a, 8
    ld [hli], a ; x
    ld a, d
    add a, $62
    ld [hli], a ; tile
    xor a
    ld [hli], a  ; attributes
    jp EndDrawSprites

SECTION "Tile data", ROM0

Tiles:
incbin "font.bin"
incbin "ball.bin"
TilesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoy:
db $98, $42, 15, "Save Your Tears"
db $98, $A4, 11, "Original by"
db $98, $C4, 10, "The Weeknd"
db $99, $06, 7,  "Remixed"
db $99, $25, 9, "in stereo"
db $99, $45, 9, "in Norway"
db $99, $E4, 12, "Use D-pad to"
db $9A, $02, 15, "toggle channels"
db 0
