; Generated from youwin.xm by xm2gb 5.0.0
youwin_chn0_ptn0:
db $40,$5F,$B0,$1F,$E3,$30,$24,$1F,$24,$1F,$E0,$F3,$31,$E6,$02,$F3
db $E6,$04,$28,$E6,$02,$28,$4B,$E6,$04,$29,$E6,$03,$29,$E0,$28,$E4
db $72,$F3,$F8,$DC,$F3,$D8,$F3,$D4,$F3,$D3,$F3,$D2,$F3,$03,$D1,$F3
db $D0,$E0,$F3,$00,$00,$00
youwin_chn1_ptn0:
db $40,$F9,$D0,$F3,$D6,$B0,$1F,$D6,$E3,$30,$24,$D6,$1F,$D6,$24,$D6
db $1F,$32,$E0,$F3,$E6,$04,$2B,$E6,$02,$2B,$4B,$E6,$04,$2E,$E6,$03
db $2E,$E0,$30,$E4,$72,$F3,$F8,$DC,$F3,$D8,$F3,$D4,$F3,$D3,$F3,$D2
db $F3,$03,$D1,$F3,$D0,$E0,$F3,$00,$00,$00
youwin_chn2_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
youwin_chn3_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
youwin_pattern_table:
dw youwin_chn0_ptn0
dw youwin_chn1_ptn0
dw youwin_chn2_ptn0
dw youwin_chn3_ptn0
youwin_song:
db 0,7
db 3,7
db 6,7
db 9,7
dw youwin_instrument_table
dw youwin_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
