SONG_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$28,$00,$00 ; 1
dw env0
db $00,$00,$00,$8C,$00,$00 ; 2
dw env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw env0
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw env4
db $00,$00,$00,$00,$00,$00 ; 6 noise (open)
dw env5
db $00,$02,$30,$00,$00,$00 ; 7 noise (snare)
dw env7
db $00,$04,$84,$00,$00,$00 ; 8 triangle (very short)
dw env4
db $00,$00,$00,$80,$00,$00 ; 9 weird noise (closed) - reduce
dw env01
db $00,$00,$00,$00,$00,$00 ; 10 noise (infinite)
dw env11
db $00,$02,$70,$00,$00,$00 ; 11 triangle megaman bass
dw env12
db $00,$02,$10,$00,$00,$00 ; 12 triangle snare
dw env2
db $00,$00,$00,$18,$00,$00 ; 13
dw env8
db $00,$00,$00,$28,$00,$00 ; 14
dw env9
db $00,$00,$00,$18,$00,$00 ; 15
dw env6
db $00,$00,$00,$00,$00,$00 ; 16

env0:
db $F0
db $00,$F0,$FF
db $08,$00,$00
db $FF,$FF
env01:
db $A0
db $00,$A0,$FF
db $08,$00,$00
db $FF,$FF
env1:
db $F0
db $00,$F0,$10
db $F0,$00,$00
db $FF,$FF
env2:
db $F0
db $00,$F0,$08
db $0C,$30,$FF
db $FF,$FF
env3:
db $F0
db $70,$00,$00
db $FF,$FF
env4:
db $E0
db $0F,$00,$00
db $FF,$FF
env5:
db $E0
db $0D,$00,$00
db $FF,$FF
env6:
db $F0
db $00,$F0,$03
db $F0,$00,$00
db $FF,$FF
env7:
db $F0
db $00,$F0,$0C
db $20,$00,$00
db $FF,$FF
env8:
db $F0
db $0E,$40,$00
db $F0,$C0,$00
db $0C,$20,$00
db $F0,$70,$00
db $0C,$10,$00
db $F0,$30,$00
db $0C,$10,$00
db $FF,$FF
env9:
db $F0
db $0C,$40,$00
db $FF,$FF
env11:
db $A0
db $26,$00,$00
db $FF,$FF
env12:
db $F0
db $12,$00,$00
db $FF,$FF

include "song.inc"
