# Porting a Game Boy sound engine to Game Boy Advance

_September 20, 2024: Version 1.0_

## Introduction

This article recounts my experiences from porting the Game Boy sound engine
found at https://github.com/khansen/gbdev/tree/master/music (used in recordings
of songs posted on my [YouTube channel](https://www.youtube.com/@notube4me/videos))
to the Game Boy Advance (GBA).

How the original NES sound engine was ported to Game Boy was described in
[this article](https://github.com/khansen/gbdev/blob/master/articles/porting-nes-sound-engine/index.md).
It is assumed that the reader is already familiar with that material (the
Game Boy sound hardware, the song format, and the workings of the engine).

The initial objective and key result of this project was to take the
[Super Mario 64 - "Main Theme" ("Bob-omb Battlefield")](https://www.youtube.com/watch?v=mvgoAMDfLjE)
Game Boy version and make it sound good on Game Boy Advance (preferably identical to
Game Boy).

The result can be found [here](https://github.com/khansen/gbdev/tree/master/music/bob-omb-battlefield-gba).
The [README](https://github.com/khansen/gbdev/blob/master/README.md#game-boy-advance)
contains instructions on how to build the ROM file.

## Game Boy versus Game Boy Advance hardware

### Sound

The Game Boy Advance includes four legacy sound channels that are inherited from
the original Game Boy: Two square wave channels, one waveform channel, and one
noise channel. Perfect, just what we need for making a 1:1 port of the Game Boy
sound engine!

Additionally, the GBA has two so-called "direct" sound channels, which can play 8-bit
PCM sample data. At first, I thought that utilizing the GBA's direct sound channels
would be outside the scope of this porting effort. While the engine could be extended
to support these channels, the purist in me renounces the idea of utilizing
general-purpose digital audio waveforms, as it arguably takes the charm and challenge
away.

However, due to a behavorial difference between the Game Boy Advance and the original
Game Boy's sound hardware, I've had to backtrack on this decision. More on that later.

A big appeal of the legacy sound channels is that they require at most a few hundred
CPU instructions in total to program one frame (approximately 1/60th of a second)
worth of audio. A sound mixer that's implemented in software requires orders of
magnitude more CPU. Streaming PCM data from ROM requires storage. By utilizing
only the legacy sound channels, those precious resources can be spent on other
things (such as rendering advanced 3D graphics).

### CPU

The Game Boy CPU is an 8-bit microprocessor that is a hybrid design based on the
Zilog Z80 and Intel 8080 CPUs, running at 4.19 MHz.

The GBA uses a 32-bit ARM (ARM7TDMI) CPU, running at 16.78 MHz. It supports both
32-bit and 16-bit (Thumb) instruction sets. In the initial conversion, I've
chosen the 32-bit instruction set for simplicity and performance.

### Memory

The Game Boy has 8 KB of Work RAM (WRAM) and 127 bytes of High RAM (HRAM).

The GBA has 32 KB of Internal Working RAM (IWRAM) and 256 KB of External Working
RAM (EWRAM). In this project, I've only made use of IWRAM (32 KB still feels
extremely luxorious and takes some time getting used to).

### Memory-mapped I/O

Like the Game Boy and the NES, the GBA uses memory mapped I/O for (among other
things) programming the sound hardware, configuring the graphics hardware, and
reading the joypad. Additionally, the GBA has powerful Direct Memory Access (DMA)
support that enables hardware-assisted (lightning fast) memory transfer between
any parts of memory.

### Graphics

The GBA supports tile-based graphics modes (like the Game Boy, only more
powerful), but also bitmapped (framebuffer) modes, with 15-bit or 8-bit
(indexed) colors. To minimize CPU time spent on drawing, it's best to stick
with the hardware-assisted tile-based modes when possible.

### Interrupts

Like the Game Boy, the GBA has a VBlank interrupt that can be triggered after
each frame has been rendered. This is where we will put all our per-frame logic:
Read the joypad, update sound, update objects, write sprites to Object Attribute
Memory, and write tilemap data or bitmap data to Video RAM.

## Step 0: Getting started with Game Boy Advance development

The very first step (before it's possible to even think about how to port the
sound engine) was to find a toolchain and get a "Hello, world" GBA program up and
running. When I asked ChatGPT which toolchain is recommended for modern GBA
development, they suggested `arm-none-eabi-gcc`. Cool, we can use vanilla GCC,
no custom or proprietary tools needed. On Mac, I installed it via Homebrew:
```
brew install --cask gcc-arm-embedded
```
> The version that can be installed with `brew install arm-none-eabi-gcc` didn't work
for me, and after some googling I arrived at `gcc-arm-embedded`.

Finding or writing a "Hello, world" program written in assembly language turned out
to be the first challenge. ChatGPT's minimal example produced a ROM that failed to
load in the [mGBA](https://mgba.io) emulator. With the help of a few guides and
repositories for development in C (https://github.com/AntonioND/gba-bootstrap,
https://gist.github.com/JShorthouse/bfe49cdfad126e9163d9cb30fd3bf3c2, and
https://github.com/Ankeraout/minimal-gba-project), I was able to cobble together a
linker script that produced a ROM with a valid header.

The joy of seeing a line of self-painted pink pixels on the screen was shortlived.
Time to move on to the real task at hand.

## Step 1: Getting to know the GBA sound hardware registers

Here are some resources for learning the GBA hardware:

- https://problemkaputt.de/gbatek.htm
- https://www.coranac.com/tonc/text/toc.htm
- https://gbadev.net/gbadoc/intro.html
- http://www.belogic.com/gba/registers.shtml

The registers of the legacy sound channels have gotten new names and are 16 bits
wide instead of 8 bits, but their contents and behaviors mostly correspond 1:1 to
the original Game Boy registers (except for one agonizing, hairloss-inducing crucial
difference, which we'll get back to).

Like I had done when porting the NES sound engine to Game Boy, I proceeded to write
a small test program that produced sound on each of the four legacy sound channels
in the simplest way. This gave me an idea of what I needed to work towards to
materialize sound in the new engine.

I decided to separate the sound engine into its [own assembly file](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/sound_engine.s)
this time, so that it can be assembled independently of the rest of the program
(song data, graphics code, etc.).

## Step 2: xm2gba

Like [xm2nes](https://github.com/khansen/xm2nes/tree/master) before it, the
[xm2gb](https://github.com/khansen/xm2nes/tree/xm2gb) command line utility converts
an XM (eXtended Module) ("song") file into the Game Boy sound engine's own format,
represented as a Game Boy assembly file. I adapted `xm2gb` to produce an ARM
assembly file instead: Say hello to [xm2gba](https://github.com/khansen/xm2nes/tree/xm2gba)!

> At some point, I should unify the NES, GB and GBA converters into one application, with
a parameter that specifies the desired output format. There are a few space optimizations
and bug fixes in the GB converter that haven't yet been backported to NES.

[Game Boy assembly output](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield/song.inc):
```
; Generated from song.xm by xm2gb 4.0.1
song_chn0_ptn0:
db $40,$BF,$F0,$02,$23,$E3,$F0,$24,$E0,$F3,$D4,$F3,$E3,$F0,$21,$E0
db $F3,$D4,$F3,$FF,$23,$E3,$F0,$24,$E4,$53,$F3,$D4,$F3,$E3,$F0,$26
db $D4,$E0,$F3,$23,$E3,$F0,$24,$5F,$E4,$53,$F3,$D4,$F3,$E0,$1B,$E3
...
```

[GBA (ARM) assembly output](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/song_data.s):
```
@ Generated from song.xm by xm2gba 4.0.1
.section .rodata
.global song_song
.extern song_instrument_table
song_chn0_ptn0:
.byte 0x40,0xBF,0xF0,0x02,0x23,0xE3,0xF0,0x24,0xE0,0xF3,0xD4,0xF3,0xE3,0xF0,0x21,0xE0
.byte 0xF3,0xD4,0xF3,0xFF,0x23,0xE3,0xF0,0x24,0xE4,0x53,0xF3,0xD4,0xF3,0xE3,0xF0,0x26
.byte 0xD4,0xE0,0xF3,0x23,0xE3,0xF0,0x24,0x5F,0xE4,0x53,0xF3,0xD4,0xF3,0xE0,0x1B,0xE3
...
```

### Changes to song header layout

With the ARM CPU, data in memory must be aligned according to their size; 32-bit data
on 4-byte boundaries and 16-bit data on 2-byte boundaries. To achieve the required
alignment with minimal amount of padding between fields, we can order fields according
to their width; first, all 32-bit (word) fields, followed by 16-bit (half-word) fields,
and finally 8-bit (byte) fields.

On the GBA, in 32-bit ARM mode, pointers are 32-bit. We must ensure that the pattern
pointer table is aligned on a 4-byte boundary.
```
.align 4
song_pattern_table:
.word song_chn0_ptn0
.word song_chn0_ptn1
.word song_chn0_ptn2
```
The assembler will insert padding before the table, if needed.

The song header follows immediately after the pattern pointer table. On the Game Boy,
the song header looked like [this](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield/song.inc#L820):
```
db 0,5
db 40,5
db 80,5
db 120,5
dw song_instrument_table
dw song_pattern_table
```

On the GBA, the song header looks like [this](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/song_data.s#L836):
```
.word song_instrument_table
.word song_pattern_table
.byte 0,5
.byte 41,5
.byte 82,5
.byte 123,5
```

The pointers to the instrument table and pattern table are placed first. They are
guaranteed to be 4-byte aligned because the preceding table of pattern pointers is
already aligned.

## Step 3: Porting the sound engine code

Overall, this was a lot easier than porting the NES sound engine to Game Boy,
despite Game Boy assembly and GBA assembly being just as different. I had the Game
Boy code and the GBA code open in the editor, side by side. I painstakingly ported
one instruction at a time, in a mostly mechanical fashion (further optimizations
are left for later). Subroutine names, variables and other labels were kept
identical to the Game Boy version.

> In this process, I even discovered some quirks in the Game Boy sound engine that
will be corrected.

![Game Boy vs Game Boy Advance assembly code](assets/gb-vs-gba-code.png?raw=true)

### Local labels in GCC

One annoyance with the GCC assembler is that it doesn't allow human-friendly
local labels; you have to use names like 1, 2, 3, ...
```
    ldrb r3, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*3)]
    tst r3, #0x80 @ LFSR width  
    beq 1f @ no_regular_output
    orr r2, r2, #8 @ 7-bit output
    1: @ no_regular_output
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    2: @ no_trigger
```

In any non-trivial subroutine with lots of branch logic, this can get out of hand
(`1f`, `2f`, `3f`, `2b`, `1f`, ...). Suddenly you've accidentally branched to the
wrong label. I strived to use local labels only in cases where the jump was very
short, and avoided branching back and forth between multiple local labels. Instead
I used a convention of prefixing "pseudo-local" labels with the name of their
"parent" label to make them both unique and descriptive:
```
update_sound:
    push {r4, r5, lr}
    ldr r0, =tracks
    ldrb r1, =NUM_TRACKS
update_sound__loop: @ pseudo-local label (not meant to be branched to from the outside)
    ldrb r2, [r0, #TRACK_SPEED_BYTE]
```

### Changes to track layout

As with the song header, I changed the layout of the track data structure to satisfy
alignment requirements on ARM.

If you recall, [this](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield/main.s#L125)
is what the track layout looks like on the Game Boy:
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
[This](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/sound_engine.s#L1)
is what the track layout looks like on the GBA (words, then half-words, then bytes):
```
.equ TRACK_PATTERN_PTR_WORD,    0
.equ TRACK_ENVELOPE_PTR_WORD,   4
.equ TRACK_PERIOD_HWORD,        8
.equ TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD, 10
.equ TRACK_SPEED_BYTE,          12
.equ TRACK_TICK_BYTE,           13
.equ TRACK_PATTERN_ROWCOUNT_BYTE, 14
.equ TRACK_PATTERN_ROW_BYTE,    15
.equ TRACK_PATTERN_ROWSTATUS_BYTE, 16
.equ TRACK_ORDER_POS_BYTE,      17
.equ TRACK_EFFECT_KIND_BYTE,    18
.equ TRACK_EFFECT_PARAM_BYTE,   19
.equ TRACK_EFFECT_POS_BYTE,     20
.equ TRACK_EFFECT_PORTAMENTO_CTRL_BYTE, 21
.equ TRACK_MASTERVOL_BYTE,      22
.equ TRACK_PERIODINDEX_BYTE,    23
.equ TRACK_SQUARE_DUTYCTRL_BYTE, 24
.equ TRACK_ENVELOPE_PHASE_BYTE, 25
.equ TRACK_ENVELOPE_POS_BYTE,   26
.equ TRACK_ENVELOPE_VOL_BYTE,   27
.equ TRACK_ENVELOPE_STEP_BYTE,  28
.equ TRACK_ENVELOPE_DEST_BYTE,  29
.equ TRACK_ENVELOPE_HOLD_BYTE,  30
.equ TRACK_SIZEOF,              32
```
There is 1 byte of padding to make the structure 32 bytes long (multiple of 4).

### Indexed addressing modes

I'm sure you all remember from the video about the NES to Game Boy port that
my biggest gripe with the Game Boy CPU is that it doesn't have any indexed
addressing modes, either by register or by constant offset.
Fortunately, the GBA CPU supports both! This meant that I didn't have to spend
time organizing fields in the supposedly optimal temporal order. It also means
that field access is self-documenting. I'm free to reorder, add, and delete
fields at any stage without existing code being impacted in unpleasant,
downright agonizing ways.

On the Game Boy, field access looks like this:
```
    .loop:
    ld a, [hli] ; Track_Speed
    cp a, $ff   ; is track used?
    jr nz, .process_track
    ld de, Track_SIZEOF
    add hl, de
    jp .next_track
    .process_track:
    inc [hl]    ; Track_Tick
    cp a, [hl]  ; speed == tick?
    jr z, .next_row
    inc l ; Track_Pattern_RowCount
    inc l ; Track_Pattern_Row
    inc l ; Track_Pattern_RowStatus
    jp .mixer_tick
    .next_row:
```
On the GBA, field access looks like this:
```
update_sound__loop:
    ldrb r2, [r0, #TRACK_SPEED_BYTE]
    cmp r2, #0xff @ is track used?
    beq update_sound__next_track
    @ process track
    ldrb r3, [r0, #TRACK_TICK_BYTE]
    add r3, r3, #1
    cmp r3, r2 @ tick == speed?
    beq update_sound__next_row
    strb r3, [r0, #TRACK_TICK_BYTE]
    b update_sound__mixer_tick
update_sound__next_row: 
```
More compact, more readable, and more maintainable.

> I did try to be clever by only writing pointer registers back to memory
strictly when needed, but initially missed a couple of spots. This was the
source of a few intense debugging sessions, since the stale pointer typically
only manifested in a glitch/crash several frames later, when the next pattern
data were read from the wrong address.

### ARM is RISC

With the ARM instruction set, it's not possible to perform operations (such as
arithmetic and bitwise) directly on data in memory. You always have to load data
to a register, perform the operation on the register, then write data back to
memory. Such is the nature of a [RISC](https://en.wikipedia.org/wiki/Reduced_instruction_set_computer)
microprocessor.

With the original Game Boy CPU, operations _mostly_ have to be performed on the A (accumulator)
register. It's cumbersome that adding a value to the B register takes minimum three
instructions: Move B to A, add value to A, and move the result to B. (If you wanted
to preserve the original value of A, more instructions are needed to save and restore
it.)

However, there are a few Game Boy instructions that can operate directly on the
memory pointed to by the HL register; these can be used to test, clear, and set bits,
shift and rotate, and increment and decrement 8-bit data in memory without the use of
an intermediate register. The ARM CPU can't do this; on the other hand, ARM has 13
general-purpose registers — not one special accumulator register — that can be used
by any instruction. So far, the GBA sound engine didn't have to use more than six of
the general-purpose registers at most.

### Updating status flags in ARM instructions

A nice feature of the ARM instruction set is that you can choose whether certain
operations should update the status flags; adding an S suffix to the instruction
mnemonic will cause status flags to be updated (`add` does not update flags,
`adds` updates flags). On the Game Boy, you might recall that I complained about
the `AND`, `OR`, and `XOR` instructions causing the carry flag to be set to zero
(how is that useful when there are dedicated instructions to set and clear the
carry flag?). Similarly, on the NES (6502 CPU), the load instructions
(`LDA`, `LDX`, `LDY`) are rather unique in that they update both the zero flag
and negative flag. I like that the ARM instruction set makes the behavior
explicit in the instruction (though I admit it takes me a while to remember to
use `subs` instead of `sub` when decrementing a loop counter).

### Linker script

Once it's written exactly the right way, the [linker script](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/gba.ld) that defines how sections of object files (produced by the assembler) should be mapped
to ROM and RAM works wonderfully.

In the initial version of `xm2gba`, there was a bug that made it produce the line
```
.section rodata
```
instead of
```
.section .rodata
```
in the assembly output. GCC was totally fine with this `.section rodata`, and the
linker seemed to be, too; no warnings or errors were produced. I couldn't understand
why the data didn't end up in ROM. But `rodata` is of course a totally different
section than `.rodata`. The default behavior of the linker is to place unknown sections
_at the end of the output, without warning_. Here the `/DISCARD/` directive comes to the
rescue:
```
    /* Discard all other unexpected sections */
    /DISCARD/ : {
        *(*)
    }
```
This gives us the desired behavior of the linker failing with an error that says
which section was discarded from which object:
```
bob-omb-battlefield-gba % make
arm-none-eabi-as -o song_data.o song_data.s
arm-none-eabi-ld -T gba.ld -o BobOmbBattlefield.elf main.o sound_engine.o image_data.o song_instrument_table.o song_data.o -Map=BobOmbBattlefield.map
`song_song' referenced in section `.text' of main.o: defined in discarded section `rodata' of song_data.o
make: *** [BobOmbBattlefield.elf] Error 1
```

### Debugging

The [mGBA](https://mgba.io) emulator provides a set of tools that are useful for
development: A debugger that loads symbol files, and viewers for memory, graphics,
and I/O registers. One weakness compared to [SameBoy](https://sameboy.github.io)
is that the memory viewer in mGBA doesn't automatically refresh when stepping
through code; you have to click on a "cell" in the viewer to refresh it.

[visualboyadvance-m](https://github.com/visualboyadvance-m/visualboyadvance-m) is
another emulator that provides a similar set of tools, _and_ it provides an option
for automatically updating the view.

### ROM header checksum

When the GBA BIOS is enabled, the program doesn't start in the
[NanoBoyAdvance](https://github.com/nba-emu/NanoBoyAdvance) emulator unless the
checksum in the ROM header is correct; if the checksum is wrong, the program
will silently halt at the startup screen. The script [header.py](https://github.com/Ankeraout/minimal-gba-project/blob/master/header.py)
can be used to repair the checksum (similar to the `rgbfix` tool that we use
in Game Boy projects).

### ROM size

If you recall, the minimum size of a Game Boy ROM is 32 KB. If the program and
data occupy less space, the ROM must be padded to reach a size of 32 KB. (In
Game Boy projects, we can use the `rgbfix` tool to achieve this.) This is a bit
sad when our program could actually fit in 16 KB or less.

For GBA ROMs, there is no minimum size constraint; padding is not needed.
Currently, the size of the Super Mario 64 - "Main Theme" ROM is around 14 KB.

## Step 4: Check the results

### Testing on emulators

There are several popular Game Boy Advance emulators, and we should aim to get
similar results on all of them. This will also increase our chances of the
output sounding the same on a real GBA.

Unfortunately, the sound output currently differs between emulators: On
[Visual Boy Advance - M](https://github.com/visualboyadvance-m/visualboyadvance-m),
it sounds as I'd like it to. On [mGBA](https://mgba.io), the volume envelopes
don't behave as desired. Recall from the Game Boy port that I relied on an
undocumented feature (bug?) of the sound hardware:
["Zombie" mode](https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware#Obscure_Behavior).
As luck would have it then, this behavior enables the channel volume to be modified
without retriggering the waveform. This is essential to achieve when volume
envelope interpolation is implemented in software. Software envelopes give more precise
control of the volume than what the hardware envelopes can provide.

In mGBA's Game Boy Color compatibility mode, the "Zombie" mode emulation was
improved (see https://github.com/mgba-emu/mgba/issues/2029). The original Game
Boy version of the Super Mario 64 - "Main Theme" therefore sounds good.

In [NanoBoyAdvance](https://github.com/nba-emu/NanoBoyAdvance), the output is
about as bad as in mGBA. However, there is a claim in this ticket
https://github.com/nba-emu/NanoBoyAdvance/issues/364 that "Zombie" mode does
exist on the GBA, and there is a discussion about how it can be added without
regressing sound emulation in a few games.

### Testing on real hardware

Unfortunately, based on my own testing using an
[EZ-Flash OMEGA cartridge](https://www.ezflash.cn/product/ez-flash-omega-definitive-edition/),
"Zombie" mode does NOT appear to exist in native GBA mode on the original Game
Boy Advance (model AGB-001). Or, I'm not writing to sound registers in the
required way. "Zombie" mode does work in GBC mode, so the hardware is capable of
it. I've yet to test on the other hardware models: Game Boy Advance SP (AGS-001
and AGS-002) and Game Boy Micro (OXY-001). But the odds of "Zombie" mode working
on those units are slim.

### Alternatives to "Zombie" mode

If we retrigger the channel on every volume change, the result does not sound
good. We get a "rasping" effect.

It's hard to accept that I most likely have to ditch my software-managed volume
envelopes in favor of the more limited hardware-supported envelopes. Or, I will
have to drop all legacy channels except the waveform channel (which has a different
mechanism to control the volume) and implement a software mixer. I wish that the
Game Boy and Game Boy Advance had treated channel volume the same way as on the
NES, where you can freely change the volume without fear of retriggering the
waveform.

## Conclusion

There you have it. The GBA is a powerhouse compared to the original Game Boy,
while mostly retaining support for the classic sound hardware. The GBA can be
programmed using libre software (GCC). The ARM instruction set is pleasant to
work with. "Zombie" mode doesn't appear to exist in native GBA mode, meaning
that a different solution must be found for supporting precise volume control.

### What's next?

- Determine whether "Zombie" mode exists on GBA SP.
- Implement channels 1, 2, and 4 in a software mixer.
- Port the panning effect (8xx) implementation.
- Add more fancy visualizations, like in the Game Boy programs.
