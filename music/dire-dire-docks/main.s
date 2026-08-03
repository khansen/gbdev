INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

NEWCHARMAP new
CHARMAP " ", $00
CHARMAP "A", $01
CHARMAP "B", $02
CHARMAP "C", $03
CHARMAP "D", $04
CHARMAP "E", $05
CHARMAP "F", $06
CHARMAP "G", $07
CHARMAP "H", $08
CHARMAP "I", $09
CHARMAP "J", $0A
CHARMAP "K", $0B
CHARMAP "L", $0C
CHARMAP "M", $0D
CHARMAP "N", $0E
CHARMAP "O", $0F
CHARMAP "P", $10
CHARMAP "Q", $11
CHARMAP "R", $12
CHARMAP "S", $13
CHARMAP "T", $14
CHARMAP "U", $15
CHARMAP "V", $16
CHARMAP "W", $17
CHARMAP "X", $18
CHARMAP "Y", $19
CHARMAP "Z", $1A
CHARMAP "a", $1B
CHARMAP "b", $1C
CHARMAP "c", $1D
CHARMAP "d", $1E
CHARMAP "e", $1F
CHARMAP "f", $20
CHARMAP "g", $21
CHARMAP "h", $22
CHARMAP "i", $23
CHARMAP "j", $24
CHARMAP "k", $25
CHARMAP "l", $26
CHARMAP "m", $27
CHARMAP "n", $28
CHARMAP "o", $29
CHARMAP "p", $2A
CHARMAP "q", $2B
CHARMAP "r", $2C
CHARMAP "s", $2D
CHARMAP "t", $2E
CHARMAP "u", $2F
CHARMAP "v", $30
CHARMAP "w", $31
CHARMAP "x", $32
CHARMAP "y", $33
CHARMAP "z", $34
CHARMAP "-", $35
CHARMAP ",", $36

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

hCount: db
hSampleIndex: db


hObjectsHead: dw
hObjectsFreeHead: dw
hKillMe: db
hCreatureIndex: db
hSpawnTimer: db
hCurrentObjectState: db


SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4
.end:

wVramBuffer:
    ds 128


rsreset
def Object_Next      rw 1                           ; 00
def Object_State     rb 1                           ; 02
def Object_PosX_Frac rb 1                           ; 03
def Object_PosX_Int  rb 1                           ; 04
def Object_PosY_Frac rb 1                           ; 05
def Object_PosY_Int  rb 1                           ; 06
def Object_SIZEOF    rb 0                           ; 07

def MAX_OBJECTS equ 8

wObjectsArena:
  ds Object_SIZEOF * MAX_OBJECTS

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
	db   "SNOWBRO 007", $00, $00, $00, $00

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

; --- Begin object engine ---

InitializeObjects:
    ld hl, wObjectsArena
    ld a, l
    ldh [hObjectsFreeHead+0], a
    ld a, h
    ldh [hObjectsFreeHead+1], a
    ld c, MAX_OBJECTS-1
.loop:
    ld a, l
    add a, Object_SIZEOF
    ld [hl], a ; Object_Next (low)
    push af
    ld a, h
    adc a, 0
    inc hl
    ld [hl], a ; Object_Next (high)
    ld h, a
    pop af
    ld l, a
    dec c
    jr nz, .loop
    xor a
    ld [hli], a ; Object_Next (low)
    ld [hli], a ; Object_Next (high)
    ldh [hObjectsHead+0], a
    ldh [hObjectsHead+1], a
    ret

; returns: hl = pointer to object
AllocateObject:
    ; take the first object from free list
    ld a, [hObjectsFreeHead+0]
    ld l, a
    ld a, [hObjectsFreeHead+1]
    ld h, a
    or a, l
    jr nz, .ok
    ; out of memory
    jp Reset
.ok:
    ; make free next the new free head
    ld a, [hli] ; Object_Next (low)
    ldh [hObjectsFreeHead+0], a
    ld a, [hl] ; Object_Next (high)
    ldh [hObjectsFreeHead+1], a
    ; make old objects head the next object
    ldh a, [hObjectsHead+1]
    ld [hl-], a ; Object_Next (high)
    ldh a, [hObjectsHead+0]
    ld [hl], a ; Object_Next (low)
    ; make allocated object the new objects head
    ld a, l
    ldh [hObjectsHead+0], a
    ld a, h
    ldh [hObjectsHead+1], a
    ret

UpdateObjects:
    ld a, [hObjectsHead+0]
    ld l, a
    ld a, [hObjectsHead+1]
    ld h, a
    ; clear the objects list
    xor a
    ldh [hObjectsHead+0], a
    ldh [hObjectsHead+1], a
.loop:
    ld a, l
    or a, h
    jr z, .exit
    ld a, [hli] ; Object_Next (low)
    push af
    ld a, [hli] ; Object_Next (high)
    push af
    push hl ; Object_PosX_Frac
    call UpdateObject
    pop hl ; Object_PosX_Frac
    dec hl ; Object_Next (high)
    ldh a, [hKillMe]
    or a
    jr z, .keepObject
    xor a
    ldh [hKillMe], a
    ; move to free list
    ldh a, [hObjectsFreeHead+1]
    ld [hl-], a ; Object_Next (high)
    ldh a, [hObjectsFreeHead+0]
    ld [hl], a ; Object_Next (low)
    ld a, l
    ldh [hObjectsFreeHead+0], a
    ld a, h
    ldh [hObjectsFreeHead+1], a
.nextObject:
    pop af ; Object_Next (high)
    ld h, a
    pop af ; Object_Next (low)
    ld l, a
    jr .loop
.keepObject:
    ; make current object new head of objects
    ldh a, [hObjectsHead+1]
    ld [hl-], a ; Object_Next (high)
    ldh a, [hObjectsHead+0]
    ld [hl], a ; Object_Next (low)
    ld a, l
    ldh [hObjectsHead+0], a
    ld a, h
    ldh [hObjectsHead+1], a
    jr .nextObject
.exit:
    ret

; hl = pointer to Object_State
UpdateObject:
    ld a, [hli] ; Object_State
    ldh [hCurrentObjectState], a
    bit 0, a ; type (0=fish, 1=blooper)
    jp z, UpdateFish
    jp UpdateBlooper

; a = Object_State
; hl = pointer to Object_PosX_Frac
UpdateBlooper:
    bit 2, a ; phase. 0 = propelling, 1 = resting
    jr nz, .rest
    ; propelling
    bit 1, a ; direction (0=right, 1=left)
    jr z, .propelRight
    ; propel left
    ld a, [hl] ; Object_PosX_Frac
    sub a, 128
    ld [hli], a ; Object_PosX_Frac
    jr nc, .propelUp
    dec [hl] ; Object_PosX_Int
    ld a, [hl] ; Object_PosX_Int
    cp a, 248
    jr nz, .propelUp
    ; a == 248
    ld a, 1
    ld [hKillMe], a
    ret
.propelUp:
    inc hl ; Object_PosY_Frac
    ld a, [hl] ; Object_PosY_Frac
    sub a, 64
    ld [hl], a ; Object_PosY_Frac
    jr nc, .noYDec
    inc hl ; Object_PosY_Int
    dec [hl] ; Object_PosY_Int
    dec hl ; Object_PosY_Frac
.noYDec:
    dec hl ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
    dec hl ; Object_State
    ld a, [hl] ; Object_State
    add a, 8
    cp a, 248
    jr c, .skip3
    ; switch to resting phase
    and a, 7
    set 2, a ; phase = resting
.skip3:
    ld [hli], a ; Object_State
    jp DrawBlooperFrame1
.propelRight:
    ld a, [hl] ; Object_PosX_Frac
    add a, 128
    ld [hli], a ; Object_PosX_Frac
    jr nc, .propelUp
    inc [hl] ; Object_PosX_Int
    ld a, [hl] ; Object_PosX_Int
    cp a, 168
    jr c, .propelUp
    ; a >= 168
    ld a, 1
    ld [hKillMe], a
    ret
.rest:
    inc hl ; Object_PosX_Int
    inc hl ; Object_PosY_Frac
    ld a, [hl] ; Object_PosY_Frac
    add a, 64
    ld [hl], a ; Object_PosY_Frac
    jr nc, .noYInc
    inc hl ; Object_PosY_Int
    inc [hl] ; Object_PosY_Int
    dec hl ; Object_PosY_Frac
.noYInc:
    dec hl ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
    dec hl ; Object_State
    ld a, [hl] ; Object_State
    add a, 8
    cp a, 248
    jr c, .skip4
    ; switch to propelling phase
    and a, 3
.skip4:
    ld [hli], a ; Object_State
    jp DrawBlooperFrame0

; a = Object_State
UpdateFish:
    bit 1, a ; direction (0=right, 1=left)
    jr z, .moveRight
    ; move left
    ld a, [hl] ; Object_PosX_Frac
    sub a, 56
    ld [hl], a ; Object_PosX_Frac
    jr nc, .skip
    inc hl ; Object_PosX_Int
    dec [hl] ; Object_PosX_Int
    ld a, [hl-] ; Object_PosX_Int
    cp a, 248
    jr nz, .skip
    ; a == 248
    ld a, 1
    ld [hKillMe], a
    ret
.moveRight:
    ld a, [hl] ; Object_PosX_Frac
    add a, 56
    ld [hl], a ; Object_PosX_Frac
    jr nc, .skip
    inc hl ; Object_PosX_Int
    inc [hl] ; Object_PosX_Int
    ld a, [hl-] ; Object_PosX_Int
    cp a, 168
    jr c, .skip
    ; a >= 168
    ld a, 1
    ld [hKillMe], a
    ret
.skip:
    inc hl ; Object_PosX_Int
    ld a, [hli] ; Object_PosX_Int
    bit 5, a
    jr nz, .moveDown
    ; move up
    ld a, [hl] ; Object_PosY_Frac
    sub a, 24
    ld [hl], a ; Object_PosY_Frac
    jr nc, .skip2
    inc hl ; Object_PosY_Int
    dec [hl] ; Object_PosY_Int
    dec hl ; Object_PosY_Frac
    jr .skip2
.moveDown:
    ld a, [hl] ; Object_PosY_Frac
    add a, 24
    ld [hl], a ; Object_PosY_Frac
    jr nc, .skip2
    inc hl ; Object_PosY_Int
    inc [hl] ; Object_PosY_Int
    dec hl ; Object_PosY_Frac
.skip2:
    dec hl ; Object_PosX_Int
    ld a, [hl-] ; Object_PosX_Int
    and a, 4
    jr nz, .drawFrame1
    ldh a, [hCurrentObjectState]
    bit 1, a ; direction (0=right, 1=left)
    jr z, .drawRightFrame0
    jp DrawFishLeftFrame0
.drawRightFrame0:
    jp DrawFishRightFrame0
.drawFrame1:
    ldh a, [hCurrentObjectState]
    bit 1, a ; direction (0=right, 1=left)
    jr z, .drawRightFrame1
    jp DrawFishLeftFrame1
.drawRightFrame1:
    jp DrawFishRightFrame1

; --- End object engine ---


; --- Sound data

DefaultWavRam:
db $11, $11, $11, $11
db $88, $88, $88, $88
db $cc, $cc, $cc, $cc
db $cc, $cc, $cc, $cc

INCLUDE "song.s"

; --- Program-specific code: Our game starts here! ---

Genesis:
	; Copy the background tile data
	ld de, BGTiles
	ld hl, $9000
	ld bc, BGTilesEnd - BGTiles
        .copyBgTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, .copyBgTiles

	; Copy the object tile data
	ld de, OBJTiles
	ld hl, $8000
	ld bc, OBJTilesEnd - OBJTiles
        .copyObjTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, .copyObjTiles

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

    ; copy obj palette data
    ld a, OCPSF_AUTOINC | 0
    ldh [rOCPS], a
    ld hl, OBJPalettes
    ld c, OBJPalettesEnd - OBJPalettes
    .copyObjPalettes:
    ld a, [hli]
    ldh [rOCPD], a
    dec c
    jr nz, .copyObjPalettes

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
    call InitializeObjects

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
    call MaybeSpawnCreature
    call UpdateObjects
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
    call DrawChannelIndicators
    ldh a, [hMuteChannelsMask]
    jp SetMutedChannelsMask

MaybeSpawnCreature:
    ld a, [hSpawnTimer]
    inc a
    cp a, 230
    jr c, .noSpawn
    ; a >= 230
    xor a
    ld [hSpawnTimer], a
    jr SpawnCreature
.noSpawn:
    ld [hSpawnTimer], a
    ret

SpawnCreature:
    call AllocateObject
    inc hl ; Object_Next (high)
    inc hl ; Object_State
    ldh a, [hCreatureIndex]
    xor b ; compute initial state
    bit 0, a ; even or odd?
    jr z, .skip4
    set 0, b ; type = blooper
.skip4:
    ld c, 0 ; initial x
    and a, 6
    jr nz, .skip2
    set 1, b ; direction = left
    ld c, 168 ; initial x
.skip2:
    bit 0, b ; type
    jr nz, .skip3 ; skip if blooper
    ldh a, [hCreatureIndex]
    and a, 7 ; multiple of 8?
    jr nz, .skip3
    set 2, b ; fish type = gray
.skip3:
    ld a, b
    ld [hli], a ; Object_State
    xor a
    ld [hli], a ; Object_PosX_Frac
    ld a, c
    ld [hli], a ; Object_PosX_Int
    xor a
    ld [hli], a ; Object_PosY_Frac
    ldh a, [hCreatureIndex]
    inc a
    ldh [hCreatureIndex], a
    ld de, .startY
    add a, e
    ld e, a
    jr nc, .skip
    inc d
.skip:
    ld a, [de]
    ld [hl], a ; Object_PosY_Int
    ret
.startY:
db  61, 103,  48, 115,  43,  93,  58,  94,  56,  88, 118,  92,  44, 100,  40, 100
db  51, 123,  51,  88,  47, 122,  59, 116,  67,  43, 113,  72,  36,  86,  57,  83
db 118,  80,  44, 114,  59, 103,  73, 116,  85,  41,  82,  45,  71,  45,  91,  39
db  80, 126,  64, 127,  50,  91, 116,  47, 111,  66,  95,  51, 120,  44,  81, 107
db  72, 108,  56, 109,  81, 117,  84, 116,  66,  37, 109,  40,  80,  45, 122,  72
db 110,  73,  38,  97,  42,  89,  41,  71, 122,  95,  70, 100,  42,  68,  97,  69
db  99,  68, 111,  68, 121,  85,  47, 119,  62,  89,  48, 109,  62,  38,  80,  52
db  89,  51,  97,  39, 102,  77, 114,  46, 120,  86,  44, 101,  39, 116,  72,  37
db 101,  42, 110,  67,  39,  88, 117,  76,  37, 120,  68,  98,  68, 111,  66, 112
db  49,  73, 120,  69, 110,  48,  89,  61,  93,  57, 119,  78, 119,  60, 106,  44
db  81,  48, 104,  65, 121,  62,  89,  60,  84, 126,  53, 128,  37, 111,  73, 115
db  47,  98,  48,  81, 125,  59,  99,  50, 114,  59, 114,  52, 116,  44, 107,  66
db  41,  95,  63,  97,  69, 114,  79, 119,  94,  43, 123,  95,  55,  95,  65,  39
db 122,  76, 111,  50, 101,  69, 122,  36, 113,  63, 115,  76, 120,  78, 106,  42
db  99,  62,  88, 114,  77, 112,  83,  55, 110,  76, 111,  70, 114,  64, 126,  65
db 126,  79, 118,  82,  49,  91,  54,  84,  55, 117,  54, 113,  67,  93,  49, 113

; hl = pointer to Object_PosX_Frac
DrawFishRightFrame0:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $00
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; fish type
    ld a, 0 ; red fish palette
    jr z, .skip
    ld a, 2 ; gray fish palette
.skip:
    push af
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $02
    ld [hli], a ; tile
    pop af
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

; hl = pointer to Object_PosX_Frac
DrawFishRightFrame1:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $04
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; fish type
    ld a, 0 ; red fish palette
    jr z, .skip
    ld a, 2 ; gray fish palette
.skip:
    push af
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $02
    ld [hli], a ; tile
    pop af
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawFishLeftFrame0:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $02
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; fish type
    ld a, 0 ; red fish palette
    jr z, .skip
    ld a, 2 ; gray fish palette
.skip:
    or a, OAMF_XFLIP
    push af
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $00
    ld [hli], a ; tile
    pop af
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawFishLeftFrame1:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $02
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; fish type
    ld a, 0 ; red fish palette
    jr z, .skip
    ld a, 2 ; gray fish palette
.skip:
    or a, OAMF_XFLIP
    push af
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $04
    ld [hli], a ; tile
    pop af
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawBlooperFrame0:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $06
    ld [hli], a ; tile
    ld a, 1
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $06
    ld [hli], a ; tile
    ld a, 1 | OAMF_XFLIP
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawBlooperFrame1:
    push hl ; Object_PosX_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc de ; Object_PosX_Int
    ld a, [de] ; Object_PosX_Int
    ld b, a
    inc de ; Object_PosY_Frac
    inc de ; Object_PosY_Int
    ld a, [de] ; Object_PosY_Int
    ld c, a
    ; left half, top
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $08
    ld [hli], a ; tile
    ld a, 1
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $08
    ld [hli], a ; tile
    ld a, 1 | OAMF_XFLIP
    ld [hli], a  ; attributes
    ; left half, bottom
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $0A
    ld [hli], a ; tile
    ld a, 1
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $0A
    ld [hli], a ; tile
    ld a, 1 | OAMF_XFLIP
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawChannelIndicators:
    ; upper half
    ld de, $9984
    ld c, 11 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ldh a, [hMuteChannelsMask]
    bit 0, a
    jr z, .channel1_not_muted_top
    ld a, 0
    jr .draw_channel1_top
    .channel1_not_muted_top:
    ldh a, [hShadowNR12]
    and a, $0e
    .draw_channel1_top:
    or a, a
    jr z, .draw_channel1_blank_top
    sla a ; ball size (0..7) * 4
    add a, $44
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
    ldh a, [hMuteChannelsMask]
    bit 1, a
    jr z, .channel2_not_muted_top
    ld a, 0
    jr .draw_channel2_top
    .channel2_not_muted_top:
    ldh a, [hShadowNR22]
    and a, $0e
    .draw_channel2_top:
    or a, a
    jr z, .draw_channel2_blank_top
    sla a ; ball size (0..7) * 4
    add a, $44
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
    ldh a, [hMuteChannelsMask]
    bit 2, a
    jr z, .channel3_not_muted_top
    ld a, 0
    jr .draw_channel3_top
    .channel3_not_muted_top:
    ldh a, [hShadowNR32]
    and a, $0e
    .draw_channel3_top:
    or a, a
    jr z, .draw_channel3_blank_top
    sla a ; ball size (0..7) * 4
    add a, $44
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
    ldh a, [hMuteChannelsMask]
    bit 3, a
    jr z, .channel4_not_muted_top
    ld a, 0
    jr .draw_channel4_top
    .channel4_not_muted_top:
    ldh a, [hShadowNR42]
    and a, $0e
    .draw_channel4_top:
    or a, a
    jr z, .draw_channel4_blank_top
    sla a ; ball size (0..7) * 4
    add a, $44
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
    ld de, $99A4
    ld c, 11 ; 2+1+2+1+2+1+2 tiles
    call BeginVramString

    ; channel 1
    ldh a, [hMuteChannelsMask]
    bit 0, a
    jr z, .channel1_not_muted_bottom
    ld a, 0
    jr .draw_channel1_bottom
    .channel1_not_muted_bottom:
    ldh a, [hShadowNR12]
    and a, $0e
    .draw_channel1_bottom:
    or a, a
    jr z, .draw_channel1_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $45
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
    ldh a, [hMuteChannelsMask]
    bit 1, a
    jr z, .channel2_not_muted_bottom
    ld a, 0
    jr .draw_channel2_bottom
    .channel2_not_muted_bottom:
    ldh a, [hShadowNR22]
    and a, $0e
    .draw_channel2_bottom:
    or a, a
    jr z, .draw_channel2_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $45
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
    ldh a, [hMuteChannelsMask]
    bit 2, a
    jr z, .channel3_not_muted_bottom
    ld a, 0
    jr .draw_channel3_bottom
    .channel3_not_muted_bottom:
    ldh a, [hShadowNR32]
    and a, $0e
    .draw_channel3_bottom:
    or a, a
    jr z, .draw_channel3_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $45
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
    ldh a, [hMuteChannelsMask]
    bit 3, a
    jr z, .channel4_not_muted_bottom
    ld a, 0
    jr .draw_channel4_bottom
    .channel4_not_muted_bottom:
    ldh a, [hShadowNR42]
    and a, $0e
    .draw_channel4_bottom:
    or a, a
    jr z, .draw_channel4_blank_bottom
    sla a ; ball size (0..7) * 4
    add a, $45
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

SECTION "Tile data", ROM0

BGTiles:
incbin "font.bin"    ; $00 - 56 tiles
incbin "scenery.bin" ; $38 - 10 tiles
incbin "flag.bin"    ; $42 - 2 tiles
incbin "ball.bin"    ; $44 - 32 tiles
BGTilesEnd:

OBJTiles:
incbin "fish.bin"    ; $00 - 6 tiles
incbin "blooper.bin" ; $06 - 6 tiles
OBJTilesEnd:

SECTION "Palette data", rom0

BGPalettes:
; 0 - sea and letters
dw %0110000000000000
dw %0000000000000000
dw %0111111000010000
dw %0111111111111111
; 1 - rocks
dw %0110000000000000
dw %0100001111110000
dw %0000001001000000
dw %0000000000000000
; 2 - seaweed
dw %0110000000000000
dw %0000000000011000
dw %0000001001000000
dw %0100001000011111
; 3 - flag
dw %0110000000000000
dw %0000000000011111
dw %0110110000000000
dw %0111111111111111
; 4 - orb
dw %0110000000000000
dw %0100001111111111
dw %0010000111101111
dw %0000100000000000
BGPalettesEnd:

OBJPalettes:
; 0 - red fish
dw %0000000000000000
dw %0000000000011111
dw %0111111111111111
dw %0000001111111111
; 1 - blooper
dw %0000000000000000
dw %0000000000000000
dw %0111111111111111
dw %0110000111101111
; 2 - gray fish
dw %0000000000000000
dw %0100011000110001
dw %0111111111111111
dw %0000001111111111
OBJPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
db $98, $00, 20, $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
db $98, $20, 20, $38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38,$38
db $98, $62, 16, "Dire, Dire Docks"
db $98, $A4, 11, "Original by"
db $98, $C5, 10, "Koji Kondo"
db $99, $43, 10, "Remixed in"
db $99, $4E, 2, $42,$43 ; flag
db $99, $C4, 12, "Use D-pad to"
db $99, $E2, 15, "toggle channels"
db $98, $60, 2, $3D,$3E
db $98, $80, 2, $3F,$40
db $98, $A0, 2, $3D,$3E
db $98, $C0, 2, $3F,$40
db $98, $72, 2, $3D,$3E
db $98, $92, 2, $3F,$40
db $98, $B2, 2, $3D,$3E
db $98, $D2, 2, $3F,$40
db $98, $E0, 4, $39,$3A,$39,$3A
db $99, $00, 4, $3B,$3C,$3B,$3C
db $98, $F0, 4, $39,$3A,$39,$3A
db $99, $10, 4, $3B,$3C,$3B,$3C
db $99, $80, 2, $3D,$3E
db $99, $A0, 2, $3F,$40
db $99, $C0, 2, $3D,$3E
db $99, $E0, 2, $3F,$40
db $99, $92, 2, $3D,$3E
db $99, $B2, 2, $3F,$40
db $99, $D2, 2, $3D,$3E
db $99, $F2, 2, $3F,$40
db $9A, $00, 20, $39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A,$39,$3A
db $9A, $20, 20, $3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C,$3B,$3C
db 0

HelloGameBoyDMGTileMapData:
db $99, $4E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
db $98, $60, 2, $02,$02
db $98, $80, 2, $02,$02
db $98, $A0, 2, $02,$02
db $98, $C0, 2, $02,$02
db $98, $72, 2, $02,$02
db $98, $92, 2, $02,$02
db $98, $B2, 2, $02,$02
db $98, $D2, 2, $02,$02
db $98, $E0, 4, $01,$01,$01,$01
db $99, $00, 4, $01,$01,$01,$01
db $98, $F0, 4, $01,$01,$01,$01
db $99, $10, 4, $01,$01,$01,$01
db $99, $4E, 2, $03,$03
db $99, $80, 2, $02,$02
db $99, $84, 11, $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
db $99, $A0, 2, $02,$02
db $99, $A4, 11, $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
db $99, $C0, 2, $02,$02
db $99, $E0, 2, $02,$02
db $99, $92, 2, $02,$02
db $99, $B2, 2, $02,$02
db $99, $D2, 2, $02,$02
db $99, $F2, 2, $02,$02
db $9A, $00, 20, $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
db $9A, $20, 20, $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
db 0
