;=================================================
; Game Boy Hardware Definitions for WLA-GB
; Converted from RGBDS `hardware.inc`
;=================================================

.ifndef HARDWARE_INC
    .define HARDWARE_INC 1

    .macro rev_Check_hardware_inc revision
        .if revision > 4
            .message "Version ".str(revision)." or later of 'hardware.inc' is required."
        .endif
    .endm

    ;===========================
    ; Memory Addresses
    ;===========================
    .define _VRAM        $8000  ; $8000->$9FFF
    .define _VRAM8000    _VRAM
    .define _VRAM8800    _VRAM+$800
    .define _VRAM9000    _VRAM+$1000
    .define _SCRN0       $9800  ; $9800->$9BFF
    .define _SCRN1       $9C00  ; $9C00->$9FFF
    .define _SRAM        $A000  ; $A000->$BFFF
    .define _RAM         $C000  ; $C000->$DFFF
    .define _RAMBANK     $D000  ; $D000->$DFFF
    .define _OAMRAM      $FE00  ; $FE00->$FE9F
    .define _IO          $FF00  ; $FF00->$FF7F,$FFFF
    .define _AUD3WAVERAM $FF30  ; $FF30->$FF3F
    .define _HRAM        $FF80  ; $FF80->$FFFE

    ;===========================
    ; MBC5 Equates
    ;===========================
    .define rRAMG        $0000  ; $0000->$1FFF
    .define rROMB0       $2000  ; $2000->$2FFF
    .define rROMB1       $3000  ; $3000->$3FFF
    .define rRAMB        $4000  ; $4000->$5FFF

    ;===========================
    ; Custom Registers
    ;===========================
    .define rP1 $FF00  ; Joypad register
    .define P1F_5 %00100000
    .define P1F_4 %00010000
    .define P1F_3 %00001000
    .define P1F_2 %00000100
    .define P1F_1 %00000010
    .define P1F_0 %00000001
    .define P1F_GET_DPAD P1F_5
    .define P1F_GET_BTN P1F_4
    .define P1F_GET_NONE P1F_4 | P1F_5

    .define rSB $FF01  ; Serial Data Transfer
    .define rSC $FF02  ; Serial I/O Control
    .define rDIV $FF04 ; Divider Register
    .define rTIMA $FF05 ; Timer Counter
    .define rTMA $FF06 ; Timer Modulo
    .define rTAC $FF07 ; Timer Control
    .define rIF $FF0F  ; Interrupt Flag

    ;===========================
    ; Sound Registers
    ;===========================
    .define rNR10 $FF10
    .define rAUD1SWEEP rNR10
    .define rNR11 $FF11
    .define rAUD1LEN rNR11
    .define rNR12 $FF12
    .define rAUD1ENV rNR12
    .define rNR13 $FF13
    .define rAUD1LOW rNR13
    .define rNR14 $FF14
    .define rAUD1HIGH rNR14

    .define rNR21 $FF16
    .define rAUD2LEN rNR21
    .define rNR22 $FF17
    .define rAUD2ENV rNR22
    .define rNR23 $FF18
    .define rAUD2LOW rNR23
    .define rNR24 $FF19
    .define rAUD2HIGH rNR24

    .define rNR30 $FF1A
    .define rAUD3ENA rNR30
    .define rNR31 $FF1B
    .define rAUD3LEN rNR31
    .define rNR32 $FF1C
    .define rAUD3LEVEL rNR32
    .define rNR33 $FF1D
    .define rAUD3LOW rNR33
    .define rNR34 $FF1E
    .define rAUD3HIGH rNR34

    ; --
    ; -- AUD4ENV/NR42 ($FF21)
    ; -- Envelope (R/W)
    ; --
    ; -- see AUD1ENV for info
    ; --
    .define rNR42 $FF21
    .define rAUD4ENV rNR42

    ; --
    ; -- AUD4POLY/NR43 ($FF22)
    ; -- Polynomial counter (R/W)
    ; --
    ; -- Bit 7-4 - Selection of the shift clock frequency of the (scf)
    ; --           polynomial counter (0000-1101)
    ; --           freq=drf*1/2^scf (not sure)
    ; -- Bit 3 -   Selection of the polynomial counter's step
    ; --           0: 15 steps
    ; --           1: 7 steps
    ; -- Bit 2-0 - Selection of the dividing ratio of frequencies (drf)
    ; --           000: f/4   001: f/8   010: f/16  011: f/24
    ; --           100: f/32  101: f/40  110: f/48  111: f/56  (f=4.194304 Mhz)
    ; --
    .define rNR43 $FF22
    .define rAUD4POLY rNR43

    ; --
    ; -- AUD4GO/NR44 ($FF23)
    ; --
    ; -- Bit 7 -   Inital
    ; -- Bit 6 -   Counter/consecutive selection
    ; --
    .define rNR44 $FF23
    .define rAUD4GO rNR44

    .define rNR50 $FF24
    .define rAUDVOL rNR50

    .define AUDVOL_VIN_LEFT  %10000000 ; SO2
    .define AUDVOL_VIN_RIGHT %00001000 ; SO1

    .define rNR51 $FF25
    .define rAUDTERM rNR51

    .define rNR52 $FF26
    .define rAUDENA rNR52

    ;===========================
    ; LCD and Graphics
    ;===========================
    .define rLCDC $FF40
    .define LCDCF_ON %10000000
    .define LCDCF_OFF %00000000
    .define LCDCF_BGON %00000001
    .define LCDCF_BGOFF %00000000
    .define LCDCF_OBJON %00000010
    .define LCDCF_OBJOFF %00000000
    .define LCDCF_OBJ8 %00000000
    .define LCDCF_OBJ16 %00000100
    .define LCDCF_BG8000 %00010000 ; BG & Window Tile Data Select
    .define LCDCF_BG9800 %00000000 ; BG Tile Map Display Select

    .define rSTAT $FF41
    .define STATF_LYC %01000000 ; LYC=LY Coincidence (Selectable)
    .define STATF_BUSY %00000010
    .define STATF_HBL %00000000
    .define STATF_VBL %00000001
    .define STATF_OAM %00000010
    .define STATF_LCD %00000011

    .define rSCY $FF42
    .define rSCX $FF43
    .define rLY $FF44
    .define rLYC $FF45
    .define rDMA $FF46
    .define rBGP $FF47
    .define rOBP0 $FF48
    .define rOBP1 $FF49

    ; --
    ; -- WY ($FF4A)
    ; -- Window Y Position (R/W)
    ; --
    ; -- 0 <= WY <= 143
    ; -- When WY = 0, the window is displayed from the top edge of the LCD screen.
    ; --
    .define rWY $FF4A


    ; --
    ; -- WX ($FF4B)
    ; -- Window X Position (R/W)
    ; --
    ; -- 7 <= WX <= 166
    ; -- When WX = 7, the window is displayed from the left edge of the LCD screen.
    ; -- Values of 0-6 and 166 are unreliable due to hardware bugs.
    ; --
    .define rWX $FF4B

    ; --
    ; -- VBK ($FF4F)
    ; -- Select Video RAM Bank (R/W)
    ; --
    ; -- Bit 0 - Bank Specification (0: Specify Bank 0; 1: Specify Bank 1)
    ; --
    .define rVBK $FF4F

    ; --
    ; -- BCPS ($FF68)
    ; -- Background Color Palette Specification (R/W)
    ; --
    .define rBCPS $FF68

    ; --
    ; -- BCPD ($FF69)
    ; -- Background Color Palette Data (R/W)
    ; --
    .define rBCPD $FF69

    .define BCPSF_AUTOINC %10000000 ; Auto Increment (0=Disabled, 1=Increment after Writing)

    ; --
    ; -- OCPS ($FF6A)
    ; -- Object Color Palette Specification (R/W)
    ; --
    .define rOCPS $FF6A

    .define OCPSF_AUTOINC %10000000 ; Auto Increment (0=Disabled, 1=Increment after Writing)

    ; --
    ; -- OCPD ($FF6B)
    ; -- Object Color Palette Data (R/W)
    ; --
    .define rOCPD $FF6B

    ; --
    ; -- SMBK/SVBK ($FF70)
    ; -- Select Main RAM Bank (R/W)
    ; --
    ; -- Bit 2-0 - Bank Specification (0,1: Specify Bank 1; 2-7: Specify Banks 2-7)
    ; --
    .define rSVBK $FF70
    .define rSMBK rSVBK

    ;===========================
    ; Interrupts
    ;===========================
    .define rIE $FFFF
    .define IEF_VBLANK %00000001
    .define IEF_STAT %00000010
    .define IEF_TIMER %00000100
    .define IEF_SERIAL %00001000
    .define IEF_HILO %00010000

    ;***************************************************************************
    ;*
    ;* Keypad related
    ;*
    ;***************************************************************************

    .define PADF_DOWN   $80
    .define PADF_UP     $40
    .define PADF_LEFT   $20
    .define PADF_RIGHT  $10
    .define PADF_START  $08
    .define PADF_SELECT $04
    .define PADF_B      $02
    .define PADF_A      $01

    .define PADB_DOWN   $7
    .define PADB_UP     $6
    .define PADB_LEFT   $5
    .define PADB_RIGHT  $4
    .define PADB_START  $3
    .define PADB_SELECT $2
    .define PADB_B      $1
    .define PADB_A      $0

    ;***************************************************************************
    ;*
    ;* OAM related
    ;*
    ;***************************************************************************
    .define OAM_COUNT 40  ; number of OAM entries in OAM RAM

    ;*
    ;* Nintendo scrolling logo
    ;* (Code won't work on a real GameBoy)
    ;* (if next lines are altered.)
    .macro NINTENDO_LOGO
        .db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
        .db $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
        .db $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
    .endm

.endif
