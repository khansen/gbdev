shoot_instrument_table:
dw .env0
db $00,$00,$00,$18,$00,$00 ; 0
dw .env0
db $00,$00,$00,$68,$00,$00 ; 1
dw .env0
db $00,$00,$00,$48,$00,$00 ; 2
dw .env0
db $00,$00,$00,$00,$00,$00 ; 3 triangle (infinite)

.env0:
db $F0
db $00,$F0,$FF
db $18,$00,$00
db $FF,$FF

include "shootsong.inc"
