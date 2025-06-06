song_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$68,$00,$00 ; 1
dw env0
db $00,$00,$00,$48,$00,$00 ; 2
dw env0
db $00,$00,$00,$00,$00,$00 ; 3 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 4 noise (closed)
dw env4
db $00,$02,$18,$00,$00,$00 ; 5 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 6 noise (snare)
dw env7
db $00,$00,$00,$80,$00,$00 ; 7 weird noise (closed) - reduce
dw env0
db $00,$00,$00,$00,$00,$00 ; 8 noise (infinite)
dw env1
db $00,$02,$F0,$00,$00,$00 ; 9 triangle (bassdrum)
dw env2
db $00,$00,$00,$48,$00,$00 ; 10
dw env6
db $00,$00,$00,$48,$00,$00 ; 11
dw env8
db $00,$00,$00,$18,$00,$00 ; 12
dw env9
db $00,$02,$18,$00,$00,$00 ; 13 triangle (snare)
dw env10
db $00,$00,$00,$00,$00,$00 ; 14 triangle (short)
dw env11
db $00,$00,$00,$00,$00,$00 ; 14 triangle (short)

env0:
db $F0
db $00,$F0,$FF
db $18,$00,$00
db $FF,$FF
env3:
db $F0
db $38,$00,$00
db $FF,$FF
env4:
db $B0
db $0C,$00,$00
db $FF,$FF
env5:
db $F0
db $00,$F0,$01
db $1E,$00,$00
db $FF,$FF
env6:
db $F0
db $20,$10,$00
db $FF,$FF
env1:
db $F0
db $12,$00,$00
db $FF,$FF
env2:
db $D0
db $20,$10,$00
db $FF,$FF
env7:
db $F0
db $14,$00,$00
db $FF,$FF
env8:
db $F0
db $10,$10,$00
db $FF,$FF
env9:
db $F0
db $20,$00,$00
db $FF,$FF
env10:
db $F0
db $00,$F0,$02
db $20,$00,$00
db $FF,$FF
env11:
db $F0
db $00,$F0,$04
db $12,$00,$00
db $FF,$FF

include "song.inc"
