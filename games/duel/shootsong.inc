; Generated from shoot.xm by xm2gb 5.0.0
shoot_chn0_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
shoot_chn1_ptn0:
db $40,$1F,$B1,$E2,$50,$30,$DC,$F3,$D8,$F3,$D4,$F3,$D0,$E0,$F3,$00
db $00,$00,$00,$00,$00,$00
shoot_chn2_ptn0:
db $40,$1F,$B3,$E2,$50,$24,$DC,$F3,$D8,$F3,$D4,$F3,$D0,$E0,$F3,$00
db $00,$00,$00,$00,$00,$00
shoot_chn3_ptn0:
db $40,$01,$B3,$E6,$02,$24,$00,$00,$01,$E0,$F3,$00,$00,$00,$00
shoot_pattern_table:
dw shoot_chn0_ptn0
dw shoot_chn1_ptn0
dw shoot_chn2_ptn0
dw shoot_chn3_ptn0
shoot_song:
db 0,7
db 3,7
db 6,7
db 9,7
dw shoot_instrument_table
dw shoot_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
