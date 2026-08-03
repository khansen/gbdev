INCLUDE "hardware.inc"
INCLUDE "sound-engine.inc"

NEWCHARMAP ui
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
CHARMAP "'", $2A

setcharmap ui

def MAIN_STATE_ROOT_MENU equ 0
def MAIN_STATE_PLAY_INIT equ 1
def MAIN_STATE_PLAY equ 2
def MAIN_STATE_SINGLES_MENU_INIT equ 3
def MAIN_STATE_PAUSE equ 4
def MAIN_STATE_SINGLES_MENU equ 5
def MAIN_STATE_ROOT_MENU_INIT equ 6

def PLAYBACK_MODE_ALBUM equ 0
def PLAYBACK_MODE_SHUFFLE equ 1
def PLAYBACK_MODE_SINGLES equ 2

def ROOT_OPTION_ALBUM equ 0
def ROOT_OPTION_SHUFFLE equ 1
def ROOT_OPTION_SINGLES equ 2
def ROOT_OPTION_COUNT equ 3

def PAUSE_OPTION_RESUME equ 0
def PAUSE_OPTION_RESTART equ 1
def PAUSE_OPTION_PREV equ 2
def PAUSE_OPTION_NEXT equ 3
def PAUSE_OPTION_QUIT equ 4
def PAUSE_OPTION_COUNT equ 5

def TILE_SPACE equ $00
def TILE_DIGIT_0 equ $01
def TILE_CURSOR equ $26
def WINDOW_X_LEFT equ 7
def WINDOW_Y_HIDDEN equ 144
def WINDOW_Y_PAUSE equ 88
def MENU_FIRST_SONG_ROW equ 4
def MENU_CURSOR_COL equ 1
def MENU_TITLE_COL equ 3
def MENU_PAGE_INDICATOR_ADDR equ $9a24
def ALBUM_SONG_INDICATOR_ADDR equ $9a24
def CHANNEL_BUTTON_ICON_TOP_ADDR equ $98c4
def CHANNEL_BUTTON_ICON_BOTTOM_ADDR equ CHANNEL_BUTTON_ICON_TOP_ADDR + 32
def CHANNEL_INDICATOR_TOP_ADDR equ $9904
def CHANNEL_INDICATOR_BOTTOM_ADDR equ CHANNEL_INDICATOR_TOP_ADDR + 32
def CHANNEL_INDICATOR_WIDTH equ 11
def TILE_CHANNEL_TOP_BASE equ $2b
def TILE_CHANNEL_BOTTOM_BASE equ TILE_CHANNEL_TOP_BASE + 1
def TILE_BUTTON_TOP_BASE equ TILE_CHANNEL_TOP_BASE + 32
def TILE_BUTTON_BOTTOM_BASE equ TILE_BUTTON_TOP_BASE + 1
def TILE_MUTE_TOP_BASE equ TILE_BUTTON_TOP_BASE + 16
def TILE_MUTE_BOTTOM_BASE equ TILE_MUTE_TOP_BASE + 1
def MASTER_VOL_LABEL_ADDR equ $99e2
def MASTER_VOL_VALUE_ADDR equ MASTER_VOL_LABEL_ADDR + 12
def MENU_CHANGE_SFX equ 1
def MENU_SFX_OUTPUT_MASK equ $11
def MENU_SFX_FRAME_COUNT equ 14
def ROOT_TITLE_ADDR equ $9800 + 4 * 32 + 2
def ROOT_HEADING_ADDR equ $9800 + 6 * 32 + 2
def ROOT_CURSOR_COL equ 2
def ROOT_OPTION_TEXT_COL equ 4
def ROOT_OPTION_ALBUM_ROW equ 9
def ROOT_OPTION_SHUFFLE_ROW equ 11
def ROOT_OPTION_SINGLES_ROW equ 13
def PAUSE_HEADING_ADDR equ $9c02
def PAUSE_CURSOR_COL equ 4
def PAUSE_OPTION_TEXT_COL equ 6

EXPORT JumpTable

SECTION "Catalog", ROM0

INCLUDE "catalog.inc"

assert SONG_COUNT <= 99

SECTION "Runtime HRAM", HRAM[$ff80]

hButtonsHeld: db
hButtonsPressed: db
hProcessingVBlank: db
hVramBufferOffset: db
hShadowLCDC: db
hWindowX: db
hWindowY: db
hMainState: db
hCurrentRootMenuItem: db
hPlaybackMode: db
hCurrentSong: db
hCurrentMenuPage: db
hMenuPageFirstSong: db
hCurrentPauseMenuItem: db
hActiveSongBank: db
hPlaybackActive: db
hSelectedSongDuration: dw
hAutoAdvanceFrames: dw
hSelectedSongPtr: dw
hSelectedWavePtr: dw
hSelectedVisualizerBank: db
hSelectedVisualizerInitPtr: dw
hSelectedVisualizerUpdatePtr: dw
hSelectedVisualizerTeardownPtr: dw
hShufflePosition: db
hShuffleRng: db
hMenuDrawSong: db
hMenuDrawRowsRemaining: db
hMenuDrawRowAddr: dw
hDisplayedMasterVol: db
hPauseMasterVol: db
hMenuSfxFrames: db
hPendingMenuChangeSfx: db

SECTION "Runtime WRAM", WRAM0

wVramBuffer:
    ds 128
wShuffleBag:
    ds SONG_COUNT

SECTION "ROM Bank $000", ROM0[$0]

RST_00:
    jp Begin

ds $08-@, $00

RST_08:
    jp Begin

ds $28-@, $ff

SECTION "RST $28", ROM0[$28]

JumpTable:
    add a
    pop hl
    ld e, a
    ld d, 0
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    push de
    pop hl
    jp hl

ds $40-@, $ff

VBlankInterrupt:
    jp VBlankInterruptHandler

ds $48-@, $ff

LCDCInterrupt:
    jp StubInterruptHandler

ds $50-@, $ff

TimerOverflowInterrupt:
    jp StubInterruptHandler

ds $58-@, $ff

SerialTransferCompleteInterrupt:
    jp StubInterruptHandler

ds $100-@, $ff

SECTION "Header", ROM0[$100]

Boot:
    nop
    jp Begin

ds $150-@, 0

SECTION "Main", ROM0[$150]

Begin:
    jp Begin2

StubInterruptHandler:
    reti

VBlankInterruptHandler:
    push af
    push bc
    push de
    push hl

    ldh a, [hProcessingVBlank]
    or a
    jr nz, .skip
    inc a
    ldh [hProcessingVBlank], a

    ; Flush queued tilemap updates before sound/state work consumes VBlank time.
    call FlushVramBuffer

    ; Hardware shadows are applied from VBlank. In particular, TurnOffLCD only
    ; clears hShadowLCDC; the actual rLCDC write happens here.
    ldh a, [hWindowX]
    ldh [rWX], a
    ldh a, [hWindowY]
    ldh [rWY], a
    ldh a, [hShadowLCDC]
    ldh [rLCDC], a

    call PollInput
    call UpdateSoundFrame
    call GoMainFunction

    ld hl, hProcessingVBlank
    dec [hl]

.skip:
    pop hl
    pop de
    pop bc
    pop af
    reti

Begin2:
    di
    ld sp, $fffe

    call WaitVBlank
    xor a
    ldh [rLCDC], a

    call ClearWRAM
    ld sp, $d000
    call ClearHRAM
    call ClearVRAM
    call LoadFont
    call InitSoundHardware
    call StopSound
    call InitMenuState
    call DrawRootMenuScreen
    call InitLCD

    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

.forever:
    halt
    jr .forever

WaitVBlank:
    ldh a, [rLY]
    cp $94
    jr nz, WaitVBlank
    ret

ClearWRAM:
    xor a
    ld hl, $dfff
    ld c, $20
    ld b, $00
.loop:
    ld [hl-], a
    dec b
    jr nz, .loop
    dec c
    jr nz, .loop
    ret

ClearHRAM:
    xor a
    ld hl, $fffe
    ld b, $7f
.loop:
    ld [hl-], a
    dec b
    jr nz, .loop
    ret

ClearVRAM:
    xor a
    ld hl, $9fff
    ld c, $20
    ld b, $00
.loop:
    ld [hl-], a
    dec b
    jr nz, .loop
    dec c
    jr nz, .loop
    ret

LoadFont:
    ld de, FontTiles
    ld hl, $8000
    ld bc, UITilesEnd - FontTiles
    jp CopyData

CopyData:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, CopyData
    ret

InitSoundHardware:
    ld a, $80
    ldh [rAUDENA], a
    ld a, $77
    ldh [rAUDVOL], a
    ret

InitLCD:
    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    ld a, %11100100
    ldh [rBGP], a
    call HideWindow
    jp TurnOnLCD

TurnOnLCD:
    ld a, LCDCF_ON | LCDCF_WINON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_WIN9C00
    ldh [hShadowLCDC], a
    ; LCD-on is safe at any time and starts VBlank delivery.
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

HideWindow:
    ld a, WINDOW_X_LEFT
    ldh [hWindowX], a
    ld a, WINDOW_Y_HIDDEN
    ldh [hWindowY], a
    ret

ShowPauseWindow:
    ld a, WINDOW_X_LEFT
    ldh [hWindowX], a
    ld a, WINDOW_Y_PAUSE
    ldh [hWindowY], a
    ret

InitMenuState:
    xor a
    ldh [hPlaybackActive], a
    ldh [hCurrentRootMenuItem], a
    ldh [hCurrentSong], a
    ldh [hCurrentMenuPage], a
    ldh [hMenuPageFirstSong], a
    ldh [hCurrentPauseMenuItem], a
    ldh [hMainState], a
    ld a, PLAYBACK_MODE_SINGLES
    ldh [hPlaybackMode], a
    ld a, 1
    ldh [hShuffleRng], a
    ret

PollInput:
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0f
    swap a
    ld b, a
    ld a, P1F_GET_BTN
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0f
    or b
    ld b, a
    ldh a, [hButtonsHeld]
    xor b
    and b
    ldh [hButtonsPressed], a
    ld a, b
    ldh [hButtonsHeld], a
    ld a, P1F_GET_NONE
    ldh [rP1], a
    ret

; Program main function, called each frame in VBlank handler.
GoMainFunction:
    ldh a, [hMainState]
    rst JumpTable
dw MainFunc_RootMenu
dw MainFunc_PlayInit
dw MainFunc_Play
dw MainFunc_SinglesMenuInit
dw MainFunc_Pause
dw MainFunc_SinglesMenu
dw MainFunc_RootMenuInit

MainFunc_RootMenu:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jp nz, SelectRootMenuOption
    bit PADB_A, a
    jp nz, SelectRootMenuOption
    bit PADB_SELECT, a
    jp nz, MoveToNextRootMenuOption
    bit PADB_DOWN, a
    jp nz, MoveToNextRootMenuOption
    bit PADB_UP, a
    jp nz, MoveToPreviousRootMenuOption
    ret

MainFunc_SinglesMenu:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jp nz, StartCurrentSong
    bit PADB_A, a
    jp nz, StartCurrentSong
    bit PADB_SELECT, a
    jp nz, MoveToNextSong
    bit PADB_DOWN, a
    jp nz, MoveToNextSong
    bit PADB_UP, a
    jp nz, MoveToPreviousSong
    bit PADB_RIGHT, a
    jp nz, MoveToNextMenuPage
    bit PADB_LEFT, a
    jp nz, MoveToPreviousMenuPage
    bit PADB_B, a
    jp nz, ReturnToRootMenu
    ret

MainFunc_Play:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jp nz, EnterPauseMode
    bit PADB_A, a
    call nz, IncreaseMasterVolume
    ldh a, [hButtonsPressed]
    bit PADB_B, a
    call nz, DecreaseMasterVolume
    ldh a, [hButtonsPressed]
    bit PADB_UP, a
    call nz, ToggleChannel1
    ldh a, [hButtonsPressed]
    bit PADB_DOWN, a
    call nz, ToggleChannel2
    ldh a, [hButtonsPressed]
    bit PADB_LEFT, a
    call nz, ToggleChannel3
    ldh a, [hButtonsPressed]
    bit PADB_RIGHT, a
    call nz, ToggleChannel4
    jp UpdatePlayModeFrame

UpdatePlayModeFrame:
    call CallSelectedVisualizerUpdate
    call PrintMasterVolumeValue
    jp UpdateAutoAdvance

UpdateSoundFrame:
    ldh a, [hPlaybackActive]
    or a
    jr z, .menu_sfx
    ; Song data lives in the active ROMX bank. Restore that bank every frame
    ; before the shared engine follows its cached song-data pointers.
    ldh a, [hActiveSongBank]
    call SwitchRomBank
    call UpdateSound
    jp UpdateMenuSfxOutput
.menu_sfx:
    ldh a, [hMenuSfxFrames]
    or a
    ret z
    call UpdateSound
    jp UpdateMenuSfxOutput

UpdateMenuSfxOutput:
    ldh a, [hMenuSfxFrames]
    or a
    ret z
    dec a
    ldh [hMenuSfxFrames], a
    ret nz
    ldh a, [hMainState]
    cp MAIN_STATE_PAUSE
    jp z, SilenceSoundOutput
    jp StopSound

UpdateAutoAdvance:
    ldh a, [hPlaybackMode]
    cp PLAYBACK_MODE_SINGLES
    ret z

    ; ALBUM and SHUFFLE advance by a per-song 16-bit frame countdown. There is
    ; no reliable end-of-song callback because the converted order data loops.
    ld hl, hAutoAdvanceFrames
    ld a, [hli]
    ld b, a
    ld a, [hl]
    or b
    ret z

    ld a, b
    or a
    jr nz, .dec_low
    dec [hl]
    dec hl
    ld [hl], $ff
    jr .check_done
.dec_low:
    dec hl
    dec [hl]
.check_done:
    ld a, [hli]
    ld b, a
    ld a, [hl]
    or b
    ret nz

    call CallSelectedVisualizerTeardown
    call SelectNextPlaybackSong
    jp StartCurrentSong

SelectNextPlaybackSong:
    ldh a, [hPlaybackMode]
    cp PLAYBACK_MODE_SHUFFLE
    jp z, SelectNextShuffleSong

SelectNextSequentialSong:
    ldh a, [hCurrentSong]
    inc a
    cp SONG_COUNT
    jr c, .store
    xor a
.store:
    ldh [hCurrentSong], a
    ret

SelectPreviousPlaybackSong:
    ldh a, [hPlaybackMode]
    cp PLAYBACK_MODE_SHUFFLE
    jp z, SelectPreviousShuffleSong

SelectPreviousSequentialSong:
    ldh a, [hCurrentSong]
    or a
    jr nz, .no_wrap
    ld a, SONG_COUNT
.no_wrap:
    dec a
    ldh [hCurrentSong], a
    ret

SelectNextShuffleSong:
    ldh a, [hShufflePosition]
    inc a
    cp SONG_COUNT
    jr c, .store
    call FillShuffleBag
    xor a
.store:
    ldh [hShufflePosition], a
    jp LoadCurrentSongFromShufflePosition

SelectPreviousShuffleSong:
    ldh a, [hShufflePosition]
    or a
    jr nz, .no_wrap
    ld a, SONG_COUNT
.no_wrap:
    dec a
    ldh [hShufflePosition], a
    jp LoadCurrentSongFromShufflePosition

LoadCurrentSongFromShufflePosition:
    ld hl, wShuffleBag
    ldh a, [hShufflePosition]
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    ldh [hCurrentSong], a
    ret

FillShuffleBag:
    ldh a, [rDIV]
    ld b, a
    ldh a, [hButtonsHeld]
    xor b
    jr nz, .store_seed
    ld a, $5d
.store_seed:
    ldh [hShuffleRng], a
    ld b, 0
.fill_loop:
    ld a, b
    cp SONG_COUNT
    jr z, .avoid_immediate_repeat
.candidate:
    push bc
    call RandomSongIndex
    ld e, a
    pop bc
    ld hl, wShuffleBag
    ld c, b
.check_loop:
    ld a, c
    or a
    jr z, .store_candidate
    ld a, [hli]
    cp e
    jr z, .candidate
    dec c
    jr .check_loop
.store_candidate:
    ld a, e
    ld [hl], a
    inc b
    jr .fill_loop
.avoid_immediate_repeat:
    ld a, SONG_COUNT
    cp 2
    ret c
    ld hl, wShuffleBag
    ld a, [hl]
    ld b, a
    ldh a, [hCurrentSong]
    cp b
    ret nz
    ld a, [hli]
    ld b, a
    ld a, [hl]
    dec hl
    ld [hli], a
    ld [hl], b
    ret

RandomSongIndex:
    call Random8
.reduce:
    cp SONG_COUNT
    ret c
    sub SONG_COUNT
    jr .reduce

Random8:
    ldh a, [hShuffleRng]
    ld b, a
    ldh a, [rDIV]
    add b
    rlca
    xor b
    xor $a7
    ldh [hShuffleRng], a
    ret

MainFunc_Pause:
    ldh a, [hButtonsPressed]
    bit PADB_START, a
    jr nz, .commit
    bit PADB_A, a
    jr nz, .commit
    bit PADB_B, a
    jp nz, ResumeCurrentSong
    bit PADB_SELECT, a
    jp nz, MoveToNextPauseOption
    bit PADB_DOWN, a
    jp nz, MoveToNextPauseOption
    bit PADB_UP, a
    jp nz, MoveToPreviousPauseOption
    ret

.commit:
    ldh a, [hCurrentPauseMenuItem]
    cp PAUSE_OPTION_RESUME
    jp z, ResumeCurrentSong
    cp PAUSE_OPTION_RESTART
    jp z, RestartCurrentSong
    cp PAUSE_OPTION_PREV
    jp z, StartPreviousSongFromPause
    cp PAUSE_OPTION_NEXT
    jp z, StartNextSongFromPause
    jp QuitToMenu

SelectRootMenuOption:
    ldh a, [hCurrentRootMenuItem]
    cp ROOT_OPTION_ALBUM
    jp z, StartAlbumMode
    cp ROOT_OPTION_SHUFFLE
    jp z, StartShuffleMode
    jp EnterSinglesMenu

StartAlbumMode:
    ld a, PLAYBACK_MODE_ALBUM
    ldh [hPlaybackMode], a
    xor a
    ldh [hCurrentSong], a
    jp StartCurrentSong

StartShuffleMode:
    ld a, PLAYBACK_MODE_SHUFFLE
    ldh [hPlaybackMode], a
    ld a, $ff
    ldh [hCurrentSong], a
    call FillShuffleBag
    xor a
    ldh [hShufflePosition], a
    call LoadCurrentSongFromShufflePosition
    jp StartCurrentSong

EnterSinglesMenu:
    ld a, PLAYBACK_MODE_SINGLES
    ldh [hPlaybackMode], a
    ; Entering SINGLES from the root menu starts at the top. Returning from a
    ; song keeps hCurrentSong and goes through MainFunc_SinglesMenuInit instead.
    xor a
    ldh [hCurrentSong], a
    ldh [hCurrentMenuPage], a
    ldh [hMenuPageFirstSong], a
    call HideWindow
    call TurnOffLCD
    ld a, MAIN_STATE_SINGLES_MENU_INIT
    ldh [hMainState], a
    ret

ReturnToRootMenu:
    ld a, ROOT_OPTION_SINGLES
    ldh [hCurrentRootMenuItem], a
    call HideWindow
    call TurnOffLCD
    ld a, MAIN_STATE_ROOT_MENU_INIT
    ldh [hMainState], a
    ret

MoveToNextRootMenuOption:
    call PlayMenuChangeSfx
    call EraseCurrentRootMenuOptionIndicator
    ldh a, [hCurrentRootMenuItem]
    inc a
    cp ROOT_OPTION_COUNT
    jr c, .store
    xor a
.store:
    ldh [hCurrentRootMenuItem], a
    jp PrintCurrentRootMenuOptionIndicator

MoveToPreviousRootMenuOption:
    call PlayMenuChangeSfx
    call EraseCurrentRootMenuOptionIndicator
    ldh a, [hCurrentRootMenuItem]
    or a
    jr nz, .no_wrap
    ld a, ROOT_OPTION_COUNT
.no_wrap:
    dec a
    ldh [hCurrentRootMenuItem], a
    jp PrintCurrentRootMenuOptionIndicator

ToggleChannel1:
    call GetMutedChannelsMask
    xor 1 << SOUND_STATUS_CH1_MUTED
    jp SetMutedChannelsMask

ToggleChannel2:
    call GetMutedChannelsMask
    xor 1 << SOUND_STATUS_CH2_MUTED
    jp SetMutedChannelsMask

ToggleChannel3:
    call GetMutedChannelsMask
    xor 1 << SOUND_STATUS_CH3_MUTED
    jp SetMutedChannelsMask

ToggleChannel4:
    call GetMutedChannelsMask
    xor 1 << SOUND_STATUS_CH4_MUTED
    jp SetMutedChannelsMask

IncreaseMasterVolume:
    ldh a, [hMasterVol]
    and $f0
    cp $f0
    jr z, .store
    add $10
.store:
    ldh [hMasterVol], a
    ret

DecreaseMasterVolume:
    ldh a, [hMasterVol]
    and $f0
    jr z, .store
    sub $10
.store:
    ldh [hMasterVol], a
    ret

MoveToNextSong:
    ldh a, [hCurrentSong]
    inc a
    cp SONG_COUNT
    jr c, .store
    xor a
.store:
    ld b, a
    call IsSongOnCurrentMenuPage
    jr nc, .redraw_page
    call PlayMenuChangeSfx
    push bc
    call EraseCurrentSongIndicator
    pop bc
    ld a, b
    ldh [hCurrentSong], a
    jp PrintCurrentSongIndicator
.redraw_page:
    ld a, b
    ldh [hCurrentSong], a
    call QueueMenuChangeSfx
    jp RequestMenuRedraw

MoveToPreviousSong:
    ldh a, [hCurrentSong]
    or a
    jr nz, .no_wrap
    ld a, SONG_COUNT
.no_wrap:
    dec a
    ld b, a
    call IsSongOnCurrentMenuPage
    jr nc, .redraw_page
    call PlayMenuChangeSfx
    push bc
    call EraseCurrentSongIndicator
    pop bc
    ld a, b
    ldh [hCurrentSong], a
    jp PrintCurrentSongIndicator
.redraw_page:
    ld a, b
    ldh [hCurrentSong], a
    call QueueMenuChangeSfx
    jp RequestMenuRedraw

MoveToNextMenuPage:
    ld a, SONG_PAGE_COUNT
    cp 2
    ret c
    call GetCurrentMenuRowOffset
    ld d, a
    ldh a, [hCurrentMenuPage]
    inc a
    cp SONG_PAGE_COUNT
    jr c, .select
    xor a
.select:
    call SelectMenuPageWithRowOffset
    call QueueMenuChangeSfx
    jp RequestMenuRedraw

MoveToPreviousMenuPage:
    ld a, SONG_PAGE_COUNT
    cp 2
    ret c
    call GetCurrentMenuRowOffset
    ld d, a
    ldh a, [hCurrentMenuPage]
    or a
    jr nz, .no_wrap
    ld a, SONG_PAGE_COUNT
.no_wrap:
    dec a
    call SelectMenuPageWithRowOffset
    call QueueMenuChangeSfx
    jp RequestMenuRedraw

GetCurrentMenuRowOffset:
    ldh a, [hCurrentSong]
    ld b, a
    ldh a, [hMenuPageFirstSong]
    ld c, a
    ld a, b
    sub c
    ret

; A = target page, D = desired row offset.
SelectMenuPageWithRowOffset:
    call GetMenuPageFirstSong
    add d
    cp SONG_COUNT
    jr c, .store
    ld a, SONG_COUNT - 1
.store:
    ldh [hCurrentSong], a
    ret

; A = page. Returns A = first song index on that page.
GetMenuPageFirstSong:
    ld b, a
    or a
    ret z
    ld c, b
    xor a
.loop:
    add a, SONGS_PER_PAGE
    dec c
    jr nz, .loop
    ret

; A = song index. Returns carry set if the song is visible on the current page.
; Preserves B.
IsSongOnCurrentMenuPage:
    push bc
    ld b, a
    ldh a, [hMenuPageFirstSong]
    ld c, a
    ld a, b
    sub c
    cp SONGS_PER_PAGE
    pop bc
    ret

RequestMenuRedraw:
    ; Page redraws update too many rows for a single VBlank, so switch the LCD
    ; off safely and let the init handler redraw directly.
    call HideWindow
    call TurnOffLCD
    ld a, MAIN_STATE_SINGLES_MENU_INIT
    ldh [hMainState], a
    ret

MoveToNextPauseOption:
    call PlayMenuChangeSfx
    call EraseCurrentPauseOptionIndicator
    ldh a, [hCurrentPauseMenuItem]
    inc a
    cp PAUSE_OPTION_COUNT
    jr c, .store
    xor a
.store:
    ldh [hCurrentPauseMenuItem], a
    jp PrintCurrentPauseOptionIndicator

MoveToPreviousPauseOption:
    call PlayMenuChangeSfx
    call EraseCurrentPauseOptionIndicator
    ldh a, [hCurrentPauseMenuItem]
    or a
    jr nz, .no_wrap
    ld a, PAUSE_OPTION_COUNT
.no_wrap:
    dec a
    ldh [hCurrentPauseMenuItem], a
    jp PrintCurrentPauseOptionIndicator

EnterPauseMode:
    ; Pause menu SFX temporarily changes hMasterVol. Save the song's setting so
    ; Resume and B-cancel restore the user's Play Mode volume.
    ldh a, [hMasterVol]
    ldh [hPauseMasterVol], a
    call PauseMusic
    call SilenceSoundOutput
    ld a, MAIN_STATE_PAUSE
    ldh [hMainState], a
    xor a
    ldh [hCurrentPauseMenuItem], a
    call QueuePauseCursorReset
    jp ShowPauseWindow

ResumeCurrentSong:
    call StopMenuChangeSfx
    ldh a, [hPauseMasterVol]
    ldh [hMasterVol], a
    call HideWindow
    call UnpauseMusic
    call RestoreSoundOutput
    ld a, MAIN_STATE_PLAY
    ldh [hMainState], a
    ret

RestartCurrentSong:
    call CallSelectedVisualizerTeardown
    jp StartCurrentSong

StartPreviousSongFromPause:
    call CallSelectedVisualizerTeardown
    call SelectPreviousPlaybackSong
    jp StartCurrentSong

StartNextSongFromPause:
    call CallSelectedVisualizerTeardown
    call SelectNextPlaybackSong
    jp StartCurrentSong

QuitToMenu:
    call CallSelectedVisualizerTeardown
    call StopMenuChangeSfx
    call StopSound
    call SilenceSoundOutput
    xor a
    ldh [hPlaybackActive], a
    call HideWindow
    call TurnOffLCD
    ldh a, [hPlaybackMode]
    cp PLAYBACK_MODE_SINGLES
    jr z, .singles
    ld a, MAIN_STATE_ROOT_MENU_INIT
    ldh [hMainState], a
    ret
.singles:
    ld a, MAIN_STATE_SINGLES_MENU_INIT
    ldh [hMainState], a
    ret

StartCurrentSong:
    call StopMenuChangeSfx
    call HideWindow
    call TurnOffLCD
    ld a, MAIN_STATE_PLAY_INIT
    ldh [hMainState], a
    ret

MainFunc_RootMenuInit:
    call DrawRootMenuScreen
    call TurnOnLCD
    ld a, MAIN_STATE_ROOT_MENU
    ldh [hMainState], a
    ret

MainFunc_SinglesMenuInit:
    call DrawMenuScreen
    call TurnOnLCD
    call PlayPendingMenuChangeSfx
    ld a, MAIN_STATE_SINGLES_MENU
    ldh [hMainState], a
    ret

MainFunc_PlayInit:
    ; This handler runs after TurnOffLCD has been applied by VBlank, so it may
    ; clear and redraw both tilemaps directly.
    call StopSound
    call SilenceSoundOutput
    call LoadCurrentSongPointers
    call DrawPlayModeScreen
    call CallSelectedVisualizerInit
    call TurnOnLCD
    call StartLoadedSong
    ; Force the master-volume digit to be queued on the first Play frame.
    ld a, $ff
    ldh [hDisplayedMasterVol], a
    ld a, MAIN_STATE_PLAY
    ldh [hMainState], a
    jp UpdatePlayModeFrame

LoadCurrentSongPointers:
    ldh a, [hCurrentSong]
    call GetSongCatalogEntry

    ld a, [hli]
    ldh [hActiveSongBank], a

    ld a, [hli]
    ldh [hSelectedSongDuration], a
    ld a, [hli]
    ldh [hSelectedSongDuration+1], a

    ld a, [hli]
    ldh [hSelectedSongPtr], a
    ld a, [hli]
    ldh [hSelectedSongPtr+1], a
    ld a, [hli]
    ldh [hSelectedWavePtr], a
    ld a, [hli]
    ldh [hSelectedWavePtr+1], a

    ld a, [hli]
    ldh [hSelectedVisualizerBank], a
    ld a, [hli]
    ldh [hSelectedVisualizerInitPtr], a
    ld a, [hli]
    ldh [hSelectedVisualizerInitPtr+1], a
    ld a, [hli]
    ldh [hSelectedVisualizerUpdatePtr], a
    ld a, [hli]
    ldh [hSelectedVisualizerUpdatePtr+1], a
    ld a, [hli]
    ldh [hSelectedVisualizerTeardownPtr], a
    ld a, [hli]
    ldh [hSelectedVisualizerTeardownPtr+1], a

    ldh a, [hActiveSongBank]
    jp SwitchRomBank

StartLoadedSong:
    ldh a, [hActiveSongBank]
    call SwitchRomBank

    ; Wave RAM is song-owned rather than part of the shared engine. Copy it
    ; before StartSong so CH3 has the right waveform from the first note.
    xor a
    ldh [rAUD3ENA], a
    ldh a, [hSelectedWavePtr]
    ld l, a
    ldh a, [hSelectedWavePtr+1]
    ld h, a
    call CopyFromHLIntoWav3Ram
    ld a, $80
    ldh [rAUD3ENA], a

    ldh a, [hSelectedSongPtr]
    ld l, a
    ldh a, [hSelectedSongPtr+1]
    ld h, a
    call StartSong

    ldh a, [hSelectedSongDuration]
    ldh [hAutoAdvanceFrames], a
    ldh a, [hSelectedSongDuration+1]
    ldh [hAutoAdvanceFrames+1], a

    ld a, 1
    ldh [hPlaybackActive], a
    ret

GetSongCatalogEntry:
    ld hl, SongCatalog
    ld de, SONG_CATALOG_ENTRY_SIZE
    ld b, a
    or a
    ret z
.loop:
    add hl, de
    dec b
    jr nz, .loop
    ret

CallSelectedVisualizerInit:
    ldh a, [hSelectedVisualizerInitPtr]
    ld l, a
    ldh a, [hSelectedVisualizerInitPtr+1]
    ld h, a
    jr CallSelectedVisualizer

CallSelectedVisualizerUpdate:
    ldh a, [hSelectedVisualizerUpdatePtr]
    ld l, a
    ldh a, [hSelectedVisualizerUpdatePtr+1]
    ld h, a
    jr CallSelectedVisualizer

CallSelectedVisualizerTeardown:
    ldh a, [hSelectedVisualizerTeardownPtr]
    ld l, a
    ldh a, [hSelectedVisualizerTeardownPtr+1]
    ld h, a

CallSelectedVisualizer:
    ldh a, [hSelectedVisualizerBank]
    or a
    jr z, .dispatch
    call SwitchRomBank
.dispatch:
    ld de, .done
    push de
    jp hl
.done:
    ; Hooks may run in a visualizer bank. Restore the song bank before returning
    ; so the next UpdateSound starts from the expected ROMX window.
    ldh a, [hActiveSongBank]
    jp SwitchRomBank

PlayMenuChangeSfx:
    ; Route only the short CH1 menu blip after the next sound-engine render.
    ; QueueSoundOutputMask avoids clobbering the song's preserved NR51 shadow.
    call SilenceSoundOutput
    ld a, $f0
    ldh [hMasterVol], a
    ld a, MENU_SFX_FRAME_COUNT
    ldh [hMenuSfxFrames], a
    ld a, MENU_CHANGE_SFX
    call PlayTrack0SFX
    ld a, MENU_SFX_OUTPUT_MASK
    jp QueueSoundOutputMask

QueueMenuChangeSfx:
    ld a, 1
    ldh [hPendingMenuChangeSfx], a
    ret

PlayPendingMenuChangeSfx:
    ldh a, [hPendingMenuChangeSfx]
    or a
    ret z
    xor a
    ldh [hPendingMenuChangeSfx], a
    jp PlayMenuChangeSfx

StopMenuChangeSfx:
    xor a
    ldh [hMenuSfxFrames], a
    ldh [hPendingMenuChangeSfx], a
    ret

; A = MBC5 ROM bank number. Version 1 uses banks below 256.
SwitchRomBank:
    ld [rROMB0], a
    xor a
    ld [rROMB1], a
    ret

CopyFromHLIntoWav3Ram:
    push bc
    ld c, LOW(_AUD3WAVERAM)
.loop:
    ld a, [hl+]
    ldh [c], a
    inc c
    ld a, c
    cp LOW(_AUD3WAVERAM) + 16
    jr nz, .loop
    pop bc
    ret

ClearTilemap:
    ld e, TILE_SPACE
    ld hl, $9800
    ld bc, $0400
    jp SetMemory

ClearWindowTilemap:
    ld e, TILE_SPACE
    ld hl, $9c00
    ld bc, $0400
    jp SetMemory

; E = byte, HL = start, BC = byte count
SetMemory:
    ld a, e
.loop:
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr z, .done
    ld a, e
    jr .loop
.done:
    ret

; Flush pending VRAM strings. Call only while VRAM is accessible.
FlushVramBuffer:
    ldh a, [hVramBufferOffset]
    or a
    ret z
    xor a
    ldh [hVramBufferOffset], a
    ldh [rVBK], a
    ld hl, wVramBuffer
    jp WriteVramStrings

; HL = address of data (zero-terminated)
; Entry format: high VRAM address, low VRAM address, count, bytes...
; Count with bit 6 set is RLE; non-RLE counts must keep bit 6 clear.
WriteVramStrings:
    ld a, [hli]
    or a
    ret z
    ld d, a ; high VRAM address
    ld a, [hli]
    ld e, a ; low VRAM address
    ld a, [hli]
    bit 6, a ; is data RLE?
    jr nz, .rle
    ld b, a ; count
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    jr WriteVramStrings
.rle:
    res 6, a ; count in lower bits
    ld b, a
    ld a, [hli] ; data
.rle_loop:
    ld [de], a
    inc de
    dec b
    jr nz, .rle_loop
    jr WriteVramStrings

; HL = address of length-prefixed string. DE = destination VRAM address.
WriteCountedString:
    ld b, [hl]
    inc hl
.loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loop
    ret

; DE = start address
; C = count
; Returns HL = vram buffer pointer after the header. Caller writes C bytes to
; [hli], then calls EndVramString.
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

; Terminates the buffered string list and commits the new buffer offset.
EndVramString:
    ld [hl], 0
    ld a, l
    sub LOW(wVramBuffer)
    ldh [hVramBufferOffset], a
    ret

; DE = VRAM address, A = tile
QueueVramTile:
    push af
    ld c, 1
    call BeginVramString
    pop af
    ld [hli], a
    jp EndVramString

DrawMenuScreen:
    call HideWindow
    call SetMenuPageForCurrentSong
    call ClearTilemap
    call ClearWindowTilemap
    ld hl, MenuStaticStrings
    call WriteVramStrings
    call DrawMenuPageSongTitles
    call PrintPageIndicator
    jp PrintCurrentSongIndicatorDirect

DrawPlayModeScreen:
    call ClearTilemap
    call ClearWindowTilemap
    ld hl, PauseWindowStrings
    call WriteVramStrings
    ld hl, PlayModeStaticStrings
    call WriteVramStrings
    call PrintSelectedSongTitle
    jp PrintAlbumSongIndicator

DrawChannelIndicators:
    ld de, CHANNEL_INDICATOR_TOP_ADDR
    ld c, CHANNEL_INDICATOR_WIDTH
    call BeginVramString
    ld e, TILE_CHANNEL_TOP_BASE
    call DrawChannelIndicatorRow
    call EndVramString
    ld de, CHANNEL_INDICATOR_BOTTOM_ADDR
    ld c, CHANNEL_INDICATOR_WIDTH
    call BeginVramString
    ld e, TILE_CHANNEL_BOTTOM_BASE
    call DrawChannelIndicatorRow
    jp EndVramString

DrawChannelIndicatorRow:
    ld b, 1 << SOUND_STATUS_CH1_MUTED
    ld c, LOW(hShadowNR12)
    call DrawChannelIndicatorPair
    call DrawChannelIndicatorSeparator
    ld b, 1 << SOUND_STATUS_CH2_MUTED
    ld c, LOW(hShadowNR22)
    call DrawChannelIndicatorPair
    call DrawChannelIndicatorSeparator
    ld b, 1 << SOUND_STATUS_CH3_MUTED
    ld c, LOW(hShadowNR32)
    call DrawChannelIndicatorPair
    call DrawChannelIndicatorSeparator
    ld b, 1 << SOUND_STATUS_CH4_MUTED
    ld c, LOW(hShadowNR42)
    jp DrawChannelIndicatorPair

DrawChannelIndicatorSeparator:
    xor a
    ld [hli], a
    ret

DrawChannelIndicatorPair:
    call GetMutedChannelsMask
    and b
    jr z, .not_muted
    ld a, e
    sub TILE_CHANNEL_TOP_BASE
    add TILE_MUTE_TOP_BASE
    ld [hli], a
    add 2
    ld [hli], a
    ret
.not_muted:
    ldh a, [c]
    and $0e
    or a
    jr z, .blank
    sla a
    add e
    ld [hli], a
    add 2
    ld [hli], a
    ret
.blank:
    ld [hli], a
    ld [hli], a
    ret

GenericVisualizerInit:
GenericVisualizerTeardown:
    ret

GenericVisualizerUpdate:
    jp DrawChannelIndicators

QueuePauseCursorReset:
    ld de, $9c00 + 1 * 32 + PAUSE_CURSOR_COL
    xor a
    call QueueVramTile
    ld de, $9c00 + 2 * 32 + PAUSE_CURSOR_COL
    xor a
    call QueueVramTile
    ld de, $9c00 + 3 * 32 + PAUSE_CURSOR_COL
    xor a
    call QueueVramTile
    ld de, $9c00 + 4 * 32 + PAUSE_CURSOR_COL
    xor a
    call QueueVramTile
    ld de, $9c00 + 5 * 32 + PAUSE_CURSOR_COL
    xor a
    call QueueVramTile
    jp PrintCurrentPauseOptionIndicator

PrintSelectedSongTitle:
    call GetCurrentSongTitlePointer
    ld de, $9882
    jp WriteCountedString

PrintAlbumSongIndicator:
    ldh a, [hPlaybackMode]
    cp PLAYBACK_MODE_ALBUM
    ret nz
    ld hl, AlbumSongIndicatorPrefix
    ld de, ALBUM_SONG_INDICATOR_ADDR
    call WriteCountedString
    ldh a, [hCurrentSong]
    inc a
    call WriteDecimal0To99
    ld hl, AlbumSongIndicatorInfix
    call WriteCountedString
    ld a, SONG_COUNT
    jp WriteDecimal0To99

; A = value 0..99. DE = destination tilemap address.
; Writes one or two decimal digit tiles and advances DE.
WriteDecimal0To99:
    ld b, 0
.tens:
    cp 10
    jr c, .ones
    sub 10
    inc b
    jr .tens
.ones:
    ld c, a
    ld a, b
    or a
    jr z, .write_ones
    add a, TILE_DIGIT_0
    ld [de], a
    inc de
.write_ones:
    ld a, c
    add a, TILE_DIGIT_0
    ld [de], a
    inc de
    ret

PrintMasterVolumeValue:
    ; hDisplayedMasterVol is a one-byte shadow for the visible digit. Only queue
    ; a tile update when the high nibble changed.
    ldh a, [hMasterVol]
    and $f0
    ld b, a
    ldh a, [hDisplayedMasterVol]
    cp b
    ret z
    ld a, b
    ldh [hDisplayedMasterVol], a
    ld de, MASTER_VOL_VALUE_ADDR
    ld a, b
    swap a
    and $0f
    inc a
    jp QueueVramTile

GetCurrentSongTitlePointer:
    ldh a, [hCurrentSong]
GetSongTitlePointer:
    ld hl, SongTitlePointers
    add a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret

SetMenuPageForCurrentSong:
    ldh a, [hCurrentSong]
    ld b, 0
    ld c, 0
.loop:
    cp SONGS_PER_PAGE
    jr c, .done
    sub SONGS_PER_PAGE
    inc b
    push af
    ld a, c
    add a, SONGS_PER_PAGE
    ld c, a
    pop af
    jr .loop
.done:
    ld a, b
    ldh [hCurrentMenuPage], a
    ld a, c
    ldh [hMenuPageFirstSong], a
    ret

DrawMenuPageSongTitles:
    ldh a, [hMenuPageFirstSong]
    ldh [hMenuDrawSong], a
    ld a, SONGS_PER_PAGE
    ldh [hMenuDrawRowsRemaining], a
    ld a, LOW($9800 + MENU_FIRST_SONG_ROW * 32 + MENU_TITLE_COL)
    ldh [hMenuDrawRowAddr], a
    ld a, HIGH($9800 + MENU_FIRST_SONG_ROW * 32 + MENU_TITLE_COL)
    ldh [hMenuDrawRowAddr+1], a
.loop:
    ldh a, [hMenuDrawRowsRemaining]
    or a
    ret z
    ldh a, [hMenuDrawSong]
    cp SONG_COUNT
    ret nc
    call GetSongTitlePointer
    ldh a, [hMenuDrawRowAddr]
    ld e, a
    ldh a, [hMenuDrawRowAddr+1]
    ld d, a
    call WriteCountedString

    ldh a, [hMenuDrawSong]
    inc a
    ldh [hMenuDrawSong], a
    ldh a, [hMenuDrawRowsRemaining]
    dec a
    ldh [hMenuDrawRowsRemaining], a
    ldh a, [hMenuDrawRowAddr]
    add a, 32
    ldh [hMenuDrawRowAddr], a
    ldh a, [hMenuDrawRowAddr+1]
    adc a, 0
    ldh [hMenuDrawRowAddr+1], a
    jr .loop

PrintPageIndicator:
    ld a, SONG_PAGE_COUNT
    cp 2
    ret c
    ld hl, PageIndicatorPointers
    ldh a, [hCurrentMenuPage]
    add a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld de, MENU_PAGE_INDICATOR_ADDR
    jp WriteCountedString

; Returns DE = cursor tile address for hCurrentSong on the current menu page.
BeginCurrentSongIndicator:
    ld de, $9800 + MENU_FIRST_SONG_ROW * 32 + MENU_CURSOR_COL
    ldh a, [hCurrentSong]
    ld b, a
    ldh a, [hMenuPageFirstSong]
    ld c, a
    ld a, b
    sub c
    ld b, a
    or a
    ret z
.loop:
    ld a, e
    add a, 32
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    dec b
    jr nz, .loop
    ret

PrintCurrentSongIndicator:
    call BeginCurrentSongIndicator
    ld a, TILE_CURSOR
    jp QueueVramTile

EraseCurrentSongIndicator:
    call BeginCurrentSongIndicator
    ld a, TILE_SPACE
    jp QueueVramTile

PrintCurrentSongIndicatorDirect:
    ; Direct variant: only call with the LCD off. Runtime cursor moves use
    ; PrintCurrentSongIndicator so they are flushed during the next VBlank.
    call BeginCurrentSongIndicator
    ld a, TILE_CURSOR
    ld [de], a
    ret

BeginCurrentPauseOptionIndicator:
    ld hl, PauseIndicatorAddresses
    ldh a, [hCurrentPauseMenuItem]
    add a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ret

PrintCurrentPauseOptionIndicator:
    call BeginCurrentPauseOptionIndicator
    ld a, TILE_CURSOR
    jp QueueVramTile

EraseCurrentPauseOptionIndicator:
    call BeginCurrentPauseOptionIndicator
    ld a, TILE_SPACE
    jp QueueVramTile

DrawRootMenuScreen:
    call HideWindow
    call ClearTilemap
    call ClearWindowTilemap
    ld hl, RootMenuStaticStrings
    call WriteVramStrings
    jp PrintCurrentRootMenuOptionIndicatorDirect

BeginCurrentRootMenuOptionIndicator:
    ld hl, RootIndicatorAddresses
    ldh a, [hCurrentRootMenuItem]
    add a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ret

PrintCurrentRootMenuOptionIndicator:
    call BeginCurrentRootMenuOptionIndicator
    ld a, TILE_CURSOR
    jp QueueVramTile

EraseCurrentRootMenuOptionIndicator:
    call BeginCurrentRootMenuOptionIndicator
    ld a, TILE_SPACE
    jp QueueVramTile

PrintCurrentRootMenuOptionIndicatorDirect:
    ; Direct variant: only call with the LCD off. Runtime cursor moves use
    ; PrintCurrentRootMenuOptionIndicator and the VRAM buffer.
    call BeginCurrentRootMenuOptionIndicator
    ld a, TILE_CURSOR
    ld [de], a
    ret

SECTION "UI Text", ROM0

RootMenuStaticStrings:
    db HIGH(ROOT_TITLE_ADDR), LOW(ROOT_TITLE_ADDR), 15, "NOTUBE4ME MUSIC"
    db HIGH(ROOT_HEADING_ADDR), LOW(ROOT_HEADING_ADDR), 9, "PLAY MODE"
    db HIGH($9800 + ROOT_OPTION_ALBUM_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db LOW($9800 + ROOT_OPTION_ALBUM_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db 5, "ALBUM"
    db HIGH($9800 + ROOT_OPTION_SHUFFLE_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db LOW($9800 + ROOT_OPTION_SHUFFLE_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db 7, "SHUFFLE"
    db HIGH($9800 + ROOT_OPTION_SINGLES_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db LOW($9800 + ROOT_OPTION_SINGLES_ROW * 32 + ROOT_OPTION_TEXT_COL)
    db 7, "SINGLES"
    db 0

MenuStaticStrings:
    db $98, $22, 15, "NOTUBE4ME MUSIC"
    db $98, $62, 11, "CHOOSE SONG"
    db 0

PlayModeStaticStrings:
    db $98, $22, 11, "NOW PLAYING"
    db HIGH(CHANNEL_BUTTON_ICON_TOP_ADDR), LOW(CHANNEL_BUTTON_ICON_TOP_ADDR), 11
    db TILE_BUTTON_TOP_BASE, TILE_BUTTON_TOP_BASE + 2, TILE_SPACE
    db TILE_BUTTON_TOP_BASE + 4, TILE_BUTTON_TOP_BASE + 6, TILE_SPACE
    db TILE_BUTTON_TOP_BASE + 8, TILE_BUTTON_TOP_BASE + 10, TILE_SPACE
    db TILE_BUTTON_TOP_BASE + 12, TILE_BUTTON_TOP_BASE + 14
    db HIGH(CHANNEL_BUTTON_ICON_BOTTOM_ADDR), LOW(CHANNEL_BUTTON_ICON_BOTTOM_ADDR), 11
    db TILE_BUTTON_BOTTOM_BASE, TILE_BUTTON_BOTTOM_BASE + 2, TILE_SPACE
    db TILE_BUTTON_BOTTOM_BASE + 4, TILE_BUTTON_BOTTOM_BASE + 6, TILE_SPACE
    db TILE_BUTTON_BOTTOM_BASE + 8, TILE_BUTTON_BOTTOM_BASE + 10, TILE_SPACE
    db TILE_BUTTON_BOTTOM_BASE + 12, TILE_BUTTON_BOTTOM_BASE + 14
    db HIGH(MASTER_VOL_LABEL_ADDR), LOW(MASTER_VOL_LABEL_ADDR), 13, "MASTER VOL: F"
    db 0

PauseWindowStrings:
    db HIGH(PAUSE_HEADING_ADDR), LOW(PAUSE_HEADING_ADDR), 6, "PAUSED"
    db HIGH($9c00 + 1 * 32 + PAUSE_OPTION_TEXT_COL)
    db LOW($9c00 + 1 * 32 + PAUSE_OPTION_TEXT_COL), 6, "RESUME"
    db HIGH($9c00 + 2 * 32 + PAUSE_OPTION_TEXT_COL)
    db LOW($9c00 + 2 * 32 + PAUSE_OPTION_TEXT_COL), 7, "RESTART"
    db HIGH($9c00 + 3 * 32 + PAUSE_OPTION_TEXT_COL)
    db LOW($9c00 + 3 * 32 + PAUSE_OPTION_TEXT_COL), 9, "PREV SONG"
    db HIGH($9c00 + 4 * 32 + PAUSE_OPTION_TEXT_COL)
    db LOW($9c00 + 4 * 32 + PAUSE_OPTION_TEXT_COL), 9, "NEXT SONG"
    db HIGH($9c00 + 5 * 32 + PAUSE_OPTION_TEXT_COL)
    db LOW($9c00 + 5 * 32 + PAUSE_OPTION_TEXT_COL), 4, "QUIT"
    db HIGH($9c00 + 1 * 32 + PAUSE_CURSOR_COL)
    db LOW($9c00 + 1 * 32 + PAUSE_CURSOR_COL), 1, TILE_SPACE
    db HIGH($9c00 + 2 * 32 + PAUSE_CURSOR_COL)
    db LOW($9c00 + 2 * 32 + PAUSE_CURSOR_COL), 1, TILE_SPACE
    db HIGH($9c00 + 3 * 32 + PAUSE_CURSOR_COL)
    db LOW($9c00 + 3 * 32 + PAUSE_CURSOR_COL), 1, TILE_SPACE
    db HIGH($9c00 + 4 * 32 + PAUSE_CURSOR_COL)
    db LOW($9c00 + 4 * 32 + PAUSE_CURSOR_COL), 1, TILE_SPACE
    db HIGH($9c00 + 5 * 32 + PAUSE_CURSOR_COL)
    db LOW($9c00 + 5 * 32 + PAUSE_CURSOR_COL), 1, TILE_SPACE
    db 0

AlbumSongIndicatorPrefix:
    db 5, "SONG "

AlbumSongIndicatorInfix:
    db 4, " OF "

RootIndicatorAddresses:
    dw $9800 + ROOT_OPTION_ALBUM_ROW * 32 + ROOT_CURSOR_COL
    dw $9800 + ROOT_OPTION_SHUFFLE_ROW * 32 + ROOT_CURSOR_COL
    dw $9800 + ROOT_OPTION_SINGLES_ROW * 32 + ROOT_CURSOR_COL

PauseIndicatorAddresses:
    dw $9c00 + 1 * 32 + PAUSE_CURSOR_COL
    dw $9c00 + 2 * 32 + PAUSE_CURSOR_COL
    dw $9c00 + 3 * 32 + PAUSE_CURSOR_COL
    dw $9c00 + 4 * 32 + PAUSE_CURSOR_COL
    dw $9c00 + 5 * 32 + PAUSE_CURSOR_COL

SECTION "UI Tiles", ROM0

FontTiles:
    INCBIN "ui/font.bin"
FontTilesEnd:
    assert TILE_CHANNEL_TOP_BASE == (FontTilesEnd - FontTiles) / 16
BallTiles:
    INCBIN "ui/ball.bin"
BallTilesEnd:
    assert BallTilesEnd - BallTiles == 512
    assert TILE_BUTTON_TOP_BASE == (BallTilesEnd - FontTiles) / 16
ButtonTiles:
    INCBIN "ui/udlr.bin"
ButtonTilesEnd:
    assert ButtonTilesEnd - ButtonTiles == 256
    assert TILE_MUTE_TOP_BASE == (ButtonTilesEnd - FontTiles) / 16
MuteTiles:
    INCBIN "ui/mute.bin"
MuteTilesEnd:
    assert MuteTilesEnd - MuteTiles == 64
UITilesEnd:
