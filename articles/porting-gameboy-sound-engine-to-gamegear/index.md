# Porting a Game Boy sound engine to Game Gear

_March 9, 2025: Version 0.5_

## Introduction

This article recounts my experiences from porting the Game Boy sound engine
found at https://github.com/khansen/gbdev/tree/master/music (used in recordings
of songs posted on my [YouTube channel](https://www.youtube.com/@notube4me/videos))
to the Sega Game Gear (GG).

How the original NES sound engine was ported to Game Boy was described in
[this article](https://github.com/khansen/gbdev/blob/master/articles/porting-nes-sound-engine/index.md).
It is assumed that the reader is already familiar with that material (the
Game Boy sound hardware, the song format, and the workings of the engine).

The initial objective and key result of this project was to take the
["Live and Learn - Sonic Adventure 2 - Game Boy remix"](https://www.youtube.com/watch?v=gEnb6_CVO78)
and make it sound good on Game Gear.

The resulting source code can be found [here](https://github.com/khansen/gbdev/tree/master/music/live-and-learn-gg).
You will need [WLA DX](https://github.com/vhelin/wla-dx) to build it.

You can find a recording of the final result here: https://www.youtube.com/watch?v=rq-iBr5dsn8

## Game Boy versus Game Gear hardware

### Game Gear versus Sega Master System

It's worth noting that Game Gear's hardware is very similar to the Sega Master
System's (SMS). (Being completely new to Sega systems, this was news to me.)
The main differences between Game Gear and SMS is that Game Gear has smaller
resolution and better color palettes. (Additionally, the Japanese SMS contains
an FM sound chip that's not included in Game Gear.)

### Sound

Game Boy and Game Gear both contain a dedicated chip responsible for generating
sound. The sound chip is programmed through a set of hardware registers that
control settings such as pitch and volume.

Game Boy and Game Gear both have four sound channels, but the channels have
different features and characteristics. Overall, Game Boy's sound chip is
superior to Game Gear's.

Recall that Game Boy has two square wave channels, one sample ("wave")
channel, and one noise channel.

Game Gear's Programmable Sound Generator (PSG model SN76489) contains
three square wave channels and one noise channel.

#### Square wave channels

##### Duty cycles

Game Boy's two square wave channels have four programmable duty cycles.
Game Gear's square wave channels all use a fixed duty cycle of 50%.

```
---+       +-------+       +-------+       +-------+       +----
   |       |       |       |       |       |       |       |
   |       |       |       |       |       |       |       |
---+-------+-------+-------+-------+-------+-------+-------+---- (50% duty cycle)
   |       |       |       |       |       |       |       |
   |       |       |       |       |       |       |       |
   +-------+       +-------+       +-------+       +-------+
`````

On Game Boy (and NES), the variable duty cycles provide a great way to create
different "timbres", which result in more varied and interesting sounds. On
Game Gear, however, all three square wave channels "sound the same", always.
A 50% duty cycle produces the most "pure", but arguably also the most "boring",
square wave. This is a major limitation and disappointment.

##### No sweep functionality

Game Gear's square wave channels don't support sweep functionality like that
found in Game Boy's first square wave channel (also found in the square wave
channels on NES). However, my sound engine never utilized such functionality
(for music, at least) because pitch slide is implemented in software, so this
was no big loss.

##### No hardware envelopes or timers

Game Gear's square wave channels don't support hardware envelopes or timers, 
like Game Boy's (and NES's) channels do. However, my sound engine never utilized
such functionality because volume envelopes are implemented in software.

##### Volume levels

Game Gear's channels all support 16 volume levels, similar to Game Boy's
channels. However, I've found that Game Gear's levels are more quiet than
the levels on Game Boy (more on this in the implementation section).

##### Period values (frequencies)

Period values on Game Gear are 10-bit (0-1023), half the resolution of period
values on Game Boy and NES (0-2047). Game Gear uses a different formula than
Game Boy for converting period values to frequencies. In practice, this
means that a smaller range of music notes is available on Game Gear: The lowest
(approximated) note supported on Game Boy is C-2 (65.41 Hz), while the lowest
(approximated) note supported on Game Gear is A-2 (110 Hz). The highest
(approximated) note supported on both Game Gear and Game Boy is B-7
(3951.07 Hz).

The lower resolution of period values also means that there can be a bigger
pitch error (difference between a music note's true frequency and the output
frequency) than on Game Boy, and that pitch slides (e.g., portamento) don't
have the same fidelity (but in practice, I haven't found this to be very
noticeable to my ear).

#### Noise channel

Game Gear's noise channel has 16 volume levels, like Game Boy, and supports
both periodic (synchronous) and white noise, like Game Boy. However, when
the noise channel is used as a stand-alone channel, the ability to control
its frequency is severely constrained compared to Game Boy, as Game Gear's
noise channel only supports three predefined frequencies. In practice, this
makes for a more uninteresting sound than on Game Boy; in this mode, it's
not possible to do pitch slide effects (such as the whip sound effect in
Castlevania on NES, which I approximated in my "Smooth Criminal" NES cover),
or achieve a wide range of metallic sounds (such as in Mega Man 2's
"Metal Man" stage).

Game Gear's noise channel can operate in a mode where its frequency is tied
to the third square wave channel's period value. This comes at the expense
of "tying down" the square wave channel. By enabling both the noise channel
and the square wave channel at the same time, this could be used to program
drum-like sounds (e.g., by applying pitch slides). I haven't implemented
support for this mode in the sound engine thus far.

### CPU

Game Gear has a standard Zilog Z80 CPU. Game Boy has a Sharp LR35902
CPU, which is a custom Z80-like processor. Game Boy's CPU removes some Z80
instructions and adds a few new ones, most notably the `LDH` ("Load High")
instruction.

### Memory

Game Gear has 8 KB of RAM. Game Boy has 8 KB of Work RAM (WRAM) and 127 bytes
of High RAM (HRAM). Game Boy's High RAM, when accessed through the CPU's custom
`LDH` instruction, plays the same role as the Zero Page on the 6502 CPU (found
in NES and other systems). `LDH` offers a faster and more compact way (smaller
instruction size) to access High RAM (and also memory-mapped I/O ports) than the
standard `LD` instruction. By carefully placing "hot" data and variables in High
RAM, Game Boy code will be faster and smaller than the corresponding Game Gear
code.

### I/O

On Game Gear, I/O is performed using the Z80 `IN` and `OUT` instructions.
Game Boy uses memory-mapped I/O via the `LD` (`LDH`) instruction.

### Graphics

While it's not strictly relevant for the sound engine, I do like to program
graphical effects that complement the music, so it's interesting to see what
the systems have to offer.

- Game Gear has 16 KB of Video RAM (VRAM). The original Game Boy model (DMG-01)
has 8 KB of VRAM, while Game Boy Color (CGB) has 16 KB of VRAM.
- Game Gear and Game Boy both have a resolution of 160x144 pixels.
- Game Gear provides two programmable 16-color palettes (one for background and
one for sprites), where colors are specified as 12-bit RGB values (4096 possible
colors).
- Game Boy Color provides 16 programmable 4-color palettes (eight for background
and eight for sprites), where colors are specified as 15-bit RGB values (32768
possible colors).
- Both systems use tile-based graphics, where a dedicated graphics chip plots
pixels on screen based on a tile map that references a set of tiles.
- On Game Gear, palette data, tile data, and tile map data must be loaded into
VRAM via I/O instructions. On Game Boy, VRAM data can be accessed like "normal"
RAM (`LD` instructions).
- On both systems, tiles are 8x8 pixels in size.
- Game Gear tiles are in planar 4-bit format (16 colors per tile), while Game
Boy tiles are in planar 2-bit format (4 colors per tile).
- Both systems provide horizontal and vertical background scrolling.
- Game Gear supports maximum 64 sprites, while Game Boy supports 40. Sprites
can be either 8x8 (one tile) or 8x16 (two tiles) in size, and can be flipped
horizontally and vertically.

### Input

Game Gear has a D-pad, two action buttons, and a Start/Pause button. (No
Select button.)

### Interrupts

Like Game Boy, Game Gear has a VBlank interrupt that can be triggered
after each frame has been rendered. This is where we can put all our per-frame
logic, such as updating the sound and writing data to VRAM.

Game Gear has a pause interrupt whose handler is called when the
Start/Pause button is pressed. It's a bit awkward that this button isn't
handled the same way as the other buttons (like on Game Boy). Typically, the
pause interrupt handler will set a flag that Start/Pause was requested, and
leave it to the game loop to check this flag.

## Implementation notes

### Implementation strategy

As mentioned, Game Gear uses a standard Z80 CPU, while Game Boy uses a
Z80-like CPU. My idea was to first port the Game Boy sound engine code to
standard Z80, and get that to work on Game Boy. Having a working Z80
implementation meant that I only had to tackle Game Gear-specific aspects
to get sound playing on Game Gear, i.e. writing to the PSG registers.
Fortunately, the code for writing to hardware-specific registers is
already clearly separated from the platform-agnostic parts of the sound
engine.

### Step 0: Getting started with Game Gear development

At first, I considered the possibility of using [RGBDS](https://rgbds.gbdev.io)
(the assembler I've been using for Game Boy development) for developing Game
Gear software. Even though RGBDS is explicitly intended for Game Boy
development, maybe I could stay away from custom Game Boy CPU instructions to
produce a standard Z80 binary, using the memory layout of Game Gear? This
seemed like it could offer the least effort of porting the existing sound
engine code to the new platform. However, after some experimentation, I found
that it's not so straightforward. I therefore set my eyes on the
[WLA DX](https://github.com/vhelin/wla-dx) assembler package instead.

WLA DX supports many target systems, including Game Boy and Game Gear. WLA DX
provides a set of assemblers, one per target CPU (e.g., `wla-gb` and `wla-z80`).
It also provides system-specific assembler directives, like
[.COMPUTESMSCHECKSUM](https://www.villehelin.com/wla-README.html#computesmschecksum),
which meant that I wouldn't need a separate script or tool for producing an
appropriate header with checksum.

I found this ["Hello, World" example](https://github.com/GameGearSamples/HelloWorld)
for Game Gear, which worked fine. For emulation, I chose
[Emulicious](https://emulicious.net) because of its extensive debugging features.

### Step 1: Porting The Game Boy sound engine to WLA DX

My next goal was to implement the "Live and Learn" Game Boy remix with WLA DX,
producing a ROM file that's binary identical to the RGBDS version. You can find
the resulting code here:
https://github.com/khansen/gbdev/tree/master/music/live-and-learn-wla-dx,
and the original RGBDS code here:
https://github.com/khansen/gbdev/tree/master/music/live-and-learn.

Some of the differences between RGBDS and WLA DX are trivial, such as WLA DX
using `.DB` and `.DW` instead of `DB` and `DW` for defining data. The `.DEFINE`
directive has different syntax, but is easy to port.

#### Defining RAM sections

Porting RGBDS's RAM sections to WLA DX wasn't entirely straightforward. I
couldn't find many non-trivial examples of Game Boy projects that use WLA DX
(most of them use RGBDS!). Finally, the
[documented disassembly of Oracle of Ages and Seasons for the Gameboy Color](https://github.com/Stewmath/oracles-disasm/blob/master/include/wram.s)
came to the rescue. I didn't realize that you could use
[an enum to lay out HRAM](https://github.com/Stewmath/oracles-disasm/blob/master/include/hram.s)!
(It can be defined as a regular `.RAMSECTION` as well, which is what I did.)

#### No character maps

WLA DX lacks the equivalent of RGBDS's [character maps](https://rgbds.gbdev.io/docs/v0.9.1/rgbasm.5#Character_maps). Instead, you can define characters using the `.DEFINE` directive:
```
.define CHAR_SPACE $00
.define CHAR_A $01
.define CHAR_B $02
...
```
and then define strings like so:
```
.dw CHAR_L, CHAR_i, CHAR_v, CHAR_e, CHAR_SPACE, CHAR_a, CHAR_n, CHAR_d, CHAR_SPACE, CHAR_L, CHAR_e, CHAR_a, CHAR_r, CHAR_n
```
which is not as readable as the RGBDS version:
```
NEWCHARMAP new
CHARMAP " ", $00
CHARMAP "A", $01
CHARMAP "B", $02
...
SETCHARMAP new
...
DB "Live and Learn"
```
Still, it's the same I did when [porting the sound engine to Game Boy Advance](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine/index.md).

#### Achieving binary equivalence

Once I had WLA DX producing a ROM file, I used [Hex Fiend](https://hexfiend.com)
to compare it to the ROM file produced by RGBDS. I could also compare the
`.sym` files to discover symbols that were not in the expected place in the
WLA DX version.

Soon I was down to just a few small byte sequences that differed, like this one:
```
1A 22 13 0B 78 B1 20 F8 3E 80 E0 68 21 6C 36 0E 20 2A
```

I knew that this was Z80 machine code. I used ChatGPT to disassemble it to
understand why it was different in the WLA DX build.

### Step 2: Porting the WLA DX Game Boy version to standard Z80

Since we are ultimately targeting Game Gear's standard Z80 CPU, we need to
get rid of Game Boy-specific instructions. With WLA DX, we can target Z80
simply by switching from the `wla-gb` assembler to `wla-z80`. `wla-z80`
will give an error when it encounters a Game Boy instruction, so we just
need to fix them all.
```
wla-z80 -o LiveAndLearn.o main.s
main.s:294: ERROR: Cannot process "ldh". Syntax error?
```

[This commit](https://github.com/khansen/gbdev/commit/20d45ce17ff4d3df864e4fbccb0398056e95f29e)
shows all the changes that I made to target Z80.

#### No LDH instruction on Z80

All `LDH` instructions must be converted to plain `LD`; there is no concept of
"High RAM" on Z80. I therefore moved all the variables from High RAM to Work
RAM. Then I could replace instructions like
```
    ldh a, [<hProcessingVBlank]
```
with
```
    ld a, [wProcessingVBlank]
```

#### No SWAP instruction on Z80

Game Boy's `SWAP` instruction exchanges the low and high nibbles (4 bits) of
the A register. In the sound engine, I sometimes use this as a trick to
effectively shift four bits left or right (i.e., multiply or divide a value by
16). The same can be achieved using standard Z80 shift instructions.

Game Boy code:
```
    and $f
    swap a
```
Z80 code:
```
    sla a
    sla a
    sla a
    sla a
```

Game Boy code:
```
    swap a
    and $f
```
Z80 code:
```
    srl a
    srl a
    srl a
    srl a
```

#### No + or - modifier for LD instructions that use the HL register

On Game Boy, `LD` instructions that use the HL register can increment or
decrement HL as part of the same instruction. On Z80, the register must be
incremented or decremented in a separate instruction.

Game Boy code:
```
    ld a, [hl+]
```
Z80 code:
```
    ld a, [hl]
    inc hl
```

Game Boy code:
```
    ld a, [hl-]
```
Z80 code:
```
    ld a, [hl]
    dec hl
```
If we are sure that HL won't cross a page boundary, an optimization is to only
increment or decrement the 8-bit L register. I use this extensively in the
sound engine:
```
    ld a, [hl]
    inc l ; Only safe when we can guarantee that L was less than 255
```

Without using `LDH` instructions, the "Live and Learn" remix build grew by
325 bytes (from 13963 bytes to 14288 bytes); that's roughly 2.33% larger than
when using `LDH`. Combined with the fewer clock cycles spent in `LDH` versus
`LD`, this shows that `LDH` does make a difference.

### Step 3: Porting the sound engine to Game Gear

Finally, we are ready to port the sound engine. This amounts to implementing
the `RenderChannelX` subroutines. You can find the code
[here](https://github.com/khansen/gbdev/blob/master/music/live-and-learn-gg/main.s#L844).
- The waveform is retriggered (channel is turned off and then on again) if a
new note was triggered on the channel.
- The channel volume level is converted to a 4-bit attenuation value.
- The period value is converted to a pair of 4-bit and 6-bit values.

As mentioned earlier, Game Gear and SMS have very similar hardware. This means
that most SMS documentation, tools, and code are also applicable to Game Gear
development. [This SMS technical documentation](https://www.smspower.org/maxim/uploads/HowToProgram/richard.txt)
was very useful, as well as
[this Game Gear hardware reference manual](https://segaretro.org/images/1/16/Sega_Game_Gear_Hardware_Reference_Manual.pdf).
[This SMS tutorial](https://www.smspower.org/maxim/HowToProgram/Index) was helpful.

#### Targeting WLA DX in xm2gb

The `xm2gb` tool that's used to convert XM files to assembly files had to be
adopted to target WLA DX. This just means outputting `.db` and `.dw` instead of
`db` and `dw` for data definitions. I haven't yet merged this feature into the
xm2gb main branch because it needs to be controlled by a switch. Currently the
code lives on
[this branch](https://github.com/khansen/xm2nes/tree/xm2gb-wla-dx).

#### Period table

I wrote [a script](https://github.com/khansen/gbdev/tree/master/scripts/generate_period_table_gg.rb)
to generate a period table for Game Gear.

```
PeriodTable:
.dw                                              $3f8,$3bf,$389 ; A-2 - B-2
.dw $357,$327,$2f9,$2cf,$2a6,$280,$25c,$23a,$21a,$1fc,$1df,$1c4 ; C-3 - B-3
.dw $1ab,$193,$17c,$167,$153,$140,$12e,$11d,$10d,$0fe,$0ef,$0e2 ; C-4 - B-4
.dw $0d5,$0c9,$0be,$0b3,$0a9,$0a0,$097,$08e,$086,$07f,$077,$071 ; C-5 - B-5
.dw $06a,$064,$05f,$059,$054,$050,$04b,$047,$043,$03f,$03b,$038 ; C-6 - B-6
.dw $035,$032,$02f,$02c,$02a,$028,$025,$023,$021,$01f,$01d,$01c ; C-7 - B-7
```

Note that large period values correspond to low frequencies, while small values
correspond to high frequencies. This is inverse of Game Boy (but same as on NES).
The logic for the pitch slide commands (up/down/portamento) therefore had to be
inverted as well.

#### Clamping of period values

Because of the smaller range of period values compared to Game Boy, I implemented
clamping for slide up and slide down to prevent wrap-around of period values.
If a period value is allowed to wrap around (e.g., goes from 1023 back to 0, or
from 0 to 1023), it will cause a very unpleasant effect. On Game Boy I never
experienced such wrap-around issues in practice, so I never bothered to implement
clamping. However, in the conversion of the "Live and Learn" remix to Game Gear,
it was immediately noticeable. To avoid having to go and adjust all pitch slide
commands in the XM to ensure there can be no wrap-around, I implemented clamping.

#### Adjusting volume levels

Initially, I mapped the sound engine's (4-bit) volume levels 1:1 to the
attenuation values of Game Gear's PSG. However, I found that many attenuation
values of the PSG produce _very_ low volumes compared to Game Boy. I therefore
introduced a table that maps the sound engine's volume level to an attenuation
value.
```
ToneAttenuationTable:
.db $0f,$09,$08,$07,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00
```
(Note that on Game Gear, the largest value (15) turns the channel OFF, and the
smallest value (0) sets the volume to maximum.)

As you can see, the full range of Game Gear attenuation values isn't used. But
I found this to be a good compromise that doesn't require adjusting the volume
envelopes of the Game Boy version of the "Live and Learn" remix. (Of course,
adjusting the volume envelopes would be a valid solution, and I might do that
for future (Game Gear-exclusive) remixes; then the attenuation mapping could be
adjusted accordingly.)

I found the noise channel to sound even softer than the square wave channels,
so I used a separate, "louder" attenuation table for that channel:
```
NoiseAttenuationTable:
.db $0f,$07,$06,$05,$04,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00
```

### Step 4: Adjusting the "Live and Learn" remix so it sounds good on Game Gear

The Game Boy version uses some notes that are too low to be played on Game
Gear. I pitched those notes up by one octave.

### Step 5: Porting the visualization

Recall that the Game Boy remix of "Live and Learn" has a screen that
diplays some text, as well as a simple "live" visualization of the volume
levels of the four sound channels.

I took the tiles from the Game Boy version and converted them from 2-bit to
4-bit. Similarly, I converted the Game Boy Color palettes from 15-bit to 12-bit.

I ported the Game Boy code for preparing a buffer in RAM that is copied to
VRAM during VBlank. The main difference is that on Game Gear, entries in the
tile map are 16-bit (two bytes).

### Step 6: Adding input support

I ported the ability to turn individual sound channels on and off using the
D-pad. On Game Gear, the input bits are inverted compared to the Game Boy;
1 means not pressed, 0 means pressed. We can simply invert (XOR) the bits to
keep the button press logic equivalent to the Game Boy version.

### Advantages of Game Gear's PSG chip

One great advantage of Game Gear's sound channels over Game Boy is that the
volume level can be changed without fear of retriggering the waveform. This
means that we don't have to (ab)use hacks like Game Boy's infamous "Zombie mode"
to implement volume envelopes. To retrigger the waveform, the channel must
first be turned off (by setting volume to OFF), and then turned on again. This
is a very nice solution. We don't need to keep copies ("shadows") of sound
registers in RAM to determine whether we need to make updates to the hardware
registers. Similarly, period values can be written to hardware registers
without fear of retriggering the waveform (which is not the case on NES).

Another advantage of Game Gear's channels is that they are rather uniform,
so they are more convenient to program than Game Boy's. The code for
programming all three square wave channels can be shared.

## Conclusion

Game Gear is a fun system that's easy to program, especially if you are
already familiar with Game Boy development. The sound chip is more simplistic
than Game Boy's, but still has its charm.

### Useful resources

- https://segaretro.org/images/1/16/Sega_Game_Gear_Hardware_Reference_Manual.pdf
- https://www.smspower.org
- https://www.smspower.org/maxim/HowToProgram/Index
- https://www.smspower.org/maxim/uploads/HowToProgram/richard.txt
- https://github.com/GameGearSamples/HelloWorld
- https://www.villehelin.com/wla-README.html
- https://wla-dx.readthedocs.io/en/latest/
- https://github.com/TheRavenfreak/Sonic-1-Game-Gear-Disassembly
- https://www.chibiakumas.com/z80/MasterSystemGameGear.php
- https://github.com/lajohnston/smslib
