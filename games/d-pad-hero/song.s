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
db $00,$00,$00,$00,$00,$00 ; 5 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 6 noise (snare)
dw env7
db $00,$00,$00,$80,$00,$00 ; 7 weird noise (open)
dw env1
db $00,$00,$00,$00,$00,$00 ; 8 triangle (short)
dw env2
db $00,$00,$00,$00,$00,$00 ; 9 triangle (very short)

env0:
db $F0
db $00,$F0,$FF
db $F0,$00,$00
db $FF,$FF
env3:
db $F0
db $30,$00,$00
db $FF,$FF
env4:
db $F0
db $18,$00,$00
db $FF,$FF
env5:
db $F0
db $16,$00,$00
db $FF,$FF
env1:
db $F0
db $00,$F0,$08
db $80,$00,$00
db $FF,$FF
env2:
db $F0
db $00,$F0,$03
db $80,$00,$00
db $FF,$FF
env7:
db $80
db $07,$00,$00
db $FF,$FF

include "song.inc"
