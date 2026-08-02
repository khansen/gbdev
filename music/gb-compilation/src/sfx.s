EXPORT SFXPatternTable
EXPORT SFXInstrumentTable

SECTION "SFX data", ROM0

SFXPatternTable:
dw SFX0Pattern
dw SFX1Pattern
dw SFX2Pattern
dw SFX3Pattern

SFX0Pattern:
db $02 ; row count
db $01 ; row status
db $b0 ; instrument 0
db 30 ; period index

SFX1Pattern:
db $02 ; row count
db $01 ; row status
db $b1 ; instrument 1
db 20 ; period index

SFX2Pattern:
db $02 ; row count
db $01 ; row status
db $b2 ; instrument 2
db 19 ; period index

SFX3Pattern:
db $10 ; row count
db $11 ; row status
db $b3 ; instrument 3
db 30  ; period index
db $d8 ; set volume
db 30  ; period index
db $11 ; row status
db $d4 ; set volume
db 30  ; period index
db $d2 ; set volume
db 30  ; period index

SFXInstrumentTable:
dw .env0
db $00,$02,$20,$18,$00,$00 ; 0
dw .env0
db $00,$01,$20,$68,$00,$00 ; 1
dw .env0
db $00,$04,$cf,$48,$00,$00 ; 2
dw .env1
db $00,$02,$18,$68,$00,$00 ; 3

.env0:
db $F0
db $10,$00,$00
db $FF,$FF

.env1:
db $F0
db $04,$00,$00
db $FF,$FF
