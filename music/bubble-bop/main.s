INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

NEWCHARMAP new
CHARMAP " ", $0
CHARMAP "A", $C1
CHARMAP "B", $C2
CHARMAP "C", $C3
CHARMAP "D", $C4
CHARMAP "E", $C5
CHARMAP "F", $C6
CHARMAP "G", $C7
CHARMAP "H", $C8
CHARMAP "I", $C9
CHARMAP "J", $CA
CHARMAP "K", $CB
CHARMAP "L", $CC
CHARMAP "M", $CD
CHARMAP "N", $CE
CHARMAP "O", $CF
CHARMAP "P", $D0
CHARMAP "Q", $D1
CHARMAP "R", $D2
CHARMAP "S", $D3
CHARMAP "T", $D4
CHARMAP "U", $D5
CHARMAP "V", $D6
CHARMAP "W", $D7
CHARMAP "-", $D8
CHARMAP "!", $D9
CHARMAP "a", $DA
CHARMAP "b", $DB
CHARMAP "c", $DC
CHARMAP "d", $DD
CHARMAP "e", $DE
CHARMAP "f", $DF
CHARMAP "g", $E0
CHARMAP "h", $E1
CHARMAP "i", $E2
CHARMAP "j", $E3
CHARMAP "k", $E4
CHARMAP "l", $E5
CHARMAP "m", $E6
CHARMAP "n", $E7
CHARMAP "o", $E8
CHARMAP "p", $E9
CHARMAP "q", $EA
CHARMAP "r", $EB
CHARMAP "s", $EC
CHARMAP "t", $ED
CHARMAP "u", $EE
CHARMAP "v", $EF
CHARMAP "x", $F0
CHARMAP "y", $F1

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

; Objects

hObjectsHead: dw
hObjectsFreeHead: dw
hKillMe: db
hCreatureIndex: db
hSpawnTimer: db


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
	db   "SNOWBRO 019", $00, $00, $00, $00

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
	ld   a, %00011011
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
    ld a, [hl] ; Object_State
    bit 7, a
    jr nz, .isBursting
    ; is floating
    inc a
    and a, $7f
    ld [hli], a ; Object_State
    ; move right
    ld a, [hl] ; Object_PosX_Frac
    add a, 80
    ld [hl], a ; Object_PosX_Frac
    jr nc, .skip
    inc hl ; Object_PosX_Int
    inc [hl] ; Object_PosX_Int
    ld a, [hl-] ; Object_PosX_Int
    cp a, 168
    jr nz, .skip
    ; a == 168
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
    dec hl ; Object_State
    cp a, 152
    jr nc, .notBursted
    cp a, 64
    jr c, .notBursted
    call Prng
    cp a, 2
    jr nc, .notBursted
    ; burst
    ld a, $80
    ld [hli], a ; Object_State
    jp DrawBubbleFrame1
.notBursted:
    ld a, [hli] ; Object_State
    srl a
    srl a
    srl a
    and a, 7
    cp a, 5
    jr nc, .drawFrame3
    jp DrawBubbleFrame0
.drawFrame3:
    jp DrawBubbleFrame3
.isBursting:
    inc a
    ld [hli], a ; Object_State
    cp a, $a8
    jr c, .noKill
    ld a, 1
    ld [hKillMe], a
.noKill:
    cp a, $90
    jr c, .drawFrame1
    jp DrawBubbleFrame2
.drawFrame1:
    jp DrawBubbleFrame1

; --- End object engine ---


; --- Sound data

DefaultWavRam:
db $11, $23, $56, $78, $a9, $98, $76, $57
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

    ; initialize seed
    ld a, 137
    ldh [hRandom], a

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
    call MaybeSpawnCreature
    call UpdateObjects

    ldh a, [hFrameCounter]
    inc a
    ldh [hFrameCounter], a
    and a, 7
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

MaybeSpawnCreature:
    ld a, [hSpawnTimer]
    inc a
    cp a, 41
    jr c, .noSpawn
    ; a >= 41
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
    xor a ; initial state
    ld [hli], a ; Object_State
    ld [hli], a ; Object_PosX_Frac
    ld a, 240 ; initial x
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
db 87, 46, 72, 20, 72, 125, 83, 24, 57, 88, 28, 82, 47, 114, 22, 77
db 109, 44, 85, 23, 117, 68, 17, 89, 38, 123, 62, 36, 66, 91, 42, 118
db 25, 77, 102, 45, 101, 18, 60, 29, 119, 91, 47, 104, 16, 56, 100, 27
db 78, 108, 33, 58, 100, 26, 124, 60, 34, 99, 38, 117, 63, 37, 120, 89
db 113, 23, 106, 54, 80, 55, 83, 31, 84, 32, 122, 56, 98, 55, 81, 121
db 30, 102, 67, 103, 41, 102, 74, 46, 99, 39, 127, 79, 43, 107, 52, 110
db 78, 51, 19, 53, 104, 50, 17, 75, 23, 122, 84, 30, 61, 37, 63, 126
db 90, 59, 117, 61, 93, 67, 33, 111, 68, 43, 94, 52, 124, 95, 26, 53
db 113, 58, 120, 76, 44, 94, 41, 125, 95, 20, 69, 112, 19, 105, 48, 124
db 80, 126, 25, 59, 111, 86, 28, 98, 48, 128, 99, 26, 70, 96, 35, 118
db 71, 31, 92, 27, 119, 59, 97, 52, 121, 97, 49, 114, 88, 36, 120, 71
db 19, 95, 34, 115, 91, 62, 127, 77, 115, 42, 74, 105, 48, 81, 113, 16
db 109, 44, 76, 116, 51, 116, 57, 29, 86, 34, 88, 64, 96, 70, 45, 21
db 79, 54, 109, 55, 85, 16, 81, 106, 30, 66, 112, 37, 84, 110, 73, 40
db 107, 82, 40, 108, 70, 123, 39, 73, 106, 69, 35, 73, 103, 65, 18, 101
db 65, 21, 75, 50, 24, 66, 90, 22, 49, 93, 41, 92, 64, 62, 87, 32

; hl = pointer to Object_PosX_Frac
DrawBubbleFrame0:
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
    ; (0,0)
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $f4
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; (1,0)
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $f6
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

; hl = pointer to Object_PosX_Frac
DrawBubbleFrame1:
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
    ; (0,0)
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $f8
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; (1,0)
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $f8
    ld [hli], a ; tile
    ld a, OAMF_XFLIP
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

; hl = pointer to Object_PosX_Frac
DrawBubbleFrame2:
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
    ; (0,0)
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    ld [hli], a ; x
    ld a, $fa
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; (1,0)
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 8
    ld [hli], a ; x
    ld a, $fc
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

; hl = pointer to Object_PosX_Frac
DrawBubbleFrame3:
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
    ; (0,0)
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 1
    ld [hli], a ; x
    ld a, $f4
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; (1,0)
    ld a, c ; Object_PosY_Int
    ld [hli], a ; y
    ld a, b ; Object_PosX_Int
    add a, 7
    ld [hli], a ; x
    ld a, $f6
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosX_Frac
    ret

Prng:
    ldh a, [hRandom]
    srl a
    jr nc, .noXor
    xor $B4
    .noXor:
    ldh [hRandom], a
    ret

SECTION "Tile data", ROM0

BGTiles:
; packchr --nametable-base=0x00 --character-output=titletiles.bin bubbleboptitle.bin
incbin "titletiles.bin"
incbin "font.bin"
incbin "flag.bin"
incbin "bubble.bin"
BGTilesEnd:

SECTION "Palette data", rom0

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

BGPalettes:
; 0 - title
rgb 0, 0, 0
rgb 31, 15, 0
rgb 26, 6, 16
rgb 31, 31, 31
; 1 - flag
rgb 0, 0, 0
rgb 20, 0, 0
rgb 0, 0, 31
rgb 31, 31, 31
BGPalettesEnd:

OBJPalettes:
; 0 - bubble
rgb 0, 0, 0
rgb 10, 10, 28
rgb 28, 8, 12
rgb 31, 31, 31
OBJPalettesEnd:

SECTION "VRAM strings", ROM0

HelloGameBoyTileMapData:
; packnam --width=18 --vram-address=0x9821 --output=titletilemap.bin packchr.nam
incbin "titletilemap.bin"
db $9A, $23, 13, "Get up and do"
db $9A, $62, 16, "the Bubble Bop!!"
db $9A, $C1, 17, "Original music by"
db $9B, $04, 11, "The Ramones"
db $9B, $43, 10, "Remixed in"
db $9B, $4E, 2, $F2,$F3 ; flag
db $9B, $84, 12, "Use D-pad to"
db $9B, $C2, 15, "toggle channels"
db 0

HelloGameBoyDMGTileMapData:
db $9B, $4E, 3, "NOR"
db 0

HelloGameBoyTileMapAttributeData:
; flag
db $9B, $4E, 2, $01,$01
db 0
