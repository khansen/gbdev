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
CHARMAP "Z", $17
CHARMAP "-", $18
CHARMAP "2", $19
CHARMAP "0", $1A
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
CHARMAP "@", $34

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

hFrameCounter: db

hScrollCounter: db

hObjectsHead: dw
hObjectsFreeHead: dw
hKillMe: db
hCreatureIndex: db
hSpawnTimer: db
hCurrentObjectState: db


SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4

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

def MAX_OBJECTS equ 20

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
	db   "SNOWBRO 016", $00, $00, $00, $00

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
    jp UpdateSnowflake

; a = Object_State
UpdateSnowflake:
    ; move down
    inc hl ; Object_PosX_Int
    inc hl ; Object_PosY_Frac
    ld a, [hl] ; Object_PosY_Frac
    add a, 140
    ld [hl+], a ; Object_PosY_Frac
    jr nc, .skip
    inc [hl] ; Object_PosY_Int
    ld a, [hl] ; Object_PosY_Int
    cp a, 160
    jr nz, .skip
    ; fell off screen
    ld a, 1
    ld [hKillMe], a
    ret
.skip:
    ; move left or right
    ld a, [hl-] ; Object_PosY_Int
    dec hl ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
    bit 4, a 
    jr nz, .moveRight
    ; move left
    ld a, [hl] ; Object_PosX_Frac
    sub a, 48
    ld [hl], a ; Object_PosX_Frac
    jr nc, .skip2
    inc hl ; Object_PosX_Int
    dec [hl] ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
    jr .skip2
.moveRight:
    ld a, [hl] ; Object_PosX_Frac
    add a, 48
    ld [hl], a ; Object_PosX_Frac
    jr nc, .skip2
    inc hl ; Object_PosX_Int
    inc [hl] ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
.skip2:
    jp DrawSnowflakeFrame0

; --- End object engine ---


; --- Sound data

DefaultWavRam:
db $11, $11, $11, $11
db $88, $88, $88, $88
db $cc, $cc, $ff, $ff
db $ff, $ff, $ff, $ff

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
    call ScrollScreen
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

ScrollScreen:
    ldh a, [hScrollCounter]
    ld de, .scrollX
    add a, e
    ld e, a
    jr nc, .skip
    inc d
.skip:
    ld a, [de]
    ldh [hScrollX], a
    ldh a, [hScrollCounter]
    inc a
    cp a, 208
    jr nz, .skip2
    xor a
.skip2:
    ldh [hScrollCounter], a
    ret
.scrollX:
db 0, 6, 11, 16, 20, 24, 28, 30, 33, 34, 36, 36, 36, 36, 35, 33, 31, 29, 26, 23, 20, 17, 14, 10, 7, 4, 0, -3, -6, -8, -11, -13, -15, -17, -18, -19, -19, -20, -20, -20, -19, -18, -17, -16, -15, -13, -11, -10, -8, -6, -4, -2, 0, 1, 3, 4, 6, 7, 8, 9, 10, 10, 11, 11, 11, 11, 11, 10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1, -1, -2, -3, -4, -4, -5, -5, -6, -6, -6, -6, -6, -6, -6, -5, -5, -5, -4, -4, -3, -2, -2, -1, -1, 0, 0, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

MaybeSpawnCreature:
    ld a, [hSpawnTimer]
    inc a
    cp a, 23
    jr c, .noSpawn
    ; a >= 23
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
    inc a
    ldh [hCreatureIndex], a
    and a, 7 ; snowflake kind
    push af
    ld [hli], a ; Object_State
    xor a
    ld [hli], a ; Object_PosX_Frac
    pop af
    ld de, .startX
    add a, e
    ld e, a
    jr nc, .skip
    inc d
.skip:
    ld a, [de]
    ld [hli], a ; Object_PosX_Int
    xor a
    ld [hli], a ; Object_PosY_Frac
    ld a, 240
    ld [hl], a ; Object_PosY_Int
    ret
.startX:
db 92, 59, 105, 97, 45, 77, 140, 95, 84, 51, 111, 100, 55, 90, 123, 128
db 86, 60, 20, 109, 103, 115, 89, 140, 66, 70, 54, 87, 31, 121, 121, 25
db 119, 32, 112, 91, 136, 111, 84, 37, 56, 44, 103, 20, 128, 129, 113, 74
db 47, 86, 29, 46, 104, 135, 72, 86, 20, 65, 44, 134, 69, 94, 20, 127
db 60, 23, 52, 78, 107, 127, 57, 35, 118, 64, 27, 60, 59, 48, 140, 73
db 114, 124, 57, 60, 57, 34, 82, 140, 109, 53, 60, 120, 52, 41, 135, 30
db 137, 39, 126, 58, 140, 22, 100, 33, 74, 39, 106, 48, 27, 121, 20, 70
db 101, 121, 54, 102, 38, 86, 116, 45, 128, 88, 74, 38, 137, 91, 52, 39
db 124, 24, 25, 42, 45, 84, 118, 72, 113, 59, 135, 31, 102, 53, 43, 139
db 65, 54, 131, 101, 33, 120, 85, 123, 73, 87, 133, 120, 24, 35, 32, 43
db 49, 104, 64, 89, 70, 136, 107, 27, 68, 51, 115, 97, 72, 94, 122, 88
db 34, 64, 70, 96, 62, 38, 27, 80, 96, 102, 72, 31, 32, 72, 59, 82
db 99, 40, 74, 38, 20, 100, 87, 78, 61, 66, 124, 20, 107, 105, 42, 53
db 105, 102, 90, 77, 87, 136, 21, 123, 73, 85, 91, 137, 45, 116, 33, 53
db 83, 119, 73, 134, 51, 122, 65, 109, 66, 22, 101, 95, 126, 105, 81, 116
db 127, 110, 60, 20, 117, 138, 98, 91, 70, 46, 115, 71, 132, 46, 92, 28

DrawSnowflakeFrame0:
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
    add a, 10
    ld c, a
    ; left half
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ldh a, [hCurrentObjectState]
    and a, 7
    add a, a
    add a, a
    push af
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    pop af
    or a, $02
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawChannelIndicators:
    ; upper half
    ld de, $9825
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
    ld de, $9845
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

SECTION "Tile data", ROM0

BGTiles:
incbin "font.bin"  ; $00 - 56 tiles
incbin "flag.bin"  ; $38 - 2 tiles
incbin "ball.bin"  ; $3A - 32 tiles
BGTilesEnd:

OBJTiles:
incbin "snowflakes.bin" ; 32 tiles
OBJTilesEnd:

SECTION "Palette data", rom0

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

BGPalettes:
; 0 - background and text
    rgb 2, 5, 15
    rgb 0, 0, 0
    rgb 0, 0, 0
    rgb 31, 31, 31
; 1 - flag
    rgb 2, 5, 15
dw %0000000000011111
dw %0101000000000000
dw %0111111111111111
; 2 - orb
    rgb 2, 5, 15
    rgb 0, 31, 31
    rgb 1, 10, 31
    rgb 1, 2, 4
; 3 - text highlight
    rgb 2, 5, 15
    rgb 0, 0, 0
    rgb 0, 0, 0
    rgb 31, 31, 2
BGPalettesEnd:

OBJPalettes:
; 0 - snowflake
rgb 2, 5, 15
rgb 4, 7, 20
rgb 12, 16, 26
rgb 28, 30, 31
OBJPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
db $98, $84, 12, "Ice Cap Zone"
db $98, $C1, 17, "Original music by"
db $99, $02, 16, "Brad Buxer et al"
db $99, $43, 10, "Remixed in"
db $99, $4E, 2, $38,$39 ; flag
db $99, $82, 15, "as requested by"
db $99, $A3, 13, "@luigitime202"
db $99, $E4, 12, "Use D-pad to"
db $9A, $02, 15, "toggle channels"
db 0

HelloGameBoyDMGTileMapData:
db $99, $4E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
; flag
db $99, $4E, 2, $01,$01
; orbs
db $98, $25, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $98, $45, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
; text highlight
db $99, $A3, 14, $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
db 0
