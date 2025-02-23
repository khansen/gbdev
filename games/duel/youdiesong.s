youdie_instrument_table:
dw .env0
db $00,$00,$00,$88,$00,$00 ; 0

.env0:
db $F0
db $00,$F0,$FF
db $18,$00,$00
db $FF,$FF

include "youdiesong.inc"
