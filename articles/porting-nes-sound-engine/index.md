# The process of porting an NES sound engine to Game Boy

_January, 2024: Version 1.0_

_February 4, 2024: Version 1.1_

_February 5, 2024: Version 1.2_

_February 24, 2024: Version 1.3_

_August 8, 2024: Version 1.4_

## Introduction

This article describes how the NES sound engine found at
https://github.com/khansen/dpadhero2/tree/master/src/sound (used in the [D-Pad
Hero games](https://www.dpadhero.com) and recordings of songs posted on my
[YouTube channel](https://www.youtube.com/@notube4me/videos)) was ported to the
Game Boy.

You can find a video version of this article [on YouTube](https://www.youtube.com/watch?v=wAKbWo5_Q7E).

The NES sound engine has largely remained unchanged the last 20 years. (Its
origins can be traced back to circa 1999; the first implementation was written
for the [X816 assembler](https://www.zophar.net/utilities/nesdev/x816-assembler.html),
later it was ported to [xorcyst](https://github.com/khansen/xorcyst).) For this
project, in addition to getting familiar with the Game Boy hardware, I wanted
to take the opportunity to apply some learnings from the early design choices
and consider how the engine could be improved, chiefly by removing unnecessary
complexity (adhering to the
[YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) principle).

The initial objective and key result of this project was to take the ["Super
Mario Land - World 1" remix for NES](https://www.youtube.com/watch?v=En-us1oEono)
and make it sound good on Game Boy. Features were implemented on a strict
need-to-have basis; this engine doesn't yet have full feature parity with the
NES engine. For example, layering sound effects on top of the music – a feature
needed for games – is not implemented.

You can find a recording of the final result here:
https://www.youtube.com/watch?v=LlEKbuuOPG8

## NES versus Game Boy sound hardware

Both NES and Game Boy have two pulse wave channels featuring 16 volume levels,
3 duty cycles, and fine-tuneable pitch.
```
---+       +-------+       +-------+       +-------+       +----
   |       |       |       |       |       |       |       |
   |       |       |       |       |       |       |       |
---+-------+-------+-------+-------+-------+-------+-------+---- (50% duty cycle)
   |       |       |       |       |       |       |       |
   |       |       |       |       |       |       |       |
   +-------+       +-------+       +-------+       +-------+
`````

> The pulse channels have hardware support for volume envelopes, length timers
and pitch sweep. In the sound engine, I've chosen to implement those features
in software instead, as it gives more flexibility, and there isn't too much
overhead involved in doing so.

Both NES and Game Boy have a noise channel with 16 volume levels, supporting
static and "regular" ("tinny") noise, and comparably coarse-grained pitch.

The NES has a triangle wave channel with only 2 volume levels ("on" and "off")
and fine-tuneable pitch.
```
    /\        /\        /\        /\        /\
   /  \      /  \      /  \      /  \      /  \
--/----\----/----\----/----\----/----\----/----\--
 /      \  /      \  /      \  /      \  /      \
/        \/        \/        \/        \/        \
```

The NES has a DPCM (1-bit delta) sample channel with programmable sample data.
This channel does not have any volume control (it's up to the programmer to
define "soft" or "loud" sample data) and only supports a coarse-grained set of
frequencies (whole notes). It's typically used for drums (example: "Super Mario
Bros 3") and bass (examples: "Gremlins 2", "Journey to Silius").

The Game Boy has a 4-bit sample (wave) channel with programmable sample data.
It has 4 volume levels and fine-tunable pitch. The wave form can be programmed
to be a pulse, triangle, sawtooth, sine, or custom shape.

The Game Boy supports panning each channel (hard left, center, hard right).

> For full references on sound hardware, see https://gbdev.io/pandocs/Audio.html
> (Game Boy) and https://www.nesdev.org/wiki/APU (NES).

## Song data

The sound engine consumes song data that can most easily be created by
converting XM (eXtended Module) files using the tool
[xm2nes](https://github.com/khansen/xm2nes/tree/xm2gb). The
[XM format](https://github.com/milkytracker/MilkyTracker/blob/master/resources/reference/xm-form.txt)
was first introduced by the program [FastTracker 2](https://en.wikipedia.org/wiki/FastTracker_2).
For the Game Boy version, I modified `xm2nes` slightly to create `xm2gb`. The
sound capabilities of NES and Game Boy are so similar that not many adjustments
had to be made. Also, the song format is mostly hardware-agnostic, which makes
it easy to adapt to any system that has sound channels with programmable pitch
and volume.

> The philosophy is that the format and core engine can use a relatively "high
level of precision" in software, and then the engine state can be "downscaled"
as necessary when the time comes to materialize the sound on the hardware.

### XM files

An XM contains a set of _patterns_ to be played in a defined _order_.
Patterns can be repeated as necessary (to save space and avoid copy/paste of
identical sections of a song, particularly useful when a song has a
verse-chorus-verse-chorus structure). Each pattern consists of _rows_
(typically 64 per pattern). Each _column_ defines notes and commands/effects
for one _channel_; the first column is channel 0, the second column is channel
1, and so on.

![A pattern in FastTracker 2](assets/ft2-pattern.png?raw=true)

The XM also contains definitions of _instruments_. Each instrument has a wave
form (8- or 16-bit sample data) associated with it. An instrument can have
additional settings, such as a volume envelope, panning, and default vibrato.
In the conversion process, the XM instruments are mapped to instrument
definitions in the sound engine's own format (described later).

### xm2gb

The [xm2gb](https://github.com/khansen/xm2nes/tree/xm2gb) command line utility
parses an XM file, analyzes it and generates its own internal ("optimized")
representation, and outputs an assembly source file. (Example:
https://github.com/khansen/gbdev/blob/master/music/super-mario-land/song.inc)
The source file is compatible with the [rgbds](https://rgbds.gbdev.io/)
assembler. The converted data together with the instrument definitions form a
complete song that can be consumed by the sound engine. (Example:
https://github.com/khansen/gbdev/blob/master/music/super-mario-land/song.s)

### Song format

The song data consists of
- A header
- An order table
- An instrument table (with volume envelope definitions)
- A pattern table

#### The song header

The first part of the header describes the song's _tracks_ and their initial
speed. Think of a track as a virtual channel. The term "track" is used to avoid
confusion with the actual hardware sound channels of the target system. `xm2gb`
maps the channels of the XM (0, 1, 2, 3) 1-to-1 to tracks in the output.
(Additional channels of the XM are ignored.)

The following data is for a song with four tracks:
```
db 0,3   ; track 1 starts at order offset 0 and has initial speed 3
db 41,3  ; track 2 starts at order offset 41 and has initial speed 3
db 82,3  ; track 3 starts at order offset 82 and has initial speed 3
db 123,3 ; track 4 starts at order offset 123 and has initial speed 3
```
The first byte of each two-byte pair is the starting offset of the track within
the order table. If a track is not used at all, this field is set to `$ff`.

The second byte is the initial speed of the track, in number of _ticks (AKA
frames) per row_. Bigger values are slower, and speed 1 is the fastest. In
practice, all tracks in songs converted by `xm2gb` have the same speed –
because there is no way to control the speed of individual channels in an XM.

> The sound engine runs its processing once per frame; this is referred to as a
> _tick_. On the Game Boy, that's approximately 59.73 times per second.

> If you were to write the song data by hand, you could use variable speed per
track, but it seems there's not much to gain from it. The song format could
easily be modified to only store a single initial speed, and the sound engine
could apply it to all tracks.

The last part of the header are the pointers to the instrument table and
pattern table.
```
dw SONG_instrument_table
dw SONG_pattern_table
```

> The song header does not have a version indicator. `xm2gb` includes a comment
> in the generated assembly file that says which version was used (e.g., > _";
> Generated from SONG.XM by xm2gb 3.0.0"_). For each new Game Boy project, I
> make a full copy of the sound engine, and then adjust the implementation as
> necessary whenever I make a (breaking) change to the song format.

#### Order table

The order table follows immediately after the header. It's an array of pattern
indexes for each track. The order table can also contain _commands_ to loop a
part of the order, or jump to a given offset (typically used for looping a song
back to the beginning).

Here's an example of an order table for a song with four tracks:
```
; track 1
db $17,$16,$00,$01,$02,$03,$04,$15,$00,$01,$02,$03,$04,$05,$06,$12
db $07,$08,$0B,$0C,$07,$0D,$0E,$0F,$09,$0A,$09,$0A,$11,$00,$01,$02
db $03,$04,$05,$06,$14,$13,$10
db $FE,0 ; loop back to the beginning
; track 2
db $2D,$2C,$18,$19,$1A,$1B,$1C,$1D,$18,$19,$1A,$1B,$1C,$1D,$1E,$28
db $1F,$20,$23,$24,$1F,$20,$23,$25,$21,$22,$21,$22,$27,$18,$19,$1A
db $1B,$1C,$1D,$29,$2B,$2A,$26
db $FE,41 ; loop back to the beginning
; track 3
db $43,$42,$2E,$2F,$30,$31,$32,$33,$2E,$2F,$30,$31,$32,$33,$34,$3E
db $35,$36,$39,$3A,$35,$36,$39,$3B,$37,$38,$37,$38,$3D,$2E,$2F,$30
db $31,$32,$33,$3F,$41,$40,$3C
db $FE,82 ; loop back to the beginning
; track 4
db $5B,$5A,$44,$45,$46,$47,$48,$57,$44,$45,$46,$47,$48,$49,$4A,$53
db $4B,$4C,$4C,$4F,$4B,$4C,$4C,$50,$58,$59,$4D,$4E,$52,$44,$45,$46
db $47,$48,$49,$54,$56,$55,$51
db $FE,123 ; loop back to the beginning
```

##### Order commands

The NES sound engine supports the following order commands.

|Command byte|Parameter|Description|
|------------|---------|-----------|
| $fb | count | Set the loop offset to the current offset, and set the loop counter to the given count. |
| $fc | - | Loop (decrement the loop counter by one; if not zero, go to the loop offset). |
| $fd | delta | Set the transpose delta to the given (signed) value. All notes in the pattern will be transposed by the given amount. |
| $fe | offset | Go to the given offset in the order table. |
| $ff | - | Stop the track. |

The Game Boy engine so far only implements the $fe command ("Go to offset"). The
other commands haven't been needed. In practice, there aren't many cases where
looping a part of the order yields any benefit. Given the following "plain"
order:

```
db $01,$02,$03,$01,$02,$03
```
It could be written as the following loop:
```
db $fb,2 ; loop twice
db $01,$02,$03
db $fc ; next
```
Both versions occupy 6 bytes of storage. The loop variant is more complex to
execute because it requires state management in the sound engine.

Similarly, I've found it to be rare that all the notes in patterns of a section
of the order can be usefully transposed without needing any other changes to
the pattern data.

> Loops and transposes add complexity to the song converter (to detect common
subsequences, etc.) and the sound engine for no compelling reason, so these
features could safely be scrapped.

#### Instrument table

The instrument table is an array of instruments, each 8 bytes in size.

The instruments are not produced by the `xm2gb` tool itself; the programmer has
to define them by hand. When you invoke `xm2gb`, you pass it the path to an
_instruments mapping file_ that says how the instruments in the XM should be
mapped to instruments in the target song.

```
xm2gb --instruments-map=instruments.txt SONG.XM
```

##### Instruments mapping file

The contents of `instruments.txt` can look like the following (taken from
https://github.com/khansen/gbdev/blob/master/music/super-mario-land/instruments.txt):
```
source:0x10 target:0 transpose:-18
source:0x11 target:1 transpose:-18
source:0x12 target:2 transpose:-18
source:0x22 target:3 transpose:-18
source:0x21 target:4 transpose:-18
source:0x31 target:5 transpose:-18
source:0x32 target:6 transpose:-18
source:0x33 target:7 transpose:-18
source:0x24 target:8 transpose:-18
source:0x34 target:9 transpose:-18
source:0x35 target:10 transpose:-18
source:0x25 target:11 transpose:-18
source:0x26 target:12 transpose:-18
source:0x01 target:13 transpose:-18
source:0x02 target:14 transpose:-18
source:0x03 target:15 transpose:-18
source:0x23 target:16 transpose:-18
```

- `source` is the index of the XM instrument.
- `target` is the index of the instrument it should be mapped to in the output.
- `transpose` defines a (signed) delta that should be added to each note to
produce the final value in the output pattern data.

> To get started on a new song project, I usually make a copy of an entire
> folder of a previous song (including the XM file, the song's assembly (.s)
> file, and instruments mapping file), and zap the song's patterns. Then I
> adjust the instruments mapping and instruments data when it's needed.

##### Instrument structure

All four tracks use the same instrument format. Instruments have the following
structure:

| Offset | Description |
|--------|-------------|
| 0-1 | Pointer to volume envelope |
| 2 | Unused |
| 3 | Default effect |
| 4 | Default effect parameter |
| 5 | Duty cycle settings (only used on pulse channels and noise channel) |
| 6 | Unused (padding) |
| 7 | Unused (padding) |

Here is an excerpt from an instrument table where instruments 0, 1 and 2 all
share the same volume envelope:
```
SONG_instrument_table:
dw env0
db $00,$00,$00,$18,$00,$00 ; 0
dw env0
db $00,$00,$00,$28,$00,$00 ; 1
dw env0
db $00,$00,$00,$8C,$00,$00 ; 2
```

##### Default effect and parameter

The supported effects are described in a later section. Setting a default
effect on the instrument can save space and avoid redundancy/repetitiveness in
the pattern data. The effect will be re-triggered each time a note is triggered.

> In the NES sound engine, "Byte 2" of the instrument could be used to define
> an "effect delay". This would cause the default effect (typically, vibrato)
> to be delayed by a number of ticks. In practice, I found that when I have a
> need to delay an effect, it's better _not_ to set a default effect on the
> instrument, but instead apply the effect in the pattern data on a per-note
> basis. This gives more flexibility and removes some complexity in the sound
> engine, at the expense of slightly larger pattern data size.

> One typical default effect I use for instruments played on the wave channel
> (triangle channel on NES) is "Slide down", to simulate a bass drum or snare
> drum.

##### Duty cycle settings

For an instrument that will be played on a pulse channel, the duty cycle
settings byte defines the initial duty cycle (2 bits), the final duty cycle
(2 bits), and the number of ticks (delay) before changing from the initial to
the final duty cycle (2 bits). (If the delay is 0, initial duty cycle is
ignored.) The layout of the byte is as follows:

```
%iiffdd00
 ||||||
 ++((((--- Initial duty cycle
   ||||
   ++((--- Final duty cycle
     ||
     ++--- Delay
```
As an example:
```
db $2C
```
means: "For the first 3 ticks of playing the note, use duty cycle 00 (12.5%),
then switch to duty cycle 10 (50%)".

> I first became aware of this duty cycle effect when studying the music in
Sunsoft games on the NES, such as Gremlins 2. Rapidly changing the duty cycle
produces an "attack" that can almost make it sound like two instruments are
played at once. It works particularly well with duty cycles 00 and 10 because
they have the biggest contrast (going from "coarse" to "smooth" and vice versa).

> In the NES sound engine, the number of ticks before changing the duty cycle
is a 4-bit value, giving a maximum delay of 15 ticks. In practice, I found that
the values 2 and 3 work best; the effect loses some of its "punch" if the delay
is longer than that. To support those cases where the composer wants to change
the duty cycle at an arbitrary time, I added a dedicated effect that can be
applied to any row in the pattern.

##### Noise channel LFSR width

For an instrument that will be played on the noise channel, the "duty cycle
settings" byte holds the LFSR width in bit 7 (1 = "tinny" noise). It can make
the noise channel sound like a triangle instrument, or like "metal" (the most
famous example being the Metal Man stage music in Mega Man 2).

#### Volume envelopes

A volume envelope specifies the initial volume of the instrument, and how the
volume should change over time. All four tracks use the same envelope format.

Since each instrument has a pointer to a volume envelope, envelopes can be
shared between instruments (and even between songs).

Volume envelopes, like instruments, are not part of the output from `xm2gb`.
You can define volume envelopes for instruments in the XM file itself, but they
are ignored by `xm2gb`.

The volume envelope format is very much inspired by the way volume envelopes
are defined in FastTracker 2: A series of points that the engine will
interpolate between, and the ability to sustain or loop the envelope from a
given point. This can be used to model basic
[ADSR](https://en.wikipedia.org/wiki/Envelope_(music)#ADSR) envelopes as well
as more complex envelopes.

![A volume envelope in FastTracker 2](assets/ft2-envelope.png?raw=true)

The following is the most basic envelope definition; it defines an envelope
that maintains a constant volume until the note is released, then fades out
rather quickly ($f0 / 8 = 30 ticks, approximately half a second):

```
env0:
db $F0 ; initial volume
db $00,$F0,$FF ; delta, target volume, sustain ($FF=until release)
db $08,$00,$00 ; delta, target volume, sustain
db $FF,$FF ; halt
```

The initial volume is an 8-bit value. 255 is maximum volume and 0 is completely
silent.

The next bytes form a series of _triplets_, where
- The first byte is the delta, which is the amount to add to or subtract from
the current volume each tick;
- The second byte is the target volume (0 to 255);
- The third byte is how many ticks the volume should be sustained at the target
volume before proceeding to the next "point" in the envelope. A value of 255
($ff) means that the volume should be sustained forever or until the note is
_released_ (see command types in a later section).

When a delta value of $ff is encountered, it signals the end of the envelope.
The next byte determines whether the envelope processing should be halted
completely ($ff - the volume will remain at the current level), or looped from
the given offset.

> In the NES sound engine, the delta uses an 8.8 fixed-point representation (1
> byte integer part, 1 byte fraction). In practice, I found that using a 4.4
> fixed-point representation (4-bit integer part, 4-bit fraction) gives
> sufficient precision; with an initial volume of 255, a delta of 1 and a
> target volume of 0, it takes approximately 4.2 seconds for the target volume
> to be reached (since the Game Boy framerate is approximately 59.73 Hz). To
> achieve an even longer fade duration, multiple envelope "points" with a delta
> of 1 and a suitable "sustain" amount can be introduced.

The final volume of the track will be scaled according to the track's current
volume level. For example, if the track volume is 50%, the volume envelope
interpolation will still be done at 100% (i.e., using the raw values from the
envelope data), but the volume output from the envelope will be scaled down to
50% when calculating the final volume level of the sound (hardware) channel.

> When composing a song, I initially rely on the basic, constant volume
> envelope, and change the track volume via pattern commands. When I get to the
> "post-production" stage, I introduce dedicated instruments and volume
> envelopes where it makes sense (the savings in storage space can be
> significant).

#### Pattern table

The pattern table is an array of pointers to patterns. The order table contains
indexes of patterns in this table.

The pattern table is shared between all tracks. Technically, it's possible to
use the same pattern in more than one track. In practice, all tracks have their
unique set of patterns, because pattern data is never exactly the same on
different tracks.

> Why use single-track patterns and separate order tables per track, instead of
> multi-track patterns and a common order table (like in the original XM files)?
> Because some tracks are often more regular (repetitive) and/or less "busy"
> than others; for example, the percussion and bass line (typically played on
> the noise channel and wave channel) compared to the lead (typically played on
> a pulse channel). By treating each track separately, we get the best
> opportunities for detecting unique patterns in each track, so that pattern
> data won't be repeated unnecessarily.

A pattern table can look like the following:
```
SONG_pattern_table:
dw SONG_chn0_ptn0 ; 0
dw SONG_chn0_ptn1 ; 1
dw SONG_chn0_ptn2 ; 2
dw SONG_chn1_ptn0 ; 3
dw SONG_chn1_ptn1 ; 4
dw SONG_chn1_ptn2 ; 5
dw SONG_chn2_ptn0 ; 6
dw SONG_chn2_ptn1 ; 7
dw SONG_chn2_ptn2 ; 8
dw SONG_chn3_ptn0 ; 9
dw SONG_chn3_ptn1 ; 10
dw SONG_chn3_ptn2 ; 11
```

##### Pattern data

The pattern data is an encoding of the notes, effects and commands that make up
a pattern of N rows of one track.

A pattern's data can look like the following:
```
SONG_chn1_ptn0:
db $40,$01,$F0,$0D,$E5,$59,$1F,$01,$1F,$01,$E5,$49,$1F,$01,$1F,$01
db $E5,$37,$21,$01,$21,$01,$E5,$59,$1F,$01,$1F
```
The first byte is the number of rows in the pattern (64).

The remaining bytes is a mix of _row status bytes_, notes, and effects and other
commands.

> The storage consumed by patterns can vary greatly depending on how
> "busy"/complex each pattern is.

###### Row status byte

Typically, not every row of a pattern has a new note or effect. To save space,
at the start of every 8th row the pattern data contains a byte that defines
which of the upcoming eight rows have some data defined for them. Rows that
have a 0 bit in the status byte do not have any data. Rows that have a 1 bit in
the status byte have some data. The sound engine processes the bits right to
left (first row status in bit 0, second row status in bit 1, and so on).

Given a row status byte
```
$01
```
this tells us that, of the upcoming eight rows, only the first row has some
data associated with it.

Given a row status byte
```
$ff
```
this tells us that, of the upcoming eight rows, all rows have some data
associated with them.

> I think this approach, on average, compresses as well or better than using a
> "rest" command to encode the delay until the next row with data, and it's
> simple to implement. A pattern with 64 rows will always contain 8 row status
> bytes, regardless of how "busy" the pattern is.

###### Notes

Notes are indexes into a [period table](https://github.com/khansen/gbdev/blob/e276838258c0cd616df67e108ace7cb7b0bbb1de/music/super-mario-land/main.s#L1923).
Value 0 is C2, value 1 is C#2, ..., value 12 is C3, ..., value 24 is C4, ...,
and value 71 is B7.
```
PeriodTable:
dw $02c,$09d,$107,$16b,$1ca,$223,$277,$2c7,$311,$358,$39b,$3db ; 0-11
dw $416,$44e,$483,$4b6,$4e5,$511,$53c,$563,$589,$5ac,$5ce,$5ed ; 12-23
dw $60b,$627,$642,$65b,$672,$689,$69e,$6b2,$6c4,$6d6,$6e7,$6f7 ; 24-35
dw $706,$714,$721,$72d,$739,$744,$74f,$759,$762,$76b,$773,$77b ; 36-47
dw $783,$78a,$791,$797,$79d,$7a3,$7a8,$7ad,$7b2,$7b6,$7ba,$7be ; 48-59
dw $7c2,$7c5,$7c9,$7cc,$7cf,$7d2,$7d4,$7d7,$7d9,$7db,$7dd,$7df ; 60-71
```

The period table was generated by this script
https://github.com/khansen/gbdev/blob/master/scripts/generate_period_table.rb
using the frequency table from https://pages.mtu.edu/~suits/notefreqs.html.

Unlike the NES (see the period table
https://github.com/khansen/dpadhero2/blob/master/src/sound/periodtable.asm#L29),
the larger the period value is on Game Boy, the higher the frequency.

###### Notes and effects and other commands

How the data for a row in the pattern is interpreted depends on the value of
the next byte of pattern data.

- If the value is between $c0 and $cf (inclusive), it's a _set speed_ command.
- If the value is between $d0 and $df (inclusive), it's a _set volume_ command.
- If the value is between $e0 and $ef (inclusive), it's an effect (which can
have a parameter).
- If the value is greater than or equal to $f0, it's an extended command (which
can have a parameter).
- Otherwise, the value is a note, and it signals the end of data for this row.

> What's the difference between a command and an effect? They both change some
> state of the track, but commands are only processed on the first tick of a
> row, whereas effects are processed on all ticks.

Zooming in on this pattern data:
```
$01,$F0,$0D,$E5,$59,$1F
```
- The first byte (row status) tells us that the next row has some data, but the
subsequent seven rows do not.
- $F0,$0D: Set the current instrument to be $0D.
- $E5,$59: Set the current effect to be arpeggio, with a parameter of $59.
- $1F: Play the note $1F (G4).

Indeed, if we look at the pattern in FastTracker 2, we can recognize these eight
rows from the data. (The note in FastTracker 2 (C4) is different because of a
transpose that is applied by the converter.)

![A pattern fragment in FastTracker 2](assets/ft2-pattern-fragment.png?raw=true)

`xm2gb` is smart enough to recognize that the effect (arpeggio $59) is the same
for all eight consecutive rows, so it does not have to be repeated in the
pattern data for each row. Only when the effect or volume setting is
_different_ from the previous row (including _absence_ of effect, 000) will a
new effect or volume be emitted.

###### Effect types

An effect type byte can be followed by a parameter byte, depending on the type
of effect. Effects are processed on every tick. A new effect can only be set at
tick 0 of a new row.

|Effect type byte| Parameter | Description |
|----------------|-----------|-------------|
|$e0| - | Clear effect |
|$e1| rate | Slide up |
|$e2| rate | Slide down |
|$e3| rate | Portamento |
|$e4| speed:depth | Vibrato |
|$e5| delta1:delta2 | Arpeggio |
|$e6| rate | Volume slide (not yet implemented on Game Boy) |
|$e7| rate | Tremolo (Not yet implemented on Game Boy) |
|$e8| ticks | Cut note |
|$e9| duty cycle | Change duty cycle (not yet implemented on Game Boy) |

Effects are described in more detail in a later section.

###### Set speed command

The set speed command ($c0 - $cf) sets the speed to the value of the lower 4
bits of the command byte plus one. The speed is applied to _all_ tracks.

For setting the speed to higher values than 16, an extended command must be
used instead (see below).

###### Set volume command

The set volume command ($d0 - $df) sets the track's master volume to the value
of the lower 4 bits of the command byte multiplied by 16 (0, 16, 32, ..., 240).

###### Extended command types

An extended command type byte ($f0 - $ff) can be followed by a parameter byte,
depending on the type of command. Commands are only processed on tick 0 of a
new row.

|Command type byte|Parameter|Description|
|-----------------|---------|-----------|
|$f0| index | Set instrument.|
|$f1| - | Release (expire volume envelope counter). |
|$f2| speed | Set speed. The speed is applied to _all_ tracks. |
|$f3| - | End of row data. This command signals that a new note should _not_ be triggered for this row, and is typically preceded by an effect (for example, vibrato or slide down).|
|$f4| - | Pan left |
|$f5| - | Pan center |
|$f6| - | Pan right |

> In the NES sound engine, _set speed_ and _set volume_ are both "extended"
commands that occupy 2 bytes. To reduce storage consumption, I introduced the
more compact commands. Songs that use a "swing"/"funky" tempo typically change
the speed every second (even) row of the pattern; by halving the size of each
command, the savings can be tremendous. Similar savings can be achieved for
those cases where manual volume control is used instead of a volume envelope.

## Sound engine architecture

Each tick (the [UpdateSound](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L666)
procedure called from the
[Non-Maskable Interrupt handler](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L245),
approximately 59.7 times per second), the sound engine performs the following
steps for each track:

1. Advance time by one tick. Update row, pattern, and order state appropriately.
Process pattern data for new row (if a new row was reached).
1. Process effect.
1. Process volume envelope.
1. "Render" the track state to sound hardware registers.

Then, we sit back and let the Game Boy hardware output sweet sounds until the
next tick.

### Track data structure

In the NES sound engine, separate data structures are used to represent the
state of each track's stage. The NES sound channels are quite heterogeneous
compared to the Game Boy; in particular, the DPCM channel is completely
different from the other channels. For the Game Boy engine, since the hardware
channels are all configured in a similar way, I opted to represent each track
by a single structure that holds the state associated with all stages:
```
rsreset
def Track_Speed rb 1                                ; 00
def Track_Tick rb 1                                 ; 01
def Track_Pattern_RowCount rb 1                     ; 02
def Track_Pattern_Row rb 1                          ; 03
def Track_Pattern_RowStatus rb 1                    ; 04
def Track_Pattern_Ptr rw 1                          ; 05
def Track_Order_Pos rb 1                            ; 07
def Track_Effect_Kind rb 1                          ; 08
def Track_Effect_Param rb 1                         ; 09
def Track_Effect_Pos rb 1                           ; 0A
rsset Track_Effect_Pos
def Track_Effect_Portamento_Ctrl rb 1 ; bit 7: done if zero. bit 0: direction ; 0A
def Track_Effect_Portamento_TargetPeriodLo rb 1     ; 0B
def Track_Effect_Portamento_TargetPeriodHi rb 1     ; 0C
def Track_MasterVol rb 1                            ; 0D
def Track_PeriodIndex rb 1                          ; 0E
def Track_PeriodLo rb 1                             ; 0F
def Track_PeriodHi rb 1                             ; 10
def Track_Square_DutyCtrl rb 1                      ; 11
def Track_Envelope_Phase rb 1                       ; 12
def Track_Envelope_Ptr rw 1                         ; 13
def Track_Envelope_Pos rb 1                         ; 15
def Track_Envelope_Vol rb 1                         ; 16
def Track_Envelope_Step rb 1                        ; 17
def Track_Envelope_Dest rb 1                        ; 18
def Track_Envelope_Hold rb 1                        ; 19
def Track_SIZEOF rb 0                               ; 1A
```

The same processing is performed on all tracks: They all support the same
effects and "high precision" period values and volume envelopes.

### Track mapping

Tracks are mapped to hardware sound channels using a fixed mapping. The
composer must adhere to this mapping when creating the song.
```
+-------+---------+
| Track | Channel |
+-------+---------+
|   0   | Pulse 1 |
|   1   | Pulse 2 |
|   2   | Wave    |
|   3   | Noise   |
+-------+---------+
```

## Effects processing

### Slide up (down)

The parameter to this effect is the amount (rate) to add to (subtract from) the
period value each tick. A low rate produces a long (slow) slide.

Note that the period table is not linear; the higher the frequency, the smaller
the difference between one period value and the next item in the table. To
maintain a similar rate of change in audible _frequency_, you'll want to use a
higher rate when sliding from a low period value and a lower rate when sliding
from a high period value. The following graph shows the difference between the
entries in the period table (starting with the difference between C#2 and C2
(lowest possible note) and ending with the difference between B7 (highest
possible note) and A#7).

![Period delta between notes](assets/period-delta-between-notes.png?raw=true)

### Portamento

The parameter to this effect is the amount (rate) to add to (subtract from) the
period value each tick until the destination note's period value is reached. A
low rate produces a long (slow) portamento.

### Vibrato

The parameter to this effect is a byte where the high 4 bits define the _speed_
of the vibrato and the low 4 bits define the _depth_ of the vibrato. A small
speed value produces a slow vibrato. A large depth value produces a deep
vibrato. Since the period table is not linear, the composer should usually be
conservative with the depth when applying vibrato to a high note, or else the
vibrato can sound very extreme ("operatic"). (Bubble Man's stage in Mega Man 2
is a good example.)

> Of course, it's up to the composer to decide whether they want an exaggerated
> or moderate effect.

The vibrato effect is produced by looking up a value in a sine table,
multiplying it by the vibrato depth, dividing the result by 128, and
adding/subtracting the final delta value to/from the base period value of the
current note to produce the period value for the current tick. The vibrato
speed determines the _stride_ by which we advance the position in the sine
table each tick. In pseudo-code:
```
delta = (VibratoTable[pos & $1f] * depth) / 128
if pos & $20 == 0 then
  period_value = base_period_value + delta
else
  period_value = base_period_value - delta
end
pos += speed
```
where VibratoTable is defined as follows:
```
VibratoTable:
db $00,$18,$31,$4A,$61,$78,$8D,$A1
db $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
db $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
db $B4,$A1,$8D,$78,$61,$4A,$31,$18
```

### Arpeggio

The parameter to this effect is a byte where the high 4 bits define the delta
to add to the base note on ticks 3 and 4, and the low 4 bits define the delta
to add to the base note on ticks 5 and 6. On the seventh and eight tick, the
base note is played again, and so on, producing a
[very rapid arpeggiated chord](https://en.wikipedia.org/wiki/Arpeggio).

The following diagram shows the note that's played on each tick when the base
note is G4 and the arpeggio parameter is $59, corresponding to a C major in the
[second inversion](https://en.wikipedia.org/wiki/Second_inversion):
```
  Note
   .
  /|\
   |
E5 |               +-------+               +-------+
   |               |       |               |       |
C5 |       +-------+       |       +-------+       |
   |       |               |       |               |
   |       |               |       |               |
G4 +-------+               +-------+               +
   |
   +---+---+---+---+---+---+---+---+---+---+---+---+----> Tick
   0   1   2   3   4   5   6   7   8   9   10  11  12
```

A popular effect achieved with an arpeggio is to use a parameter of $c0 to
alternate quickly between two octaves of a note, to produce a "shrill" sound.
```
  Note
   .
  /|\
   |
C5 |       +-------+               +-------+
   |       |       |               |       |
   |       |       |               |       |
C4 +-------+       +---------------+       +-------+
   |
   +---+---+---+---+---+---+---+---+---+---+---+---+----> Tick
   0   1   2   3   4   5   6   7   8   9   10  11  12
```

### Cut note

The parameter to this effect is the number of ticks after which the note should
be cut (i.e., volume set to zero). This produces a staccato effect. This is
different from the _release_ command, which expires the current "sustain"
counter of the instrument's volume envelope.

## Rendering the track state to sound hardware registers

"Rendering" the track state is the process of converting said state to values
that are written to the sound hardware registers, according to the parameters
and capabilities of the associated channel.

### Pulse channels

#### Duty cycle

The duty cycle bits are derived from the `Track_Square_DutyCtrl` field that
comes from the current instrument's definition.

#### Volume

The pulse channels support 16 volume levels. The output volume is a verbatim
copy of the upper 4 bits of the computed 8-bit volume of the track.

One interesting quirk (and difference from the NES) is that the volume written
to hardware register NRx2 (see
https://gbdev.io/pandocs/Audio_Registers.html#ff12--nr12-channel-1-volume--envelope)
only controls the _initial_ volume of the channel when the channel is triggered
(see https://gbdev.io/pandocs/Audio.html#triggering). Unfortunately, since
retriggering the channel causes the channel to start playing its wave from the
beginning, fading in/out the volume this way sounds ... janky. I figured there
must be a way to lower the volume without retriggering the channel... Just when
I thought all hope was lost, this article
https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware#Obscure_Behavior came
to the rescue:

> "Zombie" mode: the volume can be manually altered while a channel is playing
> by writing to NRx2. ... The only useful consistent behavior is using add mode
> with a period of zero in order to increment the volume by 1. That is, write
> $V8 to NRx2 to set the initial volume to V before triggering the channel,
> then write $08 to NRx2 to increment the volume as the sound plays (repeat 15
> times to decrement the volume by 1). This allows manual volume control on all
> units tested.

Sure enough, it works beautifully! To determine how many times the NRx2
register should be written to increment/decrement the volume, we need only
subtract the previous tick's absolute volume from the current tick's absolute
volume.

#### Period

The pulse channel period is simply copied verbatim from the `Track_PeriodLo`
and `Track_PeriodHi` fields to the corresponding hardware registers.

When a note is played (without portamento effect), the high bit of the
`Track_PeriodIndex` field is set to signal that the channel should be
triggered. This bit is copied to the high bit of the Nrx4 register, then
set to 0.

### Wave channel

#### Wave pattern RAM

So far only one hardcoded wave pattern is supported; it's written to wave
pattern RAM when the program starts up.

> The NES sound engine supports defining a custom set of DPCM samples for each
song. It would be nice to provide a similar capability in the Game Boy engine,
so that different songs (or even a single song) could use different samples for
their instruments.

#### Volume

Unlike the pulse channels and the noise channel, the wave channel supports only
4 volume levels. The output volume is derived from the upper 2 bits of the
computed 8-bit (virtual) volume of the track, according to the following table:

| Upper 2 bits of track's volume | Wave channel volume bits |
|--------------------------------|------------------------|
| 00                             | 00 (no sound) |
| 01                             | 11 (25% volume) |
| 10                             | 10 (50% volume) |
| 11                             | 01 (100% volume) |

#### Period

The period of the wave channel works the same way as the pulse channels.

### Noise channel

#### LFSR width

Bit 7 of the `Track_Square_DutyCtrl` field is copied to bit 3 of the NR43
register (see
https://gbdev.io/pandocs/Audio_Registers.html#ff22--nr43-channel-4-frequency--randomness).

#### Volume

The volume of this channel works the same way as the pulse channels.

#### Period

The noise channel has a different way to define the frequency; it's derived
from a 7-bit value instead of an 11-bit period value like the other three
channels. I wrote a script
https://github.com/khansen/gbdev/blob/master/scripts/generate_noise_table.rb
that computes all the unique frequencies (some 7-bit values produce identical
frequencies). It turns out that there are 63 unique values. I ordered them
from low frequency to high frequency (like the 11-bit period table), and
duplicated the last value to get a table of size 64, so that it can be indexed
by a 6-bit value. Now all that's needed to convert from the 11-bit period value
to 6-bit index is to divide the period value by 32, which is quick to do with a
few shift & rotate instructions.

> The noise channel supports effects like slide up/down and vibrato, but
> because the resolution of the output is lower than the other channels, the
> changes in audible frequency can be more coarse/abrupt.

## Implementation notes

### Implementation strategy

The sound engine is a non-trivial program. It manages quite a lot of state. It
reads and decodes order data and pattern data. It processes effects and volume
envelopes. It translates the state into values that are written to the Game Boy
sound hardware registers. How was I going to port the mature, battle-tested NES
sound engine to a new (unfamiliar) platform in a reasonably effective way?

#### Step 0: Getting started with Game Boy development

The very first step (before it's possible to even think about how to port the
sound engine) was to find a toolchain and get a "Hello, world" program up and
running. Part 1 of the
[GB ASM tutorial](https://gbdev.io/gb-asm-tutorial/part1/setup.html) on
gbdev.io was very useful.

##### Installing rgbds

Full disclosure: My MacBook is so old that it's challenging to compile rgbds
from source. I ended up running an
[Arch Linux image on AWS](https://wiki.archlinux.org/title/Arch_Linux_AMIs_for_Amazon_Web_Services)
and installed rgbds there:
```
sudo pacman -Sy
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -S rgbds
```
I used `scp` to copy files to/from the development machine and my local system.

##### Putting something on the screen

The Game Boy PPU (Picture Processing Unit) is very similar to the NES PPU:
- Nametables are the same.
- Tiles have a very similar format.
- Sprites have a very similar format.
- The concept of only being able to write to PPU memory (VRAM) during the
vertical blanking interval is the same.

My strategy was to learn a sufficient amount of assembly language to be able to
port the basic NES routines for buffered VRAM and sprite memory (OAM) transfer.

I relied (and still rely) heavily on
[rgbds's language reference](https://rgbds.gbdev.io/docs/master/gbz80.7).

This [comprehensive disassembly of Tetris](https://github.com/vinheim3/tetris-gb-disasm/)
is an excellent resource for learning idiomatic Game Boy programming.

#### Step 1: Getting to know the Game Boy sound hardware

Once I had a "Hello, world" program running, I proceeded to write a small test
program that produced sound on each of the four Game Boy sound channels in the
simplest way, so that I could get familiar with the hardware registers and
understand the channels' capabilities and differences. The
[Pan Docs](https://gbdev.io/pandocs/Audio.html) were extremely useful.

#### Step 2: Start processing the song data

Next, I started implementing the "sequencer" part of the sound engine: Reading
and decoding order data and pattern data. I focused on processing just the
first track; since all tracks have the same layout and capabilities, once the
first track works, the others should work too.

I relied heavily on the debugger in the
[SameBoy emulator](https://sameboy.github.io/) to verify that the engine's
state was being updated as desired; stepping through instruction by
instruction, and inspecting memory. The symbol (.sym) file produced by the
rgbds assembler, which lists the addresses of all labels, was tremendously
valuable.

> SameBoy's debugger uses a
[GDB](https://en.wikipedia.org/wiki/GNU_Debugger)-inspired text interface,
> which meant I could quickly get productive with it. SameBoy even reads
> rgbds .sym files and shows the symbolic addresses.

#### Step 3: Materialize some sound

Next, I implemented basic "rendering" of the first track to hardware (first
pulse wave channel), so that I could actually hear some output and didn't
_only_ have to rely on the debugger to check that I was on the right track
(no pun intended).

#### Step 4: Implement volume envelopes and effects

Next, I implemented volume envelope processing, and then effects processing.
Since these are separate stages in the engine's "pipeline"
([EnvelopeTick](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L1726)
and [EffectTick](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L1450)
procedures), they could be commented out/in to make it easier to track down the
source of bugs.

> I sometimes relied on multiplying the song speed by a factor (8) in code to
> slow the song down considerably, so that I could more easily listen and
> understand precisely at which point (pattern/row) something started to go
> wrong with the playback (pattern decoding, effect processing, or envelope
> processing).

#### Step 5: Process all tracks and materialize them

Once I had the first track sounding OK enough, I expanded the processing to two
tracks, then three, then four, adding the hardware "rendering" of each channel
along the way.

There is a separate procedure for rendering each channel:
```
    call RenderChannel1
    call RenderChannel2
    call RenderChannel3
    call RenderChannel4
```
The Game Boy sound channels have similar, but also some distinct, features.
Here's a breakdown:
```
+--------+-------+-------+-------+-------+
| \  Chn |       |       |       |       |
|   \    | Pulse | Pulse | Wave  | Noise |
|     \  |   1   |   2   |       |       |
| Feat  \|       |       |       |       |
+--------+-------+-------+-------+-------+
|        |       |       |       |       |
| Volume |   V0  |   V0  |   V1  |  V0   |
| method |       |       |       |       |
+--------+-------+-------+-------+-------+
|        |       |       |       |       |
| Pitch  |   P0  |   P0  |   P0  |  P1   |
| method |       |       |       |       |
+--------+-------+-------+-------+-------+
|        |       |       |       |       |
| Duty?  |  Yes  |  Yes  |       |       |
|        |       |       |       |       |
+--------+-------+-------+-------+-------+
|        |       |       |       |       |
| LFSR?  |       |       |       |  Yes  |
|        |       |       |       |       |
+--------+-------+-------+-------+-------+
V0: 4-bit volume specifier
V1: 2-bit volume specifier
P0: 11-bit frequency specifier
P1: 7-bit frequency specifier
```
Despite the similarities, I opted for creating a separate procedure for each
channel without any code sharing. These procedures rarely change. I prefer them
to be as simple and decoupled as possible. It's a relief to be able to write a
few pieces of code that don't have to do any dynamic addressing (see the later
section on this topic).

> Sometimes, a little code duplication is fine.

#### Step 6: Add simple visualization

Next, I implemented the visualization of the tracks' status (volume level), and
the ability to turn each channel off/on with the D-pad (just to get some
familiarity with processing input, too).

#### Step 7: Play to the Game Boy's strengths

Finally, I made some adjustments to the song ("Super Mario Land - World 1") to
adapt it to the Game Boy. The original NES version used the DPCM channel for
percussion; I "ported" the percussion to the noise channel on Game Boy. I made
the wave channel (bass line) a bit more "bouncy", since the Game Boy wave
channel comes through a lot better than the triangle channel on the NES, which
has a very soft sound.

### Game Boy CPU impressions

Apparently, the Game Boy CPU is a mix between the Zilog Z80 and the Intel 8080;
I couldn't tell because I'm not familiar with either of those processors. This
is the first project where I've written assembly code for the Game Boy. Here
are some thoughts on porting the code from the NES's 6502.

#### Addressing

_Warning: Long rant ahead!_

##### 6502, AKA "Of course you can index stuff!"

The Game Boy CPU lacks an indexed addressing mode like the 6502. The 6502 has
several indexed addressing modes; both direct (e.g., `LDA $1234, X`) and
indirect (e.g., `LDA [$12], Y`). Indexed addressing modes are extremely useful
when working with (arrays of) structs, where each field has an offset from a
base address. Here are some snippets from the NES sound engine:
```
; Array of track states.
tracks      .track_state[5]
...
; next row
    lda #0
    sta tracks.tick,x   ; reset tick
    inc tracks.pattern.row,x
; check if reached end of pattern
    lda tracks.pattern.row,x
    cmp tracks.pattern.row_count,x
    beq end_of_pattern
...
; advance to next track
    txa
    clc
    adc #sizeof track_state
    tax
    cpx #5*sizeof track_state
    bne track_loop
```
With this approach, we effectively achieve random access to any field of the
struct without having to change the X register, for the whole duration of each
loop iteration (track). We don't have to care much about the layout of the
struct, because accessing any field is "free". If we re-order the fields or add
or remove a field, the code for accessing the fields can remain unchanged; the
assembler will re-compute the offsets for us. In other words, this is an
essential mechanism for writing compact and maintainable code, and on the 6502
I completely take it for granted.

##### Game Boy CPU, AKA "Indexing? Are you absolutely sure you want to do such a thing?"

With the Game Boy CPU, it's only possible to load a value indirectly from or to
the address in one of the 16-bit registers BC, DE or HL. There is no way to
index the base address by either another register or a constant offset as part
of the instruction encoding.

I've never encountered a CPU that had this limitation. I found it to be
incredibly tedious. Apart from `ADD HL, r16`, you cannot add a value directly
to a 16-bit register. The other `ADD` instructions only support the 8-bit A
register as a target. So you'll have to move the low address register to A,
add the offset to A, then copy A back to the low register. Here's a snippet
(taken from the
[implementation of the Set instrument command](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L1337))
where the HL register initially points to the `Track_Effect_Param` field of a
track, and after updating that field, we want to advance to the
`Track_Square_DutyCtrl` field:
```
    ld [hl], a ; Track_Effect_Param
    ld a, l
    add a, Track_Square_DutyCtrl - Track_Effect_Param
    ld l, a
    ld a, [de]
    ld [hl], a ; Track_Square_DutyCtrl
```
That's three instructions (4 bytes, 4 cycles) just to advance HL to the next
field. And the result is only guaranteed to be correct when HL + offset cannot
cross a page boundary; if the addition could cross a page boundary, we have to
check the carry flag as well:
```
    ld a, l
    add a, Track_Square_DutyCtrl - Track_Effect_Param
    ld l, a
    jr nc, .no_page_crossing
    inc h
    .no_page_crossing:
```
Five instructions (7 bytes and at worst 8 cycles)! To avoid the carry flag
check, I make sure that the data structures are aligned so that they are
guaranteed to be placed inside one page.

An alternative approach is to load the offset (constant) into the BC or DE
register, and then add that register to HL.
```
    ld de, Track_SIZEOF
    add hl, de
```
That's only two instructions, but still 4 bytes and 5 cycles. (Such a shame
that there isn't an instruction to load an _8-bit_ constant into a 16-bit
register (zero- or sign-extending it).) Also, normally I can't afford to
clobber the BC or DE register, because those contain other data. Sure, we can
preserve the register with `PUSH` and `POP`:
```
    push de
    ld de, Track_SIZEOF
    add hl, de
    pop de
```
But that brings the instructions up to 6 bytes and 12 cycles! I can't bring
myself to wasting precious resources like that.

###### Auto-increment/decrement of HL to the rescue (somewhat)

The Game Boy CPU provides special forms of the `LD A, [HL]` and `LD [HL], A`
instructions where the HL register is auto-incremented after the load or
store. The sound engine relies heavily on these instructions to avoid
additional pointer arithmetic. Here's an example from the
[implementation of the portamento effect](https://github.com/khansen/gbdev/blob/master/music/super-mario-land/main.s#L1504):
```
    ld a, [hli] ; Track_Effect_Param
    ld c, a
    ld a, [hli] ; Track_Effect_Portamento_Ctrl
    bit 7, a
    jr z, .portamento_exit
    srl a ; CF = direction (0=down, 1=up)
    ld a, [hli] ; Track_Effect_Portamento_TargetPeriodLo
    ld e, a ; save target period lo
    ld a, [hli] ; Track_Effect_Portamento_TargetPeriodHi
    ld d, a
    inc l ; Track_PeriodIndex
    inc l ; Track_PeriodLo
    ld a, [hl] ; Track_PeriodLo
```
That's a lot more compact. But it relies on having "perfect" ordering of fields
in the struct. Notice that in some places `INC L` is used to skip a field. That
is still faster and more compact than having to perform an addition on L via A
(as long as you only have to skip 3-4 bytes).

Notice how we went from hardly having to care about field order at all on the
6502, to field order on the Game Boy CPU becoming _the most important thing_
needed to achieve compact code with low cycle count. This can feel aggravating
and conflicting, especially when the same struct is accessed in different ways
from different parts of the code. The order I ended up with for the track
struct was the result of several iterations. The guiding principle was that the
code on the common/"hot" path of the sound engine should be able to access
consecutive fields, as much as possible.

The downside of the (auto-)incrementing HL approach is that it's very easy to
lose track of what field the HL register actually points to, especially when
there are branches involved. My way to maintain just an inkling of sanity about
this was to comment, on every line involving the HL/L registers, the name of
the field being accessed (as seen in the snippet above). Similarly, below label
definitions I'd comment the name of the field that the HL register should point
to upon entry, and then try to verify that all the branch points respected
this. Still, I had some bugs that required focused debugging sessions, stepping
through a lot of code blocks. Despite the diligent comments, I broke the engine
a few times when removing and re-arranging fields (even though I was careful to
only do and verify such changes one at a time).

Honestly, this "walking up and down memory via HL" ordeal feels uncannily
similar to how a [Turing machine](https://en.wikipedia.org/wiki/Turing_machine)
is described:
> "More explicitly, a Turing machine consists of ... A head that can read and
> write symbols on the tape and move the tape left and right one (and only one)
> cell at a time."

I totally sympathize with the head, and I've begun to think there is a special
place in HL for pointers like these.

> There's a good discussion about Z80 Game Boy addressing on the NESDev forum:
> https://forums.nesdev.org/viewtopic.php?t=14691

##### Useful "direct" operations involving the HL register

The Game Boy CPU provides a few instructions that operate directly on the byte
pointed to by HL: `BIT` (test bit), `RES` (reset bit), `SET` (set bit), `DEC`,
`INC`, and shift/rotate instructions. It's nice that data operations don't
always have to go through the A register.

```
    bit 7, [hl] ; Track_PeriodIndex - check trigger flag
    jr z, .adjust_volume
```

##### High RAM

The Game Boy CPU provides something similar to the zeropage on the 6502, where
the high address byte is implied ($ff). This is useful to shave one byte and
one cycle off of the instruction.
```
    ; check if channels should be (un)muted
    ldh  a, [hButtonsPressed]
    ld b, a
    ldh a, [hSoundStatus]
    bit PADB_UP, b
    jr z, .upNotPressed
```

##### Swapping nibbles

The `SWAP` instruction swaps the low and high 4 bits of the register. In the
sound engine, this was useful on a few occasions, since 4 bits are used to
represent a channel's computed volume, but in the NRx2 hardware register they
are stored in the upper 4 bits. Swapping is a lot more compact than having to
perform 4 shift instructions.
```
    swap a ; initial channel volume in upper 4 bits
```

##### Instructions with surprising effects

The `AND`, `OR` and `XOR` instructions set the carry flag to 0! This tricked me
a few times (and will likely continue to do so). I was expecting the carry flag
to be preserved from a previous instruction.

##### Conditional ret

It's nice that the `RET` instruction can take a condition code.
```
    ldh a, [hVramBufferOffset]
    or a, a
    ret z ; return if zero
    ; carry on...
    xor a, a
```

##### Aligning on a page boundary

I was not able to get the `DS ALIGN` directive in rgbds to work with alignment
greater than 16, so I wrote this macro that pads to the next page:
```
MACRO Align256
ds ((@ + $ff) & $ff00) - @
ENDM
```

### ROM size

The minimum Game Boy ROM size is 32KB. The "Super Mario Land - World 1" remix
fits in 16KB; the last 16KB of `SuperMarioLandWorld1.gb` is just padding.

## Conclusion

The Game Boy CPU has a crippling lack of indexed addressing modes, but the Game
Boy sound chip is cool. The programmable wave channel gives a lot of
possibilities.

### What's next?

Some ideas:
- Convert more existing songs from NES to Game Boy.
- ~~Implement the panning effect (8xx).~~ _Done! (February 24, 2024)_
- Add support for custom wave patterns per instrument.
- ~~Add more fancy visualizations, like in the NES programs (port the code to
Game Boy).~~ _Done! See "Dire, Dire Docks" remix (August 8, 2024)_
- ~~Change the representation of the volume command from $f2 $x0 (2 bytes) to
$dx (1 byte) to reduce storage consumption. (The whole command range $80-$df is
still free to use.)~~ _Done! Also added a compact set speed command (February 4, 2024)_
- Isolate the sound engine to a separate source file (`soundEngine.s`), so that
it can more easily be included in other projects.
