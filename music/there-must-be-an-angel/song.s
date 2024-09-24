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
dw env0
db $00,$00,$00,$80,$00,$00 ; 7 weird noise (closed) - reduce
dw env0
db $00,$00,$00,$00,$00,$00 ; 8 noise (infinite)
dw env1
db $00,$02,$18,$00,$00,$00 ; 9 triangle (snare)
dw env2
db $00,$00,$00,$68,$00,$00 ; 10
dw env2
db $00,$00,$00,$4C,$00,$00 ; 11
dw env6
db $00,$05,$C0,$98,$00,$00 ; 12

env0:
db $C0
db $00,$C0,$FF
db $08,$00,$00
db $FF,$FF
env3:
db $D0
db $30,$00,$00
db $FF,$FF
env4:
db $F0
db $20,$00,$00
db $FF,$FF
env5:
db $F0
db $28,$00,$00
db $FF,$FF
env6:
db $B0
db $0C,$10,$00
db $50,$60,$00
db $0C,$00,$00
db $FF,$FF
env1:
db $F0
db $0D,$00,$00
db $FF,$FF
env2:
db $F0
db $30,$20,$00
db $A0,$B0,$00
db $20,$20,$00
db $70,$80,$00
db $08,$20,$00
db $FF,$FF

include "song.inc"
