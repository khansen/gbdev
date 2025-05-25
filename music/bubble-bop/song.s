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
db $00,$00,$00,$80,$00,$00 ; 7 weird noise (closed) - reduce
dw env0
db $00,$00,$00,$00,$00,$00 ; 8 noise (infinite)
dw env1
db $00,$02,$1C,$20,$00,$00 ; 9 triangle (snare)
dw env2
db $00,$00,$00,$00,$00,$00 ; 10
dw env6
db $00,$05,$C0,$68,$00,$00 ; 11
dw env8
db $00,$00,$00,$18,$00,$00 ; 12
dw env9
db $00,$00,$00,$00,$00,$00 ; 13 triangle (short)
dw env10
db $00,$02,$F0,$20,$00,$00 ; 14 triangle (bass drum)

env0:
db $F0
db $00,$F0,$FF
db $18,$00,$00
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
db $1A,$00,$00
db $FF,$FF
env6:
db $F0
db $30,$10,$00
db $60,$70,$00
db $0B,$00,$00
db $FF,$FF
env1:
db $F0
db $1A,$00,$00
db $FF,$FF
env2:
db $F0
db $1C,$00,$00
db $FF,$FF
env7:
db $A0
db $07,$00,$00
db $FF,$FF
env8:
db $F0
db $28,$10,$00
db $50,$60,$00
db $08,$08,$00
db $FF,$FF
env9:
db $F0
db $00,$F0,$07
db $30,$00,$00
db $FF,$FF
env10:
db $F0
db $30,$00,$00
db $FF,$FF

include "song.inc"
