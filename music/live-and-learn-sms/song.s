; Square channels
song_chn0_instrument_table:
song_chn1_instrument_table:
song_chn2_instrument_table:
.dw env0
.db $00,$00,$00,$00,$00,$00 ; 0
.dw env0
.db $00,$00,$00,$00,$00,$00 ; 1
.dw env0
.db $00,$00,$00,$00,$00,$00 ; 2
.dw env2
.db $00,$00,$00,$00,$00,$00 ; 3
.dw env6
.db $00,$00,$00,$00,$00,$00 ; 4
.dw env8
.db $00,$04,$72,$00,$00,$00 ; 5
.dw env1
.db $00,$02,$18,$00,$00,$00 ; 6 triangle (snare)
.dw env9
.db $00,$02,$F0,$00,$00,$00 ; 7 triangle (bass drum)

; Noise channel
song_chn3_instrument_table:
.dw env3
.db $00,$00,$00,$00,$00,$00 ; 0 noise (closed)
.dw env4
.db $00,$00,$00,$00,$00,$00 ; 1 noise (open)
.dw env5
.db $00,$00,$00,$00,$00,$00 ; 2 noise (snare)
.dw env7
.db $00,$00,$00,$00,$00,$00 ; 3 weird noise (closed) - reduce
.dw env0
.db $00,$00,$00,$00,$00,$00 ; 4 noise (infinite)

; Melodic FM channels
song_chn4_instrument_table:
song_chn5_instrument_table:
song_chn6_instrument_table:
song_chn7_instrument_table:
song_chn8_instrument_table:
song_chn9_instrument_table:
.dw env12
.db $00,$00,$00,$70,$00,$00 ; 0 pad
.dw env0
.db $00,$00,$00,$60,$00,$00 ; 1 rough lead
.dw env6
.db $00,$00,$00,$60,$00,$00 ; 2 pluck lead
.dw env13
.db $00,$00,$00,$c0,$00,$00 ; 3 short bass
.dw env0
.db $00,$00,$00,$c0,$00,$00 ; 4 infinite bass
.dw env15
.db $00,$00,$00,$c0,$00,$00 ; 5 very short bass
.dw env2
.db $00,$00,$00,$50,$00,$00 ; 6 pluck bridge
.dw env16
.db $00,$00,$00,$70,$00,$00 ; 7 chord bridge
.dw env0
.db $00,$00,$00,$90,$00,$00 ; 8 soft lead

env12:
.db $20
.db $04,$80,$FF
.db $04,$00,$00
.db $FF,$FF

env13:
.db $F0
.db $00,$F0,$07
.db $30,$00,$00
.db $FF,$FF

env15:
.db $F0
.db $00,$F0,$04
.db $50,$00,$00
.db $FF,$FF

env16:
.db $E0
.db $00,$E0,$FF
.db $04,$00,$00
.db $FF,$FF

; Rhythm FM channels
song_chn10_instrument_table:
song_chn11_instrument_table:
song_chn12_instrument_table:
.dw env10
.db $00,$00,$00,$10,$00,$00 ; 0 - bass drum
.dw env10
.db $00,$00,$00,$01,$00,$00 ; 1 - closed hi hat
.dw env10
.db $00,$00,$00,$08,$00,$00 ; 2 - snare
.dw env10
.db $00,$00,$00,$02,$00,$00 ; 3 - open hi hat/cymbal
.dw env10
.db $00,$00,$00,$04,$00,$00 ; 4 - tomtom

env0:
.db $F0
.db $00,$F0,$FF
.db $20,$00,$00
.db $FF,$FF
env3:
.db $F0
.db $38,$00,$00
.db $FF,$FF
env4:
.db $F0
.db $00,$F0,$02
.db $24,$00,$00
.db $FF,$FF
env5:
.db $F0
.db $00,$F0,$01
.db $1E,$00,$00
.db $FF,$FF
env6:
.db $F0
.db $00,$F0,$01
.db $20,$10,$00
.db $70,$80,$00
.db $10,$10,$00
.db $FF,$FF
env1:
.db $F0
.db $18,$00,$00
.db $FF,$FF
env2:
.db $F0
.db $00,$F0,$02
.db $40,$10,$00
.db $90,$A0,$01
.db $28,$10,$00
.db $50,$60,$01
.db $10,$10,$00
.db $FF,$FF
env7:
.db $30
.db $04,$00,$00
.db $FF,$FF
env8:
.db $E0
.db $07,$00,$00
.db $FF,$FF
env9:
.db $F0
.db $00,$F0,$02
.db $30,$00,$00
.db $FF,$FF
env10:
.db $F0
.db $00,$F0,$09
.db $80,$00,$00
.db $FF,$FF
env11:
.db $F0
.db $00,$F0,$04
.db $80,$00,$00
.db $FF,$FF

.include "song.inc"
