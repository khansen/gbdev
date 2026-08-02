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
CHARMAP "-", $18
CHARMAP "4", $1A
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
CHARMAP "Z", $34

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

; --- Begin object engine

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


; --- Begin object engine

rsreset
def Object_Next      rw 1                           ; 00
def Object_State     rb 1                           ; 02
def Object_SpeedX_Frac rb 1                         ; 03
def Object_SpeedX_Int  rb 1                         ; 04
def Object_PosX_Frac rb 1                           ; 05
def Object_PosX_Int  rb 1                           ; 06
def Object_SpeedY_Frac rb 1                         ; 07
def Object_SpeedY_Int  rb 1                         ; 08
def Object_PosY_Frac rb 1                           ; 09
def Object_PosY_Int  rb 1                           ; 0A
def Object_SIZEOF    rb 0                           ; 0B

def MAX_OBJECTS equ 30

wObjectsArena:
  ds Object_SIZEOF * MAX_OBJECTS

; --- End object engine

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
	db   "SNOWBRO 022", $00, $00, $00, $00

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
        call UpdateCloudPalette
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
    push hl ; Object_State
    call UpdateObject
    pop hl ; Object_State
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
    jp UpdateDrop

UpdateDrop:
    ; move down
    inc hl ; Object_PosX_Int
    inc hl ; Object_PosY_Frac
    inc hl ; Object_PosY_Int
    ldh a, [hCurrentObjectState]
    and a, 1 ; near (0) or far (1)
    add a, a
    ld b, a
    ld a, 3
    sub a, b
    ld b, a
    ld a, [hl] ; Object_PosY_Int
    add a, b
    cp a, 160
    jr c, .stayAlive
    ld a, 1
    ld [hKillMe], a
    ret
.stayAlive:
    ld [hl-], a ; Object_PosY_Int
    dec hl ; Object_PosX_Int
    dec hl ; Object_PosX_Frac
    jp DrawDropFrame0

DrawDropFrame0:
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
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $00
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    and a, 1 ; near (0) or far (1)
    jr z, .skip
    or a, $80
.skip:
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

; --- End object engine ---


; --- Sound data

DefaultWavRam:
db $11, $11, $22, $22
db $33, $44, $66, $88
db $99, $aa, $bb, $cc
db $dd, $ee, $ff, $ff

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
    call MaybeSpawnDrop
    call UpdateObjects

    ldh a, [hFrameCounter]
    inc a
    ldh [hFrameCounter], a
    and a, 15
    jr nz, .no_scroll
    ldh a, [hScrollY]
    dec a
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

MaybeSpawnDrop:
    ldh a, [hSpawnTimer]
    inc a
    cp a, 5
    jr c, .noSpawn
    ; a >= 5
    xor a
    ld [hSpawnTimer], a
    jr SpawnDrop
.noSpawn:
    ld [hSpawnTimer], a
    ret

SpawnDrop:
    call AllocateObject
    inc hl ; Object_Next (high)
    inc hl ; Object_State
    ldh a, [hCreatureIndex]
    xor b ; compute initial state
    bit 1, a
    jr nz, .skip4
    set 0, b ; far away
.skip4:
    ld a, b
    ld [hli], a ; Object_State
    xor a
    ld [hli], a ; Object_PosX_Frac
    ldh a, [hCreatureIndex]
    inc a
    ldh [hCreatureIndex], a
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
    ld [hl], a ; Object_PosY_Int
    ret
.startX:
db 47, 152, 23, 128, 89, 12, 143, 68, 34, 111, 78, 149, 56, 122, 44, 137
db 92, 18, 146, 61, 33, 115, 82, 151, 27, 108, 71, 133, 49, 126, 38, 144
db 15, 97, 64, 148, 41, 119, 86, 131, 53, 142, 29, 103, 76, 150, 22, 112
db 88, 36, 127, 58, 145, 31, 106, 73, 134, 47, 121, 84, 152, 19, 98, 65
db 43, 116, 81, 138, 25, 107, 69, 147, 34, 122, 51, 135, 28, 104, 77, 143
db 16, 96, 62, 129, 45, 118, 83, 151, 37, 109, 74, 140, 21, 99, 67, 132
db 54, 125, 39, 113, 85, 148, 26, 101, 72, 136, 48, 123, 91, 146, 32, 108
db 63, 134, 42, 117, 79, 152, 24, 102, 68, 141, 35, 114, 87, 149, 29, 105
db 75, 138, 51, 124, 43, 115, 82, 147, 31, 106, 64, 133, 46, 119, 88, 150
db 22, 98, 71, 142, 37, 112, 85, 128, 52, 121, 69, 135, 48, 116, 83, 144
db 28, 103, 76, 139, 45, 122, 87, 151, 34, 109, 61, 131, 53, 118, 81, 146
db 19, 95, 67, 136, 41, 114, 78, 152, 25, 104, 72, 143, 38, 111, 84, 147
db 32, 107, 65, 132, 49, 123, 86, 137, 27, 101, 74, 145, 36, 113, 82, 148
db 23, 99, 68, 134, 47, 119, 89, 151, 31, 105, 77, 141, 42, 116, 85, 149
db 26, 102, 71, 135, 44, 121, 88, 152, 33, 108, 63, 138, 51, 124, 79, 143
db 21, 97, 66, 131, 39, 115, 83, 146, 28, 103, 75, 142, 35, 112, 87, 150

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

UpdateCloudPalette:
    ldh a, [hFrameCounter]
    and a, $1f
    ret nz
    ldh a, [hFrameCounter]
    and a, $e0
    srl a
    srl a
    ld c, a
    ld b, 0
    ld hl, .palettes
    add hl, bc
    ld a, BCPSF_AUTOINC | 2*8
    ldh [rBCPS], a
    ld c, 8
    .loop:
    ld a, [hli]
    ldh [rBCPD], a
    dec c
    jr nz, .loop
    ret
.palettes:
; 0
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 8, 15, 15
    rgb 6, 8, 12
; 1
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 11, 17, 18
    rgb 9, 12, 16
; 2
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 14, 19, 21
    rgb 12, 16, 20
; 3
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 17, 22, 25
    rgb 16, 20, 24
; 4
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 20, 25, 29
    rgb 20, 25, 29
; 5
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 17, 22, 25
    rgb 16, 20, 24
; 6
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 14, 19, 21
    rgb 12, 16, 20
; 7
    rgb 0, 0, 0
    rgb 20, 25, 29
    rgb 11, 17, 18
    rgb 9, 12, 16

SECTION "Tile data", ROM0

BGTiles:
incbin "font.bin"  ; $00 - 56 tiles
incbin "flag.bin"  ; $38 - 2 tiles
incbin "cloud.bin" ; $3A - 9 tiles
BGTilesEnd:

OBJTiles:
incbin "drop.bin"  ; $00 - 2 tiles
OBJTilesEnd:

SECTION "Palette data", rom0

BGPalettes:
; 0 - background and text
rgb 0, 0, 0
rgb 12, 12, 12
rgb 0, 0, 0
rgb 31, 31, 31
; 1 - flag
rgb 0, 0, 0
rgb 20, 0, 0
rgb 0, 0, 31
rgb 31, 31, 31
; 2 - cloud
rgb 0, 0, 0
rgb 20, 25, 29
rgb 8, 15, 15
rgb 6, 8, 12
BGPalettesEnd:

OBJPalettes:
; 0 - drop (near)
rgb 0, 0, 0
rgb 16, 16, 31
rgb 10, 10, 22
rgb 4, 4, 11
; 1 - drop (far)
rgb 0, 0, 0
rgb 8, 8, 15
rgb 5, 5, 11
rgb 2, 2, 5
OBJPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
db $98, $26, 8, "Rain Man"
db $98, $81, 17, "Original music by"
db $98, $c5, 11, "Hans Zimmer"
db $99, $23, 10, "Remixed in"
db $99, $2E, 2, $38,$39 ; flag
db $99, $84, 12, "Use D-pad to"
db $99, $C2, 15, "toggle channels"
; cloud 0
db $9B, $46, 4,  $3A, $3B, $3A, $3B
db $9B, $63, 7,  $3A, $3C, $3A, $3F, $3F, $3E, $42
db $9B, $81, 11, $3A, $3C, $3F, $3F, $3D, $3E, $3F, $3F, $3C, $3B, $3C
db $9B, $A1, 11, $40, $41, $3E, $3D, $3E, $3F, $3E, $42, $40, $41, $42
db $9B, $C3, 5,  $40, $41, $42, $40, $42
; cloud 1
db $9B, $0E, 3, $3A, $3B, $3C
db $9B, $2D, 6, $3A, $3D, $3D, $3E, $3B, $3C
db $9B, $4D, 6, $40, $41, $41, $42, $41, $42
; cloud 2
db $9A, $A0, 3, $3A, $3B, $3C
db $9A, $C0, 5, $3E, $3F, $3F, $3C, $3C
db $9A, $E0, 5, $3F, $3D, $3E, $3E, $42
db $9B, $00, 4, $3E, $3F, $41, $42
db $9B, $20, 2, $41, $42
; cloud 3
db $9A, $49, 4,  $3A, $3B, $3B, $3C
db $9A, $67, 8,  $3A, $3B, $3F, $3F, $3E, $3F, $3C, $3C
db $9A, $86, 14, $3A, $3F, $3D, $3E, $3F, $3F, $3F, $3F, $3E, $3C, $3B, $3C, $3A, $3B
db $9A, $A6, 14, $40, $41, $41, $41, $3D, $3E, $3E, $3E, $42, $40, $41, $41, $3D, $3E
db $9A, $CA, 4,  $40, $41, $41, $42
db $9A, $D2, 2,  $40, $41
db 0

HelloGameBoyDMGTileMapData:
db $99, $2E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
; flag
db $99, $2E, 2, $01,$01
; cloud 0
db $9B, $46, 4, $02,$02,$02,$02
db $9B, $63, 7, $02,$02,$02,$02,$02,$02,$02
db $9B, $81, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $9B, $A1, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $9B, $C3, 5, $02,$02,$02,$02,$02
; cloud 1
db $9B, $0E, 3, $02,$02,$02
db $9B, $2D, 6, $02,$02,$02,$02,$02,$02
db $9B, $4D, 6, $02,$02,$02,$02,$02,$02
; cloud 2
db $9A, $A0, 3, $02,$02,$02
db $9A, $C0, 5, $02,$02,$02,$02,$02
db $9A, $E0, 5, $02,$02,$02,$02,$02
db $9B, $00, 4, $02,$02,$02,$02
db $9B, $20, 2, $02,$02
; cloud 3
db $9A, $49, 4,  $02,$02,$02,$02
db $9A, $67, 8,  $02,$02,$02,$02,$02,$02,$02,$02
db $9A, $86, 14, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $9A, $A6, 14, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $9A, $CA, 4,  $02,$02,$02,$02
db $9A, $D2, 2,  $02,$02
db 0
