INCLUDE "hardware.inc"

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

hPaletteBufferOffset: db

hPixelNo: db
hTransitionNo: db
hTransition: dw
hCursorX: db
hCursorY: db
hSourceImage: dw
hTargetImage: dw
hImageFlipFlop: db
hSourceImagePixel: db
hTargetImagePixel: db
hSourceImagePixelPaletteValue: dw
hTargetImagePixelPaletteValue: dw
hImageIndex: db
hTimer: db

hT0: db
hT1: db
hT2: db
hT3: db

; --- Begin object engine

hObjectsHead: dw
hObjectsFreeHead: dw
hKillMe: db

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

wPaletteBuffer:
    ds 96

wVramBuffer0:
    ds 128
wVramBuffer1:
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

; --- Begin object engine

rsreset
def Object_Next   rw 1 ; 00
def Object_State  rb 1 ; 02 - bits 7..6: source color, bits 5..4: target color, bits 3..0: timer
def Frame         rb 1 ; 03
def Object_PosY   rb 1 ; 04
def Object_PosX   rb 1 ; 05
def Object_SIZEOF rb 0 ; 06

def MAX_OBJECTS equ 40

wObjectsArena:
  ds Object_SIZEOF * MAX_OBJECTS

; --- End object engine

wImageAttributeTable: ds 8*8
wSourceImagePalette: ds 4*2
wTargetImagePalette: ds 4*2

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

HeaderTitle:
	db   "SNOWBRO 023", $00, $00, $00, $00

HeaderCGBFlag:
    db   $80

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
        call FlushPaletteBuffer
	    call hOamDmaFunction
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

FlushPaletteBuffer:
    ldh a, [hPaletteBufferOffset]
    or a, a
    ret z
    xor a
    ldh [hPaletteBufferOffset], a
    ld hl, wPaletteBuffer
; Fallthrough
;    jr WritePaletteStrings

WritePaletteStrings:
    ; hl = address of data
    ld a, [hli]
    or a, a
    ret z ; end of buffer
    sla a
    ld b, a ; count * 2
    ld a, [hli] ; start index
    sla a
    bit 6, a
    jr nz, .is_obj
    or a, BCPSF_AUTOINC
    ldh [rBCPS], a
    .bg_loop:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg_loop
    jr WritePaletteStrings
    .is_obj:
    and a, $3f
    or a, OCPSF_AUTOINC
    ldh [rOCPS], a
    .obj_loop:
    ld a, [hli]
    ldh [rOCPD], a
    dec b
    jr nz, .obj_loop
    jr WritePaletteStrings

; B = start color index (0-31 = BG, 32-63 = OBJ)
; C = count
; returns HL = palette buffer pointer
BeginPaletteString:
    ld hl, wPaletteBuffer
    ldh a, [hPaletteBufferOffset]
    push bc
    ld b, 0
    ld c, a
    add hl, bc
    pop bc
    ld a, c
    ld [hli], a ; count
    ld a, b
    ld [hli], a ; color index
    ret

EndPaletteString:
    xor a
    ld [hl], a
    ld a, l
    sub a, LOW(wPaletteBuffer)
    ldh [hPaletteBufferOffset], a
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
; Destroys: BC
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
    jp UpdateFlippingTile

; --- End object engine ---

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

; --- End sound engine ---

; --- Sound data

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

    ; Set up loading of first image
    ld a, [ImageTable+0]
    ld [hTargetImage+0], a
    ld a, [ImageTable+1]
    ld [hTargetImage+1], a
    ld a, 1
    ld [hImageFlipFlop], a
    call LoadTargetImagePalette
    call SetTransition

    call InitializeObjects

    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld hl, song_song
    call StartSong
    ld a, $0
    ldh [hSoundStatus], a ; unmute all channels

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

    ld a, 1
    ldh [hMainState], a ; ProcessPixels

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ8 | LCDCF_BG9800
	ld [rLCDC], a

Done:
    halt
    jp Done

; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc_NoOp                    ; 0
dw MainFunc_ProcessPixels           ; 1
dw MainFunc_DelayAfterProcessPixels ; 2
dw MainFunc_FadeToGray              ; 3
dw MainFunc_DelayAfterFlipPixel     ; 4
dw MainFunc_DelayAfterFadeStep      ; 5
dw MainFunc_DelayAfterFadeToGray    ; 6

MainFunc_NoOp:
    ret

CommonStuff:
    call HideAllSprites
    jp CheckMuteUnmuteChannels

MainFunc_ProcessPixels:
    call CommonStuff
    ; find the next pixel to flip
    .scan_pixel:
    ldh a, [hTransition+0]
    ld l, a
    ldh a, [hTransition+1]
    ld h, a
    ld b, 0
    ldh a, [hPixelNo]
    ld c, a
    add hl, bc
    ld a, [hl] ; map from pixel no to cursor
    and a, $0f
    ldh [hCursorX], a
    ld b, a
    ld a, [hl]
    and a, $f0
    swap a
    ldh [hCursorY], a
    ld c, a
    call GetSourceImagePixel
    ldh [hSourceImagePixel], a
    ldh a, [hCursorX]
    ld b, a
    ldh a, [hCursorY]
    ld c, a
    call GetTargetImagePixel
    ldh [hTargetImagePixel], a
    ; if source and target pixel palette values are the same, nothing to.
    call MapTargetImagePixelToPaletteValue
    ld a, c
    ldh [hTargetImagePixelPaletteValue+0], a
    ld a, b
    ldh [hTargetImagePixelPaletteValue+1], a
    push bc
    ldh a, [hSourceImagePixel]
    call MapSourceImagePixelToPaletteValue
    pop de ; target image pixel palette value
    ld a, e
    cp a, c
    jr nz, .flip_pixel ; if lower bytes are different, we should flip
    ld a, d
    cp a, b
    jr nz, .flip_pixel ; if higher bytes are different, we should flip
    ldh a, [hPixelNo]
    inc a ; next pixel
    ldh [hPixelNo], a
    jr nz, .scan_pixel

    ; done all pixels
    call UpdateObjects
    call CopyTargetImagePaletteToSourceImagePalette
    call ConvertTargetImagePaletteToGrayscale
    ld a, 78
    ldh [hTimer], a
    ld a, 2 ; DelayAfterProcessPixels
    ldh [hMainState], a
    ret

    .flip_pixel:
    call SpawnPixelFlip
    call EraseCursorTiles
    call UpdateObjects
    ld a, 1
    ldh [hTimer], a
    ld a, 4 ; DelayAfterFlipPixel
    ldh [hMainState], a
    ret

SpawnPixelFlip:
    call AllocateObject
    inc hl ; Object_Next (high)
    inc hl ; Object_State
    ; compute state
    ldh a, [hSourceImagePixel]
    swap a
    sla a
    sla a ; source pixel in bits 7-6
    ld [hl], a
    ldh a, [hTargetImagePixel]
    swap a ; target pixel in bits 5-4
    or a, [hl]
    or a, 3 ; set timer
    ld [hli], a ; state
    ; frame
    ; if source color is black (0), start on frame 4
    ldh a, [hSourceImagePixel]
    or a
    jr z, .start_frame_4
    xor a ; start from frame 0
    jr .set_frame
    .start_frame_4:
    ld a, 4
    .set_frame:
    ld [hli], a ; frame
;    ; y_pos
    ldh a, [hCursorY]
    sla a
    sla a
    sla a ; each tile is 8 pixels tall
    ld [hli], a
    ; x_pos
    ldh a, [hCursorX]
    sla a
    sla a
    sla a ; each tile is 8 pixels wide
    ld [hl], a
    ret

MainFunc_DelayAfterProcessPixels:
    call CommonStuff
    call UpdateObjects
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    ret nz
    ld a, 3 ; FadeToGray
    ldh [hMainState], a
    ret

MainFunc_FadeToGray:
    call CommonStuff
    ld b, 4 ; palette entries
    ld c, 0 ; count the number of components that were updated
    ld de, wSourceImagePalette
    ld hl, wTargetImagePalette
    .loop:
    push bc
    ld a, [hl] ; low byte of target palette entry
    and a, $1f ; target red
    ld b, a
    ld a, [de] ; low byte of source palette entry
    and a, $1f ; source red
    cp a, b ; source == target?
    jr z, .check_green
    jr c, .increase_red
    ; decrease red
    dec a
    .encode_red:
    ld b, a ; new red
    ld a, [de] ; low byte of source palette entry
    and a, $e0 ; remove old red
    or a, b ; set new red
    ld [de], a ; low byte of source palette entry
    pop bc
    inc c ; change counter
    push bc
    jr .check_green
    .increase_red:
    inc a
    jr .encode_red
    .check_green:
    ld a, [hli] ; low byte of target palette entry
    and a, $e0 ; keep lower 3 bits of green
    swap a
    srl a ; lower 3 bits of green
    ld b, a
    ld a, [hl] ; high byte of target palette entry
    and a, $03 ; high 2 bits of green
    swap a
    srl a
    or a, b ; target green
    ld b, a ; target green
    ld a, [de] ; low byte of source palette entry
    inc de
    and a, $e0 ; keep lower 3 bits of green
    swap a
    srl a ; lower 3 bits of green
    ld c, a
    ld a, [de] ; high byte of source palette entry
    and a, $03 ; high 2 bits of green
    swap a
    srl a
    or a, c ; source green
    cp a, b ; source == target?
    jr z, .check_blue
    jr c, .increase_green
    ; decrease green
    dec a
    .encode_green:
    ld b, a ; new green
    srl a
    srl a
    srl a ; high 2 bits of new green
    ld c, a
    ld a, [de] ; high byte of source palette entry
    and a, $7c ; remove old high bits of green
    or a, c ; set new high bits of green
    ld [de], a ; high byte of source palette entry
    dec de
    ld a, b ; new green
    and a, $07 ; lower 3 bits of new green
    swap a
    sla a
    ld b, a
    ld a, [de] ; low byte of source palette entry
    and a, $1f ; remove old bits of green
    or a, b ; set new low bits of green
    ld [de], a ; low byte of source palette entry
    inc de
    pop bc
    inc c ; change counter
    push bc
    jr .check_blue
    .increase_green:
    inc a
    jr .encode_green
    .check_blue:
    ld a, [hli] ; high byte of target palette entry
    srl a
    srl a ; target blue
    ld b, a
    ld a, [de] ; high byte of source palette entry
    srl a
    srl a ; source blue
    cp a, b ; source == target?
    jr z, .next
    jr c, .increase_blue
    ; decrease blue
    dec a
    .encode_blue:
    sla a
    sla a
    ld b, a ; new blue
    ld a, [de] ; high byte of source palette entry
    and a, $03 ; remove old blue
    or a, b ; set new blue
    ld [de], a ; high byte of source palette entry
    pop bc
    inc c ; change counter
    push bc
    jr .next
    .increase_blue:
    inc a
    jr .encode_blue
    .next:
    inc de
    pop bc
    dec b
    jr z, .loop_done
    jp .loop
    .loop_done:
    ld a, c ; change counter
    or a ; did any components change?
    jr z, .fading_done
    ; update palette and wait
    call CopySourceImagePaletteToPPUBuffer
    ld a, 6
    ldh [hTimer], a
    ld a, 5 ; DelayAfterFadeStep
    ldh [hMainState], a
    ret
    .fading_done:
    ld a, 39
    ldh [hTimer], a
    ld a, 6 ; DelayAfterFadeToGray
    ldh [hMainState], a
    ret

MainFunc_DelayAfterFadeStep:
    call CommonStuff
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    ret nz
    ld a, 3 ; FadeToGray
    ldh [hMainState], a
    ret

MainFunc_DelayAfterFadeToGray:
    call CommonStuff
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    ret nz
    ; go to next image
    xor a
    ldh [hCursorX], a
    ldh [hCursorY], a
    ldh a, [hTargetImage+0]
    ldh [hSourceImage+0], a
    ldh a, [hTargetImage+1]
    ldh [hSourceImage+1], a
    ldh a, [hImageIndex]
    inc a ; next image
    cp a, 23 ; image count
    jr nz, .skip
    xor a ; start at first image again
    .skip:
    ldh [hImageIndex], a
    sla a
    ld c, a
    ld b, 0
    ld hl, ImageTable
    add hl, bc
    ld a, [hli] ; low byte of target image
    ldh [hTargetImage+0], a
    ld a, [hl] ; high byte of target image
    ldh [hTargetImage+1], a
    ldh a, [hImageFlipFlop]
    xor a, 1 ; toggle flip-flop
    ldh [hImageFlipFlop], a
    call LoadTargetImagePalette
    call SetTransition
    ld a, 1 ; ProcessPixels
    ldh [hMainState], a
    ret

MainFunc_DelayAfterFlipPixel:
    call CommonStuff
    call UpdateObjects
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    ret nz
    ; timeout
    ldh a, [hPixelNo]
    inc a ; next pixel
    ldh [hPixelNo], a
    jr nz, .process_next_pixel
    ; done all pixels
    call CopyTargetImagePaletteToSourceImagePalette
    call ConvertTargetImagePaletteToGrayscale
    ld a, 78
    ldh [hTimer], a
    ld a, 2 ; DelayAfterProcessPixels
    ldh [hMainState], a
    ret
    .process_next_pixel:
    ld a, 1 ; ProcessPixels
    ldh [hMainState], a
    ret

EraseCursorTiles:
    ; high PPU address
    ldh a, [hCursorY]
    srl a
    srl a
    srl a ; high cursor bit in A[0]
    or a, $98
    ld d, a
    ; low PPU address
    ldh a, [hCursorY]
    and a, 7 ; lower 3 cursor bits
    swap a
    sla a
    ld e, a
    ldh a, [hCursorX]
    or a, e
    add a, $20 + 2 ; center
    jr nc, .no_inc_d
    inc d
    .no_inc_d:
    ld e, a
    ld c, 1 ; count
    call BeginVram0String
    ld a, 0 ; blank tile
    ld [hli], a
    jp EndVram0String

; A = pixel value (0..3)
; returns BC = palette value
MapSourceImagePixelToPaletteValue:
    sla a
    ld c, a
    ld b, 0
    ld hl, wSourceImagePalette
    add hl, bc
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ld b, a
    ret

; A = pixel value (0..3)
; returns BC = palette value
MapTargetImagePixelToPaletteValue:
    sla a
    ld c, a
    ld b, 0
    ld hl, wTargetImagePalette
    add hl, bc
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ld b, a
    ret

; B = x, C = y
; Returns A = pixel value (0..3)
GetSourceImagePixel:
    ldh a, [hSourceImage+0]
    ld l, a
    ldh a, [hSourceImage+1]
    ld h, a
    or a, l
    ret z
    jr GetImagePixel

; B = x, C = y
; Returns A = pixel value (0..3)
GetTargetImagePixel:
    ldh a, [hTargetImage+0]
    ld l, a
    ldh a, [hTargetImage+1]
    ld h, a
    or a, l
    ret z
    jr GetImagePixel

; HL = pointer to image
; B = x, C = y
; returns A = pixel value (0..3)
GetImagePixel:
    ld a, c
    ldh [hT0], a
    ld a, b
    ldh [hT1], a
    ; pixel byte offset calculation: (y & 8)*2 + (x & 8)*4 + (y & 7)
    ; %00xy0yyy
    and a, 8
    sla a
    ldh [hT2], a
    ld d, a
    ld a, [hT0]
    and a, 8
    or a, d
    sla a
    ldh [hT2], a
    ld d, a
    ldh a, [hT0]
    and a, 7
    or a, d
    ldh [hT2], a
    add a, 8 ; skip palette
    push bc
    ld b, 0
    ld c, a
    add hl, bc
    pop bc
    ; %01234567
    ; lower bit
    ld a, [hl]
    ldh [hT3], a
    ldh a, [hT1]
    and a, 7
    xor a, 7
    ld d, a
    ldh a, [hT3]
    jr z, .skip
    .loop:
    srl a
    dec d
    jr nz, .loop
    .skip:
    and a, 1
    ldh [hT3], a
    ; upper bit
    ld de, 8
    add hl, de
    ld a, [hl]
    ldh [hT2], a
    ldh a, [hT1]
    and a, 7
    xor a, 7
    ld d, a
    ldh a, [hT2]
    jr z, .skip2
    .loop2:
    srl a
    dec d
    jr nz, .loop2
    .skip2:
    and a, 1
    sla a
    ld d, a
    ldh a, [hT3]
    or a, d
    ldh [hT3], a
    ret

CheckMuteUnmuteChannels:
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

SetTransition:
    ldh a, [hTransitionNo]
    cp a, 17
    jr nz, .skip
    xor a
    .skip:
    inc a
    ldh [hTransitionNo], a
    dec a
    sla a
    ld c, a
    ld b, 0
    ld hl, Transitions
    add hl, bc
    ld a, [hli] ; low byte of transition
    ldh [hTransition+0], a
    ld a, [hl] ; high byte of transition
    ldh [hTransition+1], a
    ret

LoadTargetImagePalette:
    ldh a, [hTargetImage+0]
    ld l, a
    ldh a, [hTargetImage+1]
    ld h, a
    ld de, wTargetImagePalette
    ld b, 4*2
    .loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    jr CopyTargetImagePaletteToPPUBuffer

; De = source palette
CopyImagePaletteToPPUBuffer:
    push de
    ldh a, [hImageFlipFlop]
    sla a
    sla a
    push af
    ld b, a ; start color index
    ld c, 4 ; number of colors
    call BeginPaletteString
    ld b, 8
    .loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    call EndPaletteString
    pop af ; start color index (BG)
    or a, 32 ; OBJ palettes index
    ld b, a ; start color index
    ld c, 4 ; number of colors
    call BeginPaletteString
    pop de ; source palette
    ld b, 8
    .loop2:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop2
    jp EndPaletteString

CopyTargetImagePaletteToPPUBuffer:
    ld de, wTargetImagePalette
    jr CopyImagePaletteToPPUBuffer

CopySourceImagePaletteToPPUBuffer:
    ld de, wSourceImagePalette
    jr CopyImagePaletteToPPUBuffer

CopyTargetImagePaletteToSourceImagePalette:
    ld a, [wTargetImagePalette+0]
    ld [wSourceImagePalette+0], a
    ld a, [wTargetImagePalette+1]
    ld [wSourceImagePalette+1], a
    ld a, [wTargetImagePalette+2]
    ld [wSourceImagePalette+2], a
    ld a, [wTargetImagePalette+3]
    ld [wSourceImagePalette+3], a
    ld a, [wTargetImagePalette+4]
    ld [wSourceImagePalette+4], a
    ld a, [wTargetImagePalette+5]
    ld [wSourceImagePalette+5], a
    ld a, [wTargetImagePalette+6]
    ld [wSourceImagePalette+6], a
    ld a, [wTargetImagePalette+7]
    ld [wSourceImagePalette+7], a
    ret

ConvertTargetImagePaletteToGrayscale:
    ld hl, wTargetImagePalette
    ld b, 4 ; entries
.loop:
    ld a, [hl]
    and a, $1f ; red
    ld c, a
    ld a, [hli]
    swap a
    srl a
    and a, $07 ; lower 3 bits of green
    ld d, a
    ld a, [hl]
    and a, $03 ; high 2 bits of green
    swap a
    srl a
    or a, d ; green
    ld d, a
    ld a, [hl]
    srl a
    srl a ; blue
    add a, c ; add red
    add a, d ; add green
    ld e, a
    ld d, 0
    push hl
    ld hl, .div3_lut
    add hl, de
    ld a, [hl] ; (R+B+G)/3
    pop hl
    ld c, a
    sla a
    sla a
    ld d, a
    ld a, c
    srl a
    srl a
    srl a
    or a, d
    ld [hl-], a ; high byte
    ld a, c
    and a, $07 ; lower 3 bits of green
    swap a
    sla a
    or a, c ; add red
    ld [hli], a ; low byte
    inc hl ; next palette entry
    dec b
    jr nz, .loop
    ret
.div3_lut:
    db $00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05
    db $05,$05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$0A,$0A
    db $0A,$0B,$0B,$0B,$0C,$0C,$0C,$0D,$0D,$0D,$0E,$0E,$0E,$0F,$0F,$0F
    db $10,$10,$10,$11,$11,$11,$12,$12,$12,$13,$13,$13,$14,$14,$14,$15
    db $15,$15,$16,$16,$16,$17,$17,$17,$18,$18,$18,$19,$19,$19,$1A,$1A
    db $1A,$1B,$1B,$1B,$1C,$1C,$1C,$1D,$1D,$1D,$1E,$1E,$1E,$1F,$1F,$1F

; HL = pointer to object state
UpdateFlippingTile:
    call DrawFlippingTile
    ld a, [hl] ; state
    and a, $0F ; timer
    dec a
    bit 7, a ; negative?
    jr nz, .timeout
    ld b, a ; new timer value
    ld a, [hl] ; state
    and a, $f0 ; remove old timer bits
    or a, b ; set new timer bits
    ld [hl], a ; state
    ret
    .timeout:
    ld a, [hli] ; state
    and a, %00110000 ; target pixel
    ld a, 8 ; speculatively guess that target pixel is non-zero
    jr nz, .10
    srl a ; when target pixel is 0, we don't show the back side (only first 4 frames)
    .10:
    ld b, a ; end frame
    ld a, [hl] ; frame
    inc a ; next frame
    cp a, b ; reached end frame?
    jr z, .done
    ld [hl-], a ; frame
    ld a, [hl] ; state
    or a, 3 ; reset timer
    ld [hl], a ; state
    ret
    .done:
    dec hl ; state
    ld a, [hli] ; state
    and a, %00110000 ; target pixel
    swap a ; target pixel in lower 2 bits
    push af
    inc hl ; pos_y
    ld a, [hli] ; pos_y
    srl a
    srl a
    srl a ; divide by 8, since each tile is 8 pixels tall
    ld c, a ; y
    ld a, [hl] ; pos_x
    srl a
    srl a
    srl a ; divide by 8, since each tile is 8 pixels wide
    ld b, a ; x
    pop af ; pixel value
    call PlotPixel
    ld a, 1
    ld [hKillMe], a
    ret

; A = value (0..3), X = b (0..15), Y = c (0..15)
PlotPixel:
    ldh [hT0], a
    ; PPU address calculation: $9800 + y*32 + x + $20 + $02
    ; %1001100yyyy0xxxx
    ; high address
    ld a, c
    srl a
    srl a
    srl a
    or a, $98
    ld d, a
    ; low address
    ld a, c
    and a, 7
    swap a
    sla a
    or a, b
    add a, $20 + 2 ; center
    ld e, a
    jr nc, .no_inc_d
    inc d
    .no_inc_d:
    push de
    ld c, 1
    call BeginVram0String
    ldh a, [hT0]
    ld [hli], a ; tile
    call EndVram0String
    ; attribute data
    pop de
    ldh a, [rSVBK]
    cp a, $ff
    ret z ; exit if we are on DMG
    ld c, 1
    call BeginVram1String
    ldh a, [hImageFlipFlop]
    ld [hli], a ; attributes
    jp EndVram1String

; HL = pointer to object state
; Destroys: BC, DE
DrawFlippingTile:
    push hl
    ; calculate base tile of the animation
    ld a, [hli] ; state
    ld b, a
    ld a, [hl] ; frame
    bit 2, a ; front (0..3) or back (4..7)?
    ld a, b
    jr nz, .use_target_pixel
    and a, %11000000 ; use source pixel
    swap a ; source pixel * 4
    jr .10
.use_target_pixel:
    and a, %00110000 ; use target pixel
    swap a
    sla a
    sla a ; target pixel * 4
    .10:
    sub a, 4
    ld b, a ; base tile
    ld a, [hl] ; frame
    bit 2, a ; front (0..3) or back (4..7)?
    jr z, .20
    and a, 3
    xor a, 3 ; frames play in reverse order
    .20:
    or a, b ; add base tile
    ld c, a ; final tile
    ld a, [hli] ; frame
    bit 2, a ; front (0..3) or back (4..7)?
    ld a, 1 ; speculatively prepare front attributes
    jr z, .30
    ld a, OAMF_XFLIP ; back attributes
    .30:
    ld b, a ; preliminary attributes
    ldh a, [hImageFlipFlop]
    xor a, b
    ld b, a ; final attributes
    ld d, h
    ld e, l ; save HL in DE
    push bc
    call BeginDrawSprites
    ld a, [de] ; pos_y
    inc de
    add a, 16 + 8
    ld [hli], a ; sprite y
    ld a, [de] ; pos_x
    add a, 8 + 16
    ld [hli], a ;  sprite x
    pop bc
    ld a, c ; tile
    ld [hli], a ; sprite tile
    ld a, b ; attributes
    ld [hli], a ; sprite attributes
    call EndDrawSprites
    pop hl ; state
    ret

macro rgb
dw (\3 << 10) | (\2 << 5) | \1
endm

SECTION "Tile data", ROM0

BGTiles:
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00
db $00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
BGTilesEnd:

OBJTiles:
incbin "flip.bin"  ; $00 - 12 tiles
OBJTilesEnd:

SECTION "Palette data", ROM0

BGPalettes:
; 0 - placeholder for first image
rgb 0, 0, 0
rgb 0, 0, 0
rgb 0, 0, 0
rgb 0, 0, 0
; 1 - placeholder for second image
rgb 0, 0, 0
rgb 0, 0, 0
rgb 0, 0, 0
rgb 0, 0, 0
BGPalettesEnd:

SECTION "Image data", ROM0

EggImage:
rgb 0, 0, 0
rgb 8, 31, 3
rgb 12, 9, 2
rgb 27, 25, 10
incbin "egg.bin" ; pixel data

ElfImage:
rgb 0, 0, 0
rgb 15, 26, 0
rgb 27, 18, 4
rgb 10, 8, 0
incbin "elf.bin" ; pixel data

DragonImage:
rgb 0, 0, 0
rgb 8, 24, 6
rgb 31, 10, 4
rgb 31, 31, 31
incbin "dragon.bin" ; pixel data

MoneyImage:
rgb 0, 0, 0
rgb 12, 4, 2
rgb 30, 22, 31
rgb 22, 12, 6
incbin "money.bin" ; pixel data

TurtleImage:
; palette
rgb 0, 0, 0
rgb 2, 10, 2
rgb 4, 30, 4
rgb 12, 4, 30
incbin "turtle.bin" ; pixel data

JumpmanImage:
; palette
rgb 0, 0, 0
rgb 0, 15, 30
rgb 29, 25, 21
rgb 30, 7, 0
incbin "jumpman.bin" ; pixel data

HandImage:
; palette
rgb 0, 0, 0
rgb 31, 24, 20
rgb 22, 14, 16
rgb 16, 10, 4
incbin "hand.bin" ; pixel data

BootsImage:
; palette
rgb 0, 0, 0
rgb 14, 8, 2
rgb 22, 10, 16
rgb 31, 20, 24
incbin "boots.bin" ; pixel data

OhImage:
; palette
rgb 0, 0, 0
rgb 12, 6, 0
rgb 26, 22, 8
rgb 26, 22, 8
incbin "oh.bin" ; pixel data

KnightImage:
; palette
rgb 0, 0, 0
rgb 19, 7, 2
rgb 31, 20, 12
rgb 31, 31, 31
incbin "knight.bin" ; pixel data

OneUpImage:
; palette
rgb 0, 0, 0
rgb 16, 8, 0
rgb 15, 26, 0
rgb 10, 0, 13
incbin "1up.bin" ; pixel data

StarImage:
; palette
rgb 0, 0, 0
rgb 11, 12, 0
rgb 21, 22, 0
rgb 27, 27, 16
incbin "star.bin" ; pixel data

FishImage:
; palette
rgb 0, 0, 0
rgb 6, 0, 18
rgb 30, 25, 19
rgb 20, 5, 4
incbin "fish.bin" ; pixel data

LampImage:
rgb 0, 0, 0
rgb 27, 27, 16
rgb 21, 22, 0
rgb 11, 12, 0
incbin "lamp.bin" ; pixel data

StartImage:
rgb 0, 0, 0
rgb 1, 10, 26
rgb 0, 15, 5
rgb 30, 22, 31
incbin "start.bin" ; pixel data

QuestionImage:
rgb 0, 0, 0
rgb 6, 0, 18
rgb 12, 4, 30
rgb 21, 22, 0
incbin "question.bin" ; pixel data

HeartImage:
rgb 0, 0, 0
rgb 7, 24, 27
rgb 0, 6, 8
rgb 21, 3, 13
incbin "heart.bin" ; pixel data

Heart2Image:
rgb 0, 0, 0
rgb 11, 1, 0
rgb 16, 8, 0
rgb 30, 25, 19
incbin "heart2.bin" ; pixel data

AxeImage:
rgb 0, 0, 0
rgb 6, 0, 18
rgb 12, 4, 30
rgb 28, 23, 31
incbin "axe.bin" ; pixel data

KirbyImage:
rgb 0, 0, 0
rgb 31, 23, 28
rgb 21, 3, 13
rgb 6, 0, 18
incbin "kirby.bin" ; pixel data

PowImage:
rgb 0, 0, 0
rgb 7, 24, 27
rgb 27, 27, 16
rgb 6, 7, 31
incbin "pow.bin" ; pixel data

MarioImage:
rgb 0, 0, 0
rgb 20, 5, 4
rgb 31, 31, 31
rgb 31, 24, 23
incbin "mario.bin" ; pixel data

ScrewAttackImage:
rgb 0, 0, 0
rgb 16, 8, 0
rgb 5, 15, 0
rgb 27, 18, 4
incbin "screwattack.bin" ; pixel data

ImageTable:
dw StartImage
dw FishImage
dw HeartImage
dw DragonImage
dw StarImage
dw AxeImage
dw KirbyImage
dw MoneyImage
dw Heart2Image
dw LampImage
dw QuestionImage
dw PowImage
dw ScrewAttackImage
dw OneUpImage
dw EggImage
dw TurtleImage
dw JumpmanImage
dw HandImage
dw BootsImage
dw KnightImage
dw OhImage
dw ElfImage
dw MarioImage

SECTION "Transition data", ROM0

Transitions:
dw Bayer4Transition
dw GrayColumnsTransition
dw XorTransition
dw CheckerboardTransition
dw SpiralOutwardTransition
dw DiagonalZigZagTransition
dw MortonZTransition
dw CircleInwardTransition
dw RadialCenterTransition
dw DiamondInwardTransition
dw ColEdgeAlternatingTransition
dw CircleOutwardTransition
dw RandomTransition
dw SpiralInwardTransition
dw MysteryTransition
dw DiamondOutwardTransition
dw ColSnakeTransition

GrayColumnsTransition:
db $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0,$C0,$D0,$E0,$F0
db $01,$11,$21,$31,$41,$51,$61,$71,$81,$91,$A1,$B1,$C1,$D1,$E1,$F1
db $03,$13,$23,$33,$43,$53,$63,$73,$83,$93,$A3,$B3,$C3,$D3,$E3,$F3
db $02,$12,$22,$32,$42,$52,$62,$72,$82,$92,$A2,$B2,$C2,$D2,$E2,$F2
db $06,$16,$26,$36,$46,$56,$66,$76,$86,$96,$A6,$B6,$C6,$D6,$E6,$F6
db $07,$17,$27,$37,$47,$57,$67,$77,$87,$97,$A7,$B7,$C7,$D7,$E7,$F7
db $05,$15,$25,$35,$45,$55,$65,$75,$85,$95,$A5,$B5,$C5,$D5,$E5,$F5
db $04,$14,$24,$34,$44,$54,$64,$74,$84,$94,$A4,$B4,$C4,$D4,$E4,$F4
db $0C,$1C,$2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$DC,$EC,$FC
db $0D,$1D,$2D,$3D,$4D,$5D,$6D,$7D,$8D,$9D,$AD,$BD,$CD,$DD,$ED,$FD
db $0F,$1F,$2F,$3F,$4F,$5F,$6F,$7F,$8F,$9F,$AF,$BF,$CF,$DF,$EF,$FF
db $0E,$1E,$2E,$3E,$4E,$5E,$6E,$7E,$8E,$9E,$AE,$BE,$CE,$DE,$EE,$FE
db $0A,$1A,$2A,$3A,$4A,$5A,$6A,$7A,$8A,$9A,$AA,$BA,$CA,$DA,$EA,$FA
db $0B,$1B,$2B,$3B,$4B,$5B,$6B,$7B,$8B,$9B,$AB,$BB,$CB,$DB,$EB,$FB
db $09,$19,$29,$39,$49,$59,$69,$79,$89,$99,$A9,$B9,$C9,$D9,$E9,$F9
db $08,$18,$28,$38,$48,$58,$68,$78,$88,$98,$A8,$B8,$C8,$D8,$E8,$F8

XorTransition:
db $00,$11,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE,$FF
db $01,$10,$23,$32,$45,$54,$67,$76,$89,$98,$AB,$BA,$CD,$DC,$EF,$FE
db $02,$13,$20,$31,$46,$57,$64,$75,$8A,$9B,$A8,$B9,$CE,$DF,$EC,$FD
db $03,$12,$21,$30,$47,$56,$65,$74,$8B,$9A,$A9,$B8,$CF,$DE,$ED,$FC
db $04,$15,$26,$37,$40,$51,$62,$73,$8C,$9D,$AE,$BF,$C8,$D9,$EA,$FB
db $05,$14,$27,$36,$41,$50,$63,$72,$8D,$9C,$AF,$BE,$C9,$D8,$EB,$FA
db $06,$17,$24,$35,$42,$53,$60,$71,$8E,$9F,$AC,$BD,$CA,$DB,$E8,$F9
db $07,$16,$25,$34,$43,$52,$61,$70,$8F,$9E,$AD,$BC,$CB,$DA,$E9,$F8
db $08,$19,$2A,$3B,$4C,$5D,$6E,$7F,$80,$91,$A2,$B3,$C4,$D5,$E6,$F7
db $09,$18,$2B,$3A,$4D,$5C,$6F,$7E,$81,$90,$A3,$B2,$C5,$D4,$E7,$F6
db $0A,$1B,$28,$39,$4E,$5F,$6C,$7D,$82,$93,$A0,$B1,$C6,$D7,$E4,$F5
db $0B,$1A,$29,$38,$4F,$5E,$6D,$7C,$83,$92,$A1,$B0,$C7,$D6,$E5,$F4
db $0C,$1D,$2E,$3F,$48,$59,$6A,$7B,$84,$95,$A6,$B7,$C0,$D1,$E2,$F3
db $0D,$1C,$2F,$3E,$49,$58,$6B,$7A,$85,$94,$A7,$B6,$C1,$D0,$E3,$F2
db $0E,$1F,$2C,$3D,$4A,$5B,$68,$79,$86,$97,$A4,$B5,$C2,$D3,$E0,$F1
db $0F,$1E,$2D,$3C,$4B,$5A,$69,$78,$87,$96,$A5,$B4,$C3,$D2,$E1,$F0

Bayer4Transition:
db $00,$04,$08,$0C,$11,$15,$19,$1D,$22,$26,$2A,$2E,$33,$37,$3B,$3F
db $10,$14,$18,$1C,$01,$05,$09,$0D,$32,$36,$3A,$3E,$23,$27,$2B,$2F
db $20,$24,$28,$2C,$31,$35,$39,$3D,$02,$06,$0A,$0E,$13,$17,$1B,$1F
db $30,$34,$38,$3C,$21,$25,$29,$2D,$12,$16,$1A,$1E,$03,$07,$0B,$0F
db $40,$44,$48,$4C,$51,$55,$59,$5D,$62,$66,$6A,$6E,$73,$77,$7B,$7F
db $50,$54,$58,$5C,$41,$45,$49,$4D,$72,$76,$7A,$7E,$63,$67,$6B,$6F
db $60,$64,$68,$6C,$71,$75,$79,$7D,$42,$46,$4A,$4E,$53,$57,$5B,$5F
db $70,$74,$78,$7C,$61,$65,$69,$6D,$52,$56,$5A,$5E,$43,$47,$4B,$4F
db $80,$84,$88,$8C,$91,$95,$99,$9D,$A2,$A6,$AA,$AE,$B3,$B7,$BB,$BF
db $90,$94,$98,$9C,$81,$85,$89,$8D,$B2,$B6,$BA,$BE,$A3,$A7,$AB,$AF
db $A0,$A4,$A8,$AC,$B1,$B5,$B9,$BD,$82,$86,$8A,$8E,$93,$97,$9B,$9F
db $B0,$B4,$B8,$BC,$A1,$A5,$A9,$AD,$92,$96,$9A,$9E,$83,$87,$8B,$8F
db $C0,$C4,$C8,$CC,$D1,$D5,$D9,$DD,$E2,$E6,$EA,$EE,$F3,$F7,$FB,$FF
db $D0,$D4,$D8,$DC,$C1,$C5,$C9,$CD,$F2,$F6,$FA,$FE,$E3,$E7,$EB,$EF
db $E0,$E4,$E8,$EC,$F1,$F5,$F9,$FD,$C2,$C6,$CA,$CE,$D3,$D7,$DB,$DF
db $F0,$F4,$F8,$FC,$E1,$E5,$E9,$ED,$D2,$D6,$DA,$DE,$C3,$C7,$CB,$CF

CheckerboardTransition:
db $00,$02,$04,$06,$08,$0A,$0C,$0E,$11,$13,$15,$17,$19,$1B,$1D,$1F
db $20,$22,$24,$26,$28,$2A,$2C,$2E,$31,$33,$35,$37,$39,$3B,$3D,$3F
db $40,$42,$44,$46,$48,$4A,$4C,$4E,$51,$53,$55,$57,$59,$5B,$5D,$5F
db $60,$62,$64,$66,$68,$6A,$6C,$6E,$71,$73,$75,$77,$79,$7B,$7D,$7F
db $80,$82,$84,$86,$88,$8A,$8C,$8E,$91,$93,$95,$97,$99,$9B,$9D,$9F
db $A0,$A2,$A4,$A6,$A8,$AA,$AC,$AE,$B1,$B3,$B5,$B7,$B9,$BB,$BD,$BF
db $C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE,$D1,$D3,$D5,$D7,$D9,$DB,$DD,$DF
db $E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE,$F1,$F3,$F5,$F7,$F9,$FB,$FD,$FF
db $01,$03,$05,$07,$09,$0B,$0D,$0F,$10,$12,$14,$16,$18,$1A,$1C,$1E
db $21,$23,$25,$27,$29,$2B,$2D,$2F,$30,$32,$34,$36,$38,$3A,$3C,$3E
db $41,$43,$45,$47,$49,$4B,$4D,$4F,$50,$52,$54,$56,$58,$5A,$5C,$5E
db $61,$63,$65,$67,$69,$6B,$6D,$6F,$70,$72,$74,$76,$78,$7A,$7C,$7E
db $81,$83,$85,$87,$89,$8B,$8D,$8F,$90,$92,$94,$96,$98,$9A,$9C,$9E
db $A1,$A3,$A5,$A7,$A9,$AB,$AD,$AF,$B0,$B2,$B4,$B6,$B8,$BA,$BC,$BE
db $C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D0,$D2,$D4,$D6,$D8,$DA,$DC,$DE
db $E1,$E3,$E5,$E7,$E9,$EB,$ED,$EF,$F0,$F2,$F4,$F6,$F8,$FA,$FC,$FE

MortonZTransition:
db $00,$01,$10,$11,$02,$03,$12,$13,$20,$21,$30,$31,$22,$23,$32,$33
db $04,$05,$14,$15,$06,$07,$16,$17,$24,$25,$34,$35,$26,$27,$36,$37
db $40,$41,$50,$51,$42,$43,$52,$53,$60,$61,$70,$71,$62,$63,$72,$73
db $44,$45,$54,$55,$46,$47,$56,$57,$64,$65,$74,$75,$66,$67,$76,$77
db $08,$09,$18,$19,$0A,$0B,$1A,$1B,$28,$29,$38,$39,$2A,$2B,$3A,$3B
db $0C,$0D,$1C,$1D,$0E,$0F,$1E,$1F,$2C,$2D,$3C,$3D,$2E,$2F,$3E,$3F
db $48,$49,$58,$59,$4A,$4B,$5A,$5B,$68,$69,$78,$79,$6A,$6B,$7A,$7B
db $4C,$4D,$5C,$5D,$4E,$4F,$5E,$5F,$6C,$6D,$7C,$7D,$6E,$6F,$7E,$7F
db $80,$81,$90,$91,$82,$83,$92,$93,$A0,$A1,$B0,$B1,$A2,$A3,$B2,$B3
db $84,$85,$94,$95,$86,$87,$96,$97,$A4,$A5,$B4,$B5,$A6,$A7,$B6,$B7
db $C0,$C1,$D0,$D1,$C2,$C3,$D2,$D3,$E0,$E1,$F0,$F1,$E2,$E3,$F2,$F3
db $C4,$C5,$D4,$D5,$C6,$C7,$D6,$D7,$E4,$E5,$F4,$F5,$E6,$E7,$F6,$F7
db $88,$89,$98,$99,$8A,$8B,$9A,$9B,$A8,$A9,$B8,$B9,$AA,$AB,$BA,$BB
db $8C,$8D,$9C,$9D,$8E,$8F,$9E,$9F,$AC,$AD,$BC,$BD,$AE,$AF,$BE,$BF
db $C8,$C9,$D8,$D9,$CA,$CB,$DA,$DB,$E8,$E9,$F8,$F9,$EA,$EB,$FA,$FB
db $CC,$CD,$DC,$DD,$CE,$CF,$DE,$DF,$EC,$ED,$FC,$FD,$EE,$EF,$FE,$FF

RadialCenterTransition:
db $88,$78,$87,$89,$98,$77,$79,$97,$99,$68,$86,$8A,$A8,$67,$69,$76
db $7A,$96,$9A,$A7,$A9,$66,$6A,$A6,$AA,$58,$85,$8B,$B8,$57,$59,$75
db $7B,$95,$9B,$B7,$B9,$56,$5A,$65,$6B,$A5,$AB,$B6,$BA,$48,$84,$8C
db $C8,$47,$49,$74,$7C,$94,$9C,$C7,$C9,$55,$5B,$B5,$BB,$46,$4A,$64
db $6C,$A4,$AC,$C6,$CA,$38,$45,$4B,$54,$5C,$83,$8D,$B4,$BC,$C5,$CB
db $D8,$37,$39,$73,$7D,$93,$9D,$D7,$D9,$36,$3A,$63,$6D,$A3,$AD,$D6
db $DA,$44,$4C,$C4,$CC,$35,$3B,$53,$5D,$B3,$BD,$D5,$DB,$28,$82,$8E
db $E8,$27,$29,$72,$7E,$92,$9E,$E7,$E9,$26,$2A,$62,$6E,$A2,$AE,$E6
db $EA,$34,$3C,$43,$4D,$C3,$CD,$D4,$DC,$25,$2B,$52,$5E,$B2,$BE,$E5
db $EB,$18,$81,$8F,$F8,$17,$19,$33,$3D,$71,$7F,$91,$9F,$D3,$DD,$F7
db $F9,$24,$2C,$42,$4E,$C2,$CE,$E4,$EC,$16,$1A,$61,$6F,$A1,$AF,$F6
db $FA,$15,$1B,$51,$5F,$B1,$BF,$F5,$FB,$23,$2D,$32,$3E,$D2,$DE,$E3
db $ED,$08,$80,$07,$09,$14,$1C,$41,$4F,$70,$90,$C1,$CF,$F4,$FC,$06
db $0A,$60,$A0,$22,$2E,$E2,$EE,$05,$0B,$50,$B0,$13,$1D,$31,$3F,$D1
db $DF,$F3,$FD,$04,$0C,$40,$C0,$12,$1E,$21,$2F,$E1,$EF,$F2,$FE,$03
db $0D,$30,$D0,$11,$1F,$F1,$FF,$02,$0E,$20,$E0,$01,$0F,$10,$F0,$00

SpiralOutwardTransition:
db $77,$78,$88,$87,$86,$76,$66,$67,$68,$69,$79,$89,$99,$98,$97,$96
db $95,$85,$75,$65,$55,$56,$57,$58,$59,$5A,$6A,$7A,$8A,$9A,$AA,$A9
db $A8,$A7,$A6,$A5,$A4,$94,$84,$74,$64,$54,$44,$45,$46,$47,$48,$49
db $4A,$4B,$5B,$6B,$7B,$8B,$9B,$AB,$BB,$BA,$B9,$B8,$B7,$B6,$B5,$B4
db $B3,$A3,$93,$83,$73,$63,$53,$43,$33,$34,$35,$36,$37,$38,$39,$3A
db $3B,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$CB,$CA,$C9,$C8,$C7
db $C6,$C5,$C4,$C3,$C2,$B2,$A2,$92,$82,$72,$62,$52,$42,$32,$22,$23
db $24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$3D,$4D,$5D,$6D,$7D,$8D
db $9D,$AD,$BD,$CD,$DD,$DC,$DB,$DA,$D9,$D8,$D7,$D6,$D5,$D4,$D3,$D2
db $D1,$C1,$B1,$A1,$91,$81,$71,$61,$51,$41,$31,$21,$11,$12,$13,$14
db $15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$2E,$3E,$4E,$5E,$6E,$7E
db $8E,$9E,$AE,$BE,$CE,$DE,$EE,$ED,$EC,$EB,$EA,$E9,$E8,$E7,$E6,$E5
db $E4,$E3,$E2,$E1,$E0,$D0,$C0,$B0,$A0,$90,$80,$70,$60,$50,$40,$30
db $20,$10,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D
db $0E,$0F,$1F,$2F,$3F,$4F,$5F,$6F,$7F,$8F,$9F,$AF,$BF,$CF,$DF,$EF
db $FF,$FE,$FD,$FC,$FB,$FA,$F9,$F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1,$F0

SpiralInwardTransition:
db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
db $1F,$2F,$3F,$4F,$5F,$6F,$7F,$8F,$9F,$AF,$BF,$CF,$DF,$EF,$FF,$FE
db $FD,$FC,$FB,$FA,$F9,$F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1,$F0,$E0,$D0
db $C0,$B0,$A0,$90,$80,$70,$60,$50,$40,$30,$20,$10,$11,$12,$13,$14
db $15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$2E,$3E,$4E,$5E,$6E,$7E
db $8E,$9E,$AE,$BE,$CE,$DE,$EE,$ED,$EC,$EB,$EA,$E9,$E8,$E7,$E6,$E5
db $E4,$E3,$E2,$E1,$D1,$C1,$B1,$A1,$91,$81,$71,$61,$51,$41,$31,$21
db $22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$3D,$4D,$5D,$6D
db $7D,$8D,$9D,$AD,$BD,$CD,$DD,$DC,$DB,$DA,$D9,$D8,$D7,$D6,$D5,$D4
db $D3,$D2,$C2,$B2,$A2,$92,$82,$72,$62,$52,$42,$32,$33,$34,$35,$36
db $37,$38,$39,$3A,$3B,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$CB
db $CA,$C9,$C8,$C7,$C6,$C5,$C4,$C3,$B3,$A3,$93,$83,$73,$63,$53,$43
db $44,$45,$46,$47,$48,$49,$4A,$4B,$5B,$6B,$7B,$8B,$9B,$AB,$BB,$BA
db $B9,$B8,$B7,$B6,$B5,$B4,$A4,$94,$84,$74,$64,$54,$55,$56,$57,$58
db $59,$5A,$6A,$7A,$8A,$9A,$AA,$A9,$A8,$A7,$A6,$A5,$95,$85,$75,$65
db $66,$67,$68,$69,$79,$89,$99,$98,$97,$96,$86,$76,$77,$78,$88,$87

DiagonalZigZagTransition:
db $00,$01,$10,$20,$11,$02,$03,$12,$21,$30,$40,$31,$22,$13,$04,$05
db $14,$23,$32,$41,$50,$60,$51,$42,$33,$24,$15,$06,$07,$16,$25,$34
db $43,$52,$61,$70,$80,$71,$62,$53,$44,$35,$26,$17,$08,$09,$18,$27
db $36,$45,$54,$63,$72,$81,$90,$A0,$91,$82,$73,$64,$55,$46,$37,$28
db $19,$0A,$0B,$1A,$29,$38,$47,$56,$65,$74,$83,$92,$A1,$B0,$C0,$B1
db $A2,$93,$84,$75,$66,$57,$48,$39,$2A,$1B,$0C,$0D,$1C,$2B,$3A,$49
db $58,$67,$76,$85,$94,$A3,$B2,$C1,$D0,$E0,$D1,$C2,$B3,$A4,$95,$86
db $77,$68,$59,$4A,$3B,$2C,$1D,$0E,$0F,$1E,$2D,$3C,$4B,$5A,$69,$78
db $87,$96,$A5,$B4,$C3,$D2,$E1,$F0,$F1,$E2,$D3,$C4,$B5,$A6,$97,$88
db $79,$6A,$5B,$4C,$3D,$2E,$1F,$2F,$3E,$4D,$5C,$6B,$7A,$89,$98,$A7
db $B6,$C5,$D4,$E3,$F2,$F3,$E4,$D5,$C6,$B7,$A8,$99,$8A,$7B,$6C,$5D
db $4E,$3F,$4F,$5E,$6D,$7C,$8B,$9A,$A9,$B8,$C7,$D6,$E5,$F4,$F5,$E6
db $D7,$C8,$B9,$AA,$9B,$8C,$7D,$6E,$5F,$6F,$7E,$8D,$9C,$AB,$BA,$C9
db $D8,$E7,$F6,$F7,$E8,$D9,$CA,$BB,$AC,$9D,$8E,$7F,$8F,$9E,$AD,$BC
db $CB,$DA,$E9,$F8,$F9,$EA,$DB,$CC,$BD,$AE,$9F,$AF,$BE,$CD,$DC,$EB
db $FA,$FB,$EC,$DD,$CE,$BF,$CF,$DE,$ED,$FC,$FD,$EE,$DF,$EF,$FE,$FF

ColSnakeTransition:
db $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0,$C0,$D0,$E0,$F0
db $F1,$E1,$D1,$C1,$B1,$A1,$91,$81,$71,$61,$51,$41,$31,$21,$11,$01
db $02,$12,$22,$32,$42,$52,$62,$72,$82,$92,$A2,$B2,$C2,$D2,$E2,$F2
db $F3,$E3,$D3,$C3,$B3,$A3,$93,$83,$73,$63,$53,$43,$33,$23,$13,$03
db $04,$14,$24,$34,$44,$54,$64,$74,$84,$94,$A4,$B4,$C4,$D4,$E4,$F4
db $F5,$E5,$D5,$C5,$B5,$A5,$95,$85,$75,$65,$55,$45,$35,$25,$15,$05
db $06,$16,$26,$36,$46,$56,$66,$76,$86,$96,$A6,$B6,$C6,$D6,$E6,$F6
db $F7,$E7,$D7,$C7,$B7,$A7,$97,$87,$77,$67,$57,$47,$37,$27,$17,$07
db $08,$18,$28,$38,$48,$58,$68,$78,$88,$98,$A8,$B8,$C8,$D8,$E8,$F8
db $F9,$E9,$D9,$C9,$B9,$A9,$99,$89,$79,$69,$59,$49,$39,$29,$19,$09
db $0A,$1A,$2A,$3A,$4A,$5A,$6A,$7A,$8A,$9A,$AA,$BA,$CA,$DA,$EA,$FA
db $FB,$EB,$DB,$CB,$BB,$AB,$9B,$8B,$7B,$6B,$5B,$4B,$3B,$2B,$1B,$0B
db $0C,$1C,$2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$DC,$EC,$FC
db $FD,$ED,$DD,$CD,$BD,$AD,$9D,$8D,$7D,$6D,$5D,$4D,$3D,$2D,$1D,$0D
db $0E,$1E,$2E,$3E,$4E,$5E,$6E,$7E,$8E,$9E,$AE,$BE,$CE,$DE,$EE,$FE
db $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F,$7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F

ColEdgeAlternatingTransition:
db $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0,$C0,$D0,$E0,$F0
db $0F,$1F,$2F,$3F,$4F,$5F,$6F,$7F,$8F,$9F,$AF,$BF,$CF,$DF,$EF,$FF
db $F1,$E1,$D1,$C1,$B1,$A1,$91,$81,$71,$61,$51,$41,$31,$21,$11,$01
db $FE,$EE,$DE,$CE,$BE,$AE,$9E,$8E,$7E,$6E,$5E,$4E,$3E,$2E,$1E,$0E
db $02,$12,$22,$32,$42,$52,$62,$72,$82,$92,$A2,$B2,$C2,$D2,$E2,$F2
db $0D,$1D,$2D,$3D,$4D,$5D,$6D,$7D,$8D,$9D,$AD,$BD,$CD,$DD,$ED,$FD
db $F3,$E3,$D3,$C3,$B3,$A3,$93,$83,$73,$63,$53,$43,$33,$23,$13,$03
db $FC,$EC,$DC,$CC,$BC,$AC,$9C,$8C,$7C,$6C,$5C,$4C,$3C,$2C,$1C,$0C
db $04,$14,$24,$34,$44,$54,$64,$74,$84,$94,$A4,$B4,$C4,$D4,$E4,$F4
db $0B,$1B,$2B,$3B,$4B,$5B,$6B,$7B,$8B,$9B,$AB,$BB,$CB,$DB,$EB,$FB
db $F5,$E5,$D5,$C5,$B5,$A5,$95,$85,$75,$65,$55,$45,$35,$25,$15,$05
db $FA,$EA,$DA,$CA,$BA,$AA,$9A,$8A,$7A,$6A,$5A,$4A,$3A,$2A,$1A,$0A
db $06,$16,$26,$36,$46,$56,$66,$76,$86,$96,$A6,$B6,$C6,$D6,$E6,$F6
db $09,$19,$29,$39,$49,$59,$69,$79,$89,$99,$A9,$B9,$C9,$D9,$E9,$F9
db $F7,$E7,$D7,$C7,$B7,$A7,$97,$87,$77,$67,$57,$47,$37,$27,$17,$07
db $F8,$E8,$D8,$C8,$B8,$A8,$98,$88,$78,$68,$58,$48,$38,$28,$18,$08

RandomTransition:
db $EA,$09,$67,$3C,$05,$4F,$E8,$E5,$2D,$33,$83,$03,$A8,$1D,$AA,$D8
db $63,$A1,$6F,$CC,$DC,$D1,$4E,$59,$48,$BF,$9D,$77,$E2,$B8,$F4,$86
db $15,$3D,$AF,$0F,$DF,$64,$E6,$1C,$80,$B9,$54,$D0,$A4,$2C,$71,$69
db $1B,$55,$CB,$92,$99,$82,$42,$2A,$FA,$8C,$AE,$85,$73,$04,$34,$49
db $41,$0A,$68,$EE,$1E,$D3,$2E,$79,$02,$BE,$9F,$AC,$70,$9C,$5F,$2F
db $7C,$B1,$4D,$CA,$51,$26,$7B,$0D,$B6,$F2,$40,$21,$E1,$00,$F1,$7A
db $D2,$25,$6A,$A3,$52,$62,$22,$DA,$BB,$D6,$7D,$84,$78,$DB,$FC,$20
db $87,$D7,$F5,$30,$C6,$DE,$4C,$E7,$D5,$C0,$E3,$90,$13,$98,$6E,$0C
db $D9,$7E,$C4,$C9,$F8,$94,$6D,$8A,$3F,$F9,$C8,$24,$C5,$65,$7F,$91
db $95,$36,$10,$A7,$66,$50,$EF,$B5,$0E,$53,$E0,$8E,$45,$B0,$76,$AB
db $FB,$88,$2B,$F6,$9B,$12,$A5,$44,$35,$5A,$5E,$29,$5D,$A2,$74,$D4
db $CD,$19,$EB,$C1,$4A,$3A,$A9,$C7,$11,$B4,$31,$93,$5C,$9E,$A0,$4B
db $8D,$14,$60,$1F,$89,$75,$BA,$0B,$43,$E9,$58,$5B,$18,$61,$ED,$F7
db $56,$C3,$EC,$27,$DD,$57,$F0,$B2,$28,$CE,$C2,$01,$CF,$47,$96,$72
db $38,$6B,$F3,$B3,$A6,$B7,$32,$8F,$FE,$9A,$81,$3B,$37,$17,$07,$08
db $6C,$97,$16,$8B,$E4,$FD,$AD,$1A,$BC,$23,$FF,$3E,$46,$BD,$06,$39

MysteryTransition:
db $20,$70,$1B,$0E,$42,$00,$59,$ED,$C9,$B8,$47,$63,$E7,$5D,$B4,$B1
db $22,$35,$C3,$0C,$F7,$08,$EF,$BD,$9E,$EC,$25,$7B,$D1,$C0,$99,$9D
db $97,$0F,$BB,$3A,$C2,$21,$6F,$DE,$CA,$14,$81,$6A,$7C,$1A,$53,$77
db $BF,$CE,$72,$C6,$CF,$3E,$50,$AB,$2C,$4A,$EA,$10,$12,$0D,$2D,$CD
db $6E,$B7,$31,$88,$15,$AC,$CC,$91,$79,$DC,$52,$2B,$30,$F2,$37,$C1
db $1C,$C7,$9F,$EB,$6C,$4F,$89,$66,$3F,$64,$2E,$FC,$DA,$B0,$46,$96
db $4B,$F1,$92,$D4,$D6,$BE,$5E,$E5,$3D,$9C,$65,$8E,$87,$DD,$B5,$36
db $A5,$A2,$F9,$76,$AD,$8A,$09,$A8,$98,$1E,$FB,$48,$F4,$16,$4D,$D2
db $94,$95,$8C,$56,$82,$03,$68,$D9,$44,$04,$7E,$11,$E3,$26,$A0,$A4
db $43,$78,$AF,$C5,$B2,$80,$0A,$49,$FE,$E2,$1F,$3B,$A7,$D7,$75,$29
db $5A,$4C,$28,$E4,$D8,$55,$E9,$E0,$B6,$C8,$41,$A6,$D5,$07,$5B,$05
db $C4,$18,$7D,$83,$38,$69,$1D,$54,$40,$A3,$13,$84,$5F,$FA,$17,$5C
db $73,$39,$9B,$90,$F6,$F5,$A1,$F3,$34,$BC,$D3,$02,$B9,$E8,$62,$3C
db $DF,$D0,$7F,$85,$2A,$60,$CB,$24,$93,$E6,$AA,$19,$6B,$EE,$8F,$71
db $06,$AE,$9A,$32,$2F,$01,$6D,$4E,$A9,$BA,$7A,$27,$F8,$FF,$8B,$67
db $F0,$58,$61,$FD,$8D,$E1,$23,$DB,$33,$57,$0B,$45,$86,$B3,$51,$74

DiamondOutwardTransition:
db $77,$67,$76,$78,$87,$57,$66,$68,$75,$79,$86,$88,$97,$47,$56,$58
db $65,$69,$74,$7A,$85,$89,$96,$98,$A7,$37,$46,$48,$55,$59,$64,$6A
db $73,$7B,$84,$8A,$95,$99,$A6,$A8,$B7,$27,$36,$38,$45,$49,$54,$5A
db $63,$6B,$72,$7C,$83,$8B,$94,$9A,$A5,$A9,$B6,$B8,$C7,$17,$26,$28
db $35,$39,$44,$4A,$53,$5B,$62,$6C,$71,$7D,$82,$8C,$93,$9B,$A4,$AA
db $B5,$B9,$C6,$C8,$D7,$07,$16,$18,$25,$29,$34,$3A,$43,$4B,$52,$5C
db $61,$6D,$70,$7E,$81,$8D,$92,$9C,$A3,$AB,$B4,$BA,$C5,$C9,$D6,$D8
db $E7,$06,$08,$15,$19,$24,$2A,$33,$3B,$42,$4C,$51,$5D,$60,$6E,$7F
db $80,$8E,$91,$9D,$A2,$AC,$B3,$BB,$C4,$CA,$D5,$D9,$E6,$E8,$F7,$05
db $09,$14,$1A,$23,$2B,$32,$3C,$41,$4D,$50,$5E,$6F,$8F,$90,$9E,$A1
db $AD,$B2,$BC,$C3,$CB,$D4,$DA,$E5,$E9,$F6,$F8,$04,$0A,$13,$1B,$22
db $2C,$31,$3D,$40,$4E,$5F,$9F,$A0,$AE,$B1,$BD,$C2,$CC,$D3,$DB,$E4
db $EA,$F5,$F9,$03,$0B,$12,$1C,$21,$2D,$30,$3E,$4F,$AF,$B0,$BE,$C1
db $CD,$D2,$DC,$E3,$EB,$F4,$FA,$02,$0C,$11,$1D,$20,$2E,$3F,$BF,$C0
db $CE,$D1,$DD,$E2,$EC,$F3,$FB,$01,$0D,$10,$1E,$2F,$CF,$D0,$DE,$E1
db $ED,$F2,$FC,$00,$0E,$1F,$DF,$E0,$EE,$F1,$FD,$0F,$EF,$F0,$FE,$FF

CircleOutwardTransition:
db $77,$67,$76,$78,$87,$66,$68,$86,$88,$57,$75,$79,$97,$56,$58,$65
db $69,$85,$89,$96,$98,$55,$59,$95,$99,$47,$74,$7A,$A7,$46,$48,$64
db $6A,$84,$8A,$A6,$A8,$45,$49,$54,$5A,$94,$9A,$A5,$A9,$37,$73,$7B
db $B7,$36,$38,$63,$6B,$83,$8B,$B6,$B8,$44,$4A,$A4,$AA,$35,$39,$53
db $5B,$93,$9B,$B5,$B9,$27,$34,$3A,$43,$4B,$72,$7C,$A3,$AB,$B4,$BA
db $C7,$26,$28,$62,$6C,$82,$8C,$C6,$C8,$25,$29,$52,$5C,$92,$9C,$C5
db $C9,$33,$3B,$B3,$BB,$24,$2A,$42,$4C,$A2,$AC,$C4,$CA,$17,$71,$7D
db $D7,$16,$18,$61,$6D,$81,$8D,$D6,$D8,$15,$19,$51,$5D,$91,$9D,$D5
db $D9,$23,$2B,$32,$3C,$B2,$BC,$C3,$CB,$14,$1A,$41,$4D,$A1,$AD,$D4
db $DA,$07,$70,$7E,$E7,$06,$08,$22,$2C,$60,$6E,$80,$8E,$C2,$CC,$E6
db $E8,$13,$1B,$31,$3D,$B1,$BD,$D3,$DB,$05,$09,$50,$5E,$90,$9E,$E5
db $E9,$04,$0A,$40,$4E,$A0,$AE,$E4,$EA,$12,$1C,$21,$2D,$C1,$CD,$D2
db $DC,$7F,$F7,$03,$0B,$30,$3E,$6F,$8F,$B0,$BE,$E3,$EB,$F6,$F8,$5F
db $9F,$F5,$F9,$11,$1D,$D1,$DD,$4F,$AF,$F4,$FA,$02,$0C,$20,$2E,$C0
db $CE,$E2,$EC,$3F,$BF,$F3,$FB,$01,$0D,$10,$1E,$D0,$DE,$E1,$ED,$2F
db $CF,$F2,$FC,$00,$0E,$E0,$EE,$1F,$DF,$F1,$FD,$0F,$EF,$F0,$FE,$FF

CircleInwardTransition:
db $00,$0F,$F0,$FF,$01,$0E,$10,$1F,$E0,$EF,$F1,$FE,$02,$0D,$20,$2F
db $D0,$DF,$F2,$FD,$11,$1E,$E1,$EE,$03,$0C,$30,$3F,$C0,$CF,$F3,$FC
db $12,$1D,$21,$2E,$D1,$DE,$E2,$ED,$04,$0B,$40,$4F,$B0,$BF,$F4,$FB
db $05,$0A,$13,$1C,$31,$3E,$50,$5F,$A0,$AF,$C1,$CE,$E3,$EC,$F5,$FA
db $22,$2D,$D2,$DD,$06,$09,$60,$6F,$90,$9F,$F6,$F9,$07,$08,$70,$7F
db $80,$8F,$F7,$F8,$14,$1B,$41,$4E,$B1,$BE,$E4,$EB,$23,$2C,$32,$3D
db $C2,$CD,$D3,$DC,$15,$1A,$51,$5E,$A1,$AE,$E5,$EA,$16,$19,$61,$6E
db $91,$9E,$E6,$E9,$17,$18,$24,$2B,$42,$4D,$71,$7E,$81,$8E,$B2,$BD
db $D4,$DB,$E7,$E8,$33,$3C,$C3,$CC,$25,$2A,$52,$5D,$A2,$AD,$D5,$DA
db $26,$29,$34,$3B,$43,$4C,$62,$6D,$92,$9D,$B3,$BC,$C4,$CB,$D6,$D9
db $27,$28,$72,$7D,$82,$8D,$D7,$D8,$35,$3A,$53,$5C,$A3,$AC,$C5,$CA
db $44,$4B,$B4,$BB,$36,$39,$63,$6C,$93,$9C,$C6,$C9,$37,$38,$73,$7C
db $83,$8C,$C7,$C8,$45,$4A,$54,$5B,$A4,$AB,$B5,$BA,$46,$49,$64,$6B
db $94,$9B,$B6,$B9,$47,$48,$55,$5A,$74,$7B,$84,$8B,$A5,$AA,$B7,$B8
db $56,$59,$65,$6A,$95,$9A,$A6,$A9,$57,$58,$75,$7A,$85,$8A,$A7,$A8
db $66,$69,$96,$99,$67,$68,$76,$79,$86,$89,$97,$98,$77,$78,$87,$88

DiamondInwardTransition:
db $FF,$0F,$EF,$F0,$FE,$00,$0E,$1F,$DF,$E0,$EE,$F1,$FD,$01,$0D,$10
db $1E,$2F,$CF,$D0,$DE,$E1,$ED,$F2,$FC,$02,$0C,$11,$1D,$20,$2E,$3F
db $BF,$C0,$CE,$D1,$DD,$E2,$EC,$F3,$FB,$03,$0B,$12,$1C,$21,$2D,$30
db $3E,$4F,$AF,$B0,$BE,$C1,$CD,$D2,$DC,$E3,$EB,$F4,$FA,$04,$0A,$13
db $1B,$22,$2C,$31,$3D,$40,$4E,$5F,$9F,$A0,$AE,$B1,$BD,$C2,$CC,$D3
db $DB,$E4,$EA,$F5,$F9,$05,$09,$14,$1A,$23,$2B,$32,$3C,$41,$4D,$50
db $5E,$6F,$8F,$90,$9E,$A1,$AD,$B2,$BC,$C3,$CB,$D4,$DA,$E5,$E9,$F6
db $F8,$06,$08,$15,$19,$24,$2A,$33,$3B,$42,$4C,$51,$5D,$60,$6E,$7F
db $80,$8E,$91,$9D,$A2,$AC,$B3,$BB,$C4,$CA,$D5,$D9,$E6,$E8,$F7,$07
db $16,$18,$25,$29,$34,$3A,$43,$4B,$52,$5C,$61,$6D,$70,$7E,$81,$8D
db $92,$9C,$A3,$AB,$B4,$BA,$C5,$C9,$D6,$D8,$E7,$17,$26,$28,$35,$39
db $44,$4A,$53,$5B,$62,$6C,$71,$7D,$82,$8C,$93,$9B,$A4,$AA,$B5,$B9
db $C6,$C8,$D7,$27,$36,$38,$45,$49,$54,$5A,$63,$6B,$72,$7C,$83,$8B
db $94,$9A,$A5,$A9,$B6,$B8,$C7,$37,$46,$48,$55,$59,$64,$6A,$73,$7B
db $84,$8A,$95,$99,$A6,$A8,$B7,$47,$56,$58,$65,$69,$74,$7A,$85,$89
db $96,$98,$A7,$57,$66,$68,$75,$79,$86,$88,$97,$67,$76,$78,$87,$77
