; Generated from duel.xm by xm2gb 5.0.0
duel_chn0_ptn0:
db $40,$55,$BA,$2D,$2C,$26,$29,$55,$2D,$2C,$26,$29,$55,$2D,$2C,$26
db $29,$55,$2D,$2C,$26,$29,$55,$2D,$2C,$26,$29,$55,$2D,$2C,$26,$29
db $55,$2D,$2C,$26,$29,$55,$2D,$2C,$26,$29
duel_chn1_ptn0:
db $40,$A9,$D0,$F3,$D6,$BA,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D
db $D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29
db $D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA
db $D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6
db $26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26
duel_chn1_ptn1:
db $40,$AA,$D6,$BA,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D
db $D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29
db $D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA
db $D6,$29,$D6,$2D,$D6,$2C,$D6,$26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6
db $26,$AA,$D6,$29,$D6,$2D,$D6,$2C,$D6,$26
duel_chn2_ptn0:
db $40,$01,$B3,$02,$00,$01,$E1,$01,$F3,$00,$01,$E1,$02,$F3,$00,$00
db $00
duel_chn2_ptn1:
db $40,$01,$E1,$03,$F3,$00,$00,$00,$00,$00,$00,$00
duel_chn3_ptn0:
db $40,$03,$D2,$B8,$CA,$0D,$E0,$F3,$03,$C9,$F3,$E0,$F3,$03,$C8,$F3
db $E1,$01,$F3,$03,$C7,$F3,$E1,$01,$F3,$03,$C6,$F3,$E1,$01,$F3,$03
db $C5,$F3,$E1,$01,$F3,$03,$C4,$F3,$E1,$01,$F3,$03,$C3,$F3,$E1,$01
db $F3
duel_chn3_ptn1:
db $40,$03,$C2,$F3,$E1,$01,$F3,$00,$00,$00,$00,$00,$00,$00
duel_pattern_table:
dw duel_chn0_ptn0
dw duel_chn1_ptn0
dw duel_chn1_ptn1
dw duel_chn2_ptn0
dw duel_chn2_ptn1
dw duel_chn3_ptn0
dw duel_chn3_ptn1
duel_song:
db 0,11
db 5,11
db 10,11
db 15,11
dw duel_instrument_table
dw duel_pattern_table
db $00,$00,$00
db $FE,0
db $01,$02,$02
db $FE,5
db $03,$04,$04
db $FE,10
db $05,$06,$06
db $FE,15
