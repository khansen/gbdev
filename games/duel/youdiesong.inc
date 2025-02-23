; Generated from youdie.xm by xm2gb 5.0.0
youdie_chn0_ptn0:
db $40,$FF,$B0,$2A,$26,$22,$1E,$29,$25,$21,$1D,$FF,$28,$24,$20,$1C
db $27,$23,$1F,$1B,$4F,$26,$22,$1E,$1A,$E6,$02,$F3,$00,$00,$80,$E0
db $F3,$00,$00
youdie_chn1_ptn0:
db $40,$F9,$D0,$F3,$D6,$B0,$2A,$D6,$26,$D6,$22,$D6,$1E,$D6,$29,$FF
db $D6,$25,$D6,$21,$D6,$1D,$D6,$28,$D6,$24,$D6,$20,$D6,$1C,$D6,$27
db $FF,$D6,$23,$D6,$1F,$D6,$1B,$D6,$18,$D6,$26,$D6,$22,$D6,$1E,$D6
db $1A,$02,$E6,$01,$F3,$00,$00,$08,$E0,$F3,$00
youdie_chn2_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
youdie_chn3_ptn0:
db $40,$01,$D0,$F3,$00,$00,$00,$00,$00,$00,$00
youdie_pattern_table:
dw youdie_chn0_ptn0
dw youdie_chn1_ptn0
dw youdie_chn2_ptn0
dw youdie_chn3_ptn0
youdie_song:
db 0,4
db 3,4
db 6,4
db 9,4
dw youdie_instrument_table
dw youdie_pattern_table
db $00
db $FE,0
db $01
db $FE,3
db $02
db $FE,6
db $03
db $FE,9
