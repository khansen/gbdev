song_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$28,$00,$00 ; 1
dw env0
db $00,$00,$00,$88,$00,$00 ; 2
dw env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw env0
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw env4
db $00,$00,$00,$00,$00,$00 ; 6 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 7 noise (snare)
dw env7
db $00,$00,$00,$00,$00,$00 ; 8 triangle (very short)
dw env6
db $00,$00,$00,$80,$00,$00 ; 9 weird noise (closed) - reduce
dw env0
db $00,$00,$00,$00,$00,$00 ; 10 noise (infinite)
dw env11
db $00,$02,$18,$00,$00,$00 ; 11 triangle megaman bass
dw env12
db $00,$02,$18,$00,$00,$00 ; 12 triangle snare
dw env13
db $00,$00,$00,$8C,$00,$00 ; 13
dw env14
db $00,$04,$A3,$68,$00,$00 ; 14
dw env2
db $00,$01,$28,$00,$00,$00 ; 15

env0:
db $E0
db $00,$E0,$FF
db $E0,$00,$00
db $FF,$FF
env1:
db $F0
db $00,$F0,$06
db $30,$00,$00
db $FF,$FF
env3:
db $E0
db $50,$00,$00
db $FF,$FF
env4:
db $E0
db $10,$00,$00
db $FF,$FF
env5:
db $E0
db $18,$00,$00
db $FF,$FF
env6:
db $C0
db $1A,$00,$00
db $FF,$FF
env2:
db $C0
db $08,$00,$00
db $FF,$FF
env7:
db $F0
db $00,$F0,$01
db $60,$00,$00
db $FF,$FF
env11:
db $F0
db $10,$00,$00
db $FF,$FF
env12:
db $F0
db $10,$00,$00
db $FF,$FF
env13:
db $C0
db $0E,$00,$00
db $FF,$FF
env14:
db $D0
db $18,$10,$00
db $18,$70,$00
db $06,$00,$00
db $FF,$FF

include "song.inc"
