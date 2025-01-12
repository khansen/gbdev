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
db $00,$02,$14,$00,$00,$00 ; 9 triangle (snare)
dw env2
db $00,$00,$00,$68,$00,$00 ; 10
dw env6
db $00,$00,$00,$98,$00,$00 ; 11
dw env8
db $00,$04,$72,$18,$00,$00 ; 12
dw env9
db $00,$02,$80,$00,$00,$00 ; 13 triangle (bass drum)
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
db $F0
db $00,$F0,$02
db $24,$00,$00
db $FF,$FF
env5:
db $F0
db $00,$F0,$01
db $1E,$00,$00
db $FF,$FF
env6:
db $F0
db $00,$F0,$01
db $20,$10,$00
db $70,$80,$00
db $10,$10,$00
db $FF,$FF
env1:
db $F0
db $10,$00,$00
db $FF,$FF
env2:
db $F0
db $00,$F0,$02
db $40,$10,$00
db $90,$A0,$01
db $28,$10,$00
db $50,$60,$01
db $10,$10,$00
db $FF,$FF
env7:
db $70
db $06,$00,$00
db $FF,$FF
env8:
db $E0
db $07,$00,$00
db $FF,$FF
env9:
db $F0
db $00,$F0,$02
db $30,$00,$00
db $FF,$FF
env10:
db $F0
db $00,$F0,$0A
db $80,$00,$00
db $FF,$FF
env11:
db $F0
db $00,$F0,$04
db $80,$00,$00
db $FF,$FF

include "song.inc"
