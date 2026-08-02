INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

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


SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4

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


; --- Sound data

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
    jp SetMutedChannelsMask

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
