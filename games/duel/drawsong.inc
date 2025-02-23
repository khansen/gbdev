; Generated from draw.xm by xm2gb 5.0.0
draw_chn0_ptn0:
db $60,$55,$B2,$E6,$05,$23,$29,$2F,$E6,$03,$35,$00,$00,$00,$01,$E0
db $F3,$00,$00,$00,$00,$00,$00,$00
draw_chn1_ptn0:
db $60,$AB,$D0,$F3,$B2,$E6,$05,$26,$2C,$32,$E6,$03,$38,$00,$00,$00
db $01,$E0,$F3,$00,$00,$00,$00,$00,$00,$00
draw_chn2_ptn0:
db $60,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
draw_chn3_ptn0:
db $60,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
draw_pattern_table:
dw draw_chn0_ptn0
dw draw_chn1_ptn0
dw draw_chn2_ptn0
dw draw_chn3_ptn0
draw_song:
db 0,3
db 3,3
db 6,3
db 9,3
dw draw_instrument_table
dw draw_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
