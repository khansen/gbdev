song_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$68,$00,$00 ; 1
dw env0
db $00,$00,$00,$48,$00,$00 ; 2
dw env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw env7
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw env4
db $00,$02,$10,$00,$00,$00 ; 6 noise (open)
dw env5
db $00,$00,$00,$00,$00,$00 ; 7 noise (snare)
dw env2
db $00,$00,$00,$48,$00,$00 ; 8 riff two
dw env6
db $00,$00,$00,$18,$00,$00 ; 9 riff one
dw env8
db $00,$02,$80,$00,$00,$00 ; 10 triangle (bass drum)
dw env9
db $00,$02,$10,$20,$00,$00 ; 11 triangle (snare)
dw env7
db $00,$00,$00,$00,$00,$00 ; 12 noise (infinite)
dw env10
db $00,$00,$00,$58,$00,$00 ; 13 riff three
dw env11
db $00,$00,$00,$68,$00,$00 ; 14 riff four
dw env12
db $00,$00,$00,$80,$00,$00 ; 15 weird noise (open)

env0:
db $F0
db $00,$F0,$FF
db $10,$00,$00
db $FF,$FF
env7:
db $F0
db $00,$F0,$FF
db $10,$00,$00
db $FF,$FF
env1:
db $F0
db $00,$F0,$06
db $20,$00,$00
db $FF,$FF
env2:
db $F0
db $20,$10,$00
db $70,$80,$00
db $10,$10,$00
db $FF,$FF
env3:
db $F0
db $30,$00,$00
db $FF,$FF
env4:
db $F0
db $00,$F0,$01
db $20,$00,$00
db $FF,$FF
env5:
db $F0
db $00,$F0,$01
db $16,$00,$00
db $FF,$FF
env6:
db $F0
db $00,$F0,$03
db $20,$10,$00
db $FF,$FF
env8:
db $F0
db $00,$F0,$01
db $30,$00,$00
db $FF,$FF
env9:
db $F0
db $00,$F0,$01
db $18,$00,$00
db $FF,$FF
env10:
db $F0
db $00,$F0,$02
db $30,$10,$00
db $90,$A0,$01
db $20,$10,$00
db $60,$60,$01
db $04,$10,$00
db $FF,$FF
env11:
db $F0
db $1C,$10,$00
db $FF,$FF
env12:
db $E0
db $10,$00,$00
db $FF,$FF

include "song.inc"
