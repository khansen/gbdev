INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

NEWCHARMAP new
CHARMAP " ", $0
CHARMAP "A", $70
CHARMAP "B", $71
CHARMAP "C", $72
CHARMAP "D", $73
CHARMAP "E", $74
CHARMAP "F", $75
CHARMAP "G", $76
CHARMAP "H", $77
CHARMAP "I", $78
CHARMAP "J", $79
CHARMAP "K", $7a
CHARMAP "L", $7b
CHARMAP "M", $7c
CHARMAP "N", $7d
CHARMAP "O", $7e
CHARMAP "P", $7f
CHARMAP "Q", $80
CHARMAP "R", $81
CHARMAP "S", $82
CHARMAP "T", $83
CHARMAP "U", $84
CHARMAP "V", $85
CHARMAP "W", $86
CHARMAP "-", $87
CHARMAP "!", $88
CHARMAP "a", $89
CHARMAP "b", $8a
CHARMAP "c", $8b
CHARMAP "d", $8c
CHARMAP "e", $8d
CHARMAP "f", $8e
CHARMAP "g", $8f
CHARMAP "h", $90
CHARMAP "i", $91
CHARMAP "j", $92
CHARMAP "k", $93
CHARMAP "l", $94
CHARMAP "m", $95
CHARMAP "n", $96
CHARMAP "o", $97
CHARMAP "p", $98
CHARMAP "q", $99
CHARMAP "r", $9a
CHARMAP "s", $9b
CHARMAP "t", $9c
CHARMAP "u", $9d
CHARMAP "v", $9e
CHARMAP "w", $9f
CHARMAP "x", $a0
CHARMAP "y", $a1
CHARMAP "z", $a2
CHARMAP ",", $a3
CHARMAP "-", $a4
CHARMAP ".", $a5
CHARMAP "'", $a6
CHARMAP "Y", $a7

MACRO Align4
ds ((@ + $03) & $fffc) - @
ENDM

MACRO Align8
ds ((@ + $07) & $fff8) - @
ENDM

MACRO Align16
ds ((@ + $0f) & $fff0) - @
ENDM

MACRO Align64
ds ((@ + $3f) & $ffc0) - @
ENDM

MACRO Align256
ds ((@ + $ff) & $ff00) - @
ENDM

SECTION "HRAM", HRAM[$ff80]

hOamDmaFunction:
    ds $0a
.end:

hOamOffset: db

hButtonsHeld: db

hButtonsPressed: db

hProcessingVBlank: db

hMainState: db

hVramBuffer0Offset: db
hVramBuffer1Offset: db

hScrollX: db
hScrollY: db
hWindowX: db
hWindowY: db

hFrameCounter: db

hRandom: db

; --- Begin objects engine

hObjectsHead: dw
hObjectsFreeHead: dw
hKillMe: db

; --- End objects engine


; --- Begin graphics engine

hRendererMapOffset: db
hRendererSaveMapOffset: db
hRendererRoomOffset: db   ; 0..63
hRendererRoomCol: db   ; wraps at 32 (256 pixels)
hRendererRoomRow: db ; wraps at 32 (256 pixels)
hRendererTempRow: db
hRendererRoomPtr: dw ; pointer to room data
hRendererMetatileOffset: db
hRendererVramAddr: dw
hRendererFirstStripTileCount: db
hRendererTilesLeft: db
hRendererRequestFlags: db
; public (stuff that must be set up by user)
hRendererMetatilesTable: dw
hRendererMetatileAttribsPtrTable: dw
hRendererMetatileBehaviorsTable: dw
hRendererMap: dw ; room pointers
hRendererMapWidth: db
hRendererMapHeight: db
hMapObjects: dw

hScrollerWorldViewX: dw
hScrollerWorldViewY: dw

hPlayerWorldX: dw
hPlayerWorldXFrac: db
hPlayerWorldY: dw
hPlayerWorldYFrac: db
hPlayerState: db ; 0 = standing, 1 = walking
; Direction enum:
; 0=right
; 1=left
; 2=down
; 3=up
; 4=down-right
; 5=down-left
; 6=up-right
; 7=up-left
hPlayerDirection: db
hPlayerPageWrapFlags: db

hPlayerScreenX: dw
hPlayerScreenY: dw
hPlayerCel: db
hPlayerFrame: db
hPlayerAnimationTimer: db

def PLAYER_WALKING_ANIMATION_SPEED equ 8

; Temp variables used during collision detection
hPointX: dw
hPointY: dw

hObjectScreenX: dw
hObjectScreenY: dw

; Temp variable used to unload far objects
hUnloadObjectsPage: db

; --- End graphics engine

SECTION "WRAM", WRAM0[$c000]

wMapOffsetByRow:
    ds 256

wOam:
    ds OAM_COUNT*4

Align64
wVramBuffer0:
    ds 64
wVramBuffer1:
    ds 64


; --- Begin objects engine

rsreset
def Object_Next       rw 1                           ; 00
def Object_State      rb 1                           ; 02
def Object_PosX_Frac  rb 1                           ; 03
def Object_PosX_IntLo rb 1                           ; 04
def Object_PosX_IntHi rb 1                           ; 05
def Object_PosY_Frac  rb 1                           ; 06
def Object_PosY_IntLo rb 1                           ; 07
def Object_PosY_IntHi rb 1                           ; 08
def Object_SIZEOF     rb 0                           ; 09

def MAX_OBJECTS equ 16

wObjectsArena:
  ds Object_SIZEOF * MAX_OBJECTS

; --- End objects engine

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
	db   "SNOWBRO 021", $00, $00, $00, $00

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

        call FlushVramBuffers
	    call hOamDmaFunction
        ; sync scroll registers
        ldh a, [hScrollX]
        ldh [rSCX], a
        ldh a, [hScrollY]
        ldh [rSCY], a
        ; sync window registers
        ldh a, [hWindowX]
        ldh [rWX], a
        ldh a, [hWindowY]
        ldh [rWY], a
        ;
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

; DE = source address
; HL = destination address
; BC = count
CopyMemory:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, CopyMemory
    ret

; --- Begin gfx-related procedures ---

; HL = source address
; C = count
CopyBGPaletteData:
    ld a, BCPSF_AUTOINC | 0
    ldh [rBCPS], a
    .loop:
    ld a, [hli]
    ldh [rBCPD], a
    dec c
    jr nz, .loop
    ret

; HL = source address
; C = count
CopyOBJPaletteData:
    ld a, OCPSF_AUTOINC | 0
    ldh [rOCPS], a
    .loop:
    ld a, [hli]
    ldh [rOCPD], a
    dec c
    jr nz, .loop
    ret

FlushVramBuffers:
    call FlushVramBuffer0
; Fallthrough
FlushVramBuffer1:
    ldh a, [hVramBuffer1Offset]
    or a, a
    ret z
    xor a
    ldh [hVramBuffer1Offset], a
    inc a
    ldh [rVBK], a ; select bank 1
    ld hl, wVramBuffer1
    jr WriteVramStrings

FlushVramBuffer0:
    ldh a, [hVramBuffer0Offset]
    or a, a
    ret z
    xor a
    ldh [hVramBuffer0Offset], a
    ldh [rVBK], a ; select bank 0
    ld hl, wVramBuffer0
; Fallthrough

; HL = address of data
; Each string is of the format
;   High VRAM address
;   Low VRAM address
;   Length and flags
;     Bits 0-5: Length (0-63)
;     Bit 6: RLE (1=yes)
;     Bit 7: Stride 32 (1=yes)
;   Data (1 or more bytes)
; until a byte with value 0 is encountered
WriteVramStrings:
    ld a, [hli]
    or a, a
    ret z
    ld d, a ; high VRAM address
    ld a, [hli]
    ld e, a ; low VRAM address
    ld a, [hli] ; length and flags
    bit 6, a
    jr nz, .is_rle
    bit 7, a
    jr nz, .is_stride_32
    ld b, a
    .loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    jr WriteVramStrings
    .is_stride_32:
    and a, $3f
    ld b, a
    .loop_stride_32:
    ld a, [hli]
    ld [de], a
    ld a, e
    add a, 32
    ld e, a
    jr nc, .skip_inc_d
    inc d
    .skip_inc_d:
    dec b
    jr nz, .loop_stride_32
    jr WriteVramStrings
    .is_rle:
    bit 7, a
    jr nz, .is_rle_stride_32
    and a, $3f
    ld b, a
    ld a, [hli]
    .rle_loop:
    ld [de], a
    inc de
    dec b
    jr nz, .rle_loop
    jr WriteVramStrings
    .is_rle_stride_32:
    and a, $3f
    ld b, a
    ld a, [hli]
    ld c, a
    .rle_loop_stride_32:
    ld a, c
    ld [de], a
    ld a, e
    add a, 32
    ld e, a
    jr nc, .rle_skip_inc_d
    inc d
    .rle_skip_inc_d:
    dec b
    jr nz, .rle_loop_stride_32
    jr WriteVramStrings

; DE = data
; C = count
; Destroys: C, HL
CopyBytesToVram0Buffer:
    ld hl, wVramBuffer0
    ldh a, [hVramBuffer0Offset]
    push bc
    ld b, 0
    ld c, a
    add hl, bc
    pop bc
.loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec c
    jr nz, .loop
    jp EndVram0String

; DE = start address
; C = count and flags
; returns HL = vram buffer pointer
BeginVram0String:
    ld hl, wVramBuffer0
    ldh a, [hVramBuffer0Offset]
__BeginVramString:
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
    ld [hli], a ; count and flags
    ret

; DE = start address
; C = count and flags
; returns HL = vram buffer pointer
BeginVram1String:
    ld hl, wVramBuffer1
    ldh a, [hVramBuffer1Offset]
    jr __BeginVramString

EndVram0String:
    xor a
    ld [hl], a
    ld a, l
    sub a, LOW(wVramBuffer0)
    ldh [hVramBuffer0Offset], a
    ret

EndVram1String:
    xor a
    ld [hl], a
    ld a, l
    sub a, LOW(wVramBuffer1)
    ldh [hVramBuffer1Offset], a
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
    ld h, HIGH(wOam) ; wOam is aligned on 256 bytes
    ldh a, [hOamOffset]
    ld l, a
    ret

EndDrawSprites:
    ld a, l
    ldh [hOamOffset], a
    ret

; --- End gfx-related procedures ---

; --- Begin objects engine ---

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

macro TraverseObjects
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
    call \1
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
endm

UpdateObjects:
    TraverseObjects UpdateObject

; hl = pointer to Object_State
UpdateObject:
    ld a, [hli] ; Object_State
    push hl ; Object_PosX_Frac
    rst JumpTable
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC
dw UpdateNPC

UpdateNPC:
    pop hl ; Object_PosX_Frac
    call ConvertObjectWorldPositionToScreenPosition
    call RenderNPC
    ; check if player wants to talk
    ldh a, [hButtonsPressed]
    bit PADB_A, a
    ret z
    ; check if player is in range
    ldh a, [hPlayerScreenX+1]
    ld c, a
    ldh a, [hObjectScreenX+1]
    cp a, c
    ret nz
    ldh a, [hPlayerScreenY+1]
    ld c, a
    ldh a, [hObjectScreenY+1]
    cp a, c
    ret nz
    ; check in range X
    ldh a, [hPlayerScreenX]
    ld c, a
    ldh a, [hObjectScreenX]
    cp a, c
    jr nc, .noSwapX
    ld c, a
    ldh a, [hPlayerScreenX]
.noSwapX:
    sub a, c
    cp a, 24
    ret nc
    ; check in range Y
    ldh a, [hPlayerScreenY]
    ld c, a
    ldh a, [hObjectScreenY]
    cp a, c
    jr nc, .noSwapY
    ld c, a
    ldh a, [hPlayerScreenY]
.noSwapY:
    sub a, c
    cp a, 24
    ret nc
    ; let me talk to ya!
    dec hl ; Object_State
    ld a, [hl] ; Object_State
    sla a
    sla a
    ld c, a
    ld b, 0
    ld hl, NPCTextData
    add hl, bc
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ld a, [hl]
    ld c, a
    call CopyBytesToVram0Buffer
    ld a, 96
    ldh [hWindowY], a
    ld a, 7
    ldh [hWindowX], a
    ld a, 1
    ldh [hMainState], a
    ret

RenderNPC:
    ; compute clip flags, like we do for the player
    xor a, a
    ld b, a
    ldh a, [hObjectScreenX+1]
    or a, a
    jr nz, .clipXOnDifferentPage
    ldh a, [hObjectScreenX]
    cp a, 160+8
    jr nc, .hideBoth
    cp a, 160
    jr nc, .hideRightHalf
    jr .computeYClipFlags
.hideBoth:
    ; whole object is offscreen, nothing more to do
    ret
.hideRightHalf:
    set 1, b ; hide right
    jr .computeYClipFlags
.clipXOnDifferentPage:
    bit 7, a
    jr z, .hideBoth ; page >= 1: clearly offscreen
    cp a, $ff
    jr nz, .hideBoth ; page < -1: clearly offscreen
    ldh a, [hObjectScreenX]
    cp a, -8
    jr c, .hideBoth ; X < -8: whole object offscreen
    set 0, b ; hide left
.computeYClipFlags:
    ldh a, [hObjectScreenY+1]
    or a, a
    jr nz, .clipYOnDifferentPage
    ldh a, [hObjectScreenY]
    cp a, 160-8
    jr c, .drawSprites
    ; whole object is offscreen, nothing more to do
    ret
.clipYOnDifferentPage:
    bit 7, a
    jr z, .hideBoth ; page >= 1: clearly offscreen
    cp a, $ff
    jr nz, .hideBoth ; page < -1: clearly offscreen
    ldh a, [hObjectScreenY]
    cp a, -8
    jr c, .hideBoth ; Y < -8: whole object offscreen
.drawSprites:
    push hl
    call BeginDrawSprites
    bit 0, b ; hide left half?
    jr nz, .skipLeftHalf
    ; left half
    ldh a, [hObjectScreenY]
    add a, 8
    ld [hli], a ; y
    ldh a, [hObjectScreenX]
    ld [hli], a ; x
    ld a, $10
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
.skipLeftHalf:
    bit 1, b ; hide right half?
    jr nz, .skipRightHalf
    ; right half
    ldh a, [hObjectScreenY]
    add a, 8
    ld [hli], a ; y
    ldh a, [hObjectScreenX]
    add a, 8
    ld [hli], a ; x
    ld a, $12
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
.skipRightHalf:
    call EndDrawSprites
    pop hl
    ret

; --- End objects engine ---


; --- Sound data

DefaultWavRam:
db $11, $23, $45, $67
db $89, $ab, $cd, $ef
db $ff, $ee, $dc, $ba
db $98, $76, $54, $32

INCLUDE "song.s"

; --- Begin graphics engine ---

; HL = pointer to renderer data
;  0: map width
;  1: map height
;  2: pointer to map
;  4: pointer to map objects
;  6: pointer to metatiles
;  8: pointer to metatile attributes
; 10: pointer to metatile behaviors
; 12: pointer to tile data
; 14: size of tile data (word)
; 16: pointer to BG palette
; 18: size of BG palette data (byte)
; 19: pointer to OBJ palette
; 21: size of OBJ palette data (byte)
; 22: player's initial map X position
; 23: player's initial map Y position
; 24: player's initial room (X, Y) position (%xxxxyyyy)
SetRendererData:
    ld a, [hli] ; map width
    ldh [hRendererMapWidth], a
    ld a, [hli] ; map height
    ldh [hRendererMapHeight], a

    ld a, [hli] ; map (low)
    ldh [hRendererMap], a
    ld a, [hli] ; map (high)
    ldh [hRendererMap+1], a

    ld a, [hli] ; map objects (low)
    ldh [hMapObjects], a
    ld a, [hli] ; map objects (high)
    ldh [hMapObjects+1], a

    ld a, [hli] ; metatiles (low)
    ldh [hRendererMetatilesTable], a
    ld a, [hli] ; metatiles (high)
    ldh [hRendererMetatilesTable+1], a

    ld a, [hli] ; metatile attribs (low)
    ldh [hRendererMetatileAttribsPtrTable], a
    ld a, [hli] ; metatile attribs (high)
    ldh [hRendererMetatileAttribsPtrTable+1], a

    ld a, [hli] ; metatile behaviors (low)
    ldh [hRendererMetatileBehaviorsTable], a
    ld a, [hli] ; metatile behaviors (high)
    ldh [hRendererMetatileBehaviorsTable+1], a

    ld a, [hli] ; tile data (low)
    ld e, a
    ld a, [hli] ; tile data (high)
    ld d, a
    ld a, [hli] ; tile data size (low)
    ld c, a
    ld a, [hli] ; tile data size (high)
    ld b, a
    push hl
    ld a, 0
    ldh [rVBK], a ; select bank 0
    ld hl, $8000
    call CopyMemory
    pop hl

    ld a, [hli] ; BG palette data (low)
    ld e, a
    ld a, [hli] ; BG palette data (high)
    ld d, a
    ld a, [hli] ; BG palette data size
    ld c, a
    push hl
    ld l, e
    ld h, d
    call CopyBGPaletteData
    pop hl

    ld a, [hli] ; OBJ palette data (low)
    ld e, a
    ld a, [hli] ; OBJ palette data (high)
    ld d, a
    ld a, [hli] ; OBJ palette data size
    ld c, a
    push hl
    ld l, e
    ld h, d
    call CopyOBJPaletteData
    pop hl

    ld a, [hli] ; player's initial map X position
    ldh [hPlayerWorldX+1], a
    ld a, [hli] ; player's initial map Y position
    ldh [hPlayerWorldY+1], a
    ld a, [hl] ; player's initial room (X, Y) position
    and a, $f0
    or a, 8
    ldh [hPlayerWorldX], a
    ld a, [hli] ; player's initial room (X, Y) position
    and a, $0f
    swap a
    or a, 8
    ldh [hPlayerWorldY], a

    ; initialize rest of player state
    ld a, 0
    ldh [hPlayerState], a
    ldh [hPlayerFrame], a
    ldh [hPlayerWorldXFrac], a
    ldh [hPlayerWorldYFrac], a
    ldh [hPlayerPageWrapFlags], a
    ld a, 2
    ldh [hPlayerDirection], a ; down
    call MapPlayerDirectionToStandingCel
    ; fallthrough

; Destroys: B, C, HL
FillMapOffsetByRowTable:
    ldh a, [hRendererMapHeight]
    ld c, a
    ldh a, [hRendererMapWidth]
    ld b, a
    ld hl, wMapOffsetByRow
    xor a
.loop:
    ld [hli], a
    add a, b
    dec c
    jr nz, .loop
    ret

; B = starting map pos Y
; C = starting map pos X
ResetScroller:
    ld a, b
    ldh [hScrollerWorldViewY+1], a
    ld a, c
    ldh [hScrollerWorldViewX+1], a
    call ResetRenderer
    ld a, 8
    ldh [hScrollerWorldViewY], a
    ldh [hScrollerWorldViewX], a
    ret

; B = starting map pos Y
; C = starting map pos X
ResetRenderer:
    call GetMapOffset
    ldh [hRendererMapOffset], a
    xor a
    ldh [hRendererRoomCol], a
    ldh [hRendererRoomRow], a
    ldh [hRendererRequestFlags], a
    ret

; Attempts to scroll one pixel up.
; Returns: CF = 1 if scrolling was successful, CF = 0 otherwise.
TryScrollUp:
    ldh a, [hScrollerWorldViewY]
    cp a, 8
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hScrollerWorldViewY+1]
    or a, a
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewY]
    jr .canScroll
.reachedEndOfMap:
    scf
    ccf
    ret
.canScroll:
    and a, 7
    jr nz, .noTilemapUpdate
    call RequestRenderUp
.noTilemapUpdate:
    ldh a, [hScrollerWorldViewY]
    or a, a
    jr nz, .noPageWrap
    ; page wrap
    ldh a, [hScrollerWorldViewY+1]
    dec a
    ldh [hScrollerWorldViewY+1], a
    xor a
.noPageWrap:
    dec a
    ldh [hScrollerWorldViewY], a
    and a, 7
    cp a, 7
    jr nz, .noRendererRoomRowUpdate
    call RecedeRendererRoomRow
    .noRendererRoomRowUpdate:
    scf
    ret

; Attempts to scroll one pixel down.
; Returns: CF = 1 if scrolling was successful, CF = 0 otherwise.
TryScrollDown:
    ldh a, [hScrollerWorldViewY]
    cp a, 256-144-8
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hRendererMapHeight]
    dec a
    ld c, a
    ldh a, [hScrollerWorldViewY+1]
    cp a, c
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewY]
    jr .canScroll
.reachedEndOfMap:
    scf
    ccf
    ret
.canScroll:
    and a, 7
    jr nz, .noTilemapUpdate
    call RequestRenderDown
.noTilemapUpdate:
    ldh a, [hScrollerWorldViewY]
    inc a
    ldh [hScrollerWorldViewY], a
    jr nz, .noPageWrap
    ; page wrap
    ldh a, [hScrollerWorldViewY+1]
    inc a
    ldh [hScrollerWorldViewY+1], a
    ldh a, [hScrollerWorldViewY]
.noPageWrap:
    and a, 7
    jr nz, .noRendererRoomRowUpdate
    call AdvanceRendererRoomRow
    .noRendererRoomRowUpdate:
    scf
    ret

; Attempts to scroll one pixel left.
; Returns: CF = 1 if scrolling was successful, CF = 0 otherwise.
TryScrollLeft:
    ldh a, [hScrollerWorldViewX]
    cp a, 8
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hScrollerWorldViewX+1]
    or a, a
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewX]
    jr .canScroll
.reachedEndOfMap:
    scf
    ccf
    ret
.canScroll:
    and a, 7
    jr nz, .noTilemapUpdate
    call RequestRenderLeft
.noTilemapUpdate:
    ldh a, [hScrollerWorldViewX]
    or a, a
    jr nz, .noPageWrap
    ; page wrap
    ldh a, [hScrollerWorldViewX+1]
    dec a
    ldh [hScrollerWorldViewX+1], a
    xor a
.noPageWrap:
    dec a
    ldh [hScrollerWorldViewX], a
    and a, 7
    cp a, 7
    jr nz, .noRendererRoomColUpdate
    call RecedeRendererRoomCol
    .noRendererRoomColUpdate:
    scf
    ret

; Attempts to scroll one pixel right.
; Returns: CF = 1 if scrolling was successful, CF = 0 otherwise.
TryScrollRight:
    ldh a, [hScrollerWorldViewX]
    cp a, 256-160-8
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hRendererMapWidth]
    dec a
    ld c, a
    ldh a, [hScrollerWorldViewX+1]
    cp a, c
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewX]
    jr .canScroll
.reachedEndOfMap:
    scf
    ccf
    ret
.canScroll:
    and a, 7
    jr nz, .noTilemapUpdate
    call RequestRenderRight
.noTilemapUpdate:
    ldh a, [hScrollerWorldViewX]
    inc a
    ldh [hScrollerWorldViewX], a
    jr nz, .noPageWrap
    ; page wrap
    ldh a, [hScrollerWorldViewX+1]
    inc a
    ldh [hScrollerWorldViewX+1], a
    ldh a, [hScrollerWorldViewX]
.noPageWrap:
    and a, 7
    jr nz, .noRendererRoomColUpdate
    call AdvanceRendererRoomCol
    .noRendererRoomColUpdate:
    scf
    ret

; Gets map offset given a pair of (X, Y) coordinates: Y * mapwidth + X
; Params:   B = Y coordinate
;           C = X coordinate
; Returns:  A = The absolute map offset
; Destroys: HL
GetMapOffset:
    ld h, HIGH(wMapOffsetByRow)
    ld l, b
    ld a, [hl]
    add a, c
    ret

; Gets room offset given a pair of (X, Y) coordinates: (Y / 32) * 8 + (X / 32)
; Params:   B = Y coordinate
;           C = X coordinate
; Returns:  A = The absolute room offset (0..63)
; Destroys: B
GetRoomOffset:
    ld a, b
    and a, $e0
    srl a
    srl a
    ld b, a
    ld a, c
    and a, $e0
    swap a
    srl a
    or a, b
    ret

RenderScreen:
    ld a, 22+1
.loop:
    push af
    call RenderRight
    call FlushVramBuffers
    call AdvanceRendererRoomCol
    pop af
    dec a
    jr nz, .loop
    call RecedeRendererRoomCol
    ret

DEF RENDER_DOWN_REQUEST_BIT EQU 7
DEF RENDER_UP_REQUEST_BIT EQU 6
DEF RENDER_LEFT_REQUEST_BIT EQU 5
DEF RENDER_RIGHT_REQUEST_BIT EQU 4

RequestRenderRight:
    ldh a, [hRendererRequestFlags]
    res RENDER_LEFT_REQUEST_BIT, a
    set RENDER_RIGHT_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    ret

RequestRenderLeft:
    ldh a, [hRendererRequestFlags]
    res RENDER_RIGHT_REQUEST_BIT, a
    set RENDER_LEFT_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    ret

RequestRenderUp:
    ldh a, [hRendererRequestFlags]
    res RENDER_DOWN_REQUEST_BIT, a
    set RENDER_UP_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    ret

RequestRenderDown:
    ldh a, [hRendererRequestFlags]
    res RENDER_UP_REQUEST_BIT, a
    set RENDER_DOWN_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    ret

ProcessRendererRequests:
    ldh a, [hRendererRequestFlags]
    bit RENDER_RIGHT_REQUEST_BIT, a
    jr z, .checkRenderLeft
    res RENDER_RIGHT_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    jp RenderRight
.checkRenderLeft:
    bit RENDER_LEFT_REQUEST_BIT, a
    jr z, .checkRenderUp
    res RENDER_LEFT_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    jp RenderLeft
.checkRenderUp:
    bit RENDER_UP_REQUEST_BIT, a
    jr z, .checkRenderDown
    res RENDER_UP_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    jp RenderUp
.checkRenderDown:
    bit RENDER_DOWN_REQUEST_BIT, a
    ret z
    res RENDER_DOWN_REQUEST_BIT, a
    ldh [hRendererRequestFlags], a
    jp RenderDown

RenderUp:
; prepare state
    ldh a, [hRendererMapOffset]
    ldh [hRendererSaveMapOffset], a
    ldh a, [hRendererRoomCol]
    sub a, 22
    push af
    and a, 31
    ldh [hRendererRoomCol], a
    pop af
    jr nc, .noHorizontalRoomWrap
    ldh a, [hRendererMapOffset]
    dec a
    ldh [hRendererMapOffset], a
.noHorizontalRoomWrap:
; render name table
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderNameTableRow
; render attribute table on CGB
    ldh a, [rSVBK]
    cp a, $ff ; are we on DMG?
    jr z, .skipAttributeTableUpdate
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderAttribTableRow
.skipAttributeTableUpdate:
; restore state
    ldh a, [hRendererRoomCol]
    add a, 22
    and a, 31
    ldh [hRendererRoomCol], a
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
    ret

RecedeRendererRoomRow:
    ldh a, [hRendererRoomRow]
    dec a
    and a, 31
    ldh [hRendererRoomRow], a
    cp a, 31
    jr nz, .noVerticalRoomWrap
; move to previous room
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hRendererMapOffset]
    sub a, c
    ldh [hRendererMapOffset], a
.noVerticalRoomWrap:
    ret

RenderDown:
; prepare state
    ldh a, [hRendererMapOffset]
    ldh [hRendererSaveMapOffset], a
    ldh a, [hRendererRoomCol]
    sub a, 22
    push af
    and a, 31
    ldh [hRendererRoomCol], a
    pop af
    jr nc, .noHorizontalRoomWrap
    ldh a, [hRendererMapOffset]
    dec a
    ldh [hRendererMapOffset], a
.noHorizontalRoomWrap:
    ldh a, [hRendererRoomRow]
    add a, 20
    cp a, 32
    push af
    and a, 31
    ldh [hRendererRoomRow], a
    pop af
    jr c, .noVerticalRoomWrap
    ldh a, [hRendererMapOffset]
    ld c, a
    ldh a, [hRendererMapWidth]
    add a, c
    ldh [hRendererMapOffset], a
.noVerticalRoomWrap:
; render name table
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderNameTableRow
; render attribute table on CGB
    ldh a, [rSVBK]
    cp a, $ff ; are we on DMG?
    jr z, .skipAttributeTableUpdate
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderAttribTableRow
.skipAttributeTableUpdate:
; restore state
    ldh a, [hRendererRoomCol]
    add a, 22
    and a, 31
    ldh [hRendererRoomCol], a
    ldh a, [hRendererRoomRow]
    sub a, 20
    and a, 31
    ldh [hRendererRoomRow], a
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
    ret

AdvanceRendererRoomRow:
    ldh a, [hRendererRoomRow]
    inc a
    and a, 31
    ldh [hRendererRoomRow], a
    ret nz
; advance to next room
    ldh a, [hRendererMapOffset]
    ld c, a
    ldh a, [hRendererMapWidth]
    add a, c
    ldh [hRendererMapOffset], a
    ret

RenderLeft:
; render name table
    ldh a, [hRendererMapOffset]
    ldh [hRendererSaveMapOffset], a
    ldh a, [hRendererRoomCol]
    sub a, 22
    push af
    and a, 31
    ldh [hRendererRoomCol], a
    pop af
    ldh a, [hRendererMapOffset]
    jr nc, .noHorizontalRoomWrap
    dec a
    ldh [hRendererMapOffset], a
.noHorizontalRoomWrap:
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderNameTableCol
; render attribute table on CGB
    ldh a, [rSVBK]
    cp a, $ff ; are we on DMG?
    jr z, .skipAttributeTableUpdate
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderAttribTableCol
.skipAttributeTableUpdate:
; restore state
    ldh a, [hRendererRoomCol]
    add a, 22
    and a, 31
    ldh [hRendererRoomCol], a
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
    ret

RecedeRendererRoomCol:
    ldh a, [hRendererRoomCol]
    dec a
    and a, 31
    ldh [hRendererRoomCol], a
    cp a, 31
    ret nz
; move to previous room
    ldh a, [hRendererMapOffset]
    dec a
    ldh [hRendererMapOffset], a
    ret

RenderRight:
; render name table
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderNameTableCol
; render attribute table on CGB
    ldh a, [rSVBK]
    cp a, $ff ; are we on DMG?
    jr z, .skipAttributeTableUpdate
    ldh a, [hRendererMapOffset]
    call SetRendererRoomPtr
    call SyncRendererRoomOffset
    call RenderAttribTableCol
.skipAttributeTableUpdate:
    ret

AdvanceRendererRoomCol:
    ldh a, [hRendererRoomCol]
    inc a
    and a, 31
    ldh [hRendererRoomCol], a
    ret nz
; advance to next room
    ldh a, [hRendererMapOffset]
    inc a
    ldh [hRendererMapOffset], a
    ret

; Calculates room data offset from column and row.
; ofs = ((row/4)*8) + (col/4)
; Params:  None
; Returns: New offset in hRendererRoomOffset
; Destroys: A, B
SyncRendererRoomOffset:
    ldh a, [hRendererRoomCol]
    srl a
    srl a
    ld b, a
    ldh a, [hRendererRoomRow]
    and a, $FC
    sla a
    or a, b
    ldh [hRendererRoomOffset], a
    ret

; Sets room pointer.
; Params:  A = map offset
; Returns: new room pointer in hRendererRoomPtr
; Destroys: A, D, E
SetRendererRoomPtr:
    call GetRoomPtr
    ldh [hRendererRoomPtr], a
    ld a, d
    ldh [hRendererRoomPtr+1], a
    ret

; Gets room pointer.
; Params:  A = map offset
; Returns: new room pointer in A (low) and D (high)
; Destroys: D, E
GetRoomPtr:
    sla a
    ld e, a
    ldh a, [hRendererMap+1]
    adc a, 0
    ld d, a
    ldh a, [hRendererMap]
    add a, e
    ld e, a
    jr nc, .skip_inc_d
    inc d
    .skip_inc_d:
    ld a, [de] ; low
    push af
    inc de
    ld a, [de] ; high
    ld d, a
    pop af
    ret

; Gets room objects pointer.
; Params:  A = map offset
; Returns: new room pointer in A (low) and D (high)
; Destroys: D, E
GetRoomObjectsPtr:
    sla a
    ld e, a
    ldh a, [hMapObjects+1]
    adc a, 0
    ld d, a
    ldh a, [hMapObjects]
    add a, e
    ld e, a
    jr nc, .skip_inc_d
    inc d
    .skip_inc_d:
    ld a, [de] ; low
    push af
    inc de
    ld a, [de] ; high
    ld d, a
    pop af
    ret

; A = metatile #
; Returns: DE = pointer to metatile data
macro SetMetatilePtr
    ; multiply A by 16 and store result in DE
    swap a
    ld e, a
    and a, $f
    ld d, a
    ld a, e
    and a, $f0
    ld e, a
; --- begin alternative implementation that uses standard Z80 instructions ---
;    ld e, a
;    ld d, 0
;    rlc e
;    rl d
;    rlc e
;    rl d
;    rlc e
;    rl d
;    rlc e
;    rl d
; --- end alternative implementation that uses standard Z80 instructions ---
    ; add table pointer
    ld a, [hRendererMetatilesTable]
    add a, e
    ld e, a
    ld a, [hRendererMetatilesTable+1]
    adc a, d
    ld d, a
endm

; A = metatile #
; Returns: DE = pointer to metatile attribs data
macro SetMetatileAttribsPtr
    sla a
    ld e, a
    ldh a, [hRendererMetatileAttribsPtrTable+1]
    adc a, 0
    ld d, a
    ldh a, [hRendererMetatileAttribsPtrTable]
    add a, e
    ld e, a
    jr nc, .skip_inc_d_2
    inc d
    .skip_inc_d_2:
    ld a, [de] ; metatile attribs ptr (low)
    push af
    inc de
    ld a, [de] ; metatile attribs ptr (high)
    ld d, a
    pop af
    ld e, a
endm

; Renders one column (21 tiles vertically) of name table data to VRAM buffer.
RenderNameTableCol:
; calculate starting name table address: 9800 + row*32 + col
    ldh a, [hRendererRoomRow]
    ld c, a
    ld b, 0
    rept 5
    sla c
    rl b
    endr
    ld a, b
    or a, $98
    ldh [hRendererVramAddr+1], a
    ldh a, [hRendererRoomCol]
    or a, c
    ldh [hRendererVramAddr], a
; calculate # of tiles to write in 1st strip
    ldh a, [hRendererRoomRow]
    ld b, a
    ld a, 32
    sub a, b
    cp a, 20+1
    jr c, .two_strips
    ld a, 20+1
    .two_strips:
    ldh [hRendererFirstStripTileCount], a
    ldh [hRendererTilesLeft], a
; calculate initial metatile offset (0..15)
    ldh a, [hRendererRoomRow]
    and a, 3
    sla a
    sla a
    ld b, a
    ldh a, [hRendererRoomCol]
    and a, 3
    or a, b
    ldh [hRendererMetatileOffset], a
; begin VRAM string
    ldh a, [hRendererVramAddr]
    ld e, a
    ldh a, [hRendererVramAddr+1]
    ld d, a
    ldh a, [hRendererFirstStripTileCount]
    or a, $80 ; VRAM addr inc = 32
    ld c, a
    call BeginVram0String
    .render_one_metatile:
    ldh a, [hRendererRoomPtr+1]
    ld d, a
    ldh a, [hRendererRoomPtr]
    ld e, a
    ldh a, [hRendererRoomOffset]
    add a, e
    ld e, a
; assume that room data is aligned on 64 bytes
;    jr nc, .skip_inc_d
;    inc d
;    .skip_inc_d:
    ld a, [de] ; metatile #
    SetMetatilePtr
    ldh a, [hRendererMetatileOffset]
    add a, e
; assume that metatile data is aligned on 16 bytes
;   jr nc, .skip_inc_d
;   inc d
;   .skip_inc_d:
    ld e, a
    .render_one_tile:
    ld a, [de] ; tile #
    ld [hli], a
    ld a, e
    add a, 4 ; next metatile row
    ld e, a
    and a, 12
    jr nz, .no_metatile_wrap
    ; metatile wrap
    ld a, e
    and a, 3      ; row = 0
    ldh [hRendererMetatileOffset], a
    ldh a, [hRendererRoomOffset]
    add a, 8      ; next room row
    ldh [hRendererRoomOffset], a
    cp a, 64
    jr c, .no_room_wrap
    ; room wrap
    sub a, 64
    ldh [hRendererRoomOffset], a
    ldh a, [hRendererMapOffset]
    ld b, a
    ldh a, [hRendererMapWidth]
    add a, b
    call SetRendererRoomPtr
    .no_room_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_metatile
    .no_metatile_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_tile
    .strip_done:
; done rendering strip
    ldh a, [hRendererFirstStripTileCount]
    cp a, 20+1
    jr z, .column_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 20+1
    ldh [hRendererFirstStripTileCount], a
    sub a, b
    ldh [hRendererTilesLeft], a
    ld a, $98
    ld [hli], a
    ldh a, [hRendererRoomCol]
    ld [hli], a
    ldh a, [hRendererTilesLeft]
    or a, $80 ; VRAM addr inc = 32
    ld [hli], a
    jr .render_one_metatile
    .column_done:
    jp EndVram0String

; Renders one column (21 tiles vertically) of attribute table data to VRAM buffer.
RenderAttribTableCol:
; calculate starting attribute table address: 9800 + row*32 + col
    ldh a, [hRendererRoomRow]
    ld c, a
    ld b, 0
    rept 5
    sla c
    rl b
    endr
    ld a, b
    or a, $98
    ldh [hRendererVramAddr+1], a
    ldh a, [hRendererRoomCol]
    or a, c
    ldh [hRendererVramAddr], a
; calculate # of tiles to write in 1st strip
    ldh a, [hRendererRoomRow]
    ld b, a
    ld a, 32
    sub a, b
    cp a, 20+1
    jr c, .two_strips
    ld a, 20+1
    .two_strips:
    ldh [hRendererFirstStripTileCount], a
    ldh [hRendererTilesLeft], a
; calculate initial metatile offset (0..15)
    ldh a, [hRendererRoomRow]
    and a, 3
    sla a
    sla a
    ld b, a
    ldh a, [hRendererRoomCol]
    and a, 3
    or a, b
    ldh [hRendererMetatileOffset], a
; begin VRAM string
    ldh a, [hRendererVramAddr]
    ld e, a
    ldh a, [hRendererVramAddr+1]
    ld d, a
    ldh a, [hRendererFirstStripTileCount]
    or a, $80 ; VRAM addr inc = 32
    ld c, a
    call BeginVram1String
    .render_one_metatile:
    ldh a, [hRendererRoomPtr+1]
    ld d, a
    ldh a, [hRendererRoomPtr]
    ld e, a
    ldh a, [hRendererRoomOffset]
    add a, e
    ld e, a
; assume that room data is aligned on 64 bytes
;    jr nc, .skip_inc_d
;    inc d
;    .skip_inc_d:
    ld a, [de] ; metatile #
    SetMetatileAttribsPtr
    ldh a, [hRendererMetatileOffset]
    add a, e
; assume that metatile data is aligned on 16 bytes
;   jr nc, .skip_inc_d
;   inc d
;   .skip_inc_d:
    ld e, a
    .render_one_tile:
    ld a, [de] ; tile attribs
    ld [hli], a
    ld a, e
    add a, 4 ; next metatile row
    ld e, a
    and a, 12
    jr nz, .no_metatile_wrap
    ; metatile wrap
    ld a, e
    and a, 3      ; row = 0
    ldh [hRendererMetatileOffset], a
    ldh a, [hRendererRoomOffset]
    add a, 8      ; next room row
    ldh [hRendererRoomOffset], a
    cp a, 64
    jr c, .no_room_wrap
    ; room wrap
    sub a, 64
    ldh [hRendererRoomOffset], a
    ldh a, [hRendererMapOffset]
    ld b, a
    ldh a, [hRendererMapWidth]
    add a, b
    call SetRendererRoomPtr
    .no_room_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_metatile
    .no_metatile_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_tile
    .strip_done:
; done rendering strip
    ldh a, [hRendererFirstStripTileCount]
    cp a, 20+1
    jr z, .column_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 20+1
    ldh [hRendererFirstStripTileCount], a
    sub a, b
    ldh [hRendererTilesLeft], a
    ld a, $98
    ld [hli], a
    ldh a, [hRendererRoomCol]
    ld [hli], a
    ldh a, [hRendererTilesLeft]
    or a, $80 ; VRAM addr inc = 32
    ld [hli], a
    jr .render_one_metatile
    .column_done:
    jp EndVram1String

; Renders one row (23 tiles horizontally) of name table data to VRAM buffer.
RenderNameTableRow:
; calculate starting name table address: 9800 + row*32 + col
    ldh a, [hRendererRoomRow]
    ld c, a
    ld b, 0
    rept 5
    sla c
    rl b
    endr
    ld a, b
    or a, $98
    ldh [hRendererVramAddr+1], a
    ldh a, [hRendererRoomCol]
    or a, c
    ldh [hRendererVramAddr], a
; calculate # of tiles to write in 1st strip
    ldh a, [hRendererRoomCol]
    ld b, a
    ld a, 32
    sub a, b
    cp a, 22+1
    jr c, .two_strips
    ld a, 22+1
    .two_strips:
    ldh [hRendererFirstStripTileCount], a
    ldh [hRendererTilesLeft], a
; calculate initial metatile offset (0..15)
    ldh a, [hRendererRoomRow]
    and a, 3
    sla a
    sla a
    ld b, a
    ldh a, [hRendererRoomCol]
    and a, 3
    or a, b
    ldh [hRendererMetatileOffset], a
; begin VRAM string
    ldh a, [hRendererVramAddr]
    ld e, a
    ldh a, [hRendererVramAddr+1]
    ld d, a
    ldh a, [hRendererFirstStripTileCount]
    ld c, a
    call BeginVram0String
    .render_one_metatile:
    ldh a, [hRendererRoomPtr+1]
    ld d, a
    ldh a, [hRendererRoomPtr]
    ld e, a
    ldh a, [hRendererRoomOffset]
    add a, e
    ld e, a
; assume that room data is aligned on 64 bytes
;    jr nc, .skip_inc_d
;    inc d
;    .skip_inc_d:
    ld a, [de] ; metatile #
    SetMetatilePtr
    ldh a, [hRendererMetatileOffset]
    add a, e
; assume that metatile data is aligned on 16 bytes
;   jr nc, .skip_inc_d
;   inc d
;   .skip_inc_d:
    ld e, a
    .render_one_tile:
    ld a, [de] ; tile #
    ld [hli], a
    ld a, e
    inc a ; next metatile column
    ld e, a
    and a, 3
    jr nz, .no_metatile_wrap
    ; metatile wrap
    ldh a, [hRendererMetatileOffset]
    and a, 12      ; column = 0
    ldh [hRendererMetatileOffset], a
    ldh a, [hRendererRoomOffset]
    inc a      ; next room column
    ldh [hRendererRoomOffset], a
    and a, 7
    jr nz, .no_room_wrap
    ; room wrap
    ldh a, [hRendererRoomOffset]
    sub a, 8
    ldh [hRendererRoomOffset], a
    ldh a, [hRendererMapOffset]
    inc a
    call SetRendererRoomPtr
    .no_room_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_metatile
    .no_metatile_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_tile
    .strip_done:
; done rendering strip
    ldh a, [hRendererFirstStripTileCount]
    cp a, 22+1
    jr z, .row_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 22+1
    ldh [hRendererFirstStripTileCount], a
    sub a, b
    ldh [hRendererTilesLeft], a
    ld a, [hRendererVramAddr+1]
    ld [hli], a
    ldh a, [hRendererVramAddr]
    and a, $e0 ; column = 0
    ld [hli], a
    ldh a, [hRendererTilesLeft]
    ld [hli], a
    jr .render_one_metatile
    .row_done:
    jp EndVram0String

; Renders one row (23 tiles horizontally) of attribute table data to VRAM buffer.
RenderAttribTableRow:
; calculate starting name table address: 9800 + row*32 + col
    ldh a, [hRendererRoomRow]
    ld c, a
    ld b, 0
    rept 5
    sla c
    rl b
    endr
    ld a, b
    or a, $98
    ldh [hRendererVramAddr+1], a
    ldh a, [hRendererRoomCol]
    or a, c
    ldh [hRendererVramAddr], a
; calculate # of tiles to write in 1st strip
    ldh a, [hRendererRoomCol]
    ld b, a
    ld a, 32
    sub a, b
    cp a, 22+1
    jr c, .two_strips
    ld a, 22+1
    .two_strips:
    ldh [hRendererFirstStripTileCount], a
    ldh [hRendererTilesLeft], a
; calculate initial metatile offset (0..15)
    ldh a, [hRendererRoomRow]
    and a, 3
    sla a
    sla a
    ld b, a
    ldh a, [hRendererRoomCol]
    and a, 3
    or a, b
    ldh [hRendererMetatileOffset], a
; begin VRAM string
    ldh a, [hRendererVramAddr]
    ld e, a
    ldh a, [hRendererVramAddr+1]
    ld d, a
    ldh a, [hRendererFirstStripTileCount]
    ld c, a
    call BeginVram1String
    .render_one_metatile:
    ldh a, [hRendererRoomPtr+1]
    ld d, a
    ldh a, [hRendererRoomPtr]
    ld e, a
    ldh a, [hRendererRoomOffset]
    add a, e
    ld e, a
; assume that room data is aligned on 64 bytes
;    jr nc, .skip_inc_d
;    inc d
;    .skip_inc_d:
    ld a, [de] ; metatile #
    SetMetatileAttribsPtr
    ldh a, [hRendererMetatileOffset]
    add a, e
; assume that metatile data is aligned on 16 bytes
;   jr nc, .skip_inc_d
;   inc d
;   .skip_inc_d:
    ld e, a
    .render_one_tile:
    ld a, [de] ; tile attribs
    ld [hli], a
    ld a, e
    inc a ; next metatile column
    ld e, a
    and a, 3
    jr nz, .no_metatile_wrap
    ; metatile wrap
    ldh a, [hRendererMetatileOffset]
    and a, 12      ; column = 0
    ldh [hRendererMetatileOffset], a
    ldh a, [hRendererRoomOffset]
    inc a      ; next room column
    ldh [hRendererRoomOffset], a
    and a, 7
    jr nz, .no_room_wrap
    ; room wrap
    ldh a, [hRendererRoomOffset]
    sub a, 8
    ldh [hRendererRoomOffset], a
    ldh a, [hRendererMapOffset]
    inc a
    call SetRendererRoomPtr
    .no_room_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_metatile
    .no_metatile_wrap:
    ldh a, [hRendererTilesLeft]
    dec a
    jr z, .strip_done
    ldh [hRendererTilesLeft], a
    jr .render_one_tile
    .strip_done:
; done rendering strip
    ldh a, [hRendererFirstStripTileCount]
    cp a, 22+1
    jr z, .row_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 22+1
    ldh [hRendererFirstStripTileCount], a
    sub a, b
    ldh [hRendererTilesLeft], a
    ld a, [hRendererVramAddr+1]
    ld [hli], a
    ldh a, [hRendererVramAddr]
    and a, $e0 ; column = 0
    ld [hli], a
    ldh a, [hRendererTilesLeft]
    ld [hli], a
    jr .render_one_metatile
    .row_done:
    jp EndVram1String

; --- End graphics engine ---

; --- Program-specific code: Our game starts here! ---

Genesis:
    ld hl, .severance_header
    call SetRendererData
    ldh a, [hPlayerWorldX+1]
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call ResetScroller
    call RenderScreen
    call ScrollUntilCameraIsCenteredOnPlayer
    call InitializeObjects
    call LoadInitialObjects

; hide window
    ld a, 144
    ldh [hWindowY], a

    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld hl, song_song
    call StartSong

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

    ldh a, [hScrollX]
    ldh [rSCX], a
    ldh a, [hScrollY]
    ldh [rSCY], a

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_WINON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_WIN9C00
	ld [rLCDC], a

.infiniteLoop:
    halt
    jr .infiniteLoop

.severance_header:
    db 4,3 ; width=4, height=3 (MxN rooms)
    dw .severance_map
    dw .severance_map_objects
    dw .severance_metatiles
    dw .severance_metatile_attribs
    dw .severance_metatile_behaviors
    dw severance_tiles
    dw severance_tiles_end - severance_tiles
    dw severance_bg_palettes
    db severance_bg_palettes_end - severance_bg_palettes
    dw severance_obj_palettes
    db severance_obj_palettes_end - severance_obj_palettes
    db 0,0 ; player's initial map (X, Y) position
    db $cc ; player's initial room (X, Y) position

.severance_map:
    dw .room_elevator_lobby
    dw .room_mdr
    dw .room_break_room
    dw .room_goat_room
    dw .room_connector_1
    dw .room_wellness_top
    dw .room_connector_2
    dw .room_connector_3
    dw .room_wellness_bottom
    dw .room_lumon_core
    dw .room_od
    dw .room_connector_4

NEWCHARMAP severance_map
CHARMAP ".", 0 ; floor
CHARMAP "x", 1 ; wall
CHARMAP ",", 2 ; alt floor
CHARMAP "y", 3 ; alt wall

setcharmap severance_map

Align64
.room_elevator_lobby:
    db "xxxxxxxx"
    db "xxyyyyxx"
    db "xy,,,,yx"
    db "x,....,y"
    db "x..xyy.,"
    db "x..x,,.x"
    db "x..y...x"
    db "xx.,..xx"

.room_mdr:
    db "xyxxxxyx"
    db "x,yyyy,x"
    db "x.,,,,.x"
    db "y.yyyy.y"
    db ",.,,,,.,"
    db "x.yyyy.x"
    db "x.,,,,.x"
    db "xx....xx"

.room_break_room:
    db "xyyyyyyx"
    db "x,,,,,,x"
    db "x..xx..x"
    db "y..yy..y"
    db ",..,,..,"
    db "x.y..y.x"
    db "x.,..,.x"
    db "xx....xx"

.room_goat_room:
    db "xyyyyyyx"
    db "x,,,,,,x"
    db "x.x..x.x"
    db "y.y..y.x"
    db ",.,..,.x"
    db "..y..y.x"
    db "x.,..,.x"
    db "xx....xx"

.room_connector_1:
    db "xy....yx"
    db "x,.yy.,x"
    db "x..,,..x"
    db "x.yyy..x"
    db "x.,,,..x"
    db "x.yyyyyy"
    db "x.,,,,,,"
    db "xx....xx"

.room_wellness_top:
    db "xy....yx"
    db "x,....,x"
    db "x.xxx..x"
    db "y.yyy..y"
    db ",..,,..,"
    db "...yy..x"
    db "x..,,..x"
    db "xx....xx"

.room_connector_2:
    db "xy....yx"
    db "x,....,x"
    db "x..yyyyx"
    db "y..,,,,y"
    db ",......,"
    db "x..yyyyx"
    db "x..,,,,x"
    db "xx....xx"

.room_connector_3:
    db "xy....yx"
    db "x,....,x"
    db "y.yyyy.x"
    db ",.,,,,.x"
    db ".......x"
    db "x..yyyyx"
    db "x..,,,,x"
    db "xx....xx"

.room_wellness_bottom:
    db "xy....yx"
    db "x,....,x"
    db "xyyyyy.x"
    db "x,,,,,.x"
    db "x.yyyyyx"
    db "x.,,,,,y"
    db "x......,"
    db "xxxxxxxx"

.room_lumon_core:
    db "xy....yx"
    db "x,.yy.,x"
    db "x..,,..x"
    db "y..yy..y"
    db ",..,,..,"
    db "y..yy..x"
    db ",..,,..x"
    db "xxxxxxxx"

.room_od:
    db "xy....xx"
    db "x,.y..yx"
    db "x..,..,x"
    db "y..yy..y"
    db ",..,,..,"
    db "x..yy..x"
    db "x..,,..x"
    db "xxxxxxxx"

.room_connector_4:
    db "xy....yx"
    db "x,....,x"
    db "x...yyyx"
    db "xyx.,,,x"
    db "x,x....x"
    db "x.yyyy.x"
    db "x.,,,,.x"
    db "xxxxxxxx"

.severance_map_objects:
    dw .room_elevator_lobby_objects
    dw .room_mdr_objects
    dw .room_break_room_objects
    dw .room_goat_room_objects
    dw .room_connector_1_objects
    dw .room_wellness_top_objects
    dw .room_connector_2_objects
    dw .room_connector_3_objects
    dw .room_wellness_bottom_objects
    dw .room_lumon_core_objects
    dw .room_od_objects
    dw .room_connector_4_objects

.room_elevator_lobby_objects:
    db 0, $44, $ff
.room_wellness_bottom_objects:
    db 1, $aa, $ff
.room_goat_room_objects:
    db 2, $d2, $ff
.room_connector_4_objects:
    db 3, $28, $ff
.room_break_room_objects:
    db 4, $22, $ff
.room_wellness_top_objects:
    db 5, $08, $ff
.room_connector_3_objects:
    db 6, $06, $ff
.room_lumon_core_objects:
    db 7, $22, $ff
.room_mdr_objects:
.room_connector_1_objects:
.room_connector_2_objects:
.room_od_objects:
    db $ff

Align16
.severance_metatiles:
;.meta_floor1:
    db $01,$01,$01,$01
    db $01,$01,$01,$01
    db $01,$01,$01,$01
    db $01,$01,$01,$01
;.meta_wall1:
    db $02,$02,$02,$03
    db $01,$01,$01,$04
    db $01,$01,$01,$04
    db $01,$01,$01,$04
;.meta_floor2:
    db $05,$05,$05,$05
    db $05,$05,$05,$05
    db $01,$01,$01,$01
    db $01,$01,$01,$01
;.meta_wall2:
    db $02,$02,$02,$03
    db $01,$01,$01,$04
    db $01,$01,$01,$04
    db $06,$07,$08,$09

.severance_metatile_attribs:
    dw .attribs_floor
    dw .attribs_wall
    dw .attribs_floor
    dw .attribs_wall

Align16
.attribs_floor:     ds 16, $00
.attribs_wall:      ds 16, $01

.severance_metatile_behaviors:
db %00000000
db %01010101
db %00000000
db %01010101

; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc0
dw MainFunc1

MainFunc0:
    call HideAllSprites
    call UpdatePlayer
    call ConvertPlayerWorldPositionToScreenPosition
    call CenterCameraOnPlayer
    call UpdateObjects
    call RenderPlayer
    call ProcessPlayerPageWrapFlags
    call ProcessRendererRequests
; sync scroll registers
    ldh a, [hScrollerWorldViewY]
    ldh [hScrollY], a
    ldh a, [hScrollerWorldViewX]
    ldh [hScrollX], a
    ret

MainFunc1:
    ldh a, [hButtonsPressed]
    and a, PADF_A | PADF_B
    ret z
; hide window
    ld a, 144
    ldh [hWindowY], a
; back to game
    ld a, 0
    ldh [hMainState], a
    ret

ProcessPlayerPageWrapFlags:
    ldh a, [hPlayerPageWrapFlags]
    or a, a
    ret z
    bit 0, a
    jr z, .checkLeft
    call LoadObjectsRight
    ldh a, [hPlayerPageWrapFlags]
    jr .checkDown
.checkLeft:
    bit 1, a
    jr z, .checkDown
    call LoadObjectsLeft
    ldh a, [hPlayerPageWrapFlags]
.checkDown:
    bit 2, a
    jr z, .checkUp
    call LoadObjectsDown
    jr .clearFlags
.checkUp:
    bit 3, a
    jr z, .clearFlags
    call LoadObjectsUp
.clearFlags:
    xor a, a
    ldh [hPlayerPageWrapFlags], a
    ret

LoadInitialObjects:
    ; (PX, PY)
    ldh a, [hPlayerWorldX+1]
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call LoadObjectsAtMapPosition
.skip:
    ; (PX+1, PY)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip2
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call LoadObjectsAtMapPosition
.skip2:
    ; (PX, PY-1)
    ldh a, [hPlayerWorldY+1]
    dec a
    cp a, $ff
    jr z, .skip4
    ld b, a
    ldh a, [hPlayerWorldX+1]
    ld c, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY-1)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip3
    ld c, a
    ldh a, [hPlayerWorldY+1]
    dec a
    ld b, a
    call LoadObjectsAtMapPosition
.skip3:
    ; (PX+1, PY-1)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip4
    ld c, a
    ldh a, [hPlayerWorldY+1]
    dec a
    ld b, a
    call LoadObjectsAtMapPosition
.skip4:
    ; (PX, PY+1)
    ldh a, [hRendererMapHeight]
    ld b, a
    ldh a, [hPlayerWorldY+1]
    inc a
    cp a, b
    jr z, .skip6
    ld b, a
    ldh a, [hPlayerWorldX+1]
    ld c, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY+1)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip5
    ld c, a
    ldh a, [hPlayerWorldY+1]
    inc a
    ld b, a
    call LoadObjectsAtMapPosition
.skip5:
    ; (PX+1, PY+1)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip4
    ld c, a
    ldh a, [hPlayerWorldY+1]
    inc a
    ld b, a
    call LoadObjectsAtMapPosition
.skip6:
    ret

; Params:   B = Y coordinate
;           C = X coordinate
LoadObjectsAtMapPosition:
    call GetMapOffset
    call GetRoomObjectsPtr
    ld e, a
.loop:
    ld a, [de]
    inc de
    cp a, $ff
    jr z, .done
    push af
    call AllocateObject
    inc hl ; Object_Next (high)
    inc hl ; Object_State
    pop af
    ld [hl], a ; Object_State is the loader type, by default
    call LoadObject
.done:
    ret

; A = object loader type
; B = map Y coordinate
; C = map X coordinate
; HL = pointer to object
; DE = pointer to object data/definition
LoadObject:
    push hl ; Object_State
    push de
    rst JumpTable
dw .load_npc
dw .load_npc
dw .load_npc
dw .load_npc
dw .load_npc
dw .load_npc
dw .load_npc
dw .load_npc

.load_npc:
    pop de
    pop hl ; Object_State
    inc hl ; Object_PosX_Frac
    ld [hli], a ; Object_PosX_Frac
    ld a, [de] ; initial room position: %xxxxyyyy
    and a, $f0
    or a, 8
    ld [hli], a ; Object_PosX_IntLo
    ld a, c
    ld [hli], a ; Object_PosX_IntHi
    xor a, a
    ld [hli], a ; Object_PosY_Frac
    ld a, [de] ; initial room position: %xxxxyyyy
    and a, $0f
    swap a
    or a, 8
    ld [hli], a ; Object_PosY_IntLo
    ld a, b
    ld [hli], a ; Object_PosY_IntHi
    inc de
    ret

; A = X page
UnloadObjectsAtPageX:
    ldh [hUnloadObjectsPage], a
    TraverseObjects UnloadObjectIfPageX
    ret

; hl = pointer to Object_State
UnloadObjectIfPageX:
    inc hl ; Object_PosX_Frac
    inc hl ; Object_PosX_IntLo
    inc hl ; Object_PosX_IntHi
    ldh a, [hUnloadObjectsPage]
    cp a, [hl] ; Object_PosX_IntHi
    ret nz
    ld a, 1
    ldh [hKillMe], a
    ret

; A = Y page
UnloadObjectsAtPageY:
    ldh [hUnloadObjectsPage], a
    TraverseObjects UnloadObjectIfPageY
    ret

; hl = pointer to Object_State
UnloadObjectIfPageY:
    inc hl ; Object_PosX_Frac
    inc hl ; Object_PosX_IntLo
    inc hl ; Object_PosX_IntHi
    inc hl ; Object_PosY_Frac
    inc hl ; Object_PosY_IntLo
    inc hl ; Object_PosY_IntHi
    ldh a, [hUnloadObjectsPage]
    cp a, [hl] ; Object_PosY_IntHi
    ret nz
    ld a, 1
    ldh [hKillMe], a
    ret

LoadObjectsRight:
    ; unload objects at X - 2
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip
    dec a
    cp a, -1
    jr z, .skip
    call UnloadObjectsAtPageX
.skip:
    ; (PX+1, PY)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip2
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call LoadObjectsAtMapPosition
    ; (PX+1, PY-1)
    ldh a, [hPlayerWorldY+1]
    dec a
    cp a, -1
    jr z, .skip3
    ld b, a
    ldh a, [hPlayerWorldX+1]
    inc a
    ld c, a
    call LoadObjectsAtMapPosition
.skip3:
    ; (PX+1, PY+1)
    ldh a, [hRendererMapHeight]
    ld b, a
    ldh a, [hPlayerWorldY+1]
    inc a
    cp a, b
    jr z, .skip2
    ld b, a
    ldh a, [hPlayerWorldX+1]
    inc a
    ld c, a
    call LoadObjectsAtMapPosition
.skip2:
    ret

LoadObjectsLeft:
    ; unload objects at X + 2
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip
    inc a
    cp a, c
    jr z, .skip
    call UnloadObjectsAtPageX
.skip:
    ; (PX-1, PY)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip2
    ld c, a
    ldh a, [hPlayerWorldY+1]
    ld b, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY-1)
    ldh a, [hPlayerWorldY+1]
    dec a
    cp a, -1
    jr z, .skip3
    ld b, a
    ldh a, [hPlayerWorldX+1]
    dec a
    ld c, a
    call LoadObjectsAtMapPosition
.skip3:
    ; (PX-1, PY+1)
    ldh a, [hRendererMapHeight]
    ld b, a
    ldh a, [hPlayerWorldY+1]
    inc a
    cp a, b
    jr z, .skip2
    ld b, a
    ldh a, [hPlayerWorldX+1]
    dec a
    ld c, a
    call LoadObjectsAtMapPosition
.skip2:
    ret

LoadObjectsDown:
    ; unload objects at Y - 2
    ldh a, [hPlayerWorldY+1]
    dec a
    cp a, -1
    jr z, .skip
    dec a
    cp a, -1
    jr z, .skip
    call UnloadObjectsAtPageY
.skip:
    ; (PX, PY+1)
    ldh a, [hRendererMapHeight]
    ld b, a
    ldh a, [hPlayerWorldY+1]
    inc a
    cp a, b
    jr z, .skip2
    ld b, a
    ldh a, [hPlayerWorldX+1]
    ld c, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY+1)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip3
    ld c, a
    ldh a, [hPlayerWorldY+1]
    inc a
    ld b, a
    call LoadObjectsAtMapPosition
.skip3:
    ; (PX+1, PY+1)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip2
    ld c, a
    ldh a, [hPlayerWorldY+1]
    inc a
    ld b, a
    call LoadObjectsAtMapPosition
.skip2:
    ret

LoadObjectsUp:
    ; unload objects at Y + 2
    ldh a, [hRendererMapHeight]
    ld b, a
    ldh a, [hPlayerWorldY+1]
    inc a
    cp a, c
    jr z, .skip
    inc a
    cp a, c
    jr z, .skip
    call UnloadObjectsAtPageY
.skip:
    ; (PX, PY-1)
    ldh a, [hPlayerWorldY+1]
    dec a
    cp a, -1
    jr z, .skip2
    ld b, a
    ldh a, [hPlayerWorldX+1]
    ld c, a
    call LoadObjectsAtMapPosition
    ; (PX-1, PY-1)
    ldh a, [hPlayerWorldX+1]
    dec a
    cp a, -1
    jr z, .skip3
    ld c, a
    ldh a, [hPlayerWorldY+1]
    dec a
    ld b, a
    call LoadObjectsAtMapPosition
.skip3:
    ; (PX+1, PY-1)
    ldh a, [hRendererMapWidth]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    inc a
    cp a, c
    jr z, .skip2
    ld c, a
    ldh a, [hPlayerWorldY+1]
    dec a
    ld b, a
    call LoadObjectsAtMapPosition
.skip2:
    ret

UpdatePlayer:
    ldh a, [hPlayerState]
    rst JumpTable
dw UpdatePlayerStanding
dw UpdatePlayerWalking

Align16
PadInputToDirection:
    db 0
    db 0 ; PADF_RIGHT --> right
    db 1 ; PADF_LEFT --> left
    db 0 ; PADF_RIGHT | PADF_LEFT --> right
    db 3 ; PADF_UP --> up
    db 6 ; PADF_UP | PADF_RIGHT --> up-right
    db 7 ; PADF_UP | PADF_LEFT --> up-left
    db 6 ; PADF_UP | PADF_LEFT | PADF_RIGHT --> up-right
    db 2 ; PADF_DOWN --> down
    db 4 ; PADF_DOWN | PADF_RIGHT --> down-right
    db 5 ; PADF_DOWN | PADF_LEFT --> down-left
    db 4 ; PADF_DOWN | PADF_LEFT | PADF_RIGHT --> down-right
    db 2 ; PADF_DOWN | PADF_UP --> down
    db 4 ; PADF_DOWN | PADF_UP | PADF_RIGHT --> down-right
    db 5 ; PADF_DOWN | PADF_UP | PADF_LEFT --> down-left
    db 4 ; PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT --> down-right

Align8
DirectionToPlayerStandingCel:
db 30 ; right
db 10 ; left
db 0  ; down
db 20 ; up
db 35 ; down-right
db 5  ; down-left
db 25 ; up-right
db 15 ; up-left

DirectionToPlayerWalkingBaseCel:
db 31 ; right
db 11 ; left
db 1  ; down
db 21 ; up
db 36 ; down-right
db 6  ; down-left
db 26 ; up-right
db 16 ; up-left

; Maps input to direction (0..7).
; Stores result in hPlayerDirection.
; Destroys: A, HL
MapInputToPlayerDirection:
    ldh a, [hButtonsHeld]
    swap a
    and a, $f
    or a, LOW(PadInputToDirection)
    ld l, a
    ld h, HIGH(PadInputToDirection)
    ld a, [hl]
    ldh [hPlayerDirection], a
    ret

MapPlayerDirectionToStandingCel:
    ld h, HIGH(DirectionToPlayerStandingCel)
    ldh a, [hPlayerDirection]
    or a, LOW(DirectionToPlayerStandingCel)
    ld l, a
    ld a, [hl]
    ldh [hPlayerCel], a
    ret

MapPlayerStateToWalkingCel:
    ld h, HIGH(DirectionToPlayerWalkingBaseCel)
    ldh a, [hPlayerDirection]
    or a, LOW(DirectionToPlayerWalkingBaseCel)
    ld l, a
    ld a, [hl]
    ld c, a
    ldh a, [hPlayerFrame]
    add a, c
    ldh [hPlayerCel], a
    ret

UpdatePlayerStanding:
    ; check input
    ldh a, [hButtonsHeld]
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN
    jr nz, .tryToWalk
    ret
.tryToWalk:
    call MapInputToPlayerDirection
    call TryMovePlayerInDirection
    jr z, .startedWalking
    jp MapPlayerDirectionToStandingCel
.startedWalking:
    ld a, 1
    ldh [hPlayerState], a
    ld a, 0
    ldh [hPlayerFrame], a
    ld a, PLAYER_WALKING_ANIMATION_SPEED
    ldh [hPlayerAnimationTimer], a
    jp MapPlayerStateToWalkingCel

UpdatePlayerWalking:
    ; check input
    ldh a, [hButtonsHeld]
    and a, PADF_LEFT | PADF_RIGHT | PADF_UP | PADF_DOWN
    jr z, .stopWalking
    call MapInputToPlayerDirection
    call TryMovePlayerInDirection
    jr nz, .stopWalking
    call UpdatePlayerWalkingAnimation
    jp MapPlayerStateToWalkingCel
.stopWalking:
    ld a, 0
    ldh [hPlayerState], a
    jp MapPlayerDirectionToStandingCel

UpdatePlayerWalkingAnimation:
    ldh a, [hPlayerAnimationTimer]
    dec a
    ldh [hPlayerAnimationTimer], a
    ret nz
    ld a, PLAYER_WALKING_ANIMATION_SPEED
    ldh [hPlayerAnimationTimer], a
    ldh a, [hPlayerFrame]
    inc a
    and a, 3
    ldh [hPlayerFrame], a
    ret

; Try to move the player at most 1 pixel along X axis and Y axis, according to current direction.
; Returns A = 0 if successful (managed to move in at least one direction), A != 0 otherwise
TryMovePlayerInDirection:
    ldh a, [hPlayerDirection]
    rst JumpTable
    dw TryMovePlayerRight
    dw TryMovePlayerLeft
    dw TryMovePlayerDown
    dw TryMovePlayerUp
    dw TryMovePlayerDownRight
    dw TryMovePlayerDownLeft
    dw TryMovePlayerUpRight
    dw TryMovePlayerUpLeft

; Input: hPointX, hPointY
; Returns: A = metatile behavior (0..3)
; Destroys: B, C, D, E
GetMetatileBehaviorForPoint:
    ; convert point to map offset
    ldh a, [hPointY+1]
    ld b, a
    ldh a, [hPointX+1]
    ld c, a
    call GetMapOffset
    call GetRoomPtr
    ld e, a
    ; convert point to room offset
    ldh a, [hPointY]
    ld b, a
    ldh a, [hPointX]
    ld c, a
    call GetRoomOffset
    or a, e ; add 6-bit room offset (room data are 64-byte aligned)
    ld e, a
    ; get metatile
    ld a, [de]
    ld c, a
    ; get behaviors for metatile
    ldh a, [hRendererMetatileBehaviorsTable+1]
    ld d, a
    ldh a, [hRendererMetatileBehaviorsTable]
    add a, c
    ld e, a
    jr nc, .skip_inc_d
    inc d
.skip_inc_d:
    ld a, [de] ; get metatile behaviors
    push af
    ; calculate the quadrant (0..3) of the metatile to check
    ld b, 0
    ldh a, [hPointY+1]
    bit 4, a
    jr z, .isUpperHalf
    set 1, b ; b = 2
.isUpperHalf:
    ldh a, [hPointX+1]
    bit 4, a
    jr z, .isLeftHalf
    inc b
.isLeftHalf:
    pop af
    bit 1, b
    jr z, .skipShiftBy4
    swap a
.skipShiftBy4:
    bit 0, b
    jr z, .skipShiftBy2
    srl a
    srl a
.skipShiftBy2:
    and a, 3
    ret

def PLAYER_X_EXTENT equ 6
def PLAYER_Y_EXTENT equ 7

; Try to move the player 1 pixel to the right.
; Returns A = 0 if successful, A != 0 otherwise
TryMovePlayerRight:
    ; check for collision top right
    ldh a, [hPlayerWorldX]
    add a, PLAYER_X_EXTENT + 1
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    adc a, 0
    ldh [hPointX+1], a
    ldh a, [hPlayerWorldY]
    sub a, PLAYER_Y_EXTENT
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    sbc a, 0
    ldh [hPointY+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; check for collision bottom right
    ldh a, [hPlayerWorldY]
    add a, PLAYER_Y_EXTENT
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    adc a, 0
    ldh [hPointY+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; move one pixel right
    ldh a, [hPlayerWorldX]
    inc a
    ldh [hPlayerWorldX], a
    jr nz, .noPageWrap
    ldh a, [hPlayerWorldX+1]
    inc a
    ldh [hPlayerWorldX+1], a
    ldh a, [hPlayerPageWrapFlags]
    set 0, a
    ldh [hPlayerPageWrapFlags], a
.noPageWrap:
    xor a, a ; success
    ret

; Try to move the player 1 pixel to the left.
; Returns A = 0 if successful, A != 0 otherwise
TryMovePlayerLeft:
    ; check for collision top left
    ldh a, [hPlayerWorldX]
    sub a, PLAYER_X_EXTENT + 1
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    sbc a, 0
    ldh [hPointX+1], a
    ldh a, [hPlayerWorldY]
    sub a, PLAYER_Y_EXTENT
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    sbc a, 0
    ldh [hPointY+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; check for collision bottom left
    ldh a, [hPlayerWorldY]
    add a, PLAYER_Y_EXTENT
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    adc a, 0
    ldh [hPointY+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; move one pixel left
    ldh a, [hPlayerWorldX]
    or a, a
    jr nz, .noPageWrap
    ldh a, [hPlayerWorldX+1]
    dec a
    ldh [hPlayerWorldX+1], a
    ldh a, [hPlayerPageWrapFlags]
    set 1, a
    ldh [hPlayerPageWrapFlags], a
    xor a, a
.noPageWrap:
    dec a
    ldh [hPlayerWorldX], a
    xor a, a ; success
    ret

; Try to move the player 1 pixel down.
; Returns A = 0 if successful, A != 0 otherwise
TryMovePlayerDown:
    ; check for collision bottom left
    ldh a, [hPlayerWorldY]
    add a, PLAYER_Y_EXTENT + 1
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    adc a, 0
    ldh [hPointY+1], a
    ldh a, [hPlayerWorldX]
    sub a, PLAYER_X_EXTENT
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    sbc a, 0
    ldh [hPointX+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; check for collision bottom right
    ldh a, [hPlayerWorldX]
    add a, PLAYER_X_EXTENT
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    adc a, 0
    ldh [hPointX+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; move one pixel down
    ldh a, [hPlayerWorldY]
    inc a
    ldh [hPlayerWorldY], a
    jr nz, .noPageWrap
    ldh a, [hPlayerWorldY+1]
    inc a
    ldh [hPlayerWorldY+1], a
    ldh a, [hPlayerPageWrapFlags]
    set 2, a
    ldh [hPlayerPageWrapFlags], a
.noPageWrap:
    xor a, a ; success
    ret

; Try to move the player 1 pixel up.
; Returns A = 0 if successful, A != 0 otherwise
TryMovePlayerUp:
    ; check for collision top left
    ldh a, [hPlayerWorldY]
    sub a, PLAYER_Y_EXTENT + 1
    ldh [hPointY], a
    ldh a, [hPlayerWorldY+1]
    sbc a, 0
    ldh [hPointY+1], a
    ldh a, [hPlayerWorldX]
    sub a, PLAYER_X_EXTENT
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    sbc a, 0
    ldh [hPointX+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; check for collision top right
    ldh a, [hPlayerWorldX]
    add a, PLAYER_X_EXTENT
    ldh [hPointX], a
    ldh a, [hPlayerWorldX+1]
    adc a, 0
    ldh [hPointX+1], a
    call GetMetatileBehaviorForPoint
    or a, a
    ret nz
    ; move one pixel up
    ldh a, [hPlayerWorldY]
    or a, a
    jr nz, .noPageWrap
    ldh a, [hPlayerWorldY+1]
    dec a
    ldh [hPlayerWorldY+1], a
    ldh a, [hPlayerPageWrapFlags]
    set 3, a
    ldh [hPlayerPageWrapFlags], a
    xor a, a
.noPageWrap:
    dec a
    ldh [hPlayerWorldY], a
    xor a, a ; success
    ret

TryMovePlayerDownRight:
    call TryMovePlayerDown
    ld c, a
    push bc
    call TryMovePlayerRight
    pop bc
    ret z
    ld a, c
    or a, a
    ret

TryMovePlayerDownLeft:
    call TryMovePlayerDown
    ld c, a
    push bc
    call TryMovePlayerLeft
    pop bc
    ret z
    ld a, c
    or a, a
    ret

TryMovePlayerUpRight:
    call TryMovePlayerUp
    ld c, a
    push bc
    call TryMovePlayerRight
    pop bc
    ret z
    ld a, c
    or a, a
    ret

TryMovePlayerUpLeft:
    call TryMovePlayerUp
    ld c, a
    push bc
    call TryMovePlayerLeft
    pop bc
    ret z
    ld a, c
    or a, a
    ret

; Converts current object's world position to the screen position.
; HL = pointer to Object_PosX_Frac field
; Returns screen position in hObjectScreenX and hObjectScreenY
; Preserves HL
ConvertObjectWorldPositionToScreenPosition:
    push hl
    ; ScreenX
    ldh a, [hScrollerWorldViewX]
    ld c, a
    inc hl ; Object_PosX_IntLo
    ld a, [hli] ; Object_PosX_IntLo
    sub a, c
    ldh [hObjectScreenX], a
    ld e, a
    ldh a, [hScrollerWorldViewX+1]
    ld c, a
    ld a, [hli] ; Object_PosX_IntHi
    sbc a, c
    ldh [hObjectScreenX+1], a
    ; ScreenY
    ldh a, [hScrollerWorldViewY]
    ld c, a
    inc hl ; Object_PosY_IntLo
    ld a, [hli] ; Object_PosY_IntLo
    sub a, c
    ldh [hObjectScreenY], a
    ld e, a
    ldh a, [hScrollerWorldViewY+1]
    ld c, a
    ld a, [hli] ; Object_PosY_IntHi
    sbc a, c
    ldh [hObjectScreenY+1], a
    pop hl
    ret

; Converts the player's world position to the screen position.
; Returns screen position in hPlayerScreenX and hPlayerScreenY
ConvertPlayerWorldPositionToScreenPosition:
    call ConvertPlayerWorldXToScreenX
    ; fallthrough
ConvertPlayerWorldYToScreenY:
    ldh a, [hScrollerWorldViewY]
    ld c, a
    ldh a, [hPlayerWorldY]
    sub a, c
    ldh [hPlayerScreenY], a
    ld e, a
    ldh a, [hScrollerWorldViewY+1]
    ld c, a
    ldh a, [hPlayerWorldY+1]
    sbc a, c
    ldh [hPlayerScreenY+1], a
    ret

ConvertPlayerWorldXToScreenX:
    ldh a, [hScrollerWorldViewX]
    ld c, a
    ldh a, [hPlayerWorldX]
    sub a, c
    ldh [hPlayerScreenX], a
    ld e, a
    ldh a, [hScrollerWorldViewX+1]
    ld c, a
    ldh a, [hPlayerWorldX+1]
    sbc a, c
    ldh [hPlayerScreenX+1], a
    ret

; Only call this when the screen is off.
ScrollUntilCameraIsCenteredOnPlayer:
    call FlushRendererRequests
    ld a, 8
.scanlineLoop:
    push af
    call ConvertPlayerWorldPositionToScreenPosition
    call CenterCameraOnPlayer
    pop af
    dec a
    jr nz, .scanlineLoop
    ldh a, [hRendererRequestFlags]
    or a, a
    ret z
    jr ScrollUntilCameraIsCenteredOnPlayer

FlushRendererRequests:
    ldh a, [hRendererRequestFlags]
    or a, a
    ret z
    call ProcessRendererRequests
    call FlushVramBuffers
    jr FlushRendererRequests

; Attempts to center the camera on the player, scrolling 1 pixel in either direction if needed.
; Input: hPlayerScreenX and hPlayerScreenY
CenterCameraOnPlayer:
    call CenterCameraOnPlayerXAxis
    jr CenterCameraOnPlayerYAxis

CenterCameraOnPlayerXAxis:
    ldh a, [hPlayerScreenX+1]
    or a, a
    jr nz, .onDifferentPage
    ldh a, [hPlayerScreenX]
    cp a, 160/2
    ret z
    jr c, .scrollLeft
.scrollRight:
    call TryScrollRight
    ret nc
    jp ConvertPlayerWorldXToScreenX
.scrollLeft:
    call TryScrollLeft
    ret nc
    jp ConvertPlayerWorldXToScreenX
.onDifferentPage:
    bit 7, a
    jr nz, .scrollLeft
    jr .scrollRight

CenterCameraOnPlayerYAxis:
    ldh a, [hPlayerScreenX+1]
    or a, a
    jr nz, .onDifferentPage
    ldh a, [hPlayerScreenY]
    cp a, 144/2
    ret z
    jr c, .scrollUp
.scrollDown:
    call TryScrollDown
    ret nc
    jp ConvertPlayerWorldYToScreenY
.scrollUp:
    call TryScrollUp
    ret nc
    jp ConvertPlayerWorldYToScreenY
.onDifferentPage:
    bit 7, a
    jr nz, .scrollUp
    jr .scrollDown

; Input: hPlayerScreenX, hPlayerScreenY, hPlayerFrame
RenderPlayer:
    ; compute clip flags
    xor a, a
    ld b, a
    ldh a, [hPlayerScreenX+1]
    or a, a
    jr nz, .clipXOnDifferentPage
    ldh a, [hPlayerScreenX]
    cp a, 160+8
    jr nc, .hideBoth
    cp a, 160
    jr nc, .hideRightHalf
    jr .computeYClipFlags
.hideBoth:
    ; whole object is offscreen, nothing more to do
    ret
.hideRightHalf:
    set 1, b ; hide right
    jr .computeYClipFlags
.clipXOnDifferentPage:
    bit 7, a
    jr z, .hideBoth ; page >= 1: clearly offscreen
    cp a, $ff
    jr nz, .hideBoth ; page < -1: clearly offscreen
    ldh a, [hPlayerScreenX]
    cp a, -8
    jr c, .hideBoth ; X < -8: whole object offscreen
    set 0, b ; hide left
.computeYClipFlags:
    ldh a, [hPlayerScreenY+1]
    or a, a
    jr nz, .clipYOnDifferentPage
    ldh a, [hPlayerScreenY]
    cp a, 160-8
    jr c, .drawSprites
    ; whole object is offscreen, nothing more to do
    ret
.clipYOnDifferentPage:
    bit 7, a
    jr z, .hideBoth ; page >= 1: clearly offscreen
    cp a, $ff
    jr nz, .hideBoth ; page < -1: clearly offscreen
    ldh a, [hPlayerScreenY]
    cp a, -8
    jr c, .hideBoth ; Y < -8: whole object offscreen
.drawSprites:
    call BeginDrawSprites
    ld de, PlayerCelsData
    ldh a, [hPlayerCel]
    sla a
    sla a
    add a, e
    ld e, a
    jr nc, .skip_inc_d
    inc d
.skip_inc_d:
    bit 0, b ; hide left half?
    jr nz, .skipLeftHalf
    call DrawPlayerLeftHalf
    jr .maybeDrawRightHalf
.skipLeftHalf:
    inc e
    inc e
.maybeDrawRightHalf:
    bit 1, b ; hide right half?
    jr nz, .skipRightHalf
    call DrawPlayerRightHalf
.skipRightHalf:
    call EndDrawSprites
    ret

DrawPlayerLeftHalf:
    ldh a, [hPlayerScreenY]
    add a, 8
    ld [hli], a ; y
    ldh a, [hPlayerScreenX]
    ld [hli], a ; x
    ld a, [de]
    inc e
    ld [hli], a ; tile
    ld a, [de]
    inc e
    ld [hli], a  ; attributes
    ret

DrawPlayerRightHalf:
    ldh a, [hPlayerScreenY]
    add a, 8
    ld [hli], a ; y
    ldh a, [hPlayerScreenX]
    add a, 8
    ld [hli], a ; x
    ld a, [de]
    inc e
    ld [hli], a ; tile
    ld a, [de]
    inc e
    ld [hli], a  ; attributes
    ret

def PLAYER_CEL_TILES_BASE equ $10

Align4
PlayerCelsData:
    ; 0: standing, facing down
    db PLAYER_CEL_TILES_BASE+$00, 0, PLAYER_CEL_TILES_BASE+$02, 0
    ; 1: walking (0), facing down
    db PLAYER_CEL_TILES_BASE+$04, 0, PLAYER_CEL_TILES_BASE+$06, 0
    ; 2: walking (1), facing down
    db PLAYER_CEL_TILES_BASE+$00, 0, PLAYER_CEL_TILES_BASE+$02, 0
    ; 3: walking (2), facing down
    db PLAYER_CEL_TILES_BASE+$08, 0, PLAYER_CEL_TILES_BASE+$0a, 0
    ; 4: walking (3), facing down
    db PLAYER_CEL_TILES_BASE+$00, 0, PLAYER_CEL_TILES_BASE+$02, 0

    ; 5: standing, facing down-left
    db PLAYER_CEL_TILES_BASE+$0c, 0, PLAYER_CEL_TILES_BASE+$0e, 0
    ; 6: walking (0), facing down-left
    db PLAYER_CEL_TILES_BASE+$10, 0, PLAYER_CEL_TILES_BASE+$12, 0
    ; 7: walking (1), facing down-left
    db PLAYER_CEL_TILES_BASE+$0c, 0, PLAYER_CEL_TILES_BASE+$0e, 0
    ; 8: walking (2), facing down-left
    db PLAYER_CEL_TILES_BASE+$14, 0, PLAYER_CEL_TILES_BASE+$16, 0
    ; 9: walking (3), facing down-left
    db PLAYER_CEL_TILES_BASE+$0c, 0, PLAYER_CEL_TILES_BASE+$0e, 0

    ; 10: standing, facing left
    db PLAYER_CEL_TILES_BASE+$18, 0, PLAYER_CEL_TILES_BASE+$1a, 0
    ; 11: walking (0), facing left
    db PLAYER_CEL_TILES_BASE+$1c, 0, PLAYER_CEL_TILES_BASE+$1e, 0
    ; 12: walking (1), facing left
    db PLAYER_CEL_TILES_BASE+$18, 0, PLAYER_CEL_TILES_BASE+$1a, 0
    ; 13: walking (2), facing left
    db PLAYER_CEL_TILES_BASE+$20, 0, PLAYER_CEL_TILES_BASE+$22, 0
    ; 14: walking (3), facing left
    db PLAYER_CEL_TILES_BASE+$18, 0, PLAYER_CEL_TILES_BASE+$1a, 0

    ; 15: standing, facing up-left
    db PLAYER_CEL_TILES_BASE+$24, 0, PLAYER_CEL_TILES_BASE+$26, 0
    ; 16: walking (0), facing up-left
    db PLAYER_CEL_TILES_BASE+$28, 0, PLAYER_CEL_TILES_BASE+$2a, 0
    ; 17: walking (1), facing up-left
    db PLAYER_CEL_TILES_BASE+$24, 0, PLAYER_CEL_TILES_BASE+$26, 0
    ; 18: walking (2), facing up-left
    db PLAYER_CEL_TILES_BASE+$2c, 0, PLAYER_CEL_TILES_BASE+$2e, 0
    ; 19: walking (3), facing up-left
    db PLAYER_CEL_TILES_BASE+$24, 0, PLAYER_CEL_TILES_BASE+$26, 0

    ; 20: standing, facing up
    db PLAYER_CEL_TILES_BASE+$30, 0, PLAYER_CEL_TILES_BASE+$32, 0
    ; 21: walking (0), facing up
    db PLAYER_CEL_TILES_BASE+$34, 0, PLAYER_CEL_TILES_BASE+$36, 0
    ; 22: walking (1), facing up
    db PLAYER_CEL_TILES_BASE+$30, 0, PLAYER_CEL_TILES_BASE+$32, 0
    ; 23: walking (2), facing up
    db PLAYER_CEL_TILES_BASE+$38, 0, PLAYER_CEL_TILES_BASE+$3a, 0
    ; 24: walking (3), facing up
    db PLAYER_CEL_TILES_BASE+$30, 0, PLAYER_CEL_TILES_BASE+$32, 0

    ; 25: standing, facing up-right
    db PLAYER_CEL_TILES_BASE+$3c, 0, PLAYER_CEL_TILES_BASE+$3e, 0
    ; 26: walking (0), facing up-right
    db PLAYER_CEL_TILES_BASE+$40, 0, PLAYER_CEL_TILES_BASE+$42, 0
    ; 27: walking (1), facing up-right
    db PLAYER_CEL_TILES_BASE+$3c, 0, PLAYER_CEL_TILES_BASE+$3e, 0
    ; 28: walking (2), facing up-right
    db PLAYER_CEL_TILES_BASE+$44, 0, PLAYER_CEL_TILES_BASE+$46, 0
    ; 29: walking (3), facing up-right
    db PLAYER_CEL_TILES_BASE+$3c, 0, PLAYER_CEL_TILES_BASE+$3e, 0

    ; 30: standing, facing right
    db PLAYER_CEL_TILES_BASE+$48, 0, PLAYER_CEL_TILES_BASE+$4a, 0
    ; 31: walking (0), facing right
    db PLAYER_CEL_TILES_BASE+$4c, 0, PLAYER_CEL_TILES_BASE+$4e, 0
    ; 32: walking (1), facing right
    db PLAYER_CEL_TILES_BASE+$48, 0, PLAYER_CEL_TILES_BASE+$4a, 0
    ; 33: walking (2), facing right
    db PLAYER_CEL_TILES_BASE+$50, 0, PLAYER_CEL_TILES_BASE+$52, 0
    ; 34: walking (3), facing right
    db PLAYER_CEL_TILES_BASE+$48, 0, PLAYER_CEL_TILES_BASE+$4a, 0

    ; 35: standing, facing right
    db PLAYER_CEL_TILES_BASE+$54, 0, PLAYER_CEL_TILES_BASE+$56, 0
    ; 36: walking (0), facing right
    db PLAYER_CEL_TILES_BASE+$58, 0, PLAYER_CEL_TILES_BASE+$5a, 0
    ; 37: walking (1), facing right
    db PLAYER_CEL_TILES_BASE+$54, 0, PLAYER_CEL_TILES_BASE+$56, 0
    ; 38: walking (2), facing right
    db PLAYER_CEL_TILES_BASE+$5c, 0, PLAYER_CEL_TILES_BASE+$5e, 0
    ; 39: walking (3), facing right
    db PLAYER_CEL_TILES_BASE+$54, 0, PLAYER_CEL_TILES_BASE+$56, 0

SECTION "Tile data", ROM0

severance_tiles:
incbin "bgtiles.bin"
; $10
; https://gibbongl.itch.io/8-directional-gameboy-character-template?utm_source=chatgpt.com
incbin "herosprites.bin"

incbin "font.bin"
severance_tiles_end:

SECTION "Palette data", rom0

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

severance_bg_palettes:
; 0 - floor (green)
    rgb 0, 0, 0
    rgb 10, 13, 10
    rgb 15, 20, 15
    rgb 20, 23, 20
; 1 - wall (white)
    rgb 0, 0, 0
    rgb 10, 10, 10
    rgb 20, 20, 20
    rgb 30, 30, 30
severance_bg_palettes_end:

severance_obj_palettes:
; 0
    rgb 0, 0, 0
    rgb 10, 8, 5
    rgb 20, 15, 10
    rgb 31, 31, 31
severance_obj_palettes_end:

SECTION "VRAM strings", ROM0

SETCHARMAP new
NPC0Text:
db $9C, $21, 14, "The work is   "
db $9C, $41, 14, "mysterious and"
db $9C, $61, 14, "important.    "
db 0
NPC0TextEnd:
NPC1Text:
db $9C, $21, 14, "We're all in  "
db $9C, $41, 14, "this together."
db $9C, $61, 14, "              "
db 0
NPC1TextEnd:
NPC2Text:
db $9C, $21, 14, "A good worker "
db $9C, $41, 14, "is a happy    "
db $9C, $61, 14, "worker.       "
db 0
NPC2TextEnd:
NPC3Text:
db $9C, $21, 14, "Never go to   "
db $9C, $41, 14, "the Perpetuity"
db $9C, $61, 14, "Wing alone.   "
db 0
NPC3TextEnd:
NPC4Text:
db $9C, $21, 14, "I am a person."
db $9C, $41, 14, "You are not.  "
db $9C, $61, 14, "              "
db 0
NPC4TextEnd:
NPC5Text:
db $9C, $21, 14, "I wonder      "
db $9C, $41, 14, "what's for    "
db $9C, $61, 14, "dinner.       "
db 0
NPC5TextEnd:
NPC6Text:
db $9C, $21, 14, "A handshake is"
db $9C, $41, 14, "available upon"
db $9C, $61, 14, "request.      "
db 0
NPC6TextEnd:
NPC7Text:
db $9C, $21, 14, "Devour        "
db $9C, $41, 14, "feculence.    "
db $9C, $61, 14, "              "
db 0
NPC7TextEnd:

NPCTextData:
dw NPC0Text, NPC0TextEnd - NPC0Text
dw NPC1Text, NPC1TextEnd - NPC1Text
dw NPC2Text, NPC2TextEnd - NPC2Text
dw NPC3Text, NPC3TextEnd - NPC3Text
dw NPC4Text, NPC4TextEnd - NPC4Text
dw NPC5Text, NPC5TextEnd - NPC5Text
dw NPC6Text, NPC6TextEnd - NPC6Text
dw NPC7Text, NPC7TextEnd - NPC7Text
