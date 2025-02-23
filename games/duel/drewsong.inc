; Generated from drew.xm by xm2gb 5.0.0
drew_chn0_ptn0:
db $60,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
drew_chn1_ptn0:
db $60,$11,$B1,$E1,$10,$1F,$D0,$E0,$F3,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00
drew_chn2_ptn0:
db $60,$11,$B1,$E1,$10,$1F,$D0,$E0,$F3,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00
drew_chn3_ptn0:
db $60,$11,$B1,$E1,$30,$13,$D0,$E0,$F3,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00
drew_pattern_table:
dw drew_chn0_ptn0
dw drew_chn1_ptn0
dw drew_chn2_ptn0
dw drew_chn3_ptn0
drew_song:
db 0,3
db 3,3
db 6,3
db 9,3
dw drew_instrument_table
dw drew_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
