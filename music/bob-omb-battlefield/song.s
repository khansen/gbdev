song_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$68,$00,$00 ; 1
dw env0
db $00,$00,$00,$88,$00,$00 ; 2
dw env0
db $00,$00,$00,$00,$00,$00 ; 3 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 4 noise (closed)
dw env4
db $00,$00,$00,$00,$00,$00 ; 5 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 6 noise (snare)
dw env6
db $00,$00,$00,$80,$00,$00 ; 7 weird noise (closed) - reduce
dw env0
db $00,$00,$00,$00,$00,$00 ; 8 noise (infinite)
dw env13
db $00,$00,$00,$18,$00,$00 ; 9
dw env15
db $00,$00,$00,$68,$00,$00 ; 10
dw env13
db $00,$00,$00,$88,$00,$00 ; 11
dw env12
db $00,$00,$00,$18,$00,$00 ; 12

env0:
db $C0
db $00,$C0,$FF
db $18,$00,$00
db $FF,$FF
env3:
db $A0
db $20,$00,$00
db $FF,$FF
env4:
db $F0
db $14,$00,$00
db $FF,$FF
env5:
db $F0
db $28,$00,$00
db $FF,$FF
env6:
db $90
db $06,$00,$00
db $FF,$FF
env12:
db $F0
db $50,$10,$00
db $50,$F0,$00
db $FF,$01
env13:
db $90
db $0E,$10,$00
db $80,$90,$00
db $20,$10,$00
db $80,$90,$00
db $08,$28,$00
db $FF,$FF
env15:
db $C0
db $08,$00,$00
db $FF,$FF    

include "song.inc"
