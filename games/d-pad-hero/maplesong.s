maple_instrument_table:
dw .env0
db $00,$00,$00,$18,$00,$00 ; 0
dw .env0
db $00,$00,$00,$68,$00,$00 ; 1
dw .env0
db $00,$00,$00,$48,$00,$00 ; 2
dw .env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw .env7
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw .env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw .env4
db $00,$02,$14,$00,$00,$00 ; 6 noise (open)
dw .env5
db $00,$00,$00,$00,$00,$00 ; 7 noise (snare)
dw .env12
db $00,$00,$00,$80,$00,$00 ; 8 weird noise (open)
dw .env7
db $00,$00,$00,$00,$00,$00 ; 9 noise (infinite)
dw .env2
db $00,$00,$00,$68,$00,$00 ; 10
dw .env6
db $00,$00,$00,$18,$00,$00 ; 11

.env0:
db $F0
db $00,$F0,$FF
db $10,$00,$00
db $FF,$FF
.env7:
db $F0
db $00,$F0,$FF
db $40,$00,$00
db $FF,$FF
.env1:
db $F0
db $00,$F0,$0F
db $40,$00,$00
db $FF,$FF
.env3:
db $F0
db $30,$00,$00
db $FF,$FF
.env4:
db $F0
db $00,$F0,$01
db $16,$00,$00
db $FF,$FF
.env5:
db $F0
db $00,$F0,$01
db $12,$00,$00
db $FF,$FF
.env12:
db $D0
db $08,$00,$00
db $FF,$FF
.env2:
db $D0
db $10,$30,$00
db $70,$80,$00
db $08,$08,$00
db $FF,$FF
.env6:
db $F0
db $08,$10,$00
db $FF,$FF

include "maplesong.inc"
