; Generated from silent.xm by xm2gb 5.0.0
silent_chn0_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
silent_chn1_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
silent_chn2_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
silent_chn3_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
silent_pattern_table:
dw silent_chn0_ptn0
dw silent_chn1_ptn0
dw silent_chn2_ptn0
dw silent_chn3_ptn0
silent_song:
db 0,7
db 3,7
db 6,7
db 9,7
dw silent_instrument_table
dw silent_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
