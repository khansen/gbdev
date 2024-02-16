SONG_instrument_table:
dw env6
db $00,$00,$00,$10,$00,$00 ; 0
dw env0
db $00,$00,$00,$68,$00,$00 ; 1
dw env0
db $00,$00,$00,$88,$00,$00 ; 2
dw env1
db $00,$00,$00,$00,$00,$00 ; 3 triangle (short)
dw env2
db $00,$00,$00,$00,$00,$00 ; 4 triangle (infinite)
dw env3
db $00,$00,$00,$00,$00,$00 ; 5 noise (closed)
dw env4
db $00,$00,$00,$00,$00,$00 ; 6 noise (open)
dw env5
db $00,$04,$AF,$00,$00,$00 ; 7 noise (snare)
dw env3
db $00,$00,$00,$00,$00,$00 ; 8 triangle (very short)
dw env4
db $00,$00,$00,$80,$00,$00 ; 9 weird noise (closed)
    
env0:
db $F0
db $00,$F0,$FF
db $F0,$00,$00
db $FF,$FF
env1:
db $F0
db $20,$00,$00
db $FF,$FF
env3:
db $F0
db $40,$00,$00
db $FF,$FF
env4:
db $90
db $0D,$00,$00
db $FF,$FF
env5:
db $D0
db $1C,$00,$00
db $FF,$FF
env6:
db $70
db $00,$70,$FF
db $70,$00,$00
db $FF,$FF
env2:
db $F0
db $00,$F0,$FF
db $40,$00,$00
db $FF,$FF

include "song.inc"
