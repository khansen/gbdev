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
hNextMainState: db

hVramBufferOffset: db

hScrollX: db

hScrollY: db

hFrameCounter: db

hRandom: db

hShadowBGP: db
hShadowOBP0: db
hShadowLCDC: db

hTimerHi: db
hTimerLo: db
hTimerCallback: dw
def TIMER_SPEED equ 4

def HIT_CUE_DELAY_WIDTH equ 3
def HIT_CUE_BASE_PAYLOAD_WIDTH equ 4

def HIT_START_Y equ 129
def HIT_EXTENT equ 13
def HIT_GRACE_EXTENT equ 4

hHitCueStream: dw
hHitCueStreamBitCtr: db
hHitCueStreamBits: db
hHitCueTimer: db
hHitCueProcessingPending: db
hHitCueProgressHi: db
hHitCueProgressLo: db
hHitCueProgressIncHi: db
hHitCueProgressIncLo: db
def HIT_CUE_MAX_PROGRESS equ 96

; linked lists
hFreeTargetsList: db
hActiveTargetsHead: db
hActiveTargetsTail: db
hHeldTargetsHead: db
hHeldTargetsTail: db
hHitTargetsHead: db
hHitTargetsTail: db
hMissedTargetsHead: db
hMissedTargetsTail: db
hPrev: db
def ZILCH_ITEM equ $ff

hLaneInput: db
hLaneInputPosedge: db
hCheckedLanes: db
hHittableLanes: db
hHitLanes: db
hErrorLanes: db
hDrawHoldLength: db
hSuppressedLanes: db
hLaneHitZoneHighlightTimers: ds 2
hLaneMissIndicatorTimers: ds 2

hHealth: db
hHealthChanged: db
def HEALTH_MAX equ 100
def TAP_MISS_DAMAGE equ 6
def HOLD_HEAD_MISS_DAMAGE equ 8
def HOLD_BREAK_DAMAGE equ 4
def MISPRESS_DAMAGE equ 2

def SONG_COUNT equ 2
hCurrentSong: db

; stats
hSpawnedChordsCount: dw
hFullyClearedChordsCount: dw
hSpawnedTargetsCount: dw
hTapHitCount: dw
hTapMissCount: dw
hHoldHeadHitCount: dw
hHoldHeadMissCount: dw
hHoldCompleteCount: dw
hHoldBreakCount: dw
hMisPressCount: dw
hCurrentStreak: dw
hMaxStreak: dw
hComputedSongSessionAccuracy: db ; 0..100

hGameBehaviorState0: db
def GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT          equ 0
def GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY           equ 1
def GAME_BEHAVIOR_STATE0__HOLD_MODE__UNIFORM_DURATION equ 2
def GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE              equ %00000011 ; 0 = respect, 1 = tapify, 2 = uniform duration
def GAME_BEHAVIOR_STATE0_MASK__RANDOM_ENABLED         equ %00000100
def GAME_BEHAVIOR_STATE0_MASK__RANDOM_ALLOW_NONE      equ %00001000
def GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC  equ 0 << 4
def GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED         equ 1 << 4
def GAME_BEHAVIOR_STATE0__RANDOM_MODE__FULL           equ 2 << 4
def GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE            equ %00110000 ; 0 = deterministic, 1 = seeded, 2 = full
def GAME_BEHAVIOR_STATE0_MASK__RANDOM_MAX_PICKED      equ %11000000
def GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED          equ 2
def GAME_BEHAVIOR_STATE0_BIT__RANDOM_ALLOW_NONE       equ 3
hGameBehaviorState1: db
def GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE      equ %00000011
def GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE           equ 3
hIntensityMax: db
hDifficultyLevel: db
def DIFFICULTY_LEVELS_COUNT equ 5

; Playtest settings screen
def PLAYTEST_SETTINGS_COUNT equ 5 ; TODO: 6 (enable max cue notes)
def PLAYTEST_SETTING__INTENSITY_MAX equ 0
def PLAYTEST_SETTING__HOLD_NOTES equ 1
def PLAYTEST_SETTING__HOLD_NOTES_STYLE equ 2
def PLAYTEST_SETTING__RANDOM_NOTES equ 3
def PLAYTEST_SETTING__RANDOM_NOTES_STYLE equ 4
def PLAYTEST_SETTING__MAX_CUE_NOTES equ 5

rsreset
def Target_Next rb 1                    ; 00
def Target_State rb 1                   ; 01
def Target_PosY_Frac rb 1               ; 02
rsset Target_PosY_Frac
def Target_HoldTimer rb 1               ; 02
def Target_PosY_Int  rb 1               ; 03
; TODO: Target_ChordInstance
def Target_SIZEOF    rb 0               ; 04

def MAX_TARGETS equ 58

; --- Begin Sound engine

hInstrumentTable: dw

hPatternTable: dw

hOrder: dw

hPatternRowCallback: dw

hMasterVol: db

hShadowNR12: db
hShadowNR22: db
hShadowNR32: db
hShadowNR42: db

; bits 3..0: whether channel is muted (1=yes)
; bit 4: paused (1=yes)
hSoundStatus: db

; number of rows to wait before starting playback
hSoundPrerollRowsRemaining: db

; --- End Sound engine

; Scratch area for various procedures

UNION ; Division
    hNum24:  ds 3    ; 24-bit numerator (little-endian: lo,mid,hi)
    hRem16:  ds 2    ; 16-bit remainder (little-endian: lo,hi)
NEXTU ; Multiplication
    hMulA:  ds 1
    hMulHi: ds 1
    hMulCnt: ds 1
NEXTU ; Printing
    hPrintedAny: ds 1    ; 0/1
    hDigit:      ds 1    ; current digit 0..9
    hU16:        ds 2    ; current 16-bit remainder (little-endian: lo,hi)
NEXTU ; Playtest settings
    hCurrentPlaytestSetting: db
NEXTU ; Pause screen
    hCurrentPauseMenuItem: db
ENDU

; --- End HRAM

SECTION "WRAM", WRAM0[$c000]

wOam:
    ds OAM_COUNT*4

wVramBuffer:
    ds 96

wTargetsArena:
    ds Target_SIZEOF * MAX_TARGETS

def MAX_HOLD_TIMERS equ 16
wHoldTimerTable: ds MAX_HOLD_TIMERS

wTargetDurationByLane: ds 4
wLaneIntensities: ds 4

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

def NUM_MUSIC_TRACKS equ 4
def NUM_SFX_TRACKS equ 4
def NUM_TRACKS equ NUM_MUSIC_TRACKS + NUM_SFX_TRACKS

assert (@ & $ff) == 0
wTracks:
  ds Track_SIZEOF * NUM_TRACKS

; --- End Sound engine

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
	db   "SNOWBRO 026", $00, $00, $00, $00

HeaderCGBFlag:
    db   $00

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

        ldh a, [hFrameCounter]
        inc a
        ldh [hFrameCounter], a
    
        call FlushVramBuffer
	    call hOamDmaFunction
        ldh a, [hScrollX]
        ldh [rSCX], a
        ldh a, [hScrollY]
        ldh [rSCY], a
        ldh a, [hShadowBGP]
        ldh [rBGP], a
        ldh a, [hShadowOBP0]
        ldh [rOBP0], a
        ldh a, [hShadowLCDC]
        ldh [rLCDC], a

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
	ld   b, a
	ldh  a, [hButtonsHeld]
	xor  b
	and  b
	ldh  [hButtonsPressed], a
	ld   a, b
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

ClearTilemap:
    ld e, 0
    ld hl, $9800
    ld bc, $240
    jp SetMemory

FlushVramBuffer:
    ldh a, [hVramBufferOffset]
    or a, a
    ret z
    xor a
    ldh [hVramBufferOffset], a
    ld hl, wVramBuffer
    jp WriteVramStrings

; HL = Address of data (zero-terminated)
WriteVramStrings:
    ld a, [hli]
    or a, a
    ret z
    ld d, a ; high VRAM address
    ld a, [hli]
    ld e, a ; low VRAM address
    ld a, [hli]
    bit 6, a ; is data RLE?
    jr nz, .isRle
    ld b, a ; count
    .nonRleLoop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .nonRleLoop
    jr WriteVramStrings
    .isRle:
    res 6, a ; count in lower 5 bits
    ld b, a
    ld a, [hli] ; data
    .rleLoop:
    ld [de], a
    inc de
    dec b
    jr nz, .rleLoop
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

; DE = Address of string
CopyStringToVramBuffer:
    ld hl, wVramBuffer
    ldh a, [hVramBufferOffset]
    ld c, a
    ld b, 0
    add hl, bc
    ld a, [de] ; high address
    inc de
    ld [hli], a
    ld a, [de] ; high address
    inc de
    ld [hli], a
    ld a, [de] ; count
    inc de
    ld [hli], a
    bit 6, a ; is RLE?
    jr nz, .isRle
    ld b, a
    .loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    jp EndVramString
    .isRle:
    ld a, [de] ; data
    ld [hli], a
    jp EndVramString

; DE = Address of data
; A = number of bytes
CopyBytesToVramBuffer:
    push af
    ld hl, wVramBuffer
    ldh a, [hVramBufferOffset]
    ld c, a
    ld b, 0
    add hl, bc
    pop af
    ld b, a
    .loop:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .loop
    jp EndVramString

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
; destroys bc
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

; --- Begin sound engine ---

; HL = pointer to song
StartSong:
    ld b, NUM_MUSIC_TRACKS
    ld de, wTracks + Track_Order_Pos
    .music_track_loop:
    ld a, [hli] ; order pos
    ld [de], a ; Track_Order_Pos
    cp a, $ff ; channel not in use?
    jr z, .skip
    ld a, [hli] ; speed
if !def(NO_SONG_SPEED_ADJUSTMENT)
    dec a
endc
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
    xor a, a
    ld [de], a ; Track_MasterVol
    inc de
    ld [de], a ; Track_PeriodIndex
    inc de
    ld a, $ff
    ld [de], a ; Track_PeriodLo
    inc de
    ld a, $7f
    ld [de], a ; Track_PeriodHi
    inc de ; Track_Square_DutyCtrl
    inc de ; Track_Envelope_Phase
    xor a, a
    ld [de], a ; Track_Envelope_Phase
    ld a, e
    add a, Track_SIZEOF - Track_Envelope_Phase + Track_Order_Pos
    ld e, a
    dec b
    jr nz, .music_track_loop
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

    ; clear SFX tracks (set speed to $ff)
    ld b, NUM_SFX_TRACKS
    ld a, e
    sub a, Track_Order_Pos
    .sfx_track_loop:
    ld e, a
    ld a, $ff
    ld [de], a ; Track_Speed
    ld a, e
    add a, Track_SIZEOF
    dec b
    jr nz, .sfx_track_loop

    ld a, $f0
    ldh [hMasterVol], a
    xor a
    ldh [hSoundStatus], a ; unmute all channels
    ldh [hSoundPrerollRowsRemaining], a ; default is to start right away
    ret

PauseMusic:
    ldh a, [hSoundStatus]
    set 4, a ; set paused bit
    ldh [hSoundStatus], a
    ret

UnpauseMusic:
    ldh a, [hSoundStatus]
    res 4, a ; clear paused bit
    ldh [hSoundStatus], a
    ret

; A = SFX (pattern) number
; Destroys: HL, A
PlayTrack0SFX:
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 0)*Track_SIZEOF + Track_Order_Pos
    ld [hl], a ; Track_Order_Pos
    ld l, (NUM_MUSIC_TRACKS + 0)*Track_SIZEOF + Track_Speed
__PlaySFX: ; HL = Track_Speed
    ld a, 7 ; default SFX speed (pattern data can use set speed effect to override)
    ld [hli], a ; Track_Speed
    dec a
    ld [hli], a ; Track_Tick
    xor a
    ld [hli], a ; Track_Pattern_RowCount
    dec a ; $ff
    ld [hl], a ; Track_Pattern_Row
    ret

; A = SFX (pattern) number
; Destroys: HL, A
PlayTrack1SFX:
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 1)*Track_SIZEOF + Track_Order_Pos
    ld [hl], a ; Track_Order_Pos
    ld l, (NUM_MUSIC_TRACKS + 1)*Track_SIZEOF + Track_Speed
    jr __PlaySFX

; A = SFX (pattern) number
; Destroys: HL, A
PlayTrack2SFX:
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 2)*Track_SIZEOF + Track_Order_Pos
    ld [hl], a ; Track_Order_Pos
    ld l, (NUM_MUSIC_TRACKS + 2)*Track_SIZEOF + Track_Speed
    jr __PlaySFX

; A = SFX (pattern) number
; Destroys: HL, A
PlayTrack3SFX:
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 3)*Track_SIZEOF + Track_Order_Pos
    ld [hl], a ; Track_Order_Pos
    ld l, (NUM_MUSIC_TRACKS + 3)*Track_SIZEOF + Track_Speed
    jr __PlaySFX

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
    ldh a, [hSoundStatus]
    bit 4, a ; music paused?
    jr z, .loop
    ; only process SFX tracks
    ld b, NUM_MUSIC_TRACKS
    ld hl, wTracks + NUM_MUSIC_TRACKS * Track_SIZEOF
    .loop:
    ld a, [hli] ; Track_Speed
    cp a, $ff   ; is track used?
    jr nz, .process_track
    .go_next_track:
    ld de, Track_SIZEOF - 1
    add hl, de
    jp .next_track
    .process_track:
    inc [hl]    ; Track_Tick
    cp a, [hl]  ; speed == tick?
    jr z, .next_row
    inc l ; Track_Pattern_RowCount
    .continue_after_preroll_processing:
    inc l ; Track_Pattern_Row
    inc l ; Track_Pattern_RowStatus
    jp .mixer_tick
    .next_row:
    push hl
    call PatternRowCallbackTrampoline
    pop hl
    xor a, a
    ld [hli], a ; Track_Tick
    ldh a, [hSoundPrerollRowsRemaining]
    or a, a ; is there a preroll to process?
    jr z, .no_preroll ; skip if not
    bit 2, b
    jr nz, .no_preroll ; no preroll for SFX tracks
    bit 0, b
    jr nz, .continue_after_preroll_processing ; preroll is only decremented on channel 0
    bit 1, b
    jr nz, .continue_after_preroll_processing ; preroll is only decremented on channel 0
    dec a
    ldh [hSoundPrerollRowsRemaining], a
    jr nz, .continue_after_preroll_processing ; preroll not done
    ; preroll finished - carry on!
    .no_preroll:
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
    bit 2, b ; SFX track (4-7)?
    jr nz, .is_sfx_order_pos
    ; music track 0-3
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
    .10:
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
    .is_sfx_order_pos:
    bit 7, a ; end of SFX?
    jr nz, .is_sfx_end
    add a, a ; pattern number * 2
    ld c, a
    ld a, HIGH(SFXPatternTable)
    adc a, 0
    ld d, a
    ld a, $ff ; on the next end of pattern, we will satisfy the "end of SFX" condition above
    ld [hl], a ; Track_Order_Pos
    ld a, LOW(SFXPatternTable)
    jr .10
    .is_sfx_end:
    ; set track speed to $ff to mark as unused
    pop hl ; Track_Pattern_Row
    dec l ; Track_Pattern_RowCount
    dec l ; Track_Tick
    dec l ; Track_Speed
    ld a, $ff
    ld [hli], a ; Track_Speed
    push hl ; Track_Tick
    ld de, -(NUM_MUSIC_TRACKS * Track_SIZEOF) + Track_PeriodIndex - Track_Tick
    add hl, de
    set 7, [hl] ; set trigger flag
    pop hl ; Track_Tick
    jp .go_next_track
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
    ld [hli], a ; Track_Effect_Param
    ; clear effect state
    ld [hl], 0 ; Track_Effect_Pos
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
    ld [hl], c ; Track_Effect_Portamento_Ctrl
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
    ld hl, wTracks + NUM_MUSIC_TRACKS*Track_SIZEOF + Track_Speed
    ld a, [hl] ; Track_Speed
    cp a, $ff  ; is SFX track used?
    ld l, Track_Square_DutyCtrl
    jr z, .10
    ld l, Track_Square_DutyCtrl + NUM_MUSIC_TRACKS*Track_SIZEOF ; render SFX
    .10:
    ; NR11
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
    ld a, l ; Track_Square_DutyCtrl
    add a, Track_Envelope_Vol - Track_Square_DutyCtrl
    ld l, a
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    push af
    ld a, l ; Track_Envelope_Vol
    add a, Track_MasterVol - Track_Envelope_Vol
    ld l, a ; Track_MasterVol
    pop af
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    push hl ; Track_MasterVol
    ld hl, VolumeTable
    add hl, de
    ld b, [hl] ; envelope volume scaled according to track volume (0..F)
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld c, [hl] ; computed track volume scaled according to master volume (0..F)
    pop hl ; Track_MasterVol
    ld a, l ; Track_MasterVol
    add a, Track_PeriodIndex - Track_MasterVol
    ld l, a ; Track_PeriodIndex
    ld a, c ; computed volume
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
    ld a, l ; Track_PeriodIndex
    cp a, NUM_MUSIC_TRACKS*Track_SIZEOF
    jr nc, .not_muted ; SFX tracks cannot be muted
    ldh a, [hSoundStatus]
    bit 4, a ; music paused?
    jr nz, .is_muted
    bit 0, a
    jr z, .not_muted
    .is_muted:
    ld a, $ff
    ldh [rNR13], a
    ld a, $7f
    jr .write_nr14
    .not_muted:
    ; NR13
    inc l ; Track_PeriodLo
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR13], a
    ; NR14
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    .write_nr14:
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR14], a

    .update_square_duty:
    inc l ; Track_PeriodLo
    inc l ; Track_PeriodHi
    inc l ; Track_Square_DutyCtrl
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
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 2)*Track_SIZEOF + Track_Speed
    ld a, [hl] ; Track_Speed
    cp a, $ff  ; is SFX track used?
    ld l, Track_Envelope_Vol + Track_SIZEOF*2
    jr z, .10
    ld l, Track_Envelope_Vol + (NUM_MUSIC_TRACKS + 2)*Track_SIZEOF ; render SFX
    .10:
    ; NR32
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    push af
    ld a, l ; Track_Envelope_Vol
    add a, Track_MasterVol - Track_Envelope_Vol
    ld l, a ; Track_MasterVol
    pop af
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    push hl ; Track_MasterVol
    ld hl, VolumeTable
    add hl, de
    ld b, [hl] ; envelope volume scaled according to track volume (0..F)
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld a, [hl] ; computed track volume scaled according to master volume (0..F)
    pop hl ; Track_MasterVol
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
    ld a, l ; Track_MasterVol
    cp a, NUM_MUSIC_TRACKS*Track_SIZEOF
    jr nc, .not_muted ; SFX tracks cannot be muted
    ldh a, [hSoundStatus]
    bit 4, a ; music paused?
    jr nz, .is_muted
    bit 2, a
    jr z, .not_muted
    .is_muted:
    ld a, $ff
    ldh [rNR33], a
    ld a, $7f
    jr .write_nr34
    .not_muted:
    ; NR33
    inc l ; Track_PeriodIndex
    inc l ; Track_PeriodLo
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR33], a
    ; NR34
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    .write_nr34:
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR34], a
    ret

RenderChannel2:
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 1)*Track_SIZEOF + Track_Speed
    ld a, [hl] ; Track_Speed
    cp a, $ff  ; is SFX track used?
    ld l, Track_Square_DutyCtrl + Track_SIZEOF
    jr z, .10
    ld l, Track_Square_DutyCtrl + (NUM_MUSIC_TRACKS + 1)*Track_SIZEOF ; render SFX
    .10:
    ; NR21
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
    ld a, l ; Track_Square_DutyCtrl
    add a, Track_Envelope_Vol - Track_Square_DutyCtrl
    ld l, a
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    push af
    ld a, l ; Track_Envelope_Vol
    add a, Track_MasterVol - Track_Envelope_Vol
    ld l, a ; Track_MasterVol
    pop af
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    push hl ; Track_MasterVol
    ld hl, VolumeTable
    add hl, de
    ld b, [hl] ; envelope volume scaled according to track volume (0..F)
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld c, [hl] ; computed track volume scaled according to master volume (0..F)
    pop hl ; Track_MasterVol
    ld a, l ; Track_MasterVol
    add a, Track_PeriodIndex - Track_MasterVol
    ld l, a ; Track_PeriodIndex
    ld a, c ; computed volume
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
    ld a, l ; Track_PeriodIndex
    cp a, NUM_MUSIC_TRACKS*Track_SIZEOF
    jr nc, .not_muted ; SFX tracks cannot be muted
    ldh a, [hSoundStatus]
    bit 4, a ; music paused?
    jr nz, .is_muted
    bit 1, a
    jr z, .not_muted
    .is_muted:
    ld a, $ff
    ldh [rNR23], a
    ld a, $7f
    jr .write_nr24
    .not_muted:
    ; NR23
    inc l ; Track_PeriodLo
    ld a, [hli] ; Track_PeriodLo
    ldh [rNR23], a
    ; NR24
    ld a, [hl-] ; Track_PeriodHi
    dec l ; Track_PeriodIndex
    .write_nr24:
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .no_trigger
    or a, $80
    res 7, [hl] ; Track_PeriodIndex - reset trigger flag
    .no_trigger:
    ldh [rNR24], a

    .update_square_duty:
    inc l ; Track_PeriodLo
    inc l ; Track_PeriodHi
    inc l ; Track_Square_DutyCtrl
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
    ld hl, wTracks + (NUM_MUSIC_TRACKS + 3)*Track_SIZEOF + Track_Speed
    ld a, [hl] ; Track_Speed
    cp a, $ff  ; is SFX track used?
    ld l, Track_Envelope_Vol + Track_SIZEOF*3
    jr z, .10
    ld l, Track_Envelope_Vol + (NUM_MUSIC_TRACKS + 3)*Track_SIZEOF ; render SFX
    .10:
    ; NR42
    ld a, [hl] ; Track_Envelope_Vol
    swap a
    and a, $f
    push af
    ld a, l ; Track_Envelope_Vol
    add a, Track_MasterVol - Track_Envelope_Vol
    ld l, a ; Track_MasterVol
    pop af
    or a, [hl] ; Track_MasterVol
    ld e, a
    ld d, 0
    push hl ; Track_MasterVol
    ld hl, VolumeTable
    add hl, de
    ld b, [hl] ; envelope volume scaled according to track volume (0..F)
    ldh a, [hMasterVol]
    or a, b
    ld e, a
    ld hl, VolumeTable
    add hl, de
    ld c, [hl] ; computed track volume scaled according to master volume (0..F)
    pop hl ; Track_MasterVol
    ld a, l ; Track_MasterVol
    add a, Track_PeriodIndex - Track_MasterVol
    ld l, a ; Track_PeriodIndex
    ld a, c ; computed volume
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
    ld a, l ; Track_PeriodIndex
    cp a, NUM_MUSIC_TRACKS*Track_SIZEOF
    jr nc, .not_muted ; SFX tracks cannot be muted
    ldh a, [hSoundStatus]
    bit 4, a ; music paused?
    jr nz, .is_muted
    bit 3, a
    jr z, .not_muted
    .is_muted:
    ld a, $ff
    ldh [rNR43], a
    ld a, $7f
    jr .write_nr44
    .not_muted:
    ; NR43
    inc l ; Track_PeriodLo
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
    .write_nr44:
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
    ld [hl], 1 ; Track_Envelope_Hold
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
    bit 2, b ; SFX track (4-7)?
    jr nz, .is_sfx_track
    ; music track (0-3) - use the song's instrument table
    ldh a, [hInstrumentTable]
    add a, c
    ld e, a
    ldh a, [hInstrumentTable+1]
    .10:
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
    .is_sfx_track:
    ld a, LOW(SFXInstrumentTable)
    add a, c
    ld e, a
    ld a, HIGH(SFXInstrumentTable)
    jr .10

; A = new speed
; preserves DE and HL
SetSpeed:
    push de
    push hl
    bit 2, b ; SFX track (4-7)?
    jr nz, .is_sfx_track
    ; music track (0-3) - propagate speed to all tracks
    ld hl, wTracks + Track_Speed
    ld de, Track_SIZEOF
    ld [hl], a ; Track_Speed
    add hl, de
    ld [hl], a ; Track_Speed
    add hl, de
    ld [hl], a ; Track_Speed
    add hl, de
    .set_one_track_speed:
    ld [hl], a ; Track_Speed
    pop hl ; Track_Pattern_Ptr (lo)
    pop de ; pattern data ptr
    ret
    .is_sfx_track:
    ld hl, wTracks + Track_Speed + NUM_MUSIC_TRACKS*Track_SIZEOF
    ld de, Track_SIZEOF
    bit 0, b
    jr z, .skip_add
    add hl, de
    .skip_add:
    bit 1, b
    jr z, .skip_add_2
    add hl, de
    add hl, de
    .skip_add_2:
    jr .set_one_track_speed

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
    ld c, [hl] ; Track_Effect_Param
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
    ld c, [hl] ; Track_Effect_Param
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
    ld [hl], d ; Track_PeriodHi
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
    ld [hl], 0 ; Track_MasterVol
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
    ld [hl], 0 ; Track_Envelope_Pos = 0
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
    ld [hl], 0 ; Track_Envelope_Phase
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

; HL = callback address
; The callback will receive the channel number in register B.
; The callback must preserve registers BC, DE.
SetPatternRowCallback:
    ld a, l
    ldh [hPatternRowCallback], a
    ld a, h
    ldh [hPatternRowCallback+1], a
    ret

PatternRowCallbackTrampoline:
    ldh a, [hPatternRowCallback]
    ld l, a
    ldh a, [hPatternRowCallback+1]
    ld h, a
    or a, l
    ret z ; exit if no callback is set
    jp hl

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
db $11, $11, $11, $11
db $88, $88, $88, $88
db $cc, $cc, $ff, $ff
db $ff, $ff, $ff, $ff

; --- End sound engine ---

; --- Program-specific code: Our game starts here! ---

Genesis:
    ld hl, DefaultWavRam
    call CopyFromHLIntoWav3Ram

    ld a, $80
    ldh [rAUD3ENA], a ; DAC on

    ; TODO: call MainFunc_TitleScreenInit
    call MainFunc_SongSelectionInit
    ; call MainFunc_PlaytestSettingsInit
    ; call MainFunc_SongSessionResultsInit

; enable interrupts now
	ld   a, IEF_VBLANK
	ldh  [rIE], a

.InfiniteLoop:
    halt
    jp .InfiniteLoop


SetupCurrentSong:
    ldh a, [hCurrentSong]
    sla a
    sla a ; * 4 (each SongDescriptor is 4 bytes)
    add a, LOW(SongDescriptors)
    ld l, a
    ld a, HIGH(SongDescriptors)
    adc a, 0
    ld h, a
    ld a, [hli] ; hit cue stream lo
    ldh [hHitCueStream], a
    ld a, [hli] ; hit cue stream hi
    ldh [hHitCueStream+1], a
    ld a, [hli] ; song lo
    push af
    ld a, [hl]  ; song hi
    ld h, a
    pop af
    ld l, a
    call StartSong
    ld a, [wTracks + Track_Speed]
    cp 5
    jr z, .speed_5
    cp 3
    jr z, .speed_3
    cp 4
    jr z, .speed_4
    cp 6
    jr z, .speed_6
    jp Reset ; TODO: adjust according to song speed
    .speed_3:
    ld a, 46
    jr .set_preroll_rows
    .speed_4:
    ld a, 35
    jr .set_preroll_rows
    .speed_6:
    ld a, 24
    jr .set_preroll_rows
    .speed_5:
    ld a, 28
    .set_preroll_rows:
    ldh [hSoundPrerollRowsRemaining], a
    ret

GameGfxInit:
    ; palettes: from dimmed to bright
    ld  a, %00011011
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ld de, GameTiles
    ld hl, $8000
    ld bc, GameTilesEnd - GameTiles
    call CopyData

    call ClearTilemap

    ld hl, GameScreenTilemap
    jp WriteVramStrings

GameInit:
    ld a, HEALTH_MAX ; TODO: health should persist across sessions
    ldh [hHealth], a
    xor a
    ldh [hHealthChanged], a

    call GameGfxInit
    call DrawEmptyProgressBar
    call DrawEntireHealthBar
    call FlushVramBuffer

    call SetupCurrentSong

    call InitializeRandom

    call ResetGameStats

    call InitializeTargetLists
    call InitializeHoldTimerTable
    call InitializeHitCues

    ld hl, OnPatternRowChange
    jp SetPatternRowCallback

InitializeRandom:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    jr z, .deterministic
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    jr z, .seeded
    ; full
    ; Goal: Make outcomes depend on real-time jitter and player timing so runs are not meaningfully reproducible.
    ; seed = same as for "seeded", but then with subsequent stirring per random decision
    ; fallthrough
    .seeded:
    ; Goal: A given playthrough is internally consistent, but different playthroughs likely differ.
    ; seed = hash(song_id, difficulty_id, ruleset_id) XOR (DIV << 8) XOR LY XOR frame_counter
    call .deterministic
    ldh a, [hRandom]
    ld b, a
    ldh a, [hFrameCounter]
    xor a, b
    ld b, a
    ldh a, [rDIV]
    xor a, b
    ldh [hRandom], a
    ret
    .deterministic:
    ; Goal: Same song + same difficulty + same chart data ⇒ identical outcomes, every run.
    ; seed = hash(song_id, difficulty_id, ruleset_id, optional_user_seed)
    ldh a, [hCurrentSong]
    add a, 1
    ld b, a
    ldh a, [hGameBehaviorState0]
    xor a, b
    ld b, a
    ldh a, [hGameBehaviorState1]
    xor a, b
    ld b, a
    ldh a, [hIntensityMax]
    xor a, b
    ld b, a
    ldh a, [hIntensityMax]
    swap a
    xor a, b
    ldh [hRandom], a

    ld c, 16
    .warm:
    call Prng
    dec c
    jr nz, .warm
    ret


; ------ Progress Bar ------

def PROGRESS_BAR_TILES_BASE equ $90

DrawEmptyProgressBar:
    ld de, $9801
    ld c, $4C
    call BeginVramString
    ld a, PROGRESS_BAR_TILES_BASE
    ld [hli], a
    jp EndVramString

DrawEntireProgressBar:
    ld de, $9801
    ld c, HIT_CUE_MAX_PROGRESS / 8
    call BeginVramString
    ldh a, [hHitCueProgressHi]
    srl a
    srl a
    srl a
    push af ; save hHitCueProgressHi / 8
    jr z, .skip_full_blocks
    ; part 1: full blocks
    ld c, a
    ld a, PROGRESS_BAR_TILES_BASE + 8
    .full_block_loop:
    ld [hli], a
    dec c
    jr nz, .full_block_loop
    .skip_full_blocks:
    ; part 2: partial block
    ldh a, [hHitCueProgressHi]
    and $07
    jr z, .skip_partial_block
    add a, PROGRESS_BAR_TILES_BASE
    ld [hli], a
    .skip_partial_block:
    ; part 3: empty blocks
    pop af ; hHitCueProgressHi / 8
    ld c, a
    ld a, HIT_CUE_MAX_PROGRESS / 8
    sub a, c
    jr z, .skip_empty_blocks
    ld c, a
    ldh a, [hHitCueProgressHi]
    and $07
    ld a, PROGRESS_BAR_TILES_BASE
    jr z, .empty_block_loop
    dec c
    jr z, .skip_empty_blocks
    .empty_block_loop:
    ld [hli], a
    dec c
    jr nz, .empty_block_loop
    .skip_empty_blocks:
    jp EndVramString


; ------ Health Bar ------

def HEALTH_BAR_TILES_BASE equ $a2

; Health (0-100) to bar pixels (0-38)
; Formula: floor(health * 38 / 100)
HealthToPixelsTable:
db 0, 0, 0, 1, 1, 1, 2, 2, 3, 3
db 3, 4, 4, 4, 5, 5, 6, 6, 6, 7
db 7, 7, 8, 8, 9, 9, 9, 10, 10, 11
db 11, 11, 12, 12, 12, 13, 13, 14, 14, 14
db 15, 15, 15, 16, 16, 17, 17, 17, 18, 18
db 19, 19, 19, 20, 20, 20, 21, 21, 22, 22
db 22, 23, 23, 23, 24, 24, 25, 25, 25, 26
db 26, 26, 27, 27, 28, 28, 28, 29, 29, 30
db 30, 30, 31, 31, 31, 32, 32, 33, 33, 33
db 34, 34, 34, 35, 35, 36, 36, 36, 37, 38
db 38

DrawEntireHealthBar:
    ; map health to filled pixels
    ld hl, HealthToPixelsTable
    ldh a, [hHealth]
    ld c, a
    ld b, 0
    add hl, bc
    ld a, [hl] ; a = number of filled pixels (0-38)
    ld b, a

    ld de, $99ee
    ld c, 5
    call BeginVramString
    ; sector 0
    ld a, b
    cp 7
    jr c, .sector_0_partial
    ; full
    ld a, HEALTH_BAR_TILES_BASE + 7
    jr .sector_0_done
    .sector_0_partial:
    add a, HEALTH_BAR_TILES_BASE
    .sector_0_done:
    ld [hli], a
    ; sector 1
    ld a, b
    cp 8
    jr c, .sector_1_empty
    cp 15
    jr c, .sector_1_partial
    ; full
    ld a, HEALTH_BAR_TILES_BASE + 16
    jr .sector_1_done
    .sector_1_empty:
    ld a, HEALTH_BAR_TILES_BASE + 8
    jr .sector_1_done
    .sector_1_partial:
    inc a
    and a, 7
    add a, HEALTH_BAR_TILES_BASE + 8
    .sector_1_done:
    ld [hli], a
    ; sector 2
    ld a, b
    cp 15
    jr c, .sector_2_empty
    cp 23
    jr c, .sector_2_partial
    ; full
    ld a, HEALTH_BAR_TILES_BASE + 16
    jr .sector_2_done
    .sector_2_empty:
    ld a, HEALTH_BAR_TILES_BASE + 8
    jr .sector_2_done
    .sector_2_partial:
    inc a
    and a, 7
    add a, HEALTH_BAR_TILES_BASE + 8
    .sector_2_done:
    ld [hli], a
    ; sector 3
    ld a, b
    cp 23
    jr c, .sector_3_empty
    cp 31
    jr c, .sector_3_partial
    ; full
    ld a, HEALTH_BAR_TILES_BASE + 16
    jr .sector_3_done
    .sector_3_empty:
    ld a, HEALTH_BAR_TILES_BASE + 8
    jr .sector_3_done
    .sector_3_partial:
    inc a
    and a, 7
    add a, HEALTH_BAR_TILES_BASE + 8
    .sector_3_done:
    ld [hli], a
    ; sector 4
    ld a, b
    cp 31
    jr c, .sector_4_empty
    cp 38
    jr c, .sector_4_partial
    ; full
    ld a, HEALTH_BAR_TILES_BASE + 24
    jr .sector_4_done
    .sector_4_empty:
    ld a, HEALTH_BAR_TILES_BASE + 17
    jr .sector_4_done
    .sector_4_partial:
    inc a
    and a, 7
    add a, HEALTH_BAR_TILES_BASE + 17
    .sector_4_done:
    ld [hli], a
    jp EndVramString


; ------ Lane Hit Zone Highlights ------

def LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE equ $99

def LANE_HIT_ZONE_HIGHLIGHT_TIMER equ 10

; B = lane index (0-3)
TriggerLaneHitZoneHighlight:
    bit 1, b
    jr nz, .lane_2_or_3
    bit 0, b
    ldh a, [hLaneHitZoneHighlightTimers]
    jr z, .set_lane_0_timer
    ; lane 1
    and $0f
    or LANE_HIT_ZONE_HIGHLIGHT_TIMER << 4
    jr .set_lane_0_or_1_timer
    .set_lane_0_timer:
    and $f0
    or LANE_HIT_ZONE_HIGHLIGHT_TIMER
    .set_lane_0_or_1_timer:
    ldh [hLaneHitZoneHighlightTimers], a
    jr DrawLaneHitZoneHighlight
    .lane_2_or_3:
    bit 0, b
    ldh a, [hLaneHitZoneHighlightTimers+1]
    jr z, .set_lane_2_timer
    ; lane 3
    and $0f
    or LANE_HIT_ZONE_HIGHLIGHT_TIMER << 4
    jr .set_lane_2_or_3_timer
    .set_lane_2_timer:
    ldh a, [hLaneHitZoneHighlightTimers+1]
    and $f0
    or LANE_HIT_ZONE_HIGHLIGHT_TIMER
    .set_lane_2_or_3_timer:
    ldh [hLaneHitZoneHighlightTimers+1], a
    ; Fallthrough

; B = lane index (0-3)
; Destroys: A, D, E, C, HL
DrawLaneHitZoneHighlight:
    ; top half
    ld a, b
    sla a
    add a, b
    add a, $e1
    ld e, a
    ld d, $99
    push de
    ld c, $03
    call BeginVramString
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE
    ld [hli], a
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE + 1
    ld [hli], a
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE + 2
    ld [hli], a
    call EndVramString
    ; bottom half
    pop de
    inc d
    ld a, e
    and a, $1f
    ld e, a
    ld c, $03
    call BeginVramString
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE + 3
    ld [hli], a
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE + 4
    ld [hli], a
    ld a, LANE_HIT_ZONE_HIGHLIGHT_TILES_BASE + 5
    ld [hli], a
    jp EndVramString

ProcessLaneHighlights:
    ; lane 0
    ldh a, [hLaneHitZoneHighlightTimers]
    and $0f
    jr z, .check_lane_1
    ldh a, [hLaneHitZoneHighlightTimers]
    dec a
    ldh [hLaneHitZoneHighlightTimers], a
    and $0f
    jr nz, .check_lane_1
    call EraseLaneHitZoneHighlight

    .check_lane_1:
    ldh a, [hLaneHitZoneHighlightTimers]
    and $f0
    jr z, .check_lane_2
    ldh a, [hLaneHitZoneHighlightTimers]
    sub a, $10
    ldh [hLaneHitZoneHighlightTimers], a
    and $f0
    jr nz, .check_lane_2
    ld a, 1
    call EraseLaneHitZoneHighlight

    .check_lane_2:
    ldh a, [hLaneHitZoneHighlightTimers+1]
    and $0f
    jr z, .check_lane_3
    ldh a, [hLaneHitZoneHighlightTimers+1]
    dec a
    ldh [hLaneHitZoneHighlightTimers+1], a
    and $0f
    jr nz, .check_lane_3
    ld a, 2
    call EraseLaneHitZoneHighlight

    .check_lane_3:
    ldh a, [hLaneHitZoneHighlightTimers+1]
    and $f0
    ret z
    ldh a, [hLaneHitZoneHighlightTimers+1]
    sub a, $10
    ldh [hLaneHitZoneHighlightTimers+1], a
    and $f0
    ret nz
    ld a, 3
    ; Fallthrough

; A = lane index (0-3)
EraseLaneHitZoneHighlight:
    ; top half
    ld e, a
    sla a
    add a, e
    add a, $e1
    ld e, a
    ld d, $99
    push de
    ld c, $03
    call BeginVramString
    ld a, $45
    ld [hli], a
    ld a, $45 + 1
    ld [hli], a
    ld a, $45 + 2
    ld [hli], a
    call EndVramString
    ; bottom half
    pop de
    inc d
    ld a, e
    and a, $1f
    ld e, a
    ld c, $03
    call BeginVramString
    ld a, $48
    ld [hli], a
    ld a, $48 + 1
    ld [hli], a
    ld a, $48 + 2
    ld [hli], a
    jp EndVramString


; ------ Lane Miss Indicators ------

def LANE_MISS_TILES_BASE equ $9f
def LANE_MISS_INDICATOR_TIMER equ 14

; B = lane index (0-3)
TriggerLaneMissIndicator:
    bit 1, b
    jr nz, .lane_2_or_3
    bit 0, b
    ldh a, [hLaneMissIndicatorTimers]
    jr z, .set_lane_0_timer
    ; lane 1
    and $0f
    or LANE_MISS_INDICATOR_TIMER << 4
    jr .set_lane_0_or_1_timer
    .set_lane_0_timer:
    and $f0
    or LANE_MISS_INDICATOR_TIMER
    .set_lane_0_or_1_timer:
    ldh [hLaneMissIndicatorTimers], a
    jr DrawLaneMissIndicator
    .lane_2_or_3:
    bit 0, b
    ldh a, [hLaneMissIndicatorTimers+1]
    jr z, .set_lane_2_timer
    ; lane 3
    and $0f
    or LANE_MISS_INDICATOR_TIMER << 4
    jr .set_lane_2_or_3_timer
    .set_lane_2_timer:
    ldh a, [hLaneMissIndicatorTimers+1]
    and $f0
    or LANE_MISS_INDICATOR_TIMER
    .set_lane_2_or_3_timer:
    ldh [hLaneMissIndicatorTimers+1], a
    ; Fallthrough

; B = lane index (0-3)
; Destroys: A, D, E, C, HL
DrawLaneMissIndicator:
    ld a, b
    sla a
    add a, b
    add a, $21
    ld e, a
    ld d, $9a
    ld c, $03
    call BeginVramString
    ld a, LANE_MISS_TILES_BASE
    ld [hli], a
    ld a, LANE_MISS_TILES_BASE + 1
    ld [hli], a
    ld a, LANE_MISS_TILES_BASE + 2
    ld [hli], a
    jp EndVramString

ProcessLaneMissIndicators:
    ldh a, [hFrameCounter]
    and 3
    ret nz ; process every fourth frame only
    ; lane 0
    ldh a, [hLaneMissIndicatorTimers]
    and $0f
    jr z, .check_lane_1
    ldh a, [hLaneMissIndicatorTimers]
    dec a
    ldh [hLaneMissIndicatorTimers], a
    and $0f
    jr nz, .check_lane_1
    call EraseLaneMissIndicator

    .check_lane_1:
    ldh a, [hLaneMissIndicatorTimers]
    and $f0
    jr z, .check_lane_2
    ldh a, [hLaneMissIndicatorTimers]
    sub a, $10
    ldh [hLaneMissIndicatorTimers], a
    and $f0
    jr nz, .check_lane_2
    ld a, 1
    call EraseLaneMissIndicator

    .check_lane_2:
    ldh a, [hLaneMissIndicatorTimers+1]
    and $0f
    jr z, .check_lane_3
    ldh a, [hLaneMissIndicatorTimers+1]
    dec a
    ldh [hLaneMissIndicatorTimers+1], a
    and $0f
    jr nz, .check_lane_3
    ld a, 2
    call EraseLaneMissIndicator

    .check_lane_3:
    ldh a, [hLaneMissIndicatorTimers+1]
    and $f0
    ret z
    ldh a, [hLaneMissIndicatorTimers+1]
    sub a, $10
    ldh [hLaneMissIndicatorTimers+1], a
    and $f0
    ret nz
    ld a, 3
    ; Fallthrough

; A = lane index (0-3)
EraseLaneMissIndicator:
    ld e, a
    sla a
    add a, e
    add a, $21
    ld e, a
    ld d, $9a
    ld c, $43
    call BeginVramString
    xor a
    ld [hli], a
    jp EndVramString


; ------ Game Stats ------

ResetGameStats:
    xor a
    ldh [hTapHitCount], a
    ldh [hTapHitCount+1], a
    ldh [hTapMissCount], a
    ldh [hTapMissCount+1], a
    ldh [hHoldHeadHitCount], a
    ldh [hHoldHeadHitCount+1], a
    ldh [hHoldHeadMissCount], a
    ldh [hHoldHeadMissCount+1], a
    ldh [hHoldCompleteCount], a
    ldh [hHoldCompleteCount+1], a
    ldh [hHoldBreakCount], a
    ldh [hHoldBreakCount+1], a
    ldh [hMisPressCount], a
    ldh [hMisPressCount+1], a
    ldh [hSpawnedTargetsCount], a
    ldh [hSpawnedTargetsCount+1], a
    ldh [hSpawnedChordsCount], a
    ldh [hSpawnedChordsCount+1], a
    ldh [hFullyClearedChordsCount], a
    ldh [hFullyClearedChordsCount+1], a
    ldh [hCurrentStreak], a
    ldh [hCurrentStreak+1], a
    ldh [hMaxStreak], a
    ldh [hMaxStreak+1], a
    ret

; Destroys: A
IncTapHitCount:
    ldh a, [hTapHitCount]
    inc a
    ldh [hTapHitCount], a
    ret nz
    ld a, [hTapHitCount+1]
    inc a
    ldh [hTapHitCount+1], a
    ret

; Destroys: A
IncTapMissCount:
    ldh a, [hTapMissCount]
    inc a
    ldh [hTapMissCount], a
    ret nz
    ld a, [hTapMissCount+1]
    inc a
    ldh [hTapMissCount+1], a
    ret

; Destroys: A
IncHoldHeadHitCount:
    ldh a, [hHoldHeadHitCount]
    inc a
    ldh [hHoldHeadHitCount], a
    ret nz
    ld a, [hHoldHeadHitCount+1]
    inc a
    ldh [hHoldHeadHitCount+1], a
    ret

; Destroys: A
IncHoldHeadMissCount:
    ldh a, [hHoldHeadMissCount]
    inc a
    ldh [hHoldHeadMissCount], a
    ret nz
    ld a, [hHoldHeadMissCount+1]
    inc a
    ldh [hHoldHeadMissCount+1], a
    ret

; Destroys: A
IncHoldCompleteCount:
    ldh a, [hHoldCompleteCount]
    inc a
    ldh [hHoldCompleteCount], a
    ret nz
    ldh a, [hHoldCompleteCount+1]
    inc a
    ldh [hHoldCompleteCount+1], a
    ret

; Destroys: A
IncHoldBreakCount:
    ldh a, [hHoldBreakCount]
    inc a
    ldh [hHoldBreakCount], a
    ret nz
    ldh a, [hHoldBreakCount+1]
    inc a
    ldh [hHoldBreakCount+1], a
    ret

; Destroys: A
IncMisPressCount:
    ldh a, [hMisPressCount]
    inc a
    ldh [hMisPressCount], a
    ret nz
    ldh a, [hMisPressCount+1]
    inc a
    ldh [hMisPressCount+1], a
    ret

; HL = Target_State ptr
IncTapOrHoldHeadMissCount:
    ld a, [hl] ; Target_State
    and a, $fc ; extended duration?
    jr nz, IncHoldHeadMissCount
    ; missed a tap target
    jr IncTapMissCount

IncSpawnedTargetsCount:
    ldh a, [hSpawnedTargetsCount]
    inc a
    ldh [hSpawnedTargetsCount], a
    ret nz
    ldh a, [hSpawnedTargetsCount+1]
    inc a
    ldh [hSpawnedTargetsCount+1], a
    ret

IncSpawnedChordsCount:
    ldh a, [hSpawnedChordsCount]
    inc a
    ldh [hSpawnedChordsCount], a
    ret nz
    ldh a, [hSpawnedChordsCount+1]
    inc a
    ldh [hSpawnedChordsCount+1], a
    ret

IncFullyClearedChordsCount:
    ldh a, [hFullyClearedChordsCount]
    inc a
    ldh [hFullyClearedChordsCount], a
    ret nz
    ld a, [hFullyClearedChordsCount+1]
    inc a
    ldh [hFullyClearedChordsCount+1], a
    ret

ResetCurrentStreak:
    xor a
    ldh [hCurrentStreak], a
    ldh [hCurrentStreak+1], a
    ret

IncCurrentStreak:
    ldh a, [hCurrentStreak]
    inc a
    ldh [hCurrentStreak], a
    jr nz, UpdateMaxStreak
    ; overflow, increment hi byte
    ldh a, [hCurrentStreak+1]
    inc a
    ldh [hCurrentStreak+1], a
    ; fallthrough

; Copies current streak to max streak if current > max
UpdateMaxStreak:
    push hl
    ldh a, [hCurrentStreak+1]
    ld h, a
    ldh a, [hCurrentStreak]
    ld l, a
    ldh a, [hMaxStreak+1]
    cp a, h
    jr c, .update_max
    ldh a, [hMaxStreak]
    cp a, l
    jr nc, .no_update
    .update_max:
    ld a, h
    ldh [hMaxStreak+1], a
    ld a, l
    ldh [hMaxStreak], a
    .no_update:
    pop hl
    ret


; ------ Health Management ------

; Destroys: A
DealTapOrHoldHeadMissDamage:
    ld a, [hl] ; Target_State
    and a, $fc ; extended duration?
    jr nz, DealHoldHeadMissDamage

; Destroys: A
DealTapMissDamage:
    ldh a, [hHealth]
    sub a, TAP_MISS_DAMAGE
    jr __SaveHealth

; Destroys: A
DealHoldHeadMissDamage:
    ldh a, [hHealth]
    sub a, HOLD_HEAD_MISS_DAMAGE
    jr __SaveHealth

; Destroys: A
DealHoldBreakDamage:
    ldh a, [hHealth]
    sub a, HOLD_BREAK_DAMAGE
    jr __SaveHealth

; Destroys: A
DealMisPressDamage:
    ldh a, [hHealth]
    sub a, MISPRESS_DAMAGE
    ; fallthrough

__SaveHealth:
    jr nc, .no_death
    ; health dropped to zero or below
    xor a
    .no_death:
    ldh [hHealth], a
    ld a, 1
    ldh [hHealthChanged], a
    ret

; Destroys: A
RecoverHealth:
    ldh a, [hHealth]
    add a, 1
    cp HEALTH_MAX
    jr nc, .cap_health
    ldh [hHealth], a
    ld a, 1
    ldh [hHealthChanged], a
    ret
    .cap_health:
    ld a, HEALTH_MAX
    ldh [hHealth], a
    ld a, 1
    ldh [hHealthChanged], a
    ret

CheckIfHealthChanged:
    ldh a, [hHealthChanged]
    or a, a
    ret z
    xor a
    ldh [hHealthChanged], a
    call DrawEntireHealthBar
    ; TODO: check if portrait should be updated
    ldh a, [hHealth]
    or a
    ret nz ; still alive
    ; player died - start timer
    ld a, 180
    ldh [hTimerLo], a
    ; mute all music tracks
    ld a, $f
    ldh [hSoundStatus], a
    ; play death sound effect
    ld a, 3
    call PlayTrack0SFX
    ld a, 3
    jp PlayTrack3SFX


; ------ Hit Cue Management ------

; Destroys A, B, C, D, E
IncHitCueProgress:
    ldh a, [hHitCueProgressLo]
    ld b, a
    ldh a, [hHitCueProgressIncLo]
    add a, b
    ldh [hHitCueProgressLo], a
    ldh a, [hHitCueProgressHi]
    ld b, a
    ldh a, [hHitCueProgressIncHi]
    adc a, b
    ldh [hHitCueProgressHi], a
    cp a, b
    ret z ; return if no need to draw progress bar update
    ; draw progress bar update
    push af
    dec a
    srl a
    srl a
    srl a
    add a, $01
    ld e, a
    ld d, $98
    ld c, 1
    call BeginVramString
    pop af
    and a, 7
    jr nz, .10
    or a, 8 ; full tile
    .10:
    add a, PROGRESS_BAR_TILES_BASE
    ld [hli], a
    jp EndVramString

; hHitCueStream ptr is expected to be set up already.
InitializeHitCues:
    xor a
    ldh [hHitCueProcessingPending], a
    ldh [hHitCueProgressLo], a
    ldh [hHitCueProgressHi], a
    inc a
    ldh [hHitCueTimer], a
    ldh [hHitCueStreamBitCtr], a
    call ReadHitCueStreamByte ; progress increment high
    ldh [hHitCueProgressIncHi], a
    call ReadHitCueStreamByte ; progress increment low
    ldh [hHitCueProgressIncLo], a
    ret

OnPatternRowChange:
    ld a, b
    cp a, 3 ; last channel?
    ret nz
    ldh a, [hHitCueTimer]
    dec a
    ldh [hHitCueTimer], a
    ret nz ; exit if timer not yet expired
    ld a, 1
    ldh [hHitCueProcessingPending], a
    ret



; Builds lookup table of hold timers from speed.
; Each entry is (3 * speed) + (n * 4 * speed)
; where n = 0, 1, ..., MAX_HOLD_TIMERS - 1
InitializeHoldTimerTable:
    ld hl, wTracks + Track_Speed
    ld a, [hl] ; speed
    ld c, a
    add a, a
    add a, a
    ld d, a ; speed * 4
    sub a, c ; speed * 3
    ld hl, wHoldTimerTable
    ld b, MAX_HOLD_TIMERS
    .loop:
    ld [hli], a
    add a, d ; speed * 4
    dec b
    jr nz, .loop
    ret



InitializeTargetLists:
    ld a, ZILCH_ITEM
    ldh [hActiveTargetsHead], a
    ldh [hActiveTargetsTail], a
    ldh [hHeldTargetsHead], a
    ldh [hHeldTargetsTail], a
    ldh [hHitTargetsHead], a
    ldh [hHitTargetsTail], a
    ldh [hMissedTargetsHead], a
    ldh [hMissedTargetsTail], a
    ; put all targets on the free list
    xor a
    ldh [hFreeTargetsList], a
    ld hl, wTargetsArena
    ld b, MAX_TARGETS - 1
    .loop:
    add a, Target_SIZEOF ; address of next target
    ld [hli], a ; Target_Next
    assert Target_SIZEOF == 4
    inc l
    inc l
    inc l
    dec b
    jr nz, .loop
    ld [hl], ZILCH_ITEM ; Target_Next
    ret

; A = high timer value
; B = next main state
; destroys A, D, E
SetTimerWithNextStateTimeout:
    ld de, MainFunc_Delay_TimerTimeout
    call SetTimer
    ld a, b
    ldh [hNextMainState], a
    ld a, 6
    ldh [hMainState], a ; delay
    ret

; A = high timer value
; DE = timeout callback
; destroys A
SetTimer:
    ldh [hTimerHi], a
    ld a, TIMER_SPEED
    ldh [hTimerLo], a
    ld a, e
    ldh [hTimerCallback], a
    ld a, d
    ldh [hTimerCallback+1], a
    ret

TickTimer:
    ldh a, [hTimerLo]
    dec a
    jr nz, .noTimeoutLo
    ldh a, [hTimerHi]
    dec a
    jr nz, .noTimeoutHi
    ldh a, [hTimerCallback]
    ld l, a
    ldh a, [hTimerCallback+1]
    ld h, a
    jp hl
    .noTimeoutHi:
    ldh [hTimerHi], a
    ld a, TIMER_SPEED
    ldh [hTimerLo], a
    ret
    .noTimeoutLo:
    ldh [hTimerLo], a
    ret


; DE = source address
; BC = count
; HL = destination address
CopyData:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jr nz, CopyData
    ret

; HL = destination address
; BC = count
; E = value
SetMemory:
    ld a, e
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jr nz, SetMemory
    ret


TurnOnLCD:
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG8000 | LCDCF_BG9800
    ldh [hShadowLCDC], a
    ; Write to actual LCDC immediately to get vblanks firing.
    ; It's safe to do so at any time
    ldh [rLCDC], a
    ret

; https://gbdev.io/pandocs/LCDC.html#lcdc7--lcd-enable
; CAUTION: Stopping LCD operation (Bit 7 from 1 to 0) may be performed during VBlank ONLY,
; disabling the display outside of the VBlank period may damage the hardware by burning in a
; black horizontal line similar to that which appears when the GB is turned off. This appears
; to be a serious issue. Nintendo is reported to reject any games not following this rule.
TurnOffLCD:
    ldh a, [hShadowLCDC]
    and a, ~LCDCF_ON
    ldh [hShadowLCDC], a
    ; Do NOT write to actual LCDC here - wait for VBlank to do so safely
    ret


; Program main function, called each frame in NMI handler
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc_NoOp        ; 0
dw MainFunc_PlaytestSettingsInit   ; 1
dw MainFunc_PlaytestSettings ; 2
dw MainFunc_GameInit    ; 3
dw MainFunc_Gameplay    ; 4
dw MainFunc_WaitForAllClear ; 5
dw MainFunc_Delay       ; 6
dw MainFunc_GameFinished ; 7
dw MainFunc_SongSessionResultsInit ; 8
dw MainFunc_SongSessionResults ; 9
dw MainFunc_SongSelectionInit ; 10
dw MainFunc_SongSelection ; 11
dw MainFunc_DifficultySelectionInit ; 12
dw MainFunc_DifficultySelection ; 13
dw MainFunc_PauseInit  ; 14
dw MainFunc_Pause      ; 15
dw MainFunc_Unpause    ; 16
dw MainFunc_GameOverInit ; 17
dw MainFunc_GameOver   ; 18

MainFunc_NoOp:
    ret

; wait for timer to expire, then go to next state
MainFunc_Delay:
    jp TickTimer

MainFunc_Delay_TimerTimeout:
    ldh a, [hNextMainState]
    ldh [hMainState], a
    ret


; --- Playtest Settings ---

NEWCHARMAP playtestsettings
CHARMAP " ", $00
CHARMAP "0", $01
CHARMAP "1", $02
CHARMAP "2", $03
CHARMAP "3", $04
CHARMAP "4", $05
CHARMAP "5", $06
CHARMAP "6", $07
CHARMAP "7", $08
CHARMAP "8", $09
CHARMAP "9", $0A
CHARMAP "A", $0B
CHARMAP "B", $0C
CHARMAP "C", $0D
CHARMAP "D", $0E
CHARMAP "E", $0F
CHARMAP "F", $10
CHARMAP "G", $11
CHARMAP "H", $12
CHARMAP "I", $13
CHARMAP "J", $14
CHARMAP "K", $15
CHARMAP "L", $16
CHARMAP "M", $17
CHARMAP "N", $18
CHARMAP "O", $19
CHARMAP "P", $1A
CHARMAP "Q", $1B
CHARMAP "R", $1C
CHARMAP "S", $1D
CHARMAP "T", $1E
CHARMAP "U", $1F
CHARMAP "V", $20
CHARMAP "W", $21
CHARMAP "X", $22
CHARMAP "Y", $23
CHARMAP "Z", $24
CHARMAP ":", $25
CHARMAP "*", $26
CHARMAP "!", $27
CHARMAP "-", $28
CHARMAP "%", $29

MainFunc_PlaytestSettingsInit:
    ld a, GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT | GAME_BEHAVIOR_STATE0_MASK__RANDOM_ENABLED | GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    ldh [hGameBehaviorState0], a
    ld a, GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE
    ldh [hGameBehaviorState1], a
    ld a, $30
    ldh [hIntensityMax], a
    xor a
    ldh [hCurrentPlaytestSetting], a

    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap

    ld hl, PlaytestSettingsScreenTilemap
    call WriteVramStrings

    ; Write initial settings to screen
    call PrintCurrentPlaytestSettingIndicator
    call PrintIntensityMaxPlaytestSetting
    call PrintHoldNotesPlaytestSetting
    call PrintHoldNotesStylePlaytestSetting
    call PrintRandomNotesPlaytestSetting
    call PrintRandomNotesStylePlaytestSetting
    call PrintMaxCueNotesPlaytestSetting
    call FlushVramBuffer

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 2
    ldh [hMainState], a ; playtest settings
    jp TurnOnLCD

PrintIntensityMaxPlaytestSetting:
    ld de, $9851
    ld c, 1
    call BeginVramString
    ldh a, [hIntensityMax]
    srl a
    srl a
    srl a
    srl a ; divide by 16
    add a, 1
    ld [hli], a
    jp EndVramString

PrintHoldNotesPlaytestSetting:
    ld de, $988E
    ld c, 3
    call BeginVramString
    ld a, $19 ; 'O'
    ld [hli], a
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    jr z, .holdNotesOff
    ; hold notes on
    ld a, $18 ; 'N'
    ld [hli], a
    ld a, $00 ; ' '
    ld [hli], a
    jp EndVramString
    .holdNotesOff:
    ld a, $10 ; 'F'
    ld [hli], a
    ld a, $10 ; 'F'
    ld [hli], a
    jp EndVramString

PrintHoldNotesStylePlaytestSetting:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    jr z, .notAvailable
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT
    jr z, .normalStyle
    ; uniform style
    ld de, .uniformStyleString
    jp CopyStringToVramBuffer
    .normalStyle:
    ld de, .normalStyleString
    jp CopyStringToVramBuffer
    .notAvailable:
    ld de, .notAvailableString
    jp CopyStringToVramBuffer
.uniformStyleString:
    db $98,$CB,7,"UNIFORM"
.normalStyleString:
    db $98,$CB,7,"NORMAL "
.notAvailableString:
    db $98,$CB,7,"---    "

PrintRandomNotesPlaytestSetting:
    ld de, $9910
    ld c, 3
    call BeginVramString
    ld a, $19 ; 'O'
    ld [hli], a
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    jr z, .randomNotesOff
    ; random notes on
    ld a, $18 ; 'N'
    ld [hli], a
    ld a, $00 ; ' '
    ld [hli], a
    jp EndVramString
    .randomNotesOff:
    ld a, $10 ; 'F'
    ld [hli], a
    ld a, $10 ; 'F'
    ld [hli], a
    jp EndVramString

PrintRandomNotesStylePlaytestSetting:
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    jr z, .notAvailable
    and GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    jr z, .deterministic
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    jr z, .seeded
    ; full
    ld de, .wildStyleString
    jp CopyStringToVramBuffer
    .deterministic:
    ld de, .fixedStyleString
    jp CopyStringToVramBuffer
    .seeded:
    ld de, .seededStyleString
    jp CopyStringToVramBuffer
    .notAvailable:
    ld de, .notAvailableString
    jp CopyStringToVramBuffer
.fixedStyleString:
    db $99,$4B,6,"FIXED "
.seededStyleString:
    db $99,$4B,6,"SEEDED"
.wildStyleString:
    db $99,$4B,6,"WILD  "
.notAvailableString:
    db $99,$4B,6,"---   "

PrintMaxCueNotesPlaytestSetting:
    ; not supported yet
    ret
    ld de, $9991
    ld c, 1
    call BeginVramString
    ldh a, [hGameBehaviorState1]
    and GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    add a, 1
    ld [hli], a
    jp EndVramString

EraseCurrentPlaytestSettingIndicator:
    ld d, $02
    ldh a, [hCurrentPlaytestSetting]
    inc a
    or a, $60
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    or a, 1
    ld e, a
    ld c, 1
    call BeginVramString
    ld a, 0 ; space
    ld [hli], a
    jp EndVramString

PrintCurrentPlaytestSettingIndicator:
    ld d, $02
    ldh a, [hCurrentPlaytestSetting]
    inc a
    or a, $60
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    or a, 1
    ld e, a
    ld c, 1
    call BeginVramString
    ld a, $26 ; '*'
    ld [hli], a
    jp EndVramString

MainFunc_PlaytestSettings:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr z, .startNotPressed
    jp .startPressed

    .startNotPressed:
    bit PADB_UP, a
    jr nz, .previousSetting
    bit PADB_DOWN, a
    jr nz, .nextSetting
    bit PADB_SELECT, a
    jr nz, .nextSetting
    bit PADB_LEFT, a
    jr nz, .previousValue
    bit PADB_B, a
    jr nz, .previousValue
    bit PADB_RIGHT, a
    jr nz, .nextValue
    bit PADB_A, a
    jr nz, .nextValue
    ret

    .previousSetting:
    ld a, 0
    call PlayTrack0SFX
    jp PreviousPlaytestSetting

    .nextSetting:
    ld a, 0
    call PlayTrack0SFX
    jp NextPlaytestSetting

    .previousValue:
    ld a, 1
    call PlayTrack0SFX
    jp PreviousPlaytestSettingValue

    .nextValue:
    ld a, 1
    call PlayTrack0SFX
    jp NextPlaytestSettingValue

    .startPressed:
    ld a, 3
    ldh [hMainState], a ; game init
    jp TurnOffLCD

PreviousPlaytestSetting:
    call EraseCurrentPlaytestSettingIndicator
    .previousSettingAgain:
    ldh a, [hCurrentPlaytestSetting]
    or a
    jr nz, .noWrapToLastSetting
    ld a, PLAYTEST_SETTINGS_COUNT
    .noWrapToLastSetting:
    dec a
    ldh [hCurrentPlaytestSetting], a
    cp PLAYTEST_SETTING__HOLD_NOTES_STYLE
    jr z, .skipHoldNotesStylePreviousSettingIfNotApplicable
    cp PLAYTEST_SETTING__RANDOM_NOTES_STYLE
    jr z, .skipRandomNotesStylePreviousSettingIfNotApplicable
    jp PrintCurrentPlaytestSettingIndicator

    .skipHoldNotesStylePreviousSettingIfNotApplicable:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    jr z, .previousSettingAgain
    jp PrintCurrentPlaytestSettingIndicator

    .skipRandomNotesStylePreviousSettingIfNotApplicable:
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    jr z, .previousSettingAgain
    jp PrintCurrentPlaytestSettingIndicator

NextPlaytestSetting:
    call EraseCurrentPlaytestSettingIndicator
    .nextSettingAgain:
    ldh a, [hCurrentPlaytestSetting]
    inc a
    cp PLAYTEST_SETTINGS_COUNT
    jr c, .noWrapToFirstSetting
    xor a
    .noWrapToFirstSetting:
    ldh [hCurrentPlaytestSetting], a
    cp PLAYTEST_SETTING__HOLD_NOTES_STYLE
    jr z, .skipHoldNotesStyleNextSettingIfNotApplicable
    cp PLAYTEST_SETTING__RANDOM_NOTES_STYLE
    jr z, .skipRandomNotesStyleNextSettingIfNotApplicable
    jp PrintCurrentPlaytestSettingIndicator

    .skipHoldNotesStyleNextSettingIfNotApplicable:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    jr z, .nextSettingAgain
    jp PrintCurrentPlaytestSettingIndicator

    .skipRandomNotesStyleNextSettingIfNotApplicable:
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    jr z, .nextSettingAgain
    jp PrintCurrentPlaytestSettingIndicator

PreviousPlaytestSettingValue:
    ldh a, [hCurrentPlaytestSetting]
    cp PLAYTEST_SETTING__INTENSITY_MAX
    jr z, .decreaseIntensityMax
    cp PLAYTEST_SETTING__HOLD_NOTES
    jr z, .toggleHoldNotes
    cp PLAYTEST_SETTING__HOLD_NOTES_STYLE
    jr z, .toggleHoldNotesStyle
    cp PLAYTEST_SETTING__RANDOM_NOTES
    jr z, .toggleRandomNotes
    cp PLAYTEST_SETTING__RANDOM_NOTES_STYLE
    jr z, .previousRandomNotesStyle
    cp PLAYTEST_SETTING__MAX_CUE_NOTES
    jr z, .decreaseMaxCueNotes
    ; unhandled setting
    jp Reset

    .decreaseIntensityMax:
    ldh a, [hIntensityMax]
    sub a, $10
    ldh [hIntensityMax], a
    jp PrintIntensityMaxPlaytestSetting

    .toggleHoldNotes:
    jp ToggleHoldNotesPlaytestSetting

    .toggleHoldNotesStyle:
    jp ToggleHoldNotesStylePlaytestSetting

    .toggleRandomNotes:
    jp ToggleRandomNotesPlaytestSetting

    .previousRandomNotesStyle:
    jp PreviousRandomNotesStylePlaytestSetting

    .decreaseMaxCueNotes:
    ldh a, [hGameBehaviorState1]
    and ~GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    ld b, a
    ldh a, [hGameBehaviorState1]
    and GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    dec a
    jr nz, .noWrapToMax
    ld a, GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE
    .noWrapToMax:
    or a, b
    ldh [hGameBehaviorState1], a
    jp PrintMaxCueNotesPlaytestSetting

NextPlaytestSettingValue:
    ldh a, [hCurrentPlaytestSetting]
    cp PLAYTEST_SETTING__INTENSITY_MAX
    jr z, .increaseIntensityMax
    cp PLAYTEST_SETTING__HOLD_NOTES
    jr z, .toggleHoldNotes
    cp PLAYTEST_SETTING__HOLD_NOTES_STYLE
    jr z, .toggleHoldNotesStyle
    cp PLAYTEST_SETTING__RANDOM_NOTES
    jr z, .toggleRandomNotes
    cp PLAYTEST_SETTING__RANDOM_NOTES_STYLE
    jr z, .nextRandomNotesStyle
    cp PLAYTEST_SETTING__MAX_CUE_NOTES
    jr z, .increaseMaxCueNotes
    ; unhandled setting
    jp Reset

    .increaseIntensityMax:
    ldh a, [hIntensityMax]
    add a, $10
    ldh [hIntensityMax], a
    jp PrintIntensityMaxPlaytestSetting

    .toggleHoldNotes:
    jp ToggleHoldNotesPlaytestSetting

    .toggleHoldNotesStyle:
    jp ToggleHoldNotesStylePlaytestSetting

    .toggleRandomNotes:
    jp ToggleRandomNotesPlaytestSetting

    .nextRandomNotesStyle:
    jp NextRandomNotesStylePlaytestSetting

    .increaseMaxCueNotes:
    ldh a, [hGameBehaviorState1]
    and ~GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    ld b, a
    ldh a, [hGameBehaviorState1]
    and GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    inc a
    cp GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE + 1
    jr c, .noWrapToOne
    ld a, 1
    .noWrapToOne:
    or a, b
    ldh [hGameBehaviorState1], a
    jp PrintMaxCueNotesPlaytestSetting

ToggleHoldNotesPlaytestSetting:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    jr z, .turnOnHoldNotes
    ; turn off hold notes
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    or GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
    ldh [hGameBehaviorState0], a
    call PrintHoldNotesPlaytestSetting
    jp PrintHoldNotesStylePlaytestSetting
    .turnOnHoldNotes:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    or GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT
    ldh [hGameBehaviorState0], a
    call PrintHoldNotesPlaytestSetting
    jp PrintHoldNotesStylePlaytestSetting

ToggleHoldNotesStylePlaytestSetting:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT
    jr z, .setUniformStyle
    ; set normal style
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    or GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT
    ldh [hGameBehaviorState0], a
    jp PrintHoldNotesStylePlaytestSetting
    .setUniformStyle:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    or GAME_BEHAVIOR_STATE0__HOLD_MODE__UNIFORM_DURATION
    ldh [hGameBehaviorState0], a
    jp PrintHoldNotesStylePlaytestSetting

ToggleRandomNotesPlaytestSetting:
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    jr nz, .turnOffRandomNotes
    ; turn on random notes
    ldh a, [hGameBehaviorState0]
    set GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    ldh [hGameBehaviorState0], a
    ; default to deterministic style when enabling
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    ldh [hGameBehaviorState0], a
    call PrintRandomNotesPlaytestSetting
    jp PrintRandomNotesStylePlaytestSetting
    .turnOffRandomNotes:
    ldh a, [hGameBehaviorState0]
    res GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a
    ldh [hGameBehaviorState0], a
    call PrintRandomNotesPlaytestSetting
    jp PrintRandomNotesStylePlaytestSetting

PreviousRandomNotesStylePlaytestSetting:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    jr z, .setWildStyle
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    jr z, .setDeterministicStyle
    ; set seeded style
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting
    .setDeterministicStyle:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting
    .setWildStyle:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__FULL
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting

NextRandomNotesStylePlaytestSetting:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    jr z, .setSeededStyle
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    jr z, .setWildStyle
    ; set deterministic style
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting
    .setSeededStyle:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting
    .setWildStyle:
    ldh a, [hGameBehaviorState0]
    and ~GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    or GAME_BEHAVIOR_STATE0__RANDOM_MODE__FULL
    ldh [hGameBehaviorState0], a
    jp PrintRandomNotesStylePlaytestSetting


; --- Difficulty Selection ---

MainFunc_DifficultySelectionInit:
    ld a, 2 ; Normal is default
    ldh [hDifficultyLevel], a ; TODO: remember last selected difficulty per song

    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ; TODO: use own tiles for this screen
    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap

    ld hl, DifficultySelectionScreenTilemap
    call WriteVramStrings

    call PrintCurrentDifficultyLevelIndicator
    call FlushVramBuffer

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 13
    ldh [hMainState], a ; difficulty selection
    jp TurnOnLCD

BeginCurrentDifficultyLevelIndicatorVramString:
    ld d, $02
    ldh a, [hDifficultyLevel]
    add a, $63
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    or a, 4
    ld e, a
    ld c, 1
    jp BeginVramString

PrintCurrentDifficultyLevelIndicator:
    call BeginCurrentDifficultyLevelIndicatorVramString
    ld a, $26 ; '*'
    ld [hli], a
    jp EndVramString

EraseCurrentDifficultyLevelIndicator:
    call BeginCurrentDifficultyLevelIndicatorVramString
    xor a ; blank tile
    ld [hli], a
    jp EndVramString

MainFunc_DifficultySelection:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr nz, .commit
    bit PADB_A, a
    jr nz, .commit

    bit PADB_UP, a
    jr nz, .previous
    bit PADB_DOWN, a
    jr nz, .next
    bit PADB_SELECT, a
    jr nz, .next
    bit PADB_B, a
    jr nz, .back
    ret

    .previous:
    ld a, 1
    call PlayTrack0SFX
    call EraseCurrentDifficultyLevelIndicator
    ldh a, [hDifficultyLevel]
    or a
    jr nz, .noWrapToLast
    ld a, DIFFICULTY_LEVELS_COUNT
    .noWrapToLast:
    dec a
    ldh [hDifficultyLevel], a
    jp PrintCurrentDifficultyLevelIndicator

    .next:
    ld a, 1
    call PlayTrack0SFX
    call EraseCurrentDifficultyLevelIndicator
    ldh a, [hDifficultyLevel]
    inc a
    cp DIFFICULTY_LEVELS_COUNT
    jr c, .noWrapToFirst
    xor a
    .noWrapToFirst:
    ldh [hDifficultyLevel], a
    jp PrintCurrentDifficultyLevelIndicator

    .back:
    ld a, 10
    ldh [hMainState], a ; song selection init
    jp TurnOffLCD

    .commit:
    call InitializeGameplayParametersFromDifficultyLevel
    ld a, 3
    ldh [hMainState], a ; game init
    jp TurnOffLCD

InitializeGameplayParametersFromDifficultyLevel:
    ldh a, [hDifficultyLevel]
    sla a
    ld d, 0
    ld e, a
    ld hl, .ParametersByDifficultyLevel
    add hl, de
    ld a, [hli]
    ldh [hGameBehaviorState0], a
    ld a, GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE ; TODO: make it variable per difficulty level
    ldh [hGameBehaviorState1], a
    ld a, [hl]
    ldh [hIntensityMax], a
    ret
.ParametersByDifficultyLevel:
; Beginner
db GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
db $10 ; intensity max
; Easy
db GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY
db $30 ; intensity max
; Normal
db GAME_BEHAVIOR_STATE0__HOLD_MODE__UNIFORM_DURATION | GAME_BEHAVIOR_STATE0_MASK__RANDOM_ENABLED | GAME_BEHAVIOR_STATE0__RANDOM_MODE__DETERMINISTIC
db $70 ; intensity max
; Hard
db GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT | GAME_BEHAVIOR_STATE0_MASK__RANDOM_ENABLED | GAME_BEHAVIOR_STATE0__RANDOM_MODE__SEEDED
db $b0 ; intensity max
; Expert
db GAME_BEHAVIOR_STATE0__HOLD_MODE__RESPECT | GAME_BEHAVIOR_STATE0_MASK__RANDOM_ENABLED | GAME_BEHAVIOR_STATE0__RANDOM_MODE__FULL
db $f0 ; intensity max


; --- Pause Menu ---

MainFunc_PauseInit:
    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ; TODO: use own tiles for this screen
    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap

    ld hl, PauseScreenTilemap
    call WriteVramStrings

    call HideAllSprites

    xor a
    ldh [hCurrentPauseMenuItem], a
    call PrintCurrentPauseOptionIndicator
    call FlushVramBuffer

    ld a, 15 ; pause
    ldh [hMainState], a
    jp TurnOnLCD


MainFunc_Pause:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr nz, .commit
    bit PADB_A, a
    jr nz, .commit

    bit PADB_UP, a
    jr nz, .previous
    bit PADB_DOWN, a
    jr nz, .next
    bit PADB_SELECT, a
    jr nz, .next
    ret

    .previous:
    ld a, 1
    call PlayTrack0SFX
    call EraseCurrentPauseOptionIndicator
    ldh a, [hCurrentPauseMenuItem]
    or a
    jr nz, .noWrapToLast
    ld a, 3
    .noWrapToLast:
    dec a
    ldh [hCurrentPauseMenuItem], a
    jp PrintCurrentPauseOptionIndicator

    .next:
    ld a, 1
    call PlayTrack0SFX
    call EraseCurrentPauseOptionIndicator
    ldh a, [hCurrentPauseMenuItem]
    inc a
    cp 3
    jr c, .noWrapToFirst
    xor a
    .noWrapToFirst:
    ldh [hCurrentPauseMenuItem], a
    jp PrintCurrentPauseOptionIndicator

    .commit:
    ldh a, [hCurrentPauseMenuItem]
    cp 0
    jr z, .unpause
    cp 1
    jr z, .restart
    ; 2 - quit to song select
    ; TODO: ask for confirmation
    ld a, 10 ; song selection init
    ldh [hMainState], a
    jp TurnOffLCD

    .restart:
    ld a, 3 ; game init
    ldh [hMainState], a
    jp TurnOffLCD

    .unpause:
    ld a, 16 ; unpause
    ldh [hMainState], a
    jp TurnOffLCD

MainFunc_Unpause:
    call GameGfxInit
    call DrawEntireProgressBar
    call DrawEntireHealthBar
    call FlushVramBuffer
    call UnpauseMusic
    ld a, 4
    ldh [hMainState], a ; gameplay
    jp TurnOnLCD

BeginCurrentPauseOptionIndicatorVramString:
    ld d, $02
    ldh a, [hCurrentPauseMenuItem]
    add a, $63
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    sla a
    rl d
    or a, 4
    ld e, a
    ld c, 1
    jp BeginVramString

PrintCurrentPauseOptionIndicator:
    call BeginCurrentPauseOptionIndicatorVramString
    ld a, $26 ; '*'
    ld [hli], a
    jp EndVramString

EraseCurrentPauseOptionIndicator:
    call BeginCurrentPauseOptionIndicatorVramString
    ld a, 0 ; space
    ld [hli], a
    jp EndVramString


; --- Gameplay ---

MainFunc_GameInit:
    call GameInit

    ld a, 4
    ldh [hMainState], a ; gameplay

    jp TurnOnLCD

MainFunc_Gameplay:
    ldh a, [hHealth]
    or a
    jr nz, .is_alive
    ; player is dead
    ldh a, [hTimerLo]
    dec a
    ldh [hTimerLo], a
    jr nz, .is_zombie
    ; timer expired, now it's really the end
    ld a, 17 ; game over init
    ldh [hMainState], a
    jp TurnOffLCD
    .is_zombie:
    xor a
    ldh [hLaneInputPosedge], a
    ldh [hLaneInput], a
    jr .do_core_processing
    .is_alive:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr z, .no_pause
    ; pause the game
    call PauseMusic
    ld a, 14 ; pause init
    ldh [hMainState], a
    jp TurnOffLCD
    .no_pause:
    call GetLaneInputsFromButtons
    .do_core_processing:
    call HideAllSprites
    call ProcessHitCues
    call ProcessActiveTargets
    call ProcessHeldTargets
    call ProcessHitTargets
    call ProcessMissedTargets
    call ProcessLaneHighlights
    call ProcessLaneMissIndicators
    jp CheckIfHealthChanged

MainFunc_WaitForAllClear:
    call MainFunc_Gameplay
    ldh a, [hActiveTargetsHead]
    cp ZILCH_ITEM ; any active targets?
    ret nz ; exit if so
    ldh a, [hHeldTargetsHead]
    cp ZILCH_ITEM ; any held targets?
    ret nz ; exit if so
    ldh a, [hHitTargetsHead]
    cp ZILCH_ITEM ; any hit targets?
    ret nz ; exit if so
    ldh a, [hMissedTargetsHead]
    cp ZILCH_ITEM ; any missed targets?
    ret nz ; exit if so
    ; TODO: expire any remaining lane highlights and miss indicators
    ld a, 30 ; timer
    ld b, 7 ; game finished
    jp SetTimerWithNextStateTimeout

MainFunc_GameFinished:
    ld a, 8
    ldh [hMainState], a ; to song session results init
    jp TurnOffLCD

MACRO Align8
ds ((@ + 7) & $fff8) - @
ENDM

ProcessHitCues:
    ldh a, [hHitCueProcessingPending]
    or a
    ret z ; exit if no processing pending
    dec a
    ldh [hHitCueProcessingPending], a
    ; set lane defaults
    xor a
    ld hl, wTargetDurationByLane
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ldh [hSuppressedLanes], a
    ld a, $30
    ld hl, wLaneIntensities
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ; process hit cue entry
    ld a, HIT_CUE_BASE_PAYLOAD_WIDTH
    call ReadHitCueStreamBits
    or a
    jr z, .setNextTimer ; it's just a delay, no targets to spawn
    cp 12 ; extended payload?
    jr nc, .extendedPayload
    ld c, a ; chord id (nonzero)

    .processLanesAfterExtensions:
    call SuppressLanesByIntensity
    call SuppressLanesByMaxNotesPerCue
    push bc ; save chord id
    call IncHitCueProgress ; make sure progress is updated even if no targets are spawned
    pop bc ; restore chord id
    ld a, c ; chord id
    or a, LOW(.ChordIdToLanesBitmask)
    ld l, a
    ld h, HIGH(.ChordIdToLanesBitmask)
    ld b, [hl] ; lane bits
    ldh a, [hSuppressedLanes]
    xor a, b
    and a, b
    jr z, .setNextTimer ; no lanes to spawn

    ld b, a ; effective lane bits
    xor a ; lane
    .laneLoop:
    srl b ; lane bit into carry
    jr nc, .nextLane
    push af ; save lane
    push bc ; save lane bits
    call AddTarget
    call IncSpawnedTargetsCount
    pop bc ; restore lane bits
    pop af ; restore lane
    .nextLane:
    inc a
    cp 4    ; done all lanes?
    jr nz, .laneLoop

    call IncSpawnedChordsCount

    .setNextTimer:
    ld a, HIT_CUE_DELAY_WIDTH
    call ReadHitCueStreamBits
    ; map value to timer
    or a, LOW(.HitCueTimerTable)
    ld l, a
    ld h, HIGH(.HitCueTimerTable)
    ld a, [hl]
    ldh [hHitCueTimer], a
    ret

    .extendedPayload:
    and a, 3 ; lower 2 bits of chord id
    ld c, a
    ld a, 2
    push bc
    call ReadHitCueStreamBits ; high 2 bits of chord id
    pop bc
    sla a
    sla a
    or c ; full chord id
    cp 15 ; end of stream?
    jp z, .endOfStream
    ; not end of stream, process all extensions
    ld c, a ; save chord id

    ; process intensities
    ld a, 1
    push bc ; save chord id
    call ReadHitCueStreamBits ; intensities flag
    pop bc ; restore chord id
    bit 0, a
    jr z, .processRandomization
    ; set intensities for lanes in chord
    ld a, c ; chord id (nonzero)
    dec a
    sla a
    sla a
    or a, LOW(.ChordIdToLanesMetadata)
    ld l, a
    ld h, HIGH(.ChordIdToLanesMetadata)
    ld a, [hli] ; number of lanes
    cp 1
    jr z, .intensitySingleLaneChord
    ; handle multi-lane chord
    .intensityMultiLaneChordLoop:
    push af ; save number of lanes
    push hl ; save metadata ptr
    push bc ; save chord id
    ld a, 1
    call ReadHitCueStreamBits ; intensity flag for lane
    pop bc ; restore chord id
    pop hl ; restore metadata ptr
    bit 0, a ; does this lane have an intensity?
    ld a, [hli] ; lane index
    jr z, .skipIntensityForLane
    ; read and set intensity for this lane
    push af ; save lane index
    push hl ; save metadata ptr
    push bc ; save chord id
    ld a, 4
    call ReadHitCueStreamBits ; intensity
    pop bc ; restore chord id
    pop hl ; restore metadata ptr
    sla a
    sla a
    sla a
    sla a
    ld b, a ; intensity << 4
    pop af ; restore lane index
    or a, LOW(wLaneIntensities)
    ld e, a
    ld d, HIGH(wLaneIntensities)
    ld a, b
    ld [de], a ; set intensity for lane
    .skipIntensityForLane:
    pop af ; restore number of lanes
    dec a
    jr nz, .intensityMultiLaneChordLoop
    jr .processRandomization

    .intensitySingleLaneChord:
    ld a, [hl] ; lane index
    push af ; save lane index
    push bc
    ld a, 4
    call ReadHitCueStreamBits ; intensity
    pop bc
    sla a
    sla a
    sla a
    sla a
    ld b, a ; intensity << 4
    pop af ; restore lane index
    or a, LOW(wLaneIntensities)
    ld l, a
    ld h, HIGH(wLaneIntensities)
    ld [hl], b ; set intensity for lane

    .processRandomization:
    push bc ; save chord id
    ld a, 1
    call ReadHitCueStreamBits ; randomization flag
    pop bc ; restore chord id
    bit 0, a
    jr z, .processHolds
    ; process randomization
    ld a, c ; chord id (nonzero)
    dec a
    sla a
    sla a
    or a, LOW(.ChordIdToLanesMetadata)
    ld l, a
    ld h, HIGH(.ChordIdToLanesMetadata)
    ld a, [hli] ; number of lanes
    cp 1
    jr z, .randomizeSingleLaneChord
    ; handle multi-lane chord
    .randomizeMultiLaneChordLoop:
    push af ; save number of lanes
    push hl ; save metadata ptr
    push bc ; save chord id
    ld a, 1
    call ReadHitCueStreamBits ; "apply randomization" flag for lane
    pop bc ; restore chord id
    pop hl ; restore metadata ptr
    bit 0, a ; does this lane have randomization?
    ld a, [hli] ; lane index
    jr z, .skipRandomizationForLane
    ; decide if this lane is to be suppressed
    push af ; save lane index
    ; if RANDOM_ENABLED is 0, never suppress ( = treat as deterministic lane)
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a ; randomization enabled?
    jr nz, .considerRandomizationForLane
    pop af ; restore lane index
    jr .skipRandomizationForLane
    .considerRandomizationForLane:
    ; TODO: if ALLOW_NONE is 0, make sure at least one candidate lane remains
    call RandomDecision
    and a, 1 ; 50% chance
    ld b, a
    pop af ; restore lane index
    bit 0, b
    jr z, .skipRandomizationForLane
    ; suppress this lane
    ; compute the lane bitmask in b
    ld b, 1
    or a
    jr z, .randomizeLaneOfMultiLaneChord_10
    .randomizeLaneOfMultiLaneChord_20:
    sla b
    dec a
    jr nz, .randomizeLaneOfMultiLaneChord_20
    .randomizeLaneOfMultiLaneChord_10:
    ldh a, [hSuppressedLanes]
    or b
    ldh [hSuppressedLanes], a
    .skipRandomizationForLane:
    pop af ; restore number of lanes
    dec a
    jr nz, .randomizeMultiLaneChordLoop
    jr .processHolds

    .randomizeSingleLaneChord:
    ; decide if the lane is to be suppressed
    ; if RANDOM_ENABLED is 0, never suppress ( = treat as deterministic lane)
    ldh a, [hGameBehaviorState0]
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ENABLED, a ; randomization enabled?
    jr z, .processHolds
    bit GAME_BEHAVIOR_STATE0_BIT__RANDOM_ALLOW_NONE, a
    jr z, .processHolds
    call RandomDecision
    and a, 1 ; 50% chance
    jr z, .processHolds
    ; suppress the lane
    ld a, [hl] ; lane index
    ; compute the lane bitmask in b
    ld b, 1
    or a
    jr z, .randomizeSingleLaneChord_10
    .randomizeSingleLaneChord_20:
    sla b
    dec a
    jr nz, .randomizeSingleLaneChord_20
    .randomizeSingleLaneChord_10:
    ldh a, [hSuppressedLanes]
    or b
    ldh [hSuppressedLanes], a

    .processHolds:
    ld a, 1
    push bc ; save chord id
    call ReadHitCueStreamBits ; holds flag
    pop bc ; restore chord id
    bit 0, a
    jr z, .doneProcessingHolds
    ; set hold durations for lanes in chord
    ld a, c ; chord id (nonzero)
    dec a
    sla a
    sla a
    or a, LOW(.ChordIdToLanesMetadata)
    ld l, a
    ld h, HIGH(.ChordIdToLanesMetadata)
    ld a, [hli] ; number of lanes
    cp 1
    jr z, .holdSingleLaneChord
    ; handle multi-lane chord
    .holdMultiLaneChordLoop:
    push af ; save number of lanes
    push hl ; save metadata ptr
    push bc ; save chord id
    ld a, 1
    call ReadHitCueStreamBits ; hold flag for lane
    pop bc ; restore chord id
    pop hl ; restore metadata ptr
    bit 0, a ; does this lane have a hold?
    ld a, [hli] ; lane index
    jr z, .skipHoldForLane
    ; read and set hold duration for this lane
    push af ; save lane index
    push hl ; save metadata ptr
    push bc ; save chord id
    ld a, 4
    call ReadHitCueStreamBits ; hold duration - 1
    pop bc ; restore chord id
    pop hl ; restore metadata ptr
    inc a
    sla a
    sla a
    ld b, a ; duration << 2
    pop af ; restore lane index
    or a, LOW(wTargetDurationByLane)
    ld e, a
    ld d, HIGH(wTargetDurationByLane)
    ; if holds should be converted to taps, don't set hold duration anyway
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY ; convert holds to taps?
    jr z, .skipHoldForLane ; then don't set duration anyway
    ld a, b
    ld [de], a ; set hold duration for lane
    .skipHoldForLane:
    pop af ; restore number of lanes
    dec a
    jr nz, .holdMultiLaneChordLoop
    jr .doneProcessingHolds

    .holdSingleLaneChord:
    ld a, [hl] ; lane index
    push af ; save lane index
    push bc ; save chord id
    ld a, 4
    call ReadHitCueStreamBits ; hold duration - 1
    pop bc ; restore chord id
    inc a
    sla a
    sla a
    ld b, a ; duration << 2
    pop af ; restore lane index
    or a, LOW(wTargetDurationByLane)
    ld l, a
    ld h, HIGH(wTargetDurationByLane)
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__TAPIFY ; convert holds to taps?
    jr z, .doneProcessingHolds ; then don't set duration anyway
    ld [hl], b ; set hold duration for lane

    .doneProcessingHolds:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__HOLD_MODE
    cp GAME_BEHAVIOR_STATE0__HOLD_MODE__UNIFORM_DURATION
    jr nz, .doneProcessingExtensions
    call SetUniformHoldDurations

    .doneProcessingExtensions:
    jp .processLanesAfterExtensions

    .endOfStream:
    ld hl, 0
    call SetPatternRowCallback
    ld a, 5
    ldh [hMainState], a ; wait for all clear
    .ceilProgress:
    call IncHitCueProgress
    ldh a, [hHitCueProgressHi]
    cp HIT_CUE_MAX_PROGRESS
    jr c, .ceilProgress
    ret

MACRO Align16
ds ((@ + $f) & $fff0) - @
ENDM

Align16
.ChordIdToLanesBitmask:
db %0000 ; 0 - none
db %0001 ; 1 - left
db %0010 ; 2 - right
db %0100 ; 3 - B
db %1000 ; 4 - A
db %0101 ; 5 - left + B
db %1001 ; 6 - left + A
db %0110 ; 7 - right + B
db %1010 ; 8 - right + A
db %1100 ; 9 - B + A
db %1101 ; 10 - left + B + A
db %1110 ; 11 - right + B + A

MACRO Align64
ds ((@ + $3f) & $ffc0) - @
ENDM

Align64
.ChordIdToLanesMetadata:
; number of lanes, lane indices, padding
db 1,0,0,0
db 1,1,0,0
db 1,2,0,0
db 1,3,0,0
db 2,0,2,0
db 2,0,3,0
db 2,1,2,0
db 2,1,3,0
db 2,2,3,0
db 3,0,2,3
db 3,1,2,3

Align8
.HitCueTimerTable:
db 1,2,4,8,12,16,24,32

SetUniformHoldDurations:
    ; first pass: find min hold duration among the lanes in the chord
    ld hl, wTargetDurationByLane
    ld b, $ff ; best
    ld d, 4 ; lane counter
    .findLoop:
    ld a, [hli]
    or a
    jr z, .nextLane
    cp a, b
    jr nc, .nextLane
    ld b, a ; new best
    .nextLane:
    dec d
    jr nz, .findLoop
    ; second pass: set all hold durations to best
    ld hl, wTargetDurationByLane
    ld d, 4 ; lane counter
    .setLoop:
    ld a, [hl]
    or a
    jr z, .nextLane2
    ld [hl], b ; set to best
    .nextLane2:
    inc l
    dec d
    jr nz, .setLoop
    ret

; Destroys: HL, B
; Suppresses lanes whose intensity is below hIntensityMax
SuppressLanesByIntensity:
    ldh a, [hIntensityMax]
    ld hl, wLaneIntensities
    ld b, 0
    cp [hl] ; lane 0 intensity
    jr nc, .10
    set 0, b ; suppress lane 0
    .10:
    inc l
    cp [hl] ; lane 1 intensity
    jr nc, .20
    set 1, b ; suppress lane 1
    .20:
    inc l
    cp [hl] ; lane 2 intensity
    jr nc, .30
    set 2, b ; suppress lane 2
    .30:
    inc l
    cp [hl] ; lane 3 intensity
    jr nc, .40
    set 3, b ; suppress lane 3
    .40:
    ldh a, [hSuppressedLanes]
    or a, b
    ldh [hSuppressedLanes], a
    ret

; C = chord id
SuppressLanesByMaxNotesPerCue:
    ldh a, [hGameBehaviorState1]
    and GAME_BEHAVIOR_STATE1_MASK__MAX_NOTES_PER_CUE
    cp GAME_BEHAVIOR_STATE1__MAX_NOTES_PER_CUE ; no limit?
    ret z
    ; TODO: implement suppression based on intensity order
    ret

; A = lane (bits 1..0)
; Destroys: A, B, HL, DE
AddTarget:
    push af ; save lane
; grab target from free list
    ldh a, [hFreeTargetsList]
    cp ZILCH_ITEM ; empty list?
    jr nz, .10
    ; fatal, no more free targets
    jp Reset
    .10:
    ld h, HIGH(wTargetsArena)
    ld l, a
    ld a, [hl] ; Target_Next (new head of free list)
    ldh [hFreeTargetsList], a
    ld a, ZILCH_ITEM
    ld [hli], a ; Target_Next (this will become the new tail)
; initialize the target
    pop af ; restore lane
    ld b, a ; lane
  ; get duration
    ld d, HIGH(wTargetDurationByLane)
    or a, LOW(wTargetDurationByLane)
    ld e, a
    ld a, [de] ; duration
;    ld a, 2 << 2 ; for testing, fixed hold
    or a, b ; add lane
    ld [hli], a ; Target_State
    xor a
    ld [hli], a ; Target_PosY_Frac
    ld a, 0 ; initial Y position
    ld [hl-], a ; Target_PosY_Int
    dec l ; Target_State
    dec l ; Target_Next
; append to active targets list
    ldh a, [hActiveTargetsTail] ; old tail
    cp a, ZILCH_ITEM ; empty list?
    jr nz, .20
    ; initialize the list
    ld a, l
    ldh [hActiveTargetsHead], a
    ldh [hActiveTargetsTail], a
    ret
    .20:
    ld b, l ; this target
    ld l, a ; old tail
    ld a, b
    ld [hl], a ; old tail's Target_Next = new target
    ldh [hActiveTargetsTail], a
    ret

; A = number of bits to read (max 8)
; Returns: A = bits read
; Destroys: B, C, D, H, L
ReadHitCueStreamBits:
    ld d, a ; bit counter
    ldh a, [hHitCueStreamBitCtr]
    ld b, a
    ldh a, [hHitCueStreamBits]
    ld c, 0 ; output will be shifted into here
    .readOneBit:
    dec b
    jr nz, .10
    ; reset counter, read next byte from stream
    ld b, 8
    ldh a, [hHitCueStream]
    ld l, a
    ldh a, [hHitCueStream+1]
    ld h, a
    ld a, [hli] ; next data byte
    push af
    ; write back stream pointer
    ld a, l
    ldh [hHitCueStream], a
    ld a, h
    ldh [hHitCueStream+1], a
    pop af ; restore next data byte
    .10:
    sla a ; top bit into carry
    rl c ; shift it into result
    dec d ; one bit done
    jr nz, .readOneBit
    ldh [hHitCueStreamBits], a
    ld a, b
    ldh [hHitCueStreamBitCtr], a
    ld a, c ; final result
    ret

; Reads a byte from hit cue stream
; Returns: A = bits read
; Destroys: B, C, D, H, L
ReadHitCueStreamByte:
    ld a, 8
    jr ReadHitCueStreamBits

; Computes hLaneInputPosedge and hLaneInput from hButtonsPressed and hButtonsHeld
; Destroys: A, B
GetLaneInputsFromButtons:
    ; compute hLaneInputPosedge
    xor a
    ld b, a
    ldh a, [hButtonsPressed]
    bit PADB_LEFT, a
    jr z, .10
    set 0, b
    .10:
    bit PADB_DOWN, a
    jr z, .20
    set 1, b
    .20:
    bit PADB_B, a
    jr z, .30
    set 2, b
    .30:
    bit PADB_A, a
    jr z, .40
    set 3, b
    .40:
    ld a, b
    ldh [hLaneInputPosedge], a
    ; compute hLaneInput
    xor a
    ld b, a
    ldh a, [hButtonsHeld]
    bit PADB_LEFT, a
    jr z, .50
    set 0, b
    .50:
    bit PADB_DOWN, a
    jr z, .60
    set 1, b
    .60:
    bit PADB_B, a
    jr z, .70
    set 2, b
    .70:
    bit PADB_A, a
    jr z, .80
    set 3, b
    .80:
    ld a, b
    ldh [hLaneInput], a
    ret

ProcessActiveTargets:
    xor a
    ldh [hCheckedLanes], a
    ldh [hHittableLanes], a
    ldh [hHitLanes], a
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hActiveTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    jr nz, .doTarget

    call CheckForErrors
    jp SweepActiveTargets

    .doTarget:
    ld l, a ; Target_Next
    inc l ; Target_State
    ; check for hit/miss
    ld a, [hl] ; Target_State
    ; compute bit mask for lane in C
    ld c, 1
    and a, 3 ; lane
    jr z, .10
    .20:
    sla c
    dec a
    jr nz, .20

    .10:
    ldh a, [hCheckedLanes]
    and c
    jr nz, .moveAndDraw ; we already checked this lane, target can't possibly be within hit range

    ldh a, [hCheckedLanes]
    or c ; set lane bit
    ldh [hCheckedLanes], a
    ; not hittable, hittable or missed?
    inc l ; Target_PosY_Frac
    inc l ; Target_PosY_Int
    ld a, [hl-] ; Target_PosY_Int
    dec l ; Target_State
    sub HIT_START_Y
    ; TODO: if not hittable, check if it's inside grace window ("nearly hittable")
    jr c, .moveAndDraw ; not hittable
    sub HIT_EXTENT
    jr nc, .missed

    ; it's hittable
    ldh a, [hHittableLanes]
    or c ; set lane bit
    ldh [hHittableLanes], a
    ; is it actually hit?
    ldh a, [hLaneInputPosedge]
    and c
    jr z, .moveAndDraw ; not hit

    ; direct hit!
    ldh a, [hHitLanes]
    or c ; set lane bit
    ldh [hHitLanes], a
    jr .next ; don't draw. It will be moved to hit list or held list by SweepActiveTargets()

    ; hl should point to Target_State
    .moveAndDraw:
    call MoveTarget
    ld a, [hl] ; Target_State
    and a, $fc ; extended duration?
    jr nz, .isHoldTarget
    ; is a tap target
    call DrawTapTarget
    jr .next
    .isHoldTarget:
; map duration to tail length in pixels
    srl a
    srl a
    dec a
    or a, LOW(wHoldTimerTable)
    ld e, a
    ld d, HIGH(wHoldTimerTable)
    ld a, [de] ; timer
    ldh [hDrawHoldLength], a
    call DrawHoldTarget
    .next:
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    ld l, a
    ld a, [hl] ; Target_Next
    jr .loop

    .missed:
    call HandleMissedTarget
    jr .loop


; HL = pointer to Target_State
HandleMissedTarget:
    ldh a, [hHealth]
    or a
    jr z, .10 ; player is dead, skip some of the processing

    call IncTapOrHoldHeadMissCount
    call DealTapOrHoldHeadMissDamage
    call ResetCurrentStreak

; turn off the square wave channels
    ldh [hSoundStatus], a
    or a, 3
    ldh [hSoundStatus], a

; trigger lane miss indicator
    ld a, [hl] ; Target_State
    and a, 3 ; lane
    ld b, a
    push hl ; Target_State
    call TriggerLaneMissIndicator
    pop hl ; Target_State

    .10:
; move active target to missed list
    ld a, l
    and a, ~3 ; Target_Next
    ld l, a
    jp MoveActiveTargetToMissedList


; HL = pointer to Target_State
MoveTarget:
    inc l ; Target_PosY_Frac
    ; TODO: can we drop frac part?
    inc l ; Target_PosY_Int
    ld a, [hl] ; Target_PosY_Int
    inc a
    ld [hl-], a ; Target_PosY_Int
    dec l ; Target_State
    ret

; HL = pointer to Target_State
DrawTapTarget:
    push hl ; Target_State
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc e ; Target_PosY_Frac
    inc e ; Target_PosY_Int
    ld a, [de] ; Target_PosY_Int
    ld b, a
    dec e ; Target_PosY_Frac
    dec e ; Target_State
    ld a, [de] ; Target_State
    and a, 3 ; lane
    sla a
    sla a
    sla a
    ld c, a ; lane * 8
    sla a ; lane * 16 (0, 16, 32, 48)
    add a, c ; lane * 24
    add a, 20 ; left offset
    ld c, a ; x
    ; left half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, $4c
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    add a, 8
    ld [hli], a ; x
    ld a, $4c
    ld [hli], a ; tile
    ld a, OAMF_XFLIP
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_State
    ret

; HL = pointer to Target_State
; hDrawHoldLength = length of hold tail in pixels
; Destroys: AF, BC, DE
DrawHoldTarget:
    push hl ; Target_State
; Step 1. Draw the head (same as tap target, but different tile)
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc e ; Target_PosY_Frac
    inc e ; Target_PosY_Int
    ld a, [de] ; Target_PosY_Int
    ld b, a
    dec e ; Target_PosY_Frac
    dec e ; Target_State
    ld a, [de] ; Target_State
    and a, 3 ; lane
    sla a
    sla a
    sla a
    ld c, a ; lane * 8
    sla a ; lane * 16 (0, 16, 32, 48)
    add a, c ; lane * 24
    add a, 20 ; left offset
    ld c, a ; x
    ; left half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, $4e
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    add a, 8
    ld [hli], a ; x
    ld a, $4e
    ld [hli], a ; tile
    ld a, OAMF_XFLIP
    ld [hli], a  ; attributes
; Step 2. Draw the tail
    ld a, c ; x
    add a, 4
    ld c, a ; x
; draw the segments
    ldh a, [hDrawHoldLength]
    .wholeSegmentsLoop:
    ld e, a ; remaining length
    cp 16
    jr c, .partialSegment
    ld a, b ; y
    sub a, 16
    ld b, a
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, $6e
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ld a, e
    sub 16
    jr z, .tailDone
    jr .wholeSegmentsLoop
    .partialSegment:
    ld a, b ; y
    sub a, e ; remaining length
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, e ; remaining length
    sla a
    add a, $4e
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    .tailDone:
    call EndDrawSprites
    pop hl ; Object_State
    ret

; HL = pointer to Target_PosY_Frac
; Destroys: AF, BC, DE
DrawExplodedTarget:
    push hl ; Target_PosY_Frac
    ld d, h
    ld e, l
    call BeginDrawSprites
    inc e ; Target_PosY_Int
    ld a, [de] ; Target_PosY_Int
    ld b, a
    dec e ; Target_PosY_Frac
    dec e ; Target_State
    ld a, [de] ; Target_State
    and a, 3 ; lane
    sla a
    sla a
    sla a
    ld c, a ; lane * 8
    sla a ; lane * 16 (0, 16, 32, 48)
    add a, c ; lane * 24
    add a, 20 ; left offset
    ld c, a ; x
    ; left half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    ld [hli], a ; x
    ld a, [de] ; Target_State
    and $38
    srl a
    add a, $70 ; exploded tile base
    push af
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    ; right half
    ld a, b ; y
    ld [hli], a ; y
    ld a, c ; x
    add a, 8
    ld [hli], a ; x
    pop af
    add a, 2
    ld [hli], a ; tile
    ld a, 0
    ld [hli], a  ; attributes
    call EndDrawSprites
    pop hl ; Object_PosY_Frac
    ret

; ProcessActiveTargets() helper function.
CheckForErrors:
    ldh a, [hLaneInputPosedge]
    ld b, a
    ldh a, [hHittableLanes]
    xor a, b
    and a, b
    ldh [hErrorLanes], a
    ret z ; exit if no errors
    ld b, 0 ; lane index
    .misPressesLoop:
    srl a
    push af
    jr nc, .10
    ; mis-press in this lane
    call IncMisPressCount
    call DealMisPressDamage
    call TriggerLaneHitZoneHighlight
    .10:
    inc b ; next lane
    pop af
    jr nz, .misPressesLoop
    ld a, 2
    call PlayTrack0SFX
    jp ResetCurrentStreak

; ProcessActiveTargets() helper function.
; Moves active targets that were hit either to the hit list (duration=1) or held list (duration>1).
SweepActiveTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hActiveTargetsHead]
    ld l, a
    ld h, HIGH(wTargetsArena)
    .loop:
    ldh a, [hHitLanes]
    or a
    ret z ; exit if no more hits to process

    inc l ; Target_State
    ld a, [hl] ; Target_State
    ; compute bit mask for lane in C
    ld c, 1
    and a, 3 ; lane
    jr z, .10
    .20:
    sla c
    dec a
    jr nz, .20

    .10:
    ldh a, [hHitLanes]
    and a, c ; is this lane hit?
    jr nz, .hitTarget
    dec l ; Target_Next
    ld a, l
    ldh [hPrev], a
    ld l, [hl] ; Target_Next
    jr .loop

    .hitTarget:
    ld a, c ; lane mask
    xor $ff ; invert
    ld c, a
    ldh a, [hHitLanes]
    and a, c ; mask off this lane
    ldh [hHitLanes], a

    ; turn on the sound channels
    ldh a, [hSoundStatus]
    and ~3
    ldh [hSoundStatus], a
    ; set trigger flag (bit 7 of Track_PeriodIndex) for square wave channels
    push hl
    ld hl, wTracks + Track_PeriodIndex
    set 7, [hl]
    ld hl, wTracks + Track_PeriodIndex + Track_SIZEOF
    set 7, [hl]
    pop hl

    inc l ; Target_PosY_Frac
    inc l ; Target_PosY_Int
    ld a, HIT_START_Y + (HIT_EXTENT / 2); lock to grid
    ld [hl-], a ; Target_PosY_Int
    dec l ; Target_State
    ld a, [hl-] ; Target_State
    and a, $fc ; extended duration?
    jr nz, .isHeldTarget
    ; it's a tap target
    call IncTapHitCount
    call RecoverHealth
    call IncCurrentStreak
    call MoveActiveTargetToHitList
    ld l, a ; Target_Next
    jr .loop

    .isHeldTarget:
; map duration to hold timer
    srl a
    srl a
    dec a
    or a, LOW(wHoldTimerTable)
    ld e, a
    ld d, HIGH(wHoldTimerTable)
    ld a, [de] ; timer
    inc l ; Target_State
    inc l ; Target_HoldTimer
    ld [hl-], a ; Target_HoldTimer
    dec l ; Target_Next

    call IncHoldHeadHitCount
    call MoveActiveTargetToHeldList
    ld l, a ; Target_Next
    jr .loop

; HL = pointer to Target_Next
; Returns: A = old Target_Next
; Destroys: BC
MoveActiveTargetToHitList:
    ld b, [hl] ; old Target_Next
    ld [hl], ZILCH_ITEM ; Target_Next (end of list)
    ldh a, [hHitTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hHitTargetsTail], a ; this target becomes new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hHitTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hActiveTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hActiveTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; old Target_Next
    ldh [hActiveTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

; HL = pointer to Target_Next
; Returns: A = old Target_Next
; Destroys: BC
MoveActiveTargetToMissedList:
    ld b, [hl] ; old Target_Next
    ld [hl], ZILCH_ITEM ; Target_Next (end of list)
    ldh a, [hMissedTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hMissedTargetsTail], a ; make this the new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hMissedTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hActiveTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hActiveTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; old Target_Next
    ldh [hActiveTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

; HL = pointer to Target_Next
; Returns: A = old Target_Next
; Destroys: BC
MoveActiveTargetToHeldList:
    ld b, [hl] ; old Target_Next
    ld [hl], ZILCH_ITEM ; Target_Next
    ldh a, [hHeldTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hHeldTargetsTail], a ; this target becomes new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hHeldTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hActiveTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hActiveTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; old Target_Next
    ldh [hActiveTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

; HL = pointer to Target_Next
; Returns: A = old Target_Next
; Destroys: BC
MoveHeldTargetToHitList:
    ld b, [hl] ; old Target_Next
    ld [hl], ZILCH_ITEM ; Target_Next
    ldh a, [hHitTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hHitTargetsTail], a ; this target becomes new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hHitTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hHeldTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hHeldTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; old Target_Next
    ldh [hHeldTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

; HL = pointer to Target_Next
; Returns: A = old Target_Next
; Destroys: BC
MoveHeldTargetToMissedList:
    ld b, [hl] ; old Target_Next
    ld [hl], ZILCH_ITEM ; Target_Next (end of list)
    ldh a, [hMissedTargetsTail]
    ld c, a ; save old tail
    ld a, l
    ldh [hMissedTargetsTail], a ; make this the new tail
    ld a, c ; old tail
    cp ZILCH_ITEM ; starting the list?
    jr nz, .10
    ld a, l
    ldh [hMissedTargetsHead], a ; yes. This target becomes the head
    jr .20
    .10:
    ld a, l ; this target
    ld l, c ; old tail
    ld [hl], a ; Target_Next (point old tail to this)
    ld l, a
    .20:
    ldh a, [hHeldTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .30
    ldh [hHeldTargetsTail], a ; yes. Previous becomes new tail
    .30:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .40
    ld a, b ; old Target_Next
    ldh [hHeldTargetsHead], a ; yes. Next becomes new head
    ret
    .40:
    ld l, a
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    ret

ProcessHeldTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hHeldTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    ret z ; exit if so
    .foo:
    ld l, a ; Target_Next
    inc l ; Target_State
    ld a, [hli] ; Target_State
    ; compute bit mask for lane in C
    ld c, 1
    and a, 3 ; lane
    jr z, .10
    .20:
    sla c
    dec a
    jr nz, .20
    .10:
    ldh a, [hLaneInput]
    and a, c ; is this lane still held?
    jr nz, .stillHeld

    ; no longer held - move held target to missed list
    ldh a, [hHealth]
    or a
    jr z, .30 ; player is dead, skip some of the processing

    call IncHoldBreakCount
    call DealHoldBreakDamage
    call ResetCurrentStreak
    ; turn off the square wave channels
    ldh [hSoundStatus], a
    or a, 3
    ldh [hSoundStatus], a

    .30:
    ; clear timer
    xor a
    ld [hl-], a ; Target_HoldTimer
    dec l ; Target_Next
    call MoveHeldTargetToMissedList
    jr .loop

    .stillHeld:
    ld a, [hl] ; Target_HoldTimer
    dec a
    jr z, .timerExpired
    ; not yet expired
    ld [hl-], a ; Target_HoldTimer
    ldh [hDrawHoldLength], a
    call DrawHoldTarget
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    ld l, a
    ld a, [hl] ; Target_Next
    jr .loop

    .timerExpired:
    ; hold complete
    call IncHoldCompleteCount
    call RecoverHealth
    call IncCurrentStreak
    ld a, l
    and a, ~3 ; Target_Next
    ld l, a
    call MoveHeldTargetToHitList
    jr .loop

ProcessHitTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hHitTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    ret z ; exit if so
    ld l, a ; Target_Next
    inc l ; Target_State
    ld a, [hl] ; Target_State
    and a, $3C ; counter bits (5..2)
    cp $3C
    jr z, .evaporated
    ld a, [hl] ; Target_State
    add a, 4 ; increment counter
    ld [hli], a ; Target_State
    call DrawExplodedTarget
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    ld l, a
    ld a, [hl] ; Target_Next
    jr .loop

    .evaporated:
    ; put on free list
    dec l ; Target_Next
    ld b, [hl] ; old Target_Next
    ldh a, [hFreeTargetsList] ; old head of free list
    ld [hl], a ; Target_Next
    ld a, l ; this target
    ldh [hFreeTargetsList], a ; make new head of list
    ; remove from hit targets list
    ldh a, [hHitTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .10
    ldh [hHitTargetsTail], a ; yes. Previous becomes new tail
    .10:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .20
    ld a, b ; old Target_Next
    ldh [hHitTargetsHead], a ; yes. Next becomes new head
    jr .loop
    .20:
    ld l, a ; previous
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    jr .loop

ProcessMissedTargets:
    ld a, ZILCH_ITEM
    ldh [hPrev], a
    ldh a, [hMissedTargetsHead]
    ld h, HIGH(wTargetsArena)
    .loop:
    cp ZILCH_ITEM ; end of list?
    ret z ; exit if so
    ld l, a ; Target_Next
    inc l ; Target_State
    call MoveTarget
    inc l ; Target_PosY_Frac
    inc l ; Target_PosY_Int
    ld a, [hl] ; Target_PosY_Int
    cp 160 ; fell off screen?
    jr nc, .fell_off
    ; still visible
    dec l ; Target_PosY_Frac
    dec l ; Target_State
    ; TODO: if it's a hold target, collapse the tail
    call DrawTapTarget
    ld a, l
    and a, ~3 ; Target_Next
    ldh [hPrev], a
    ld l, a
    ld a, [hl] ; Target_Next
    jr .loop

    .fell_off:
    ; put on free list
    ld a, l
    and a, ~3 ; Target_Next
    ld l, a
    ld b, [hl] ; old Target_Next
    ldh a, [hFreeTargetsList] ; old head of free list
    ld [hl], a ; Target_Next
    ld a, l ; this target
    ldh [hFreeTargetsList], a ; make new head of list
    ; remove from missed targets list
    ldh a, [hMissedTargetsTail]
    cp a, l ; removing the tail?
    ldh a, [hPrev]
    jr nz, .10
    ldh [hMissedTargetsTail], a ; yes. Previous becomes new tail
    .10:
    cp ZILCH_ITEM ; removing the head?
    jr nz, .20
    ld a, b ; old Target_Next
    ldh [hMissedTargetsHead], a ; yes. Next becomes new head
    jr .loop
    .20:
    ld l, a ; previous
    ld a, b ; old Target_Next
    ld [hl], a ; previous Target_Next = this Target_Next
    jr .loop


Prng:
    ldh a, [hRandom]
    srl a
    jr nc, .noXor
    xor $B4
    .noXor:
    ldh [hRandom], a
    ret

; Destroys: A, B
RandomDecision:
    ldh a, [hGameBehaviorState0]
    and GAME_BEHAVIOR_STATE0_MASK__RANDOM_MODE
    cp GAME_BEHAVIOR_STATE0__RANDOM_MODE__FULL
    jr nz, .skipStir
    ldh a, [hRandom]
    ld b, a
    ldh a, [rDIV]
    xor b
    ld b, a
    ldh a, [rDIV]
    rrc a
    xor a, b
    ldh [hRandom], a
    .skipStir:
    jr Prng


; --- Song Selection Screen ---

MainFunc_SongSelectionInit:
    xor a
    ldh [hCurrentSong], a

    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ; TODO: use own tiles for this screen
    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap

    ld hl, SongSelectionScreenTilemap
    call WriteVramStrings

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    call PrintCurrentSongSelectionIndicator

    ld a, 11
    ldh [hMainState], a ; song selection
    jp TurnOnLCD

BeginCurrentSongSelectionIndicatorVramString:
    ld d, $99
    ldh a, [hCurrentSong]
    sla a
    sla a
    sla a
    sla a
    sla a
    sla a
    add a, $01
    ld e, a
    ld c, 1
    jp BeginVramString

PrintCurrentSongSelectionIndicator:
    call BeginCurrentSongSelectionIndicatorVramString
    ld a, $26 ; '*'
    ld [hli], a
    jp EndVramString

EraseCurrentSongIndicator:
    call BeginCurrentSongSelectionIndicatorVramString
    ld a, 0 ; space
    ld [hli], a
    jp EndVramString

MainFunc_SongSelection:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr nz, .chooseSong
    bit PADB_A, a
    jr nz, .chooseSong
    bit PADB_SELECT, a
    jr nz, .nextSong
    bit PADB_DOWN, a
    jr nz, .nextSong
    bit PADB_UP, a
    jr nz, .previousSong
    ret z

    .chooseSong:
;    ld a, 1 ; playtest settings init
    ld a, 12 ; difficulty selection init
    ldh [hMainState], a
    jp TurnOffLCD

    .previousSong:
    ld a, 0
    call PlayTrack0SFX
    call EraseCurrentSongIndicator
    ldh a, [hCurrentSong]
    or a
    jr nz, .noWrapToLastSong
    ld a, SONG_COUNT
    .noWrapToLastSong:
    dec a
    ldh [hCurrentSong], a
    jp PrintCurrentSongSelectionIndicator

    .nextSong:
    ld a, 0
    call PlayTrack0SFX
    call EraseCurrentSongIndicator
    ldh a, [hCurrentSong]
    inc a
    cp SONG_COUNT
    jr c, .noWrapToFirstSong
    xor a
    .noWrapToFirstSong:
    ldh [hCurrentSong], a
    jp PrintCurrentSongSelectionIndicator


; --- Song Session Results Screen ---

MainFunc_SongSessionResultsInit:
    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ; TODO: use own tiles for this screen
    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap

    ld hl, SongSessionResultsScreenTilemap
    call WriteVramStrings

    call ComputeSongSessionAccuracy
    call PrintSongSessionResults

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 9
    ldh [hMainState], a ; song session results
    jp TurnOnLCD

MainFunc_SongSessionResults:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    ret z ; start not pressed
    ; start pressed
    ld a, 10
    ldh [hMainState], a ; song selection init
    jp TurnOffLCD

; Returns: DE = hit_notes (tap_hit_count + hold_complete_count)
ComputeHitNotes:
    ldh a, [hTapHitCount]
    ld e, a
    ldh a, [hHoldCompleteCount]
    add a, e
    ld e, a
    ldh a, [hTapHitCount+1]
    ld d, a
    ldh a, [hHoldCompleteCount+1]
    adc a, d
    ld d, a
    ret

PrintSongSessionHitNotesResult:
    ld de, $988E
    ld c, 5
    call BeginVramString
    call ComputeHitNotes
    call PrintU16Dec_DE
    jp EndVramString

PrintSongSessionMissesResult:
    ld de, $98CE
    ld c, 5
    call BeginVramString
    ; misses = tap_miss_count + hold_head_miss_count + hold_break_count
    ldh a, [hTapMissCount]
    ld e, a
    ldh a, [hHoldHeadMissCount]
    add a, e
    ld e, a
    ldh a, [hTapMissCount+1]
    ld d, a
    ldh a, [hHoldHeadMissCount+1]
    adc a, d
    ld d, a
    ldh a, [hHoldBreakCount]
    add a, e
    ld e, a
    ldh a, [hHoldBreakCount+1]
    adc a, d
    ld d, a
    call PrintU16Dec_DE
    jp EndVramString

PrintSongSessionMisPressesResult:
    ld de, $990E
    ld c, 5
    call BeginVramString
    ldh a, [hMisPressCount]
    ld e, a
    ldh a, [hMisPressCount+1]
    ld d, a
    call PrintU16Dec_DE
    jp EndVramString

PrintSongSessionMaxStreakResult:
    ld de, $994E
    ld c, 5
    call BeginVramString
    ldh a, [hMaxStreak]
    ld e, a
    ldh a, [hMaxStreak+1]
    ld d, a
    call PrintU16Dec_DE
    jp EndVramString

ComputeSongSessionAccuracy:
    call ComputeHitNotes
    ld b, d
    ld c, e
    ld a, 100
    call MulU16xU8 ; hit_notes * 100 -> E:HL
    ld a, l
    ldh [hNum24+0], a
    ld a, h
    ldh [hNum24+1], a
    ld a, e
    ldh [hNum24+2], a
    ldh a, [hSpawnedTargetsCount]
    ld c, a
    ldh a, [hSpawnedTargetsCount+1]
    ld b, a
    call DivU24ByU16 ; (hit_notes * 100) / spawned_targets_count -> HL
    ld a, l
    ldh [hComputedSongSessionAccuracy], a
    ret

PrintSongSessionAccuracyResult:
    ld de, $998C
    ld c, 3
    call BeginVramString
    ldh a, [hComputedSongSessionAccuracy]
    call PrintU8Dec_A
    jp EndVramString

PrintSongSessionRankResult:
    ld de, $99EC
    ld c, 1
    call BeginVramString
    ldh a, [hComputedSongSessionAccuracy]
    cp 98
    jr nc, .rankS
    cp 92
    jr nc, .rankA
    cp 85
    jr nc, .rankB
    cp 75
    jr nc, .rankC
    ; rank D
    ld a, $0E
    jr .print
    .rankS:
    ld a, $1D
    jr .print
    .rankA:
    ld a, $0B
    jr .print
    .rankB:
    ld a, $0C
    jr .print
    .rankC:
    ld a, $0D
    .print:
    ld [hli], a
    jp EndVramString

PrintSongSessionResults:
    call PrintSongSessionHitNotesResult
    call PrintSongSessionMissesResult
    call PrintSongSessionMisPressesResult
    call PrintSongSessionMaxStreakResult
    call PrintSongSessionAccuracyResult
    call PrintSongSessionRankResult
    jp FlushVramBuffer


; --- Game over screen ---

MainFunc_GameOverInit:
    ; palettes: from bright to dimmed
    ld  a, %11100100
    ldh [hShadowBGP], a
    ldh [hShadowOBP0], a

    ; TODO: use own tiles for this screen
    ld de, PlaytestSettingsScreenTiles
    ld hl, $8000
    ld bc, PlaytestSettingsScreenTilesEnd - PlaytestSettingsScreenTiles
    call CopyData

    call ClearTilemap
    ld hl, GameOverScreenTilemap
    call WriteVramStrings

    call HideAllSprites

    ld hl, silent_song
    call StartSong

    ld a, 18
    ldh [hMainState], a ; game over
    jp TurnOnLCD

MainFunc_GameOver:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    ret z ; start not pressed
    ; start pressed
    ld a, 10 ; song selection init
    ldh [hMainState], a
    jp TurnOffLCD


SECTION "Multiplication", ROM0
; ------------------------------------------------------------
; MulU16xU8
;   Unsigned multiply: (BC * A) -> DE:HL
;
; IN:
;   BC = multiplicand (u16)
;   A  = multiplier   (u8)
;
; OUT:
;   E:HL = 24-bit product
;
; CLOBBERS:
;   AF, BC, DE, HL
; ------------------------------------------------------------
MulU16xU8:
    ldh [hMulA], a

    xor a
    ld e, a
    ld h, a
    ld l, a
    ldh [hMulHi], a

    ld a, 8
.loop:
    ldh [hMulCnt], a
    ; multiplier >>= 1, old bit0 -> carry
    ldh a, [hMulA]
    srl a
    ldh [hMulA], a
    jr nc, .skip_add

    add hl, bc

    ; E += hMulHi + carry
    ldh a, [hMulHi]
    ld d, a
    ld a, e
    adc a, d
    ld e, a

.skip_add:
    ; multiplicand <<= 1 across (hMulHi:BC)
    sla c
    rl  b
    ldh a, [hMulHi]
    rl  a
    ldh [hMulHi], a

    ; counter--
    ldh a, [hMulCnt]
    dec a
    jr nz, .loop
    ret


SECTION "Division", ROM0

; ------------------------------------------------------------
; DivU24ByU16
;   Unsigned divide: hNum24 / BC
; IN:
;   hNum24 = 24-bit numerator (little-endian)
;   BC     = 16-bit divisor (BC != 0)
; OUT:
;   HL     = 16-bit quotient
;   hRem16 = 16-bit remainder (optional use)
; CLOBBERS:
;   AF, BC, DE, HL
; ------------------------------------------------------------
DivU24ByU16:
    xor a
    ld h, a
    ld l, a              ; quotient = 0

    ldh [hRem16+0], a
    ldh [hRem16+1], a     ; remainder = 0

    ld d, 24
.loop:
    ; Shift remainder left by 1
    ldh a, [hRem16+0]
    sla a
    ldh [hRem16+0], a
    ldh a, [hRem16+1]
    rl a
    ld [hRem16+1], a

    ; Shift numerator left by 1, MSB goes into carry
    ; (hNum24 <<= 1), carry after last RL is old bit23
    ldh a, [hNum24+0]
    sla a
    ldh [hNum24+0], a
    ldh a, [hNum24+1]
    rl  a
    ldh [hNum24+1], a
    ldh a, [hNum24+2]
    rl  a
    ldh [hNum24+2], a     ; carry now holds old bit23

    ; Bring that carry bit into remainder LSB
    ldh a, [hRem16+0]
    adc a, 0             ; add carry
    ldh [hRem16+0], a
    ldh a, [hRem16+1]
    adc a, 0
    ldh [hRem16+1], a

    ; quotient <<= 1
    add hl, hl

    ; if remainder >= divisor: remainder -= divisor; quotient |= 1
    ldh a, [hRem16+1]
    cp b
    jr c, .no_sub
    jr nz, .do_sub
    ldh a, [hRem16+0]
    cp c
    jr c, .no_sub

.do_sub:
    ; remainder -= BC
    ldh a, [hRem16+0]
    sub c
    ldh [hRem16+0], a
    ldh a, [hRem16+1]
    sbc b
    ldh [hRem16+1], a
    inc l                ; set low bit of quotient

.no_sub:
    dec d
    jr nz, .loop
    ret


; ============================================================
; Decimal printing (GBZ80 / RGBDS)
; - Output pointer: HL (writes tile IDs, inc HL)
; - Digits contiguous: '0' = $01 ... '9' = $0A
; - Space tile: $00
; ============================================================

DEF DIGIT_TILE_0 EQU $01
DEF SPACE_TILE   EQU $00

; -------------------------
; ROM tables (powers of 10)
; -------------------------
SECTION "Decimal tables", ROM0

; 10^4 .. 10^0 (16-bit)
Pow10_16:
    dw 10000
    dw 1000
    dw 100
    dw 10
    dw 1

; -------------------------
; Output helpers
; -------------------------
SECTION "Decimal print", ROM0

; ============================================================
; PrintU16Dec_DE
;   DE = unsigned 16-bit value (0..65535)
;   HL = output pointer
; Clobbers: AF,BC,DE,HL
; ============================================================
PrintU16Dec_DE:
    ; Store remainder
    ld a, e
    ldh [hU16+0], a
    ld a, d
    ldh [hU16+1], a

    ld de, Pow10_16
    ld b, 5              ; number of places (10^4..10^0)

    xor a
    ldh [hPrintedAny], a

.u16_place_loop:
    push hl ; save output pointer
    ; Load power into H:L (table is little-endian)
    ld a, [de]           ; lo
    inc de
    ld l, a
    ld a, [de]           ; hi
    inc de
    ld h, a              ; HL = power

    push de ; save Pow10_16 pointer

    ; Load current value into D:E
    ldh a, [hU16+0]
    ld e, a
    ldh a, [hU16+1]
    ld d, a

    xor a

.u16_sub_loop:
    ldh [hDigit], a
    ; if (DE < HL) break
    ld a, d
    cp h
    jr c, .u16_digit_done
    jr nz, .u16_do_sub
    ld a, e
    cp l
    jr c, .u16_digit_done

.u16_do_sub:
    ; DE -= HL
    ld a, e
    sub l
    ld e, a
    ld a, d
    sbc h
    ld d, a

    ; digit++
    ldh a, [hDigit]
    inc a
    jr .u16_sub_loop

.u16_digit_done:
    ; Store remainder back
    ld a, e
    ldh [hU16+0], a
    ld a, d
    ldh [hU16+1], a

    pop de ; restore Pow10_16 pointer
    pop hl ; restore output pointer

    ; ---- Fixed width: leading SPACES until first non-zero digit,
    ;      but always print at least one digit on last place.
    ldh a, [hDigit]
    or a
    jr nz, .u16_fixed_print_digit
    ldh a, [hPrintedAny]
    or a
    jr nz, .u16_fixed_print_digit
    ld a, b
    cp 1
    jr z, .u16_fixed_print_digit

    ; leading space
    ld a, SPACE_TILE
    ld [hli], a
    jr .u16_next_place

.u16_fixed_print_digit:
    ld a, 1
    ldh [hPrintedAny], a
    ldh a, [hDigit]
    add a, DIGIT_TILE_0
    ld [hli], a

.u16_next_place:
    dec b
    jr nz, .u16_place_loop
    ret


; ============================================================
; PrintU8Dec_A
;   A  = unsigned value (0..100)
;   HL = output pointer
; Prints 3 chars, right-aligned, leading spaces
;
; Example:
;   0   -> "  0"
;   5   -> "  5"
;   42  -> " 42"
;   100 -> "100"
;
; Clobbers: AF,BC,D
; ============================================================
PrintU8Dec_A:
    ld b, a          ; B = remainder
    xor a
    ldh [hPrintedAny], a

    ld c, 100
    call .PrintDigitU8
    ld c, 10
    call .PrintDigitU8
    ld c, 1
    ; fall through

; ------------------------------------------------------------
; .PrintDigitU8
;   B = remainder
;   C = place value (100, 10, or 1)
; ------------------------------------------------------------
.PrintDigitU8:
    ld d, 0            ; D = digit = 0

.sub_loop:
    ld a, b
    sub c
    jr c, .done
    ld b, a
    inc d           ; digit++
    jr .sub_loop

.done:
    ; D = digit
    ; B = new remainder

    ; decide space vs digit
    ld a, d
    or a
    jr nz, .print_digit
    ld a, [hPrintedAny]
    or a
    jr nz, .print_digit
    ld a, c
    bit 0, c
    jr nz, .print_digit   ; always print last digit

    ; leading space
    ld a, SPACE_TILE
    ld [hli], a
    ret

.print_digit:
    ld a, 1
    ld [hPrintedAny], a
    ld a, d
    add a, DIGIT_TILE_0
    ld [hli], a
    ret


SECTION "Tile data", ROM0

PlaytestSettingsScreenTiles:
incbin "playtestsettingsfont.bin"
PlaytestSettingsScreenTilesEnd:

GameTiles:
incbin "gamescreentiles.bin"
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
incbin "targetsprites.bin"
incbin "explosionsprites.bin"
incbin "progressbartiles.bin"
incbin "hilitehitzonetiles.bin"
incbin "misstiles.bin"
incbin "healthbartiles.bin"
GameTilesEnd:

SECTION "VRAM strings", ROM0

GameOverScreenTilemap:
db $99, $05, 9, "GAME OVER"
db 0

PauseScreenTilemap:
db $98, $C6, 6, "RESUME"
db $99, $06, 7, "RESTART"
db $99, $46, 4, "QUIT"
db 0

SongSelectionScreenTilemap:
db $98, $83, 12, "CHOOSE SONG:"
db $99, $03, 7, "WHISKEY"
db $99, $43, 10, "MAPLE LEAF"
db 0

DifficultySelectionScreenTilemap:
db $98, $65, 11, "DIFFICULTY:"
db $98, $c6, 8, "BEGINNER"
db $99, $06, 4, "EASY"
db $99, $46, 6, "NORMAL"
db $99, $86, 4, "HARD"
db $99, $c6, 6, "EXPERT"
db 0

PlaytestSettingsScreenTilemap:
db $98, $42, 14, "INTENSITY MAX:"
db $98, $82, 11, "HOLD NOTES:"
db $98, $C2, 8,  "  STYLE:"
db $99, $02, 13, "RANDOM NOTES:"
db $99, $42, 8,  "  STYLE:"
;db $99, $82, 14, "MAX CUE NOTES:"
db $99, $E5, 10, "PUSH START"
db $9A, $06, 8,  "TO PLAY!"
db 0

SongSessionResultsScreenTilemap:
db $98, $26, 7, "RESULTS"
db $98, $82, 9, "HIT NOTES"
db $98, $C2, 6, "MISSES"
db $99, $02, 11, "MIS-PRESSES"
db $99, $42, 10, "MAX STREAK"
db $99, $82, 8, "ACCURACY"
db $99, $8F, 1, "%"
db $99, $E6, 4, "RANK"
db 0

GameScreenTilemap:
incbin "gamescreentilemap.bin"
db 0

SECTION "Hit cue streams", ROM0

include "whiskeycues.inc"
include "maplecues.inc"

SECTION "Song data", ROM0

INCLUDE "whiskeysong.s"
INCLUDE "maplesong.s"
INCLUDE "silentsong.s"

SECTION "SFX data", ROM0

SFXPatternTable:
dw SFX0Pattern
dw SFX1Pattern
dw SFX2Pattern
dw SFX3Pattern

SFX0Pattern:
db $02 ; row count
db $01 ; row status
db $b0 ; instrument 0
db 30 ; period index
SFX1Pattern:
db $02 ; row count
db $01 ; row status
db $b1 ; instrument 1
db 20 ; period index
SFX2Pattern:
db $02 ; row count
db $01 ; row status
db $b2 ; instrument 2
db 19 ; period index
SFX3Pattern:
db $10 ; row count
db $11 ; row status
db $b3 ; instrument 3
db 30  ; period index
db $d8 ; set volume
db 30  ; period index
db $11 ; row status
db $d4 ; set volume
db 30  ; period index
db $d2 ; set volume
db 30  ; period index

SFXInstrumentTable:
dw .env0
db $00,$02,$20,$18,$00,$00 ; 0
dw .env0
db $00,$01,$20,$68,$00,$00 ; 1
dw .env0
db $00,$04,$cf,$48,$00,$00 ; 2
dw .env1
db $00,$02,$18,$68,$00,$00 ; 3

.env0:
db $F0
db $10,$00,$00
db $FF,$FF
.env1:
db $F0
db $04,$00,$00
db $FF,$FF

SECTION "Song descriptors", ROM0

SongDescriptors:
dw whiskey_cues, whiskey_song
dw maple_cues, maple_song
