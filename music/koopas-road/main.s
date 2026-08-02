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
CHARMAP "6", $19
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
CHARMAP "z", $34
CHARMAP "'", $35
CHARMAP "-", $36

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

def MAX_OBJECTS equ 12

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
	db   "SNOWBRO 008", $00, $00, $00, $00

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
    bit 0, a ; type (0=bulletbill, 1=koopa)
    jp z, UpdateBulletBill
    jp UpdateKoopa

; a = Object_State
; hl = pointer to Object_PosX_Frac
UpdateKoopa:
    ; move left
    ld a, [hl] ; Object_PosX_Frac
    sub a, 80
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
.skip:
    inc hl ; Object_PosX_Int
    ld a, [hli] ; Object_PosX_Int
    bit 5, a
    jr nz, .moveDown
    ; move up
    ld a, [hl] ; Object_PosY_Frac
    sub a, 48
    ld [hl], a ; Object_PosY_Frac
    jr nc, .skip2
    inc hl ; Object_PosY_Int
    dec [hl] ; Object_PosY_Int
    dec hl ; Object_PosY_Frac
    jr .skip2
.moveDown:
    ld a, [hl] ; Object_PosY_Frac
    add a, 48
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
    jp DrawKoopaFrame0
.drawFrame1:
    jp DrawKoopaFrame1

; a = Object_State
UpdateBulletBill:
    ; move left
    inc hl ; Object_PosX_Int
    dec [hl] ; Object_PosX_Int
    ld a, [hl-] ; Object_PosX_Int
    cp a, 248
    jr nz, .skip
    ; a == 248
    ld a, 1
    ld [hKillMe], a
    ret
.skip:
    jp DrawBulletBill

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
    cp a, 56
    jr c, .noSpawn
    ; a >= 56
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
    set 0, b ; type = koopa
.skip4:
    ld c, 168 ; initial x
.skip2:
    bit 0, b ; type
    jr z, .skip3 ; skip if bullet bill
    ldh a, [hCreatureIndex]
    and a, 7
    cp a, 7
    jr nz, .skip3
    set 2, b ; koopa type = red
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
db 82, 36, 124, 68, 44, 121, 58, 83, 126, 59, 126, 85, 40, 124, 79, 47
db 105, 72, 37, 109, 42, 67, 118, 50, 77, 104, 65, 94, 38, 66, 102, 45
db 78, 128, 49, 115, 91, 62, 96, 67, 124, 37, 86, 108, 60, 88, 112, 38
db 78, 120, 69, 118, 60, 89, 116, 65, 41, 93, 55, 125, 97, 69, 103, 41
db 70, 94, 103, 61, 36, 103, 61, 104, 64, 101, 61, 89, 65, 126, 41, 95
db 70, 46, 100, 67, 116, 55, 85, 117, 43, 73, 111, 48, 81, 111, 54, 84
db 117, 50, 87, 117, 47, 92, 118, 64, 93, 64, 91, 116, 63, 91, 39, 125
db 84, 59, 89, 115, 43, 88, 60, 122, 95, 58, 121, 90, 38, 72, 123, 96
db 59, 92, 125, 62, 86, 111, 57, 99, 74, 48, 123, 76, 48, 109, 74, 45
db 98, 42, 70, 99, 42, 97, 127, 53, 86, 113, 39, 63, 112, 51, 75, 99
db 72, 98, 39, 122, 94, 46, 90, 120, 58, 90, 55, 83, 114, 54, 80, 110
db 56, 80, 121, 53, 85, 110, 52, 81, 113, 82, 106, 56, 81, 119, 47, 71
db 101, 45, 77, 113, 76, 44, 104, 68, 36, 107, 69, 43, 107, 74, 115, 100
db 68, 112, 40, 80, 107, 76, 102, 50, 77, 105, 79, 46, 119, 75, 51, 114
db 78, 52, 98, 122, 63, 95, 51, 120, 96, 71, 56, 106, 66, 93, 54, 87
db 127, 52, 87, 100, 73, 102, 37, 73, 105, 49, 108, 82, 108, 57, 83, 109

DrawBulletBill:
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
    ld a, 1 ; palette
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

DrawKoopaFrame0:
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
    ld a, $06
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; koopa type
    ld a, 2 ; green palette
    jr z, .skip
    ld a, 3 ; red palette
.skip:
    or a, OAMF_XFLIP
    push af
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $04
    ld [hli], a ; tile
    pop af
    push af
    ld [hli], a  ; attributes
    ; left half, bottom
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $0E
    ld [hli], a ; tile
    pop af
    push af
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $0C
    ld [hli], a ; tile
    pop af
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

DrawKoopaFrame1:
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
    ld a, $0A
    ld [hli], a ; tile
    ldh a, [hCurrentObjectState]
    bit 2, a ; koopa type
    ld a, 2 ; green palette
    jr z, .skip
    ld a, 3 ; red palette
.skip:
    or a, OAMF_XFLIP
    push af
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $08
    ld [hli], a ; tile
    pop af
    push af
    ld [hli], a  ; attributes
    ; left half, bottom
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $12
    ld [hli], a ; tile
    pop af
    push af
    ld [hli], a  ; attributes
    ; right half, top
    ld a, c ; Object_PosY_Int
    add a, 16
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $10
    ld [hli], a ; tile
    pop af
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
incbin "font.bin" ; 56 tiles
incbin "flag.bin" ; 2 tiles
incbin "ball.bin" ; 32 tiles
BGTilesEnd:

OBJTiles:
incbin "bulletbill.bin" ; 4 tiles
incbin "koopa.bin" ; 12 tiles
OBJTilesEnd:

SECTION "Palette data", rom0

BGPalettes:
; 0 - scenery and letters
dw %0000000000000000
dw %0000000000000000
dw %0111111000010000
dw %0111111111111111
; 1 - flag
dw %0000000000000000
dw %0000000000011111
dw %0110110000000000
dw %0111111111111111
; 2 - orb
dw %0000000000000000
dw %0111111111110000
dw %0011110111101000
dw %0000000000000010
; 3 - flag
BGPalettesEnd:

OBJPalettes:
; 0 - orb
dw %0000000000000000
dw %0100001111111111
dw %0010000111101111
dw %0000100000000000
; 1 - bullet bill
dw %0000000000000000
dw %0010110101101011
dw %0111111111111111
dw %0100001000010000
; 2 - green koopa
dw %0000000000000000
dw %0000001110000000
dw %0111111111111111
dw %0000001010011111
; 3 - red koopa
dw %0000000000000000
dw %0000000000011100
dw %0111111111111111
dw %0000001010011111
OBJPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
db $98, $43, 14, "Super Mario 64"
db $98, $84, 12, "Koopa's Road"
db $98, $E4, 11, "Original by"
db $99, $05, 10, "Koji Kondo"
db $99, $63, 10, "Remixed in"
db $99, $6E, 2, $38,$39
db $99, $C4, 12, "Use D-pad to"
db $99, $E2, 15, "toggle channels"
db 0

HelloGameBoyDMGTileMapData:
db $99, $6E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
db $99, $6E, 2, $01,$01
db $99, $84, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db $99, $A4, 11, $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
db 0
