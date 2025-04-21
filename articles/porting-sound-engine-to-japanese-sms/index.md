# Porting a sound engine to the Japanese Sega Master System

_April 21, 2025: Version 1.0_

## Introduction

This article recounts my experiences from porting the Game Boy sound engine
found at https://github.com/khansen/gbdev/tree/master/music (used in recordings
of songs posted on my [YouTube channel](https://www.youtube.com/@notube4me/videos))
to the Japanese Sega Master System (SMS).

The process of porting the Game Boy sound engine to _Sega Game Gear_ was
described in
[this article](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine-to-gamegear/index.md).
It is assumed that the reader is already familiar with that material (the
Game Gear hardware, the song format, and the workings of the engine).

The initial objective and key result of this project was to take the
["Live and Learn - Sonic Adventure 2 - Game Boy remix"](https://www.youtube.com/watch?v=gEnb6_CVO78)
and make it sound good on Sega Master System, utilizing _both sound chips_
(PSG and FM) found in the Japanese model.

The resulting source code can be found [here](https://github.com/khansen/gbdev/tree/master/music/live-and-learn-sms).
You will need [WLA DX](https://github.com/vhelin/wla-dx) to build it.

You can find a recording of the final result here: https://www.youtube.com/watch?v=NLoRQ2rmqMU

## Game Gear versus Master System

Game Gear and Master System have very similar hardware. They have the same Z80
CPU and overall memory map. Game Gear has smaller resolution and better color
palettes. In addition to the Programmable Sound Generator (PSG) chip that's
also found in Game Gear, the Japanese Master System contains an FM sound chip.
I've never before ported the sound engine to a platform with FM sound, so this
looked intriguing &ndash; especially with the fully functional Game Gear port as a
starting point. This allowed me to focus exclusively on the FM aspects (and not
have to deal with the dozen other things that normally come into play when
porting the engine to yet another platform). I figured it was mostly a matter
of adapting the "audio hardware rendering" part of the sound engine to write to
FM registers. It turns out that this was less than half the story.

## Meet the YM2413 FM sound generator

The FM chip found in the Japanese SMS has nine sound channels. Either all nine
channels can be used to play "melodic" sounds, or the chip can be put in Rhythm
Mode, where six channels can play "melodic" sounds and the remaining three
channels are used to provide five kinds of rhythm (percussion) sounds.

> In the initial port of the sound engine, Rhythm Mode is always used. Later, if 
there is a need for it, this could be controlled via a flag in the song header,
for example.

Each FM sound channel is programmed through a set of registers that control the
instrument, pitch, and volume.

### Instruments

For "melodic" sounds, the FM chip provides the following 15 preset instruments:

| ID | Designated name |
|----|-------------|
| 1  | Violin      |
| 2  | Guitar      |
| 3  | Piano       |
| 4  | Flute       |
| 5  | Clarinet    |
| 6  | Oboe        |
| 7  | Trumpet     |
| 8  | Organ       |
| 9  | Horn        |
| 10 | Synthesizer |
| 11 | Harpsichord |
| 12 | Vibraphone  |
| 13 | Synthesizer Bass |
| 14 | Acoustic Bass |
| 15 | Electric Guitar |

Instrument 0 can be programmed to generate custom sounds.

> The initial version of the sound engine only uses preset instruments. It
would be fun to experiment with custom sounds later, to get a better
understanding of how the FM sound synthesis works and hopefully create some
sounds that are less cookie-cutter. But the preset instruments provide an easy
starting point and cover a variety of sounds. For the "Live and Learn" remix,
I found suitable instrumentation (for the lead, bass, synth pads, and so on)
through quick experimentation.

The predefined instruments have fixed (ADSR) volume envelopes, but custom
(software) envelopes can be applied on top of the hardware envelopes by
changing the volume level of the channel.

### Pitch

The frequency of an FM sound channel is specified by a pair of values: A 9-bit
_F-number_ and a 3-bit _Block_ (octave) number. This scheme is different from
the "1-dimensional" period values of NES, Game Boy, and Game Gear, where the
frequency is represented by a single 11- or 10-bit value; as this value grows
or shrinks, the frequency adjusts accordingly. The "non-standard" nature of FM
frequency specifiers presented a challenge, since some key software-managed
effects provided by the sound engine &ndash; slide up, slide down, portamento,
and vibrato &ndash; rely on changing the period value merely by adding
(subtracting) a delta value to (from) the current period value. With the
frequency specifier split into two disparate parts, such a simple
increment/decrement operation is no longer readily applicable. We will return
to this topic in a later section.

### Volume

Just like the PSG sound channels, the FM channels support 16 volume levels.
(Technically, these are _attenuation levels_, where a value of 0 produces
the loudest volume and 15 produces the lowest.)

### Vibrato

FM instruments have a vibrato ON/OFF switch. Unfortunately there is no
way to customize the speed or depth of the vibrato, and it's not possible to
turn vibrato off for the preset instruments. The sound engine provides vibrato
in software (and it can be applied on top of a hardware-generated vibrato, if
it makes sense).

### Triggering a melodic sound

Each FM channel has a "Key On" flag that requires a positive edge trigger
(write 0, then 1) to trigger the sound. This will reset the channel's volume
envelope and other "tone data" according to the selected instrument. So long as
the "Key On" flag is set, the channel's pitch and volume can be updated freely
without fear of retriggering the waveform.

> Each channel also has a "Sustain On" flag which, when set, I suppose will keep
the volume at the Sustain level of the instrument's ADSR envelope until the
flag is cleared (though I haven't verified this behavior). Sustaining the
volume could be useful to prevent some of the preset instruments from fading
out too quickly. The initial version of the sound engine doesn't support the
"Sustain On" flag.

### Percussion sounds

Rhythm Mode "steals" three sound channels that could otherwise be used for
melodic sounds. When Rhythm Mode is enabled, the following percussion sounds
can be played: Bass drum, snare drum, tom-tom, top cymbal, and high hat.
Aggravatingly, percussion sounds are programmed in a style different from the
melodic sounds. Rather than specifying instrument IDs, each percussion sound
is triggered via a positive edge trigger (write 0, then 1) of a bit of the
Rhythm register ($0E):

| Bit | Designated name |
|-----|-------------|
| 0   | High hat    |
| 1   | Top cymbal  |
| 2   | Tom-tom     |
| 3   | Snare drum  |
| 4   | Bass drum   |

For melodic sounds, the 4-bit volume and 4-bit instrument ID of each channel
are written to one 8-bit register. In Rhythm Mode, the volume levels of
percussion sounds are stored across three 8-bit registers:

| Register | High nibble | Low nibble |
|----------|-------------|------------|
| $36      |             | Bass drum  |
| $37      | High hat    | Snare drum |
| $38      | Tom-tom     | Top cymbal |

According to the FM chip documentation, the channels' F-numbers must be set to
prescribed values. For this reason, the sound engine doesn't support variable
pitch for percussion sounds.

Since all percussion sounds can be played simultaneously and have individual
volume controls, they effectively make up five logical channels, that happen to
be mapped to the same sound registers used by the three last melodic channels
in non-Rhythm Mode.

## Track mapping

In the sound engine, tracks of the song are mapped to hardware sound channels
using a fixed mapping. The composer must adhere to this mapping when composing
the song.

Recall that one of the requirements is that the sound engine should be able to
utilize both the PSG sound chip and the FM sound chip in a single song (but
it's up to the composer whether they want to use one or both). I chose to map
tracks 0 to 3 to the PSG channels (like in the Game Gear port), tracks 4 to 9
to FM melodic sounds, and tracks 10 to 12 to FM percussion sounds.

| Track (XM channel) | Description |
|-------|-------------|
| 0     | PSG tone 1  |
| 1     | PSG tone 2  |
| 2     | PSG tone 3  |
| 3     | PSG noise   |
| 4     | FM melody 1 |
| 5     | FM melody 2 |
| 6     | FM melody 3 |
| 7     | FM melody 4 |
| 8     | FM melody 5 |
| 9     | FM melody 6 |
| 10    | FM rhythm 1 |
| 11    | FM rhythm 2 |
| 12    | FM rhythm 3 |

> Why not use five tracks for rhythm, since the five percussion sounds can be
played simultaneously? In practice, I haven't had a need to play more than
three percussion sounds simultaneously: Bass drum, high hat, and snare drum.
To avoid storing a lot of mostly empty rhythm patterns, the instrument data
contains the bit that specifies which percussion sound to trigger, and any
percussion sound can be triggered on any of the three rhythm tracks.

## Step -1: Extending the Song Format

In its previous incarnations, the sound engine only had to support five
tracks per song, at most.

- Each song had a single shared pattern table, for a maximum of 256 unique
patterns per song (or an average of 64 patterns per track, in a song with four
tracks).
- Each song had a single shared order table, for a maximum of 256 entries
per song (or an average order length of 64 per track, in a song with four
tracks).
- Each song had a single shared instrument table, where instruments 0-15 had
a space-efficient 1-byte "Set Instrument" command encoding, but up to 32
instruments were supported.

For the target systems at the time, imposing these limitations made sense,
since they allowed for compact song encoding backed by small and fast playback
code. Only on a few rare occasions did I hit the ceiling because a song was too
long and/or complex, for example in the
["Mega Jean Trooper" remix (NES)](https://github.com/khansen/nesdev/tree/main/music/mega-jean-trooper).
The solution (workaround) in that case was to split the song into two parts
(songs), and have the second part (song) start to play seamlessly when the
first part (song) ended. The song conversion utility doesn't support splitting
the source (XM) file into multiple output songs (and I have no intentions of
extending it to do so), which means that the split has to be done manually by
managing two separate XM files. This split doesn't come completely
for free in terms of storage; the song conversion utility doesn't support
sharing patterns between songs (and I have no intentions of extending it to do
so), which means that data for patterns that could potentially be identical in
the two parts (for example, the chorus) are duplicated. Still, the result is
usually acceptably compact (the "Mega Jean Trooper" remix, player code, and
simple visuals fit in 16KB of program ROM) and the slight inconvenience of
juggling two song files is tolerable.

However, with _13 tracks_, the strategy of sharing the pattern table, order
table, and instrument table between all tracks is no longer viable; at least
one of these limits would likely be reached even for quite short songs. So, I
went back and redesigned the song format to remove the above limitations.

> The reason this is "Step -1" of supporting FM sound is because it's a
completely separate concern from programming the FM chip itself. The new song
format could be backported to the existing sound engines (NES and Game Boy) at
the cost of a slightly (around a few dozen bytes) bigger song header and a few
more CPU instructions needed to fetch per-track data. In return, songs like
the "Mega Jean Trooper" NES remix wouldn't have to be split into multiple
parts.

### Song Header

The new song header format is best explained by looking at the header for the
"Live and Learn" remix (found [here](https://github.com/khansen/gbdev/blob/master/music/live-and-learn-sms/song.inc#L1866)):
```
.db 14 ; channel count 
.db 6 ; speed
.dw song_chn0_order, song_chn0_pattern_table, song_chn0_instrument_table, 0
.dw song_chn1_order, song_chn1_pattern_table, song_chn1_instrument_table, 0
.dw song_chn2_order, song_chn2_pattern_table, song_chn2_instrument_table, 0
.dw song_chn3_order, song_chn3_pattern_table, song_chn3_instrument_table, 0
.dw song_chn4_order, song_chn4_pattern_table, song_chn4_instrument_table, 0
.dw song_chn5_order, song_chn5_pattern_table, song_chn5_instrument_table, 0
.dw song_chn6_order, song_chn6_pattern_table, song_chn6_instrument_table, 0
.dw song_chn7_order, song_chn7_pattern_table, song_chn7_instrument_table, 0
.dw song_chn8_order, song_chn8_pattern_table, song_chn8_instrument_table, 0
.dw song_chn9_order, song_chn9_pattern_table, song_chn9_instrument_table, 0
.dw song_chn10_order, song_chn10_pattern_table, song_chn10_instrument_table, 0
.dw song_chn11_order, song_chn11_pattern_table, song_chn11_instrument_table, 0
.dw song_chn12_order, song_chn12_pattern_table, song_chn12_instrument_table, 0
.dw 0, 0, 0, 0
```
- The first byte is the number of channels (N) in the original XM song (maximum
32).
- The second byte is the initial (default) speed of all tracks.
- Next follows an array of N track descriptors. Each descriptor is an array of
four 16-bit words.
  - The first word is a pointer to the track's order table.
  - The second word is a pointer to the track's pattern table.
  - The third word is a pointer to the track's instrument table.
  - The fourth word is just padding to ensure that each descriptor is a multiple
of eight bytes.
  - If a track is unused (empty), its track descriptor contains four zero
pointers.

### Instrument Tables

Recall that the song conversion utility does not produce the instrument tables
with their instrument definitions; the song header merely _references_ those
tables. The composer (programmer) must provide the actual definitions (i.e.,
make sure that the labels are defined and that the instrument data are proper).

> Note that these are the sound engine's own instrument definitions and
shouldn't be confused with the instruments provided by the FM chip.

From looking at the instrument table pointers in the header
(`song_chn0_instrument_table`, `song_chn1_instrument_table`, and so on), you
might think that each track _must_ have its own set of unique instrument
definitions. However, it's fine to have multiple pointers that point to the
same place in memory! For example, it can make sense to share instruments
between the three PSG tone channels (so that any of those instruments can be
used on any of the three channels):

```
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
...
```

Furthermore, the PSG noise channel can have its own instruments:

```
; Noise channel
song_chn3_instrument_table:
.dw env3
.db $00,$00,$00,$00,$00,$00 ; 0 noise (closed)
.dw env4
.db $00,$00,$00,$00,$00,$00 ; 1 noise (open)
.dw env5
.db $00,$00,$00,$00,$00,$00 ; 2 noise (snare)
...
```

Similarly, the tracks that are mapped to the six melodic FM channels can share
a set of instruments:

```
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
...
```

Lastly, the three tracks that are mapped to the rhythm channels can share
another set of instruments:

```
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
...
```
(The above snippets are instruments from the "Live and Learn" remix,
found in
[this file](https://github.com/khansen/gbdev/blob/master/music/live-and-learn-sms/song.s).)

It's up to the composer (programmer) to decide if they want to share
instruments between some or all tracks; the format merely offers that
flexibility.

A benefit of having separate instrument tables for different (groups of) tracks
is that an instrument ID will quite likely fit in four bits (0..15), so that
the most space-efficient encoding of the "Set Instrument" command can be used;
with a single shared instrument table, most non-trivial songs might surpass 16
instruments in total. Another benefit of multiple instrument tables is that
they make it possible to have more than 32 instruments in total per song.

### Instrument Format

Recall that the sound engine's own instruments are defined by a structure
that's eight bytes in size.

| Offset | Description |
|--------|-------------|
| 0-1 | Pointer to volume envelope |
| 2 | Unused |
| 3 | Default effect |
| 4 | Default effect parameter |
| 5 | Channel-specific data |
| 6 | Unused (padding) |
| 7 | Unused (padding) |

"Channel-specific data" (at offset 5) are interpreted according to which kind
of sound channel &ndash; PSG tone, PSG noise, melodic FM, rhythm FM &ndash; the
track is played on. For melodic FM channels, this byte holds the FM instrument
ID. For rhythm FM channels, this byte holds the percussion sound bit.

### Volume Envelopes

Recall that the song conversion utility does not produce any volume envelope
definitions. The composer (programmer) must provide volume envelopes in the
proper format. The envelope format remains unchanged in this version, so I
won't explain it again here. Conveniently, the FM sound channels support 16
volume levels (just like the PSG channels), making the volume envelopes' 4.4
fixed-point representation of volume levels and deltas a perfect match.

Different instruments can share the same volume envelope &ndash; even
instruments that are played on "heterogeneous" channels (e.g., PSG versus FM).
It's up to the composer (programmer) to decide if they want to share envelopes
between instruments; the instrument format merely offers that flexibility.

### Instruments Mapping File

Recall that the instruments mapping file says how an instrument from the source
(XM) file should be mapped to a target instrument.
[Here](https://github.com/khansen/gbdev/blob/master/music/live-and-learn-sms/instruments.txt)
is the mapping file for the "Live and Learn" remix in its entirety:
```
# Square channels
source:0x10 target:0 transpose:-27
source:0x11 target:1 transpose:-27
source:0x12 target:2 transpose:-27
source:0x01 target:3 transpose:-27
source:0x02 target:4 transpose:-27
source:0x03 target:5 transpose:-27
source:0x26 target:6 transpose:-39
source:0x25 target:7 transpose:-48
# Noise channel
source:0x31 target:0 transpose:-40
source:0x32 target:1 transpose:-40
source:0x33 target:2 transpose:-40
source:0x34 target:3 transpose:-20
source:0x35 target:4 transpose:-40
# Melodic FM channels
source:0x13 target:0 transpose:-22
source:0x14 target:1 transpose:-22
source:0x15 target:2 transpose:-22
source:0x22 target:3 transpose:-34
source:0x21 target:4 transpose:-34
source:0x24 target:5 transpose:-34
source:0x16 target:6 transpose:-22
source:0x17 target:7 transpose:-22
source:0x18 target:8 transpose:-22
# Rhythm FM channels
source:0x39 target:0
source:0x3A target:1
source:0x3B target:2
source:0x3C target:3
source:0x3D target:4
```

Notice that the mapping file doesn't say anything about which _track_ the
instrument is played on. Regardless of where the source instrument is used, it
will be mapped to the same target. There are multiple source instruments that
(seemingly) map to the same target (index). But as we saw earlier, different
tracks can use different instrument tables. Therefore, the instrument mappings
must be seen in conjunction with the instrument table pointers found in the
track descriptors in the song header. I use comments in the mapping file to
delimit groups of instruments that are mapped to a particular instrument table.

### New version of xm2gb

A new (prerelease) version of `xm2gb` that produces output in the new format
currently lives on
[this branch of the xm2gb repository](https://github.com/khansen/xm2nes/tree/xm2gb-wla-dx-nextgen).

## Step 0: Porting the sound engine to idiomatic Z80 (utilizing index registers)

Recall that when porting the sound engine from Game Boy to Game Gear, Game
Boy-specific CPU instructions had to be replaced with standard Z80
instructions. However, I didn't take advantage of the Z80's index registers (IX
and IY) at the time. The index registers greatly simplify accessing fields of
a structure. A substantial amount of the work that went into the Game Boy port
revolved around laying out the data structures in a way that allowed sequential
access of fields, to optimize for code size and performance &ndash; and then a
similar amount of work went into debugging subtle errors related to said field
access, painstakingly stepping through instructions to learn where the
addressing went off the rails. With the Z80's index registers, memory field
access becomes trivial. By refactoring the code to use index registers, the
code size was reduced and the HL register was freed up so it can be used for
other things. But most importantly, the code is much easier to maintain.
Writing the code that renders the FM tracks' state to hardware registers became
easier. The price to pay is that the SMS sound engine code deviates from the
Game Boy in a non-trivial way, meaning that it will require (marginally) more
work to implement fixes and new features on both platforms. But it's easily
worth it.
[This commit](https://github.com/khansen/gbdev/commit/ce22f9ca6dcee66fa8ad62674d0355a881695183)
contains the whole refactoring.

## Step 1: Creating a 1-dimensional "period value" for FM channels

As mentioned, the frequency of an FM sound channel is specified by a pair of
values. The sound engine, however, fundamentally relies on manipulating
so-called "period values" (that represent frequencies) as single integers, and
then writing those integers to hardware registers as the last step. To keep
this core concept, I introduced a _virtual period scheme_ for the FM channels.
This allows the sound engine core to work with the period values it knows and
loves, even for tracks that will be played on FM sound channels. When it's time
to update the hardware registers, the virtual period value is converted to a
pair of values that makes the FM chip produce the desired frequency.

In order for the conversion process to be performant, a lookup table is
employed. We should choose a resolution (bit width) for period values that is
sufficiently large to be able to represent a wide range of frequencies with
high degree of accuracy, but not so large that the lookup table itself takes
up excessive memory.

> This lookup table concept is similar to what was used to implement
[resampling in the Game Boy Advance port](https://github.com/khansen/gbdev/blob/master/articles/implementing-gba-sound-mixer/index.md#periods-frequency-and-resampling).

[This Ruby script](https://github.com/khansen/gbdev/blob/master/scripts/generate_period_table_ym2413.rb)
generates the mapping from virtual period value to FM register values. (The
script was created with help from ChatGPT.) The resolution is set to _11 bits_
(2048 possible values), same as on NES and Game Boy. Each entry of the table
(which contains an F-number and a Block value) occupies 16 bits (two bytes).
The total size of the lookup table (stored in ROM) is therefore four kilobytes.
(That's 12.5% of the total ROM size (32 kilobytes) of the "Live and Learn"
remix ROM. I would call it "non-negligible" rather than "excessive".)

The input to the algorithm is the array of frequencies of musical notes that we
want to represent as virtual period values. The total space of period values
(2048) is then divided to make equal spacing (number of steps) between each
note. The difference in Hertz between the next note and the current note is
used to calculate the increment in frequency per step (period value). Then the
algorithm interpolates the frequency step by step, and for each step finds the
FM register values that _closest approximate the frequency associated with the
period value_.

## Step 2: Unifying period values for the PSG channels and FM channels

Why use 11-bit period values for FM instead of 10-bit? The PSG uses 10-bit
period values, after all. In my experience, 10 bits yield too inaccurate and
course-grained results when you want to cover a rich range of musical notes
(six octaves or more). When I ported the "Live and Learn" remix from Game Boy
to Game Gear, I had to adjust some notes (pitch them up or down by one octave)
because the PSG simply couldn't cover the same range. The double cost of the
lookup table (four kilobytes instead of two) is therefore justified. For an
array of 80 notes (more than six and a half octaves), with 11 bits we get 25
steps ("intermediate period values") from one note to the next, which is
sufficient to produce smooth slide, portamento, and vibrato effects.

Still, it's preferable that all period values use the same scale in the sound
engine core. This allows the same effects processing code to be shared (without
branching logic) between tracks that will be played on PSG channels and tracks
that will be played on FM channels.

A raw PSG period value is "normalized" (i.e., converted from "10-bit descending"
to "11-bit ascending") by multiplying it by two and subtracting the result from
2047. To "denormalize" the value (so that it can be written to PSG hardware
registers), the operations are reversed. This can be done in a few CPU
instructions (no lookup table needed).

## Step 3: Render melodic FM channels

For each melodic channel:

1. If a new note should be triggered, reset the channel's "Key On" flag.
1. Calculate the channel's effective 4-bit volume level.
1. Map the volume level to an attenuation value.
1. Retrieve the 4-bit instrument ID from the instrument data.
1. Combine the attenuation value and instrument ID into an 8-bit value and
write it to hardware register.
1. Look up the F-number and Block values for the current period value.
1. Write the F-number, Block, and "Key On"=1 to hardware registers.

## Step 4: Render rhythm FM channels

Unlike the melodic channels, where each channel has its own dedicated hardware
registers, rhythm channels share a few hardware registers. To accommodate this,
the new state for all five percussion sounds is first combined into
_shadow registers_ that are stored in work RAM, and then the final shadow
register values are copied to the real registers.

For each rhythm channel:

1. Retrieve the percussion sound flag from the instrument data.
1. If a new note should be triggered, reset the percussion sound flag of
the Rhythm register ($0E) and then set the flag.
1. Calculate the channel's effective 4-bit volume level.
1. Map the volume level to an attenuation value.
1. Write the attenuation value to the nibble of the shadow register that
corresponds to the percussion sound flag.

## Step 5: Incorporate FM into the "Live and Learn" remix

I used the "Live and Learn" Game Gear remix as the starting point, keeping
the first and second PSG tone channels and the noise channel practically
identical.

I moved the contents of the third PSG channel &ndash; the bass line &ndash; to
an FM channel. I could then use the third PSG channel to mimick percussion
sounds.

I copied the lead from the PSG tone channel into an FM channel and added an
echo effect in a second FM channel wherever I had an extra channel to spare.

I spent three FM channels on a synth pad that's mostly playing the same chords
as the arpeggios in the second PSG tone channel.

I added percussion based on the drum patterns of the PSG noise channel, using
the bass drum, (closed) high hat, and snare drum sounds. On a few occasions I
added a tom-tom drum.

### Achieving harmony between PSG and FM

One issue I didn't anticipate was that certain notes sounded _out of tune_ when
PSG and FM sounds were played together. I blame this on the coarse-grained
resolution of PSG period values, making them ill-suited for approximating the
precise frequencies of musical notes. I was able to alleviate this issue by
pitching select (sections of) patterns up by one octave.

Initially I had the impression that the FM sound was too loud compared to the
PSG. To be able to utilize different volume levels for the two chips, I created
a separate mapping from volume level to attenuation value for FM. In the end,
for the "Live and Learn" remix, both chips use the same attenuation values,
effectively making the FM sound louder. Since the focus of this remix was on
showcasing FM, it makes sense that PSG is more subdued.

## Step 6: Adding visualization and input handling

The visualization is similar to the Game Gear port, but now there are
_three rows_ of channel (volume) indicators (because all 13 wouldn't fit on
one row!): One row for PSG (4 tracks), one for melodic FM (6 tracks), and one
for rhythm FM (3 tracks).

In previous sound engine ports, tracks could be muted/unmuted by using the
D-pad (one direction per track). But with 13 tracks, there aren't enough
buttons on the joypad to map buttons to particular tracks! So I introduced the
concept of a _currently selected track_. The selected track is drawn with
different (brighter) colors than the other tracks. The selected track index can
be changed by using the D-pad. The selected track can be muted/unmuted by
pressing one of the action buttons.

> One flaw of this "highlighting" approach for indicating the selected track is
that when the selected track is not muted, but completely silent, it's not
possible to see that the track is selected. This could be fixed by drawing some
cursor or outline around or below the track, for example.

In previous sound engine ports, since there were less than eight tracks in
total, the muted/unmuted flags were stored in a single byte, separate from
the individual tracks' state. To keep the implementation simple now that there
can be more than eight tracks, I moved this flag into a new `Status` field of
the track structure.

## Sound engine RAM consumption

The memory that holds the tracks' state is pre-allocated to support the maximum
number of tracks (13). Each track occupies 28 bytes. The total memory occupied
is 28 * 13 = 364 bytes. In addition, the sound engine uses 8 more bytes to hold
various state (including the FM shadow registers), for a grand total of 372
bytes. That's 4.54% of the SMS's 8 kilobytes of work RAM.

## Emulator support

On macOS, the only emulator I've found with plausibly accurate emulation of the
FM chip is [SMS Plus](https://www.bannister.org/software/sms.htm). So far I
haven't had the opportunity to run the "Live and Learn" ROM on real hardware,
so I can't actually tell whether SMS Plus has faithful FM emulation, but let's
hope so, because it sounds good in my ears!

## Conclusion

The YM2413 FM chip provides a sufficient number of channels to make it suitable
for creating rich, layered compositions. FM sound can be combined with the PSG
chip for an even richer (truly retro-sounding) result. For the most parts, the
FM chip is easy to program, despite some quirkiness regarding percussion sounds
and the representation of frequencies.

## Useful resources

- https://www.smspower.org/maxim/Documents/YM2413ApplicationManual
