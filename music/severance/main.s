INCLUDE "hardware.inc"

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
db $11, $23, $45, $67
db $89, $ab, $cd, $ef
db $ff, $ee, $dc, $ba
db $98, $76, $54, $32

; --- End sound engine ---

; --- Sound data

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
    ld a, 16
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

ScrollUp:
    ldh a, [hScrollerWorldViewY]
    cp a, 16
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hScrollerWorldViewY+1]
    or a, a
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewY]
    jr .canScroll
.reachedEndOfMap:
    ret
.canScroll:
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
    jr nz, .noTilemapUpdate
    call RequestRenderUp
.noTilemapUpdate:
    ret

ScrollDown:
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
.noPageWrap:
    ret

ScrollLeft:
    ldh a, [hScrollerWorldViewX]
    cp a, 16
    jr nz, .canScroll
    ; check if allowed to scroll any further
    ldh a, [hScrollerWorldViewX+1]
    or a, a
    jr z, .reachedEndOfMap
    ldh a, [hScrollerWorldViewX]
    jr .canScroll
.reachedEndOfMap:
    ret
.canScroll:
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
    jr nz, .noTilemapUpdate
    call RequestRenderLeft
.noTilemapUpdate:
    ret

ScrollRight:
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
.noPageWrap:
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
    ld a, 23
.loop:
    push af
    call RenderRight
    call FlushVramBuffers
    pop af
    dec a
    jr nz, .loop
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
; move to previous row
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
; prepare state
    ldh a, [hRendererMapOffset]
    ldh [hRendererSaveMapOffset], a
    ldh a, [hRendererRoomCol]
    sub a, 23
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
    add a, 23
    and a, 31
    ldh [hRendererRoomCol], a
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
    ret

RenderDown:
; prepare state
    ldh a, [hRendererMapOffset]
    ldh [hRendererSaveMapOffset], a
    ldh a, [hRendererRoomCol]
    sub a, 23
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
    add a, 21
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
    add a, 23
    and a, 31
    ldh [hRendererRoomCol], a
    ldh a, [hRendererRoomRow]
    sub a, 21
    and a, 31
    ldh [hRendererRoomRow], a
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
; advance to next row
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
    sub a, $18
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
; move to previous column
    ldh a, [hRendererSaveMapOffset]
    ldh [hRendererMapOffset], a
    ldh a, [hRendererRoomCol]
    add a, $18 - 1
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
; advance to next column
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
    cp a, 21
    jr c, .two_strips
    ld a, 21
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
    cp a, 21
    jr z, .column_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 21
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
    cp a, 21
    jr c, .two_strips
    ld a, 21
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
    cp a, 21
    jr z, .column_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 21
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
    cp a, 23
    jr c, .two_strips
    ld a, 23
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
    cp a, 23
    jr z, .row_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 23
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
    cp a, 23
    jr c, .two_strips
    ld a, 23
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
    cp a, 23
    jr z, .row_done   ; exit if no more bytes to write
; prepare to write second strip
    ld b, a
    ld a, 23
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
    ld a, $0
    ldh [hSoundStatus], a ; unmute all channels

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
    call UpdateObjects
    call ProcessPlayerPageWrapFlags
    call ConvertPlayerWorldPositionToScreenPosition
    call RenderPlayer
    call CenterCameraOnPlayer
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
    ; ScreenX
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
    ; ScreenY
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
    jp ScrollRight
.scrollLeft:
    jp ScrollLeft
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
    jp ScrollDown
.scrollUp:
    jp ScrollUp
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
