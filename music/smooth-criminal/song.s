song_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$68,$00,$00 ; 1
dw env0
db $00,$00,$00,$48,$00,$00 ; 2
dw env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw env7
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw env4
db $00,$00,$00,$00,$00,$00 ; 6 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 7 noise (snare)
dw env2
db $00,$00,$00,$00,$00,$00 ; 8 triangle (very short)
dw env6
db $00,$00,$00,$18,$00,$00 ; 9 short chorus vocals
dw env8
db $00,$02,$F0,$20,$00,$00 ; 10 square (bass drum)
dw env9
db $00,$02,$24,$20,$00,$00 ; 11 square (snare)
dw env7
db $00,$00,$00,$00,$00,$00 ; 12 noise (infinite)

env0:
db $C0
db $00,$C0,$FF
db $10,$00,$00
db $FF,$FF
env7:
db $F0
db $00,$F0,$FF
db $0C,$00,$00
db $FF,$FF
env1:
db $F0
db $00,$F0,$09
db $14,$00,$00
db $FF,$FF
env2:
db $F0
db $00,$F0,$03
db $30,$00,$00
db $FF,$FF
env3:
db $F0
db $30,$00,$00
db $FF,$FF
env4:
db $F0
db $00,$F0,$02
db $24,$00,$00
db $FF,$FF
env5:
db $F0
db $00,$F0,$01
db $12,$00,$00
db $FF,$FF
env6:
db $C0
db $10,$00,$00
db $FF,$FF
env8:
db $F0
db $28,$00,$00
db $FF,$FF
env9:
db $F0
db $18,$00,$00
db $FF,$FF

include "song.inc"
