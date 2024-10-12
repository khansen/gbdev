# Implementing an audio mixer for Game Boy Advance

_October 14, 2024: Version 1.0_

## Introduction

This article recounts my experiences from adapting the Game Boy Advance sound engine
found at https://github.com/khansen/gbdev/tree/master/music/bob-omb-battlefield-gba from
using the legacy Game Boy sound channels to using the aptly named Direct Sound channels.
It is the third article in a series:
- [Part 1: Porting an NES sound engine to Game Boy](https://github.com/khansen/gbdev/blob/master/articles/porting-nes-sound-engine/index.md)
- [Part 2: Porting a Game Boy sound engine to Game Boy Advance](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine/index.md)

It is assumed that the reader is already familiar with the material in the two
previous articles. Knowledge of Game Boy Advance hardware and development,
including ARM assembly language, is a plus.

Direct Sound was a new feature on the GBA. The two Direct Sound channels provide
playback of linear 8-bit audio data. Programming these channels is a big departure
from programming the legacy sound channels.

The initial objective and key result of this project was to take the
[Super Mario 64 - "Main Theme" ("Bob-omb Battlefield")](https://www.youtube.com/watch?v=mvgoAMDfLjE)
Game Boy version and make it sound good (but not necessarily identical) on Game
Boy Advance.

The resulting code can be found [here](https://github.com/khansen/gbdev/tree/master/music/bob-omb-battlefield-gba-v2).
The [README](https://github.com/khansen/gbdev/blob/master/README.md#game-boy-advance)
contains instructions on how to build the ROM file.

You can [listen to the final result on YouTube](https://www.youtube.com/watch?v=Gj8VuRwxeyw).

### "Zombie" Mode is Dead on GBA

Recall from the [previous article](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine/index.md#testing-on-real-hardware)
that on the Game Boy, I relied on the elusive, undocumented
["Zombie" mode](https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware#Obscure_Behavior)
to achieve precise volume control with smooth playback. "Zombie" mode is what
enabled the use of custom, software-defined volume envelopes that are much
more flexible than the "official" hardware volume envelopes.

Experiments seem to corroborate that when the Game Boy Advance is running in
native mode (not Game Boy compatibility mode), "Zombie" mode is not available.
Therefore, I saw no other choice but to stop using the two square wave channels
(channels 1 and 2) and the noise channel (channel 4). The waveform channel
(channel 3) is still fine to use on GBA, since it allows changing the volume
without retriggering the waveform. (On the downside, the waveform channel only
has four volume levels, while the square and noise channels have 16 levels.)

### Hardware Mixer versus Software Mixer

As mentioned in the [previous article](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine/index.md#sound),
a big appeal of the legacy hardware sound
channels is that they require at most a few hundred CPU instructions in total to
program one frame (approximately 1/60th of a second) worth of audio. The Audio
Processing Unit (APU) takes care of generating waveforms of the configured type,
with the configured frequency, with the configured volume. The APU handles
mixing of the channels' signals to produce the final audio signal. Meanwhile,
the main CPU is free to tend to other business.

> Having a dedicated APU for audio is similar to having a dedicated Picture
Processing Unit (PPU) for graphics that is responsible for plotting pixels on
the screen based on tile data and tile map data in VRAM. Again, this allows the
main CPU to do other things instead.

To use the Direct Sound channels, a mixer must be implemented in software. The
mixer must output enough bytes to keep the playback smooth at the configured
playback frequency. Unlike other systems, like the Nintendo 64, the GBA doesn't
have a co-processor that the mixing can be offloaded onto. No matter how well
we optimize our mixer, it _will_ steal precious CPU cycles from other parts of
our GBA program. Still, there are some tradeoffs we can make, and optimizations
we can apply, to make the mixer less costly. More on that later.

## Step 0: Preparing the Move to a Software-based Mixer

My goal was to keep the sound engine's core operation unchanged: It should run at
the end of each frame (in the VBlank interrupt handler), where it will first
update its internal state in RAM (sequencing the tracks and processing their
effects), and then use that state to "render" a new frame
worth of audio. The key difference is that instead of writing to the hardware
registers for legacy sound channels 1, 2, and 4, the software mixer should now
be invoked instead. Fortunately, the "rendering part" of the sound engine is
already fully decoupled from the "sequencer part"; I designed it that way
precisely to make it easier to port the engine to new platforms and
configurations. Before, we had
[this code](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba/sound_engine.s#L380):
```
    @ Update internal state of all virtual channels (tracks)
    @ ...

    @ Write to audio hardware registers
    ldr r0, =tracks
    ldr r1, =SOUND_CONTROL_REGISTERS_BASE_ADDRESS
    bl render_channel1
    bl render_channel2
    bl render_channel3
    bl render_channel4
```
Now it looks like this:
```
    @ Update internal state of all virtual channels (tracks)
    @ ...

    @ Write to sound channel 3 "shadow" registers
    bl render_channel3_shadow_registers
    @ Mix other virtual channels for Direct Sound output
    bl mix_sound
```
(The channel 3 "shadow" registers will be explained later.)

All that remains now is to configure the playback of the Direct Sound channel
and write the `mix_sound` function!

## Step 1: Implementing Smooth, Double-Buffered Audio Mixing and Playback

### The Concept of Double-Buffering

A double-buffered audio pipeline uses the same concept as a double-buffered graphics
pipeline: While the audio or graphics hardware is busy consuming one frame worth of
data from the buffer starting at memory address A, our program is producing the contents
of the next frame in the buffer starting at address B. After the hardware is done
rendering the current frame, the buffers are swapped, so that on the next frame, the
hardware renders buffer B while our program populates buffer A. This process then
repeats.
```
+--------------------------------------------+
| Frame | Hardware reads from | Program writes to |
+--------------------------------------------+
| 0     | Buffer A         | Buffer B        |
| 1     | Buffer B         | Buffer A        |
| 2     | Buffer A         | Buffer B        |
| 3     | Buffer B         | Buffer A        |
| 4     | Buffer A         | Buffer B        |
| ...   | ...              | ...             |
+--------------------------------------------+
```

Typically, the two buffers are laid out consecutively in memory.

```
                  "Even" frames:                "Odd" frames:
Buffer A ---+----------------------+    ---+----------------------+
            | Rendering hardware   |       | Program writes       |
            | reads from this area |       | to this area         |
            |                      |       |                      |
Buffer B ---+----------------------+    ---+----------------------+
            | Program writes       |       | Rendering hardware   |
            | to this area         |       | reads from this area |
            |                      |       |                      |
            +----------------------+       +----------------------+
            |
           \|/
            +    Higher addresses
```

In graphics, double-buffering avoids visible artifacts, such as tearing, that can
happen if the graphics hardware reads memory while our program is writing to it.
In audio, double-buffering ensures that the sound is smooth, avoiding unpleasant
audible artifacts such as snaps, crackles and pops.

<!-- In the video, give an example of what it sounds like -->

### Setting Up Double-Buffered Audio on GBA

[This excellent tutorial](https://deku.gbadev.org/program/sound1.html) explained
everything I needed to know about implementing double-buffered mixing and
playback on the GBA. It even includes a working example project coded in C.
Major kudos to the author, as I would not have been able to complete my own
project as quickly without their work.

In short, we want to configure the GBA Timer 0 and DMA channel 1 so that our mixer
buffer will be output to the sound FIFO A input register at _exactly_ the right rate
to be timed to the VBlank interrupt:
```
    ldr r0, =TIMER_REGISTERS_BASE_ADDRESS @ 0x04000100
    ldr r1, =MIXER_TIMER_VALUE            @ Choose carefully
    strh r1, [r0, #TM0CNT_L]
    ldr r1, =0x80
    strh r1, [r0, #TM0CNT_H] @ enable timer

    ldr r0, =DMA_REGISTERS_BASE_ADDRESS   @ 0x040000b0
    ldr r1, =FIFO_A                       @ 0x040000a0
    str r1, [r0, #DMA1DAD]
    eor r1, r1, r1
    str r1, [r0, #DMA1CNT]
```
In the VBlank interrupt handler, we swap the mixer buffers like so:
```
swap_sound_buffers:
    ldr r0, =current_mix_buffer
    ldr r1, [r0]
    ldr r2, =sound_buffer_data
    cmp r1, r2
    bne 1f
    @ start playing buffer 0
    add r1, r2, #SOUND_BUFFER_SIZE
    str r1, [r0] @ current_mix_buffer = sound_buffer_data + SOUND_BUFFER_SIZE
    ldr r0, =DMA_REGISTERS_BASE_ADDRESS
    eor r3, r3, r3
    str r3, [r0, #DMA1CNT]
    str r2, [r0, #DMA1SAD] @ sound_buffer_data
    ldr r1, =0xb640 @ DMA_DEST_FIXED | DMA_REPEAT | DMA_WORD | DMA_MODE_FIFO | DMA_ENABLE
    strh r1, [r0, #DMA1CNT_H]
    bx lr
    1:
    str r2, [r0] @ current_mix_buffer = sound_buffer_data
    bx lr
```
Now we are all set to mix our next frame of audio into `current_mix_buffer`.

### Mixer Frequency and Buffer Size

As explained in the aforementioned [tutorial](https://deku.gbadev.org/program/sound1.html),
there are only a handful of frequencies that can be chosen when we want to
time the mixer to the VBlank interrupt. For now I've decided to go with 42048 Hz
(high quality, but also highly CPU-demanding), which yields a mixer buffer
size of 704 bytes. Targeting a different frequency is possible, but requires
adjusting the _step values_ that are used in the resampling process, described in
a later section. I've introduced compile-time flags that allow different frequencies
to be chosen (I didn't see a need to be able to change the frequency at runtime).
The lower the frequency, the "chunkier" the output will sound, but this can be
a reasonable tradeoff when you desperately want to spend the CPU cycles on other
things.

### Mono versus Stereo

The GBA has two Direct Sound channels, A and B. To implement stereo sound
(with panning effects), we can use both channels. This comes at the expense
of the mixer having to output twice the amount of bytes (two buffers instead
of one, twice as taxing on the CPU). For simplicity and efficiency, the
sound engine currently only makes use of one Direct Sound channel.

## Step 2: Defining The Constraints of The Softsynth

Recall that in the [previous article](https://github.com/khansen/gbdev/blob/master/articles/porting-gameboy-sound-engine/index.md#sound),
I wrote that the purist in me renounces
the idea of utilizing general-purpose digital audio waveforms. While the
prospect can seem seductive, playing "real" samples on a vast number of virtual
channels can take the charm out of the final sound, and it can take the technical
challenge and ingenuity out of the composition process. With all the freedom that
comes with a software mixer, I don't want the result to sound too "generic".
It should sound "retro". It shouldn't sound too "soft". I still want to use my
arpeggios without the output sounding muffled or garbled.

Second, to put a reasonable upper bound on the amount of CPU cycles that can be
hogged by the mixer, it makes sense to limit the number of virtual channels (tracks).

Third, it's nice to be able to have the flexibility to compose a song _first_,
and _then_ decide whether I want to target the NES, Game Boy, or Game Boy
Advance, or all three, without having to make significant compromises or
adjustments for each platform.

> Granted, the NES does have a fifth channel (DPCM). I only use it when I
know that I'm making an "exclusive" NES song.

Therefore, I decided that the GBA software mixer shall only support three (3)
channels: Let's call them "Square" 1, "Square" 2, and Noise.

### Virtual "Square" Channels

The virtual "Square" channels are similar to the waveform channel (channel 3)
on the Game Boy. However, instead of waveforms defined by 32 4-bit samples,
these waveforms are defined by 256 signed 8-bit samples (I know, very
extravagant!).

The waveforms don't actually have to represent _square_ waves; they can be any shape.
My initial idea was to model them directly after the square wave channels on the Game
Boy and NES. Recall that on the Game Boy and NES, the square wave's duty cycle has
four possible settings, representing the ratio of "low" versus" high" signal values:
```
+---------+------------+--------------------------------+
| Setting | Duty cycle | Waveform                       |
+---------+------------+--------------------------------+
| 00      | 12.5%      |     +--+            +--+       |
|         |            |     |  |            |  |       |
|         |            |-----+  +------------+  +-------|
+---------+------------+                                |
| 01      | 25.0%      |   +----+          +----+       |
|         |            |   |    |          |    |       |
|         |            |---+    +----------+    +-------|
+---------+------------+                                |
| 10      | 50.0%      |  +-------+       +-------+     |
|         |            |  |       |       |       |     |
|         |            |--+       +-------+       +-----|
+---------+------------+                                |
| 11      | 75.0%      |---+    +----------+    +-------|
|         |            |   |    |          |    |       |
|         |            |   +----+          +----+       |
+---------+------------+--------------------------------+
```

> The 75% duty cycle is a bit of a dud, sounding identical to
25% duty cycle. I've never used it.

A square wave with 12.5% duty cycle can be represented by the following
signed 8-bit sample data:
```
.byte 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128
```

When testing these samples, I was rather baffled to discover that "perfect"
square waves sound horrible when played on the Game Boy Advance's Direct Sound
channel! Of course, there might be a glaring issue with my mixer code ... but
the square waves sound distorted and have annoying overtones. I read up a bit
on the
[Nyquist-Shannon sampling theorem](https://en.wikipedia.org/wiki/Nyquist–Shannon_sampling_theorem)
and briefly experimented with various forms of aliasing/smoothing of the sample
data, and while the overtone artifacts can be subdued, the results tend to sound
very dull. Instead I went with a few alternative waveforms (generated by ChatGPT)
that are combinations of sawtooth (sounding "raw", reminiscent of a square wave
with 12.5% duty cycle), pulse (sounding "clean", reminiscent of a square
wave with 50% duty cycle), and sinusoidal waves. Effectively, the duty cycle
setting becomes a sample selector, with a maximum of four different waveforms
per song (for a total of 1 KB of sample data).

#### Duty Cycle (Sample Index) Settings

Like the Game Boy engine before it, the GBA sound engine supports rapidly
switching from one "duty cycle" (in this case, sample index) to another, either
1, 2, or 3 frames after triggering a note. Changing the sample this way can be
used to produce an "attack" that can almost make it sound like two instruments
are played at once. This effect is used on the lead instrument in the first two
"verses" of the Super Mario 64 - "Main Theme" ("Bob-omb Battlefield") remix,
which transitions from a "raw" to a more "clean" sample.

### Noise Channel

For the virtual noise channel, I wanted to emulate both the 15-bit LFSR setting
(that produces traditional "white" noise) and the 7-bit LFSR setting (that
produces "regular" noise) of the original Game Boy noise channel. ChatGPT
provided a few scripts that generate tables of suitable random values.

For white noise, I found that at least 1024 samples are needed to make it sound
"white enough". I opted for 2048 samples (2 KB of sample data). These values
could alternatively be generated at runtime using a pseudo-random number
generator.

For "regular" noise, I found that 64 bytes of sample data were sufficient.

### Volume Levels

The virtual channels support 16 volume levels, just like the original Game Boy
hardware sound channels. While 64 or even 256 levels could easily be supported,
I didn't see a need to do so. 16 levels provide plenty of fidelity for a retro
sound.

As in the previous version of the engine, volumes are stored in a 4.4
fixed-point format, so that volume envelopes can affect the volume by a
fractional amount each frame.

## Step 3: Mixing The First Track

### Changes to Track Layout

The _track_ structure holds the state of one logical/virtual channel of the song
that's playing. The new structure is [as follows](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba-v2/track_constants.s):
```
.equ TRACK_PATTERN_PTR_WORD,    0
.equ TRACK_ENVELOPE_PTR_WORD,   4
.equ TRACK_SAMPLE_POS_WORD,     8 @ This is new!
.equ TRACK_PERIOD_HWORD,        12
.equ TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD, 14
.equ TRACK_SPEED_BYTE,          16
.equ TRACK_TICK_BYTE,           17
.equ TRACK_PATTERN_ROWCOUNT_BYTE, 18
.equ TRACK_PATTERN_ROW_BYTE,    19
.equ TRACK_PATTERN_ROWSTATUS_BYTE, 20
.equ TRACK_ORDER_POS_BYTE,      21
.equ TRACK_EFFECT_KIND_BYTE,    22
.equ TRACK_EFFECT_PARAM_BYTE,   23
.equ TRACK_EFFECT_POS_BYTE,     24
.equ TRACK_EFFECT_PORTAMENTO_CTRL_BYTE, 25
.equ TRACK_MASTERVOL_BYTE,      26
.equ TRACK_PERIODINDEX_BYTE,    27
.equ TRACK_SQUARE_DUTYCTRL_BYTE, 28
.equ TRACK_ENVELOPE_PHASE_BYTE, 29
.equ TRACK_ENVELOPE_POS_BYTE,   30
.equ TRACK_ENVELOPE_VOL_BYTE,   31
.equ TRACK_ENVELOPE_STEP_BYTE,  32
.equ TRACK_ENVELOPE_DEST_BYTE,  33
.equ TRACK_ENVELOPE_HOLD_BYTE,  34
.equ TRACK_EFFECTIVE_VOL_BYTE,  35 @ This is new!
.equ TRACK_SIZEOF,              36
```

There are two differences from the previous (legacy hardware-based output) track format:
- A new word (32-bit) field appeared: `TRACK_SAMPLE_POS_WORD`. This holds a
16.16 fixed-point value. As we shall see, it is used to keep track of the
offset that the mixer should fetch sample data from.
- A new byte field appeared: `TRACK_EFFECTIVE_VOL_BYTE`. This contains the result
of combining the global master volume, the track master volume, and the
envelope volume. I use it to render a visual indicator of the effective (output)
volume level of the channel.

### Periods, Frequency, and Resampling

The tracks that correspond to the three new virtual channels still use the same
11-bit period values (0-2047) that the original Game Boy sound engine did. The
period value is stored in the `TRACK_PERIOD_HWORD` field. Effects such as slide
up/down, portamento, and vibrato, manipulate the period value in different ways.

#### Calculating Sample Step Values

When targeting the legacy Game Boy sound channels, we simply wrote the period
values to the corresponding sound hardware registers, and the Audio Processing Unit
took care of generating a waveform with the corresponding
frequency. With the software mixer, the period value must first be translated to a
_step value_. The step value is what enables us to generate a waveform with the desired frequency in
the mixer's output buffer. This process is called "resampling". Since we are
going to play sound on both the legacy waveform channel (channel 3) and the
Direct Sound channel at the same time, we want each period value to match
exactly the frequency that's output by the legacy Game Boy hardware.

Given a sample length of `sample_length` bytes and a mixer frequency of `mixer_hz`
Hz, the formula for calculating the 16.16 fixed-point step value is

```
round((0x200000000 * sample_length) / (2048 - period) / mixer_hz)
```

For example, the period value of middle C (C4, 261.63 Hz) is `0x60b`. Substituting
`sample_length = 256` and `mixer_hz = 42048`, we get the step value

```
round((0x200000000 * 256) / (2048 - 0x60b) / 42048)
```

which is 104387, or `0x197c3`. It represents the value 1.5927. This
means that for each byte we output to the mixer buffer, the sample position
should be incremented by 1.5927. Then the waveform will maintain an audible
frequency of approximately 261.63 Hz.

#### Producing the Resampled Output

Equipped with the step value, we are ready to add the sample data to the mixer
buffer. In pseudo-code:
```
for i = 0 to mixer_buffer.length do
  mixer_buffer[i] += sample_data[(sample_pos >> 16) & (sample_length-1)]
  sample_pos += sample_step
end
```

> sample_length must be a power of 2 in order for this to work.

> Since this loop is on the critical ("hot") path of the mixer, it's crucial
that the actual implementation maintains as many variables as possible in
CPU registers.

#### Using a Lookup Table For Sample Step Values

The GBA CPU doesn't have a divide instruction, and we don't want to perform the
costly step value computation on the fly. Instead we can precalculate all 2048
possible step values and store them in a lookup table.
[This Ruby script](https://github.com/khansen/gbdev/blob/master/scripts/generate_step_table.rb)
produces a lookup table given a sample size and mixer frequency.
[Here](https://github.com/khansen/gbdev/blob/master/music/bob-omb-battlefield-gba-v2/square_step_table_256_42048.inc)
is what a full table looks like, and here is how we use it in the mixer:

```
    @ r0 points to the track
    ldrh r1, [r0, #TRACK_PERIOD_HWORD]
    ldr r2, =square_step_table
    ldr r2, [r2, r1, lsl #2] @ convert period to sample step
```

> The lookup table is 8 KB in size (2048 32-bit values). An alternative approach
is to implement division in software (like the GCC runtime library does) and
populate the lookup table in RAM when the program starts. Or, the entries of the
table could be populated lazily when a period is looked up for the first time
(if the somewhat unpredictable overhead of such a computation is acceptable).

### Scaling The Sample Data According to Volume Levels

The following components of the sound engine's state determine the final
(effective) volume of each virtual channel's output:
* The global master volume. Usually this is set to `0xf0` (maximum volume).
  It could be manipulated to fade a song in or out at any point, for example.
* The track master volume. By default, this is `0xf0` (maximum volume), but it
  can be altered by volume commands in the song data.
* The volume envelope's current volume. This is computed each frame
  according to the envelope's definition.

To scale a sample byte according to the volume, we first calculate the effective
volume, then multiply the original sample value by that amount, then arithmetically
shift the result right by 24 to get rid of the scaling factor introduced by the
multiplication.

```
effective_volume = global_volume * channel_volume * envelope_volume

scaled_sample = (original_sample * effective_volume) >> 24
```

Example: Assume that global_volume = `0xf0`, channel_volume = `0xc0`,
envelope_volume = `0x80`, and original_sample = -128. Then we get

```
effective_volume = 0xf0 * 0xc0 * 0x80 = 0x5a0000

scaled_sample = (-128 * 0x5a0000) >> 24 = -45
```

In other words, -45 is the sample value that should be added to the mixer buffer.

> In the Game Boy engine, a lookup table 256 bytes in size is used to translate
the volume. In the GBA engine, a lookup table isn't needed because multiplication
on the ARM7TDMI CPU is fast! (Faster than calculating the index value and reading
the value from memory.)

> The effective volume is only computed once per virtual channel per frame, and
stored in a CPU register for fast access inside the mixer's most critical `for`
loop.

## Step 4: Adding The Second Virtual Channel to The Mix

The second virtual ("square") channel has exactly the same characteristics as
the first. The sample data to be added to the mixer buffer are derived the same
way.

### Clamping

In digital audio processing, to mix two samples, we simply add the sample values
together. However, the final sample value must still be represented as a signed
8-bit value (otherwise our ears would not be pleased with the result). To achieve
this, the result of the addition should be _clamped_. The following four
instructions clamp the value in `r11`:
```
    cmp r11, #127
    movgt r11, #127  @ clamp high
    cmp r11, #-128
    movlt r11, #-128 @ clamp low
```

### Optimizing Clamping With Unsigned Sample Data

If we represent the input sample data as unsigned 8-bit values
(0..255 instead of -128..127), clamping can be achieved in only two
instructions, and the result converted to a signed 8-bit value by
the third instruction:
```
    cmp r11, #255
    movgt r11, #255 @ clamp
    sub r11, r11, #128 @ convert to signed
```

## Step 5: Adding The Third Virtual Channel to The Mix

The third virtual channel represents a noise channel. It uses different input
sample data and step tables than the two "square" channels, but otherwise the
process of adding sample values to the mixer buffer is the same. Which
sample data to use ("white" or "regular") is determined by the LFSR bit of the
instrument definition.

## Step 6: Adding The Legacy Waveform Channel

The legacy waveform channel is handled the same way as in the previous version
of the sound engine, with one crucial difference: Writes to the sound hardware
registers are delayed by one frame. This is done so that the timing of the
waveform channel matches the timing of the Direct Sound channel. Since the
Direct Sound channel uses _double-buffering_, the audio data that will be played
during the next frame _were mixed during the previous frame_. Therefore, in
addition to swapping
the Direct Sound buffers, the legacy waveform channel should also be configured
with the values that were computed in the _previous_ frame. Otherwise, the waveform
channel output would effectively be "one frame ahead" (approximately 1/60th of
a second) of the Direct Sound channel output. (You might think that this is too
quick to be audible, but I actually discovered this issue when noticing that the
bass line in the Super Mario 64 - "Main Theme" ("Bob-omb Battlefield") remix
appeared to be slightly "off beat".)

Delaying the hardware registers update by one frame is achieved by keeping
copies of the registers in RAM, so-called "shadow" registers. In the VBlank
interrupt handler, the "shadow" registers are first written to hardware. Then,
after the sound engine has updated the internal state of track 3 in RAM as
per usual, the newly computed hardware register values are written to the
waveform "shadow" registers, effectively "buffering" them.

## Step 7: Optimizing For Speed (and Size)

Now that we have a basic mixer working without audible glitches, let's analyze
its performance and find ways to improve it. First we will look at improving
performance without losing sound quality (using a playback frequency of
42048 Hz). Then, we will observe the effects on both quality and performance
as we reduce the mixer's playback frequency.

All measurements were done using the [mGBA emulator](https://mgba.io).

### Displaying a Scanline Count

An effective way to measure performance on the GBA is to count the number of
scanlines it takes to do some heavy processing. To do this, first read the
VCOUNT register to get the initial scanline value, then do the heavy
processing (in our case, call the sound engine), then read the VCOUNT register
again. Now use the two scanline values to calculate the number of scanlines it
took to do the work. This represents the total cost of calling the sound
engine (which includes both the sequencing & effects processing part and the
mixing part).

Note that the VBlank period consists of only 68 (228 - 160) scanlines. If the
sound engine finishes on or before scanline 227, we can calculate the number
of scanlines by subtracting the starting scanline value from the ending
scanline value. If processing takes longer, the VCOUNT register will have
wrapped around to 0 and we have to add 228 to the calculation to get the
scanline count.

### Establishing The Baseline Performance

Without applying any of the optimizations described in this section, the sound
engine takes about _189-190 scanlines_ per frame. Wow, that's a lot; roughly
83% of the total frame time! Anyhow, 190 is our baseline number. Let's see how
much lower we can go.

### Optimization 1: Mixing Channels 1 and 2 in One Pass

In a general-purpose mixer supporting N virtual channels, we might start by
clearing the mixer buffer (using DMA), then loop N times, adding each virtual
channel's contributions to the mixer buffer. In pseudo-code:

```
clear_mixer_buffer()
for i = 0 to vchannels.length do
  mix_vchannel(i)
end
```

Currently, the sound engine only has 3 virtual channels. In the inner loop that
derives the samples for a channel's contributions to the mixer buffer, the mixer
needs the following four channel variables at its disposal:
- The effective volume
- The sample data pointer
- The sample data position (16.16 fixed-point)
- The sample data step (16.16 fixed-point)

These can be stored in _four CPU registers_. We also need _one register_ for the
mixer output buffer pointer, and _one register_ for the loop counter (initialized
to the mixer buffer length). We need _a couple of registers_ to hold intermediate
results (the conversion of sample data position to integer, and the result of
multiplying the original sample data by volume). That's _eight registers_ in
total.

The GBA (ARM7TDMI) CPU has 13 general-purpose registers. This means that we
still have room for an additional set of channel variables (four). The mixer
uses this arrangement to mix both virtual "Square" channel 1 and virtual
"Square" channel 2 in a single pass.

The mixer also relies on the fact that these two channels are always mixed
_first_. Therefore, there is no need to clear the mixer buffer as a separate
step.

Here's the code to mix the two samples (clamping the result is not shown):

```
    lsr r10, r1, #16 @ integer part of channel 1 sample pos
    and r10, r10, #(SQUARE_SAMPLE_SIZE - 1)
    ldrsb r10, [r3, r10] @ get channel 1 signed sample byte
    mul r11, r4, r10

    lsr r10, r5, #16 @ integer part of channel 2 sample pos
    and r10, r10, #(SQUARE_SAMPLE_SIZE - 1)
    ldrsb r10, [r7, r10] @ get channel 2 signed sample byte
    mla r11, r8, r10, r11
    asr r11, r11, #10
```

Note that the `mla` (Multiply And Add) instruction is conveniently used instead
of a pair of `mul` and `add` instructions.

#### Result

This optimization reduces the total processing time of the sound engine by
about _25 scanlines_ compared to the baseline (from 190 to 165), which
represents a speedup of roughly 1.15x.

### Optimization 2: Copying Sample Data to IWRAM

On the GBA, accessing RAM is significantly faster than accessing ROM, and the
hardware does not have any data cache. If your project has the memory to spare,
copying the sample data to RAM will make the mixer run faster.
I put this feature between a compile-time flag called
`COPY_SAMPLE_DATA_TO_RAM`.

> The total size of the sample data (square and noise) is currently 3136 bytes.

#### Result

This optimization reduces the total processing time of the sound engine by about
_14 scanlines_ compared to Optimization 1 (from 165 to 151), which represents
a speedup of roughly 1.09x, and a total speedup of roughly 1.25x relative to
the baseline.

### Optimization 3: Copying "Hot" Mixer Code to IWRAM

When the GBA CPU executes instructions, those instructions have to be fetched
from memory. The hardware does not have an instruction cache. The same way as
with sample data, fetching instructions from RAM is a lot faster than fetching
them from ROM. If your project has the memory to spare, copying the "hot"
mixer code to RAM will make the mixer run _significantly_ faster.
I put this feature between a compile-time flag called
`COPY_MIXER_CODE_TO_RAM`.

> The mixer code is currently 600 bytes in size.

#### Result

This optimization reduces the total processing time of the sound engine by about
_119 scanlines_ compared to Optimization 2 (from 151 to 32), which
represents a speedup of roughly 4.7x, and a total speedup of roughly 5.9x
relative to the baseline. _Wow, this is where it's at!_

> This optimization applies equally well to any performance-critical code, not
just audio mixing. For example, pushing pixels to a frame buffer in bitmap mode.

At this point, the sound engine demands "only" roughly 14% of the total CPU
time each frame.

#### A Note on Position-Independent Code

When I first tried this optimization, the code didn't run correctly after it
had been copied to RAM. This was because instructions like the following rely
on an assembler mechanism called the _constant pool_:
```
  ldr r0, =tracks
```
The assembler turns the above into a PC-relative load instruction. We have to
ensure that the constant pool is included when we copy the code to RAM.
Fortunately, with the `arm-none-eabi-as` assembler, this can easily be
achieved by placing the `.ltorg` directive immediately after the function
code, which instructs the assembler to place the constant pool there:
```
    bx lr
.ltorg
mix_sound_channel1_and_2_rom_end:
```
This way, both the code _and_ the associated constant pool will be copied to
RAM.

It's not possible to call a function in RAM from ROM via PC-relative addressing;
the distance is too great. We have to make a call to the absolute address like
so:
```
  adr lr, 1f
  ldr r0, =mix_sound_channel1_and_2
  bx r0
  1:
```

### The Cost of The Mixer

At this point, it can be instructive to check how much of the sound engine's
total time is spent on mixing versus on other tasks (sequencing the tracks
and processing their effects). We can find out simply by commenting out
the call to the `mix_sound` function (which will cause only the legacy
waveform channel to be audible). This brings the sound engine time down to
just _2-3 scanlines_. When the playback frequency is 42048 Hz, the cost of the
mixer alone is therefore roughly _29-30 scanlines_.

### Summary of Lossless Optimizations

| Optimizations | Scanline reduction relative to previous | Speedup relative to baseline | Engine's percentage of frame time |
|--------------|--------------------|-----------------------------|--------------------------|
| 0. Baseline  | 0 | 1.0x | 83% |
| 1. Mix channels 1 and 2 in one pass | 25 | 1.15x | 72% |
| 1 + 2. Copy sample data to IWRAM | 14 | 1.25x | 66% |
| 1 + 2 + 3. Copy mixer code to IWRAM | 119 | 5.9x | 14% |

We managed to reduce the number of scanlines occupied by the sound engine
from 190 to 32 through just a few simple optimizations, at the cost of a
few kilobytes of RAM consumption.

### Improving Performance By Reducing The Playback Frequency

It might not be possible to squeeze substantially more performance out of the
mixer in its current configuration. If we are willing to compromise on sound
quality, we can reduce the playback frequency to make the mixer run even faster
(and use less RAM). The current setting of 42048 Hz is a very high value that
results in high CPU overhead.

#### 5734 Hz

Let's start by examining what happens if we change the playback frequency from
42048 Hz to 5734 Hz, the lowest possible setting. At this setting, the mixer
buffer length is only 96 bytes, which is roughly 13.6% the size of the buffer
at 42048 Hz (704 bytes).

##### Results

This configuration reduces the total processing time of the sound engine by
about _25 scanlines_ compared to the optimized mixer with playback frequency
42048 Hz (from 32 to 7), which represents a speedup of roughly 4.5x.

I would say that this configuration produces too poor quality sound to be
used in a real project, but it does provide a useful reference point.

#### 21024 Hz

At this frequency, the mixer buffer length is 352 bytes, half the size of the
buffer at 42048 Hz.

##### Results

This configuration reduces the total processing time of the sound engine by
about _14 scanlines_ compared to the optimized mixer with playback frequency
42048 Hz (from 32 to 18), which represents a speedup of roughly 1.8x.

I would say that this configuration produces sound of acceptable quality, but
the difference from 42048 Hz is certainly noticeable when you've heard both
versions.

#### 31536 Hz

This frequency sits right between 21024 Hz and 42048 Hz. At this setting, the 
mixer buffer length is 528 bytes, 75% the size of the buffer at 42048 Hz.

##### Results

This configuration reduces the total processing time of the sound engine by
about _7 scanlines_ compared to the optimized mixer with playback frequency
42048 Hz (from 32 to 25), which represents a speedup of roughly 1.3x.

I would say that this configuration produces sound of very good quality,
hardly distinguishable from 42048 Hz.

### Summary of Impacts of Playback Frequency

In the following table, the baseline is the sound engine with mixer frequency
42048 Hz and all lossless optimizations enabled.

| Frequency     | Absolute scanline reduction | Speedup relative to baseline | Engine's percentage of frame time | RAM reduction relative to baseline (bytes) | Perceived sound quality |
|---------------|-----------------------------|------------------------------|-----------------------------------|--------------------------------------------|-------------------------|
| 42048 Hz      |        0                    | 1x    | 14%  | 0   | Excellent |
| 31536 Hz      |        7                    | 1.28x | 11%  | 176 | Very good |
| 21024 Hz      |       14                    | 1.78x | 7.9% | 352 | Fair      |
| 10512 Hz      |       22                    | 3.20x | 4.4% | 528 | Tolerable |
| 5734 Hz       |       25                    | 4.57x | 3.1% | 608 | Untolerable |

## Further Reading

While working on this project, I came across the following useful and/or
interesting resources:
- [forums.nesdev.org: Why was the GBA sound so poor?](https://forums.nesdev.org/viewtopic.php?t=19688)
- [gbatemp.net: HQ sound in native GBA games is entirely possible](https://gbatemp.net/threads/hq-sound-in-native-gba-games-is-entirely-possible.625549/)
- [gba-hq-mixer on GitHub](https://github.com/ipatix/gba-hq-mixer)
- [retrosix.wiki: Dehum Dehiss: Removing noise from GBA audio](https://www.retrosix.wiki/dehum-dehiss-removing-noise-from-gba-audio)

## Conclusion

There you have it. The GBA's Direct Sound channel, when used in conjunction
with a hardware timer and DMA, can be used to implement realtime mixing and
output of any 8-bit audio data. This gives a lot of flexibility, but comes
at the cost of vastly higher CPU consumption compared to the Game Boy legacy
sound hardware. This issue can chiefly be mitigated in two ways: By
compromising on output quality (playback frequency), and/or by applying a few
optimizations, such as ensuring that both data and code on the "hot" path of
the mixer are stored in IWRAM instead of read from ROM. These optimizations
incur a cost of increased RAM consumption.

## What's Next?

- Convert "square" sample data to unsigned 8-bit values, so that one instruction
can be saved when clamping each derived sample value.
- Consider supporting a 16-bit mixer buffer, to avoid loss of precision when adding
together samples.
- Add more fancy visualizations, like in the Game Boy (Color) programs.
