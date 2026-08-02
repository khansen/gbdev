def SOUND_STATUS_CH1_MUTED equ 0
def SOUND_STATUS_CH2_MUTED equ 1
def SOUND_STATUS_CH3_MUTED equ 2
def SOUND_STATUS_CH4_MUTED equ 3

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
def Track_Effect_Portamento_Ctrl rb 1               ; 0A
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
if def(SOUND_ENGINE_ENABLE_SFX)
def NUM_SFX_TRACKS equ 4
else
def NUM_SFX_TRACKS equ 0
endc
def NUM_TRACKS equ NUM_MUSIC_TRACKS + NUM_SFX_TRACKS

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
