.include "dma_constants.s"
.include "track_constants.s"

@ If COPY_SAMPLE_DATA_TO_RAM is not defined, the mixer will read sample data
@ from ROM, which is a lot slower.
.equ COPY_SAMPLE_DATA_TO_RAM, 1

.ifdef COPY_SAMPLE_DATA_TO_RAM
.equ square_sample_data, square_sample_data_ram
.equ noise_7bit_lfsr_sample_data, noise_7bit_lfsr_sample_data_ram
.equ noise_15bit_lfsr_sample_data, noise_15bit_lfsr_sample_data_ram
.else
.equ square_sample_data, square_sample_data_rom
.equ noise_7bit_lfsr_sample_data, noise_7bit_lfsr_sample_data_rom
.equ noise_15bit_lfsr_sample_data, noise_15bit_lfsr_sample_data_rom
.endif

@ If COPY_MIXER_CODE_TO_RAM is not defined, the mixer code will run from ROM,
@ which is a lot slower.
.equ COPY_MIXER_CODE_TO_RAM, 1

.ifdef COPY_MIXER_CODE_TO_RAM
.equ mix_sound_channel1_and_2, mix_sound_channel1_and_2_ram
.equ mix_sound_channel4, mix_sound_channel4_ram
.else
.equ mix_sound_channel1_and_2, mix_sound_channel1_and_2_rom
.equ mix_sound_channel4, mix_sound_channel4_rom
.endif

.equ NUM_TRACKS, 4

.equ INSTRUMENT_ENVELOPE_PTR_WORD, 0
.equ INSTRUMENT_EFFECT_KIND_BYTE, 4
.equ INSTRUMENT_EFFECT_PARAM_BYTE, 5
.equ INSTRUMENT_SQUARE_DUTYCTRL_BYTE, 6

.equ ENV_RESET, 0x80
.equ ENV_PROCESS, 0x40
.equ ENV_SUSTAIN, 0x20

.equ NO_EFFECT, 0
.equ SLIDE_UP_EFFECT, 1
.equ SLIDE_DOWN_EFFECT, 2
.equ PORTAMENTO_EFFECT, 3
.equ VIBRATO_EFFECT, 4
.equ ARPEGGIO_EFFECT, 5
.equ VOLUME_SLIDE_EFFECT, 6
.equ CUT_EFFECT, 7

.equ SOUND_CONTROL_REGISTERS_BASE_ADDRESS, 0x04000060
.equ SOUND3CNT_L, 0x10
.equ SOUND3CNT_H, 0x12
.equ SOUND3CNT_X, 0x14
.equ SOUNDCNT_L, 0x20
.equ SOUNDCNT_H, 0x22
.equ SOUNDCNT_X, 0x24
.equ WAVERAM, 0x30

.equ DMA_REGISTERS_BASE_ADDRESS,   0x040000b0
.equ DMA1SAD, 0x0c
.equ DMA1DAD, 0x10
.equ DMA1CNT, 0x14
.equ DMA1CNT_H, 0x16

.equ TIMER_REGISTERS_BASE_ADDRESS, 0x04000100
.equ TM0CNT_L, 0x00
.equ TM0CNT_H, 0x02

.equ FIFO_A, 0x040000a0

@ Only one of these should be defined:
@ .equ MIXER_FREQ_5734, 1
@ .equ MIXER_FREQ_10512, 1
@ .equ MIXER_FREQ_13379, 1
@ .equ MIXER_FREQ_18157, 1
@ .equ MIXER_FREQ_21024, 1
@ .equ MIXER_FREQ_26758, 1
@ .equ MIXER_FREQ_31536, 1
@ .equ MIXER_FREQ_36314, 1
@ .equ MIXER_FREQ_40137, 1
.equ MIXER_FREQ_42048, 1
@ .equ MIXER_FREQ_43959, 1

.section .rodata
.align 4
@ ProTracker sine table
vibrato_table:
.byte 0x00,0x18,0x31,0x4A,0x61,0x78,0x8D,0xA1
.byte 0xB4,0xC5,0xD4,0xE0,0xEB,0xF4,0xFA,0xFD
.byte 0xFF,0xFD,0xFA,0xF4,0xEB,0xE0,0xD4,0xC5
.byte 0xB4,0xA1,0x8D,0x78,0x61,0x4A,0x31,0x18

period_table:
.hword 0x02c,0x09d,0x107,0x16b,0x1ca,0x223,0x277,0x2c7,0x312,0x358,0x39b,0x3da @ 0-11
.hword 0x416,0x44e,0x483,0x4b5,0x4e5,0x511,0x53c,0x563,0x589,0x5ac,0x5ce,0x5ed @ 12-23
.hword 0x60b,0x627,0x642,0x65b,0x672,0x689,0x69e,0x6b2,0x6c4,0x6d6,0x6e7,0x6f7 @ 24-35
.hword 0x706,0x714,0x721,0x72d,0x739,0x744,0x74f,0x759,0x762,0x76b,0x773,0x77b @ 36-47
.hword 0x783,0x78a,0x790,0x797,0x79d,0x7a2,0x7a7,0x7ac,0x7b1,0x7b6,0x7ba,0x7be @ 48-59
.hword 0x7c2,0x7c5,0x7c8,0x7cb,0x7ce,0x7d1,0x7d4,0x7d6,0x7d9,0x7db,0x7dd,0x7df @ 60-71

volume_table:
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00      @ MasterVol = 0
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01      @ 1
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02      @ 2
.byte 0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x02,0x02,0x02,0x02,0x02,0x03      @ 3
.byte 0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x01,0x02,0x02,0x02,0x02,0x03,0x03,0x03,0x04      @ ..
.byte 0x00,0x00,0x00,0x01,0x01,0x01,0x02,0x02,0x02,0x03,0x03,0x03,0x04,0x04,0x04,0x05
.byte 0x00,0x00,0x00,0x01,0x01,0x02,0x02,0x02,0x03,0x03,0x04,0x04,0x04,0x05,0x05,0x06
.byte 0x00,0x00,0x00,0x01,0x01,0x02,0x02,0x03,0x03,0x04,0x04,0x05,0x05,0x06,0x06,0x07
.byte 0x00,0x00,0x01,0x01,0x02,0x02,0x03,0x03,0x04,0x04,0x05,0x05,0x06,0x06,0x07,0x08
.byte 0x00,0x00,0x01,0x01,0x02,0x03,0x03,0x04,0x04,0x05,0x06,0x06,0x07,0x07,0x08,0x09
.byte 0x00,0x00,0x01,0x02,0x02,0x03,0x04,0x04,0x05,0x06,0x06,0x07,0x08,0x08,0x09,0x0A
.byte 0x00,0x00,0x01,0x02,0x02,0x03,0x04,0x05,0x05,0x06,0x07,0x08,0x08,0x09,0x0A,0x0B
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x04,0x05,0x06,0x07,0x08,0x08,0x09,0x0A,0x0B,0x0C
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D
.byte 0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E
.byte 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F

@ TODO: Create all step files for noise. Currently only 42048 is supported.
.ifdef MIXER_FREQ_5734
    .include "square_step_table_256_5734.inc"
    .include "noise_15bit_lfsr_step_table_2048_5734.inc"
    .include "noise_7bit_lfsr_step_table_64_5734.inc"
.else
    .ifdef MIXER_FREQ_10512
        .include "square_step_table_256_10512.inc"
        .include "noise_15bit_lfsr_step_table_2048_10512.inc"
        .include "noise_7bit_lfsr_step_table_64_10512.inc"
    .else
        .ifdef MIXER_FREQ_13379
            .include "square_step_table_256_13379.inc"
            .include "noise_15bit_lfsr_step_table_2048_13379.inc"
            .include "noise_7bit_lfsr_step_table_64_13379.inc"
        .else
            .ifdef MIXER_FREQ_18157
                .include "square_step_table_256_18157.inc"
                .include "noise_15bit_lfsr_step_table_2048_18157.inc"
                .include "noise_7bit_lfsr_step_table_64_18157.inc"
            .else
                .ifdef MIXER_FREQ_21024
                    .include "square_step_table_256_21024.inc"
                    .include "noise_15bit_lfsr_step_table_2048_21024.inc"
                    .include "noise_7bit_lfsr_step_table_64_21024.inc"
                .else
                    .ifdef MIXER_FREQ_26758
                        .include "square_step_table_256_26758.inc"
                        .include "noise_15bit_lfsr_step_table_2048_26758.inc"
                        .include "noise_7bit_lfsr_step_table_64_26758.inc"
                    .else
                        .ifdef MIXER_FREQ_31536
                            .include "square_step_table_256_31536.inc"
                            .include "noise_15bit_lfsr_step_table_2048_31536.inc"
                            .include "noise_7bit_lfsr_step_table_64_31536.inc"
                        .else
                            .ifdef MIXER_FREQ_36314
                                .include "square_step_table_256_36314.inc"
                                .include "noise_15bit_lfsr_step_table_2048_36314.inc"
                                .include "noise_7bit_lfsr_step_table_64_36314.inc"
                            .else
                                .ifdef MIXER_FREQ_40137
                                    .include "square_step_table_256_40137.inc"
                                    .include "noise_15bit_lfsr_step_table_2048_40137.inc"
                                    .include "noise_7bit_lfsr_step_table_64_40137.inc"
                                .else
                                    .ifdef MIXER_FREQ_42048
                                        .include "square_step_table_256_42048.inc"
                                        .include "noise_15bit_lfsr_step_table_2048_42048.inc"
                                        .include "noise_7bit_lfsr_step_table_64_42048.inc"
                                    .else
                                        .ifdef MIXER_FREQ_43959
                                            .include "square_step_table_256_43959.inc"
                                            .include "noise_15bit_lfsr_step_table_2048_43959.inc"
                                            .include "noise_7bit_lfsr_step_table_64_43959.inc"
                                        .else
                                            .error "One of MIXER_FREQ_xxx must be defined."
                                        .endif
                                    .endif
                                .endif
                            .endif
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
.endif

.include "noise_15bit_lfsr_sample_data.inc"
.include "noise_7bit_lfsr_sample_data.inc"

default_wav_ram:
@ bank 0
.byte 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88
.byte 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0xff
@ bank 1
.byte 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88
.byte 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0xff

square_sample_data_rom:
@ wave 00
.byte -120, -119, -118, -117, -116, -115, -114, -113, -112, -111, -110, -109, -108, -107, -106, -105
.byte -104, -104, -103, -102, -101, -100, -99, -98, -97, -96, -95, -94, -93, -92, -91, -90
.byte -89, -88, -88, -87, -86, -85, -84, -83, -82, -81, -80, -79, -78, -77, -76, -75
.byte -74, -73, -72, -72, -71, -70, -69, -68, -67, -66, -65, -64, -63, -62, -61, -60
.byte -59, -58, -57, -56, -56, -55, -54, -53, -52, -51, -50, -49, -48, -47, -46, -45
.byte -44, -43, -42, -41, -40, -40, -39, -38, -37, -36, -35, -34, -33, -32, -31, -30
.byte -29, -28, -27, -26, -25, -24, -24, -23, -22, -21, -20, -19, -18, -17, -16, -15
.byte -14, -13, -12, -11, -10, -9, -8, -8, -7, -6, -5, -4, -3, -2, -1, 0
.byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 14
.byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 24, 25, 26, 27, 28, 29
.byte 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 40, 41, 42, 43, 44
.byte 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59
.byte 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 72, 73, 74
.byte 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 88, 89
.byte 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 104
.byte 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120
@ wave 01
.byte 0, 3, 6, 9, 12, 16, 20, 24, 28, 32, 36, 40, 45, 50, 55, 60
.byte 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 125, 120, 115, 110, 105, 100, 95, 90
.byte 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 36, 32, 28, 24, 20, 16
.byte 12, 9, 6, 3, 0, -3, -6, -9, -12, -16, -20, -24, -28, -32, -36, -40
.byte -45, -50, -55, -60, -65, -70, -75, -80, -85, -90, -95, -100, -105, -110, -115, -120
.byte -125, -127, -127, -127, -127, -127, -127, -127, -127, -127, -125, -120, -115, -110, -105, -100
.byte -95, -90, -85, -80, -75, -70, -65, -60, -55, -50, -45, -40, -36, -32, -28, -24
.byte -20, -16, -12, -9, -6, -3, 0, 3, 6, 9, 12, 16, 20, 24, 28, 32
.byte 36, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110
.byte 115, 120, 125, 127, 127, 127, 127, 127, 127, 127, 127, 127, 125, 120, 115, 110
.byte 105, 100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 36, 32
.byte 28, 24, 20, 16, 12, 9, 6, 3, 0, -3, -6, -9, -12, -16, -20, -24
.byte -28, -32, -36, -40, -45, -50, -55, -60, -65, -70, -75, -80, -85, -90, -95, -100
.byte -105, -110, -115, -120, -125, -127, -127, -127, -127, -127, -127, -127, -127, -127, -127, -125
.byte -120, -115, -110, -105, -100, -95, -90, -85, -80, -75, -70, -65, -60, -55, -50, -45
.byte -40, -36, -32, -28, -24, -20, -16, -12, -9, -6, -3
@ wave 10
.byte 0, 65, 66, 68, 69, 71, 72, 74, 75, 77, 78, 80, 82, 83, 84, 86
.byte 87, 89, 90, 92, 93, 94, 96, 97, 98, 100, 101, 102, 103, 105, 106, 107
.byte 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 118, 119, 120, 121, 121
.byte 122, 122, 123, 123, 124, 124, 125, 125, 125, 126, 126, 126, 126, 126, 126, 126
.byte 126, 126, 126, 126, 126, 126, 126, 125, 125, 125, 124, 124, 124, 123, 123, 122
.byte 121, 121, 120, 119, 119, 118, 117, 116, 115, 115, 114, 113, 112, 111, 110, 109
.byte 107, 106, 105, 104, 103, 102, 100, 99, 98, 96, 95, 94, 92, 91, 90, 88
.byte 87, 85, 84, 82, 81, 79, 78, 76, 75, 73, 72, 70, 68, 67, 65, 64
.byte -64, -65, -67, -68, -70, -72, -73, -75, -76, -78, -79, -81, -82, -84, -85, -87
.byte -88, -90, -91, -92, -94, -95, -96, -98, -99, -100, -102, -103, -104, -105, -106, -107
.byte -109, -110, -111, -112, -113, -114, -115, -115, -116, -117, -118, -119, -119, -120, -121, -121
.byte -122, -123, -123, -124, -124, -124, -125, -125, -125, -126, -126, -126, -126, -126, -126, -126
.byte -126, -126, -126, -126, -126, -126, -126, -125, -125, -125, -124, -124, -123, -123, -122, -122
.byte -121, -121, -120, -119, -118, -118, -117, -116, -115, -114, -113, -112, -111, -110, -109, -108
.byte -107, -106, -105, -103, -102, -101, -100, -98, -97, -96, -94, -93, -92, -90, -89, -87
.byte -86, -84, -83, -82, -80, -78, -77, -75, -74, -72, -71, -69, -68, -66, -65, -63
@ wave 11
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
.byte -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128, -128
square_sample_data_rom_end:

.section .bss
.align 4
tracks: .space NUM_TRACKS * TRACK_SIZEOF

@ If you change the sample sizes, the xxx_step_table_yyy_zzz.inc files should be updated to match
.equ SQUARE_SAMPLE_SIZE, 256
.equ NOISE_15BIT_LFSR_SAMPLE_SIZE, 2048
.equ NOISE_7BIT_LFSR_SAMPLE_SIZE, 64

.ifdef MIXER_FREQ_5734
    .equ SOUND_BUFFER_SIZE, 96
.else
    .ifdef MIXER_FREQ_10512
        .equ SOUND_BUFFER_SIZE, 176
    .else
        .ifdef MIXER_FREQ_13379
            .equ SOUND_BUFFER_SIZE, 224
        .else
            .ifdef MIXER_FREQ_18157
                .equ SOUND_BUFFER_SIZE, 304
            .else
                .ifdef MIXER_FREQ_21024
                    .equ SOUND_BUFFER_SIZE, 352
                .else
                    .ifdef MIXER_FREQ_26758
                        .equ SOUND_BUFFER_SIZE, 448
                    .else
                        .ifdef MIXER_FREQ_31536
                            .equ SOUND_BUFFER_SIZE, 528
                        .else
                            .ifdef MIXER_FREQ_36314
                                .equ SOUND_BUFFER_SIZE, 608
                            .else
                                .ifdef MIXER_FREQ_40137
                                    .equ SOUND_BUFFER_SIZE, 672
                                .else
                                    .ifdef MIXER_FREQ_42048
                                        .equ SOUND_BUFFER_SIZE, 704
                                    .else
                                        .ifdef MIXER_FREQ_43959
                                            .equ SOUND_BUFFER_SIZE, 736
                                        .else
                                            .error "One of MIXER_FREQ_xxx must be defined."
                                        .endif
                                    .endif
                                .endif
                            .endif
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
.endif

.align 4

sound_buffer_data: .space SOUND_BUFFER_SIZE * 2
current_mix_buffer: .space 4

.ifdef COPY_SAMPLE_DATA_TO_RAM
@ Sample data is copied to RAM because it's much faster to access.
square_sample_data_ram: .space SQUARE_SAMPLE_SIZE * 4
noise_7bit_lfsr_sample_data_ram: .space NOISE_7BIT_LFSR_SAMPLE_SIZE
noise_15bit_lfsr_sample_data_ram: .space NOISE_15BIT_LFSR_SAMPLE_SIZE
.endif

.ifdef COPY_MIXER_CODE_TO_RAM
@ "Hot" mixer code is copied to RAM because it's much faster to execute.
mix_sound_channel1_and_2_ram: .space (mix_sound_channel1_and_2_rom_end - mix_sound_channel1_and_2_rom)
mix_sound_channel4_ram: .space (mix_sound_channel4_rom_end - mix_sound_channel4_rom)
.endif

.align 4
instrument_table_ptr: .space 4
pattern_table_ptr: .space 4
order_table_ptr: .space 4
play_note_callback: .space 4
shadow_sound3cnt_x: .space 2
master_vol: .space 1
sound_status: .space 1
shadow_nr32: .space 1

.section .text
.global init_sound
.global set_play_note_callback
.global start_song
.global update_sound
.global tracks
.global sound_status
.extern dma3
.extern jump_table
.code 32
.cpu arm7tdmi

.ifdef MIXER_FREQ_5734
    .equ MIXER_TIMER_VALUE, 62610
.else
    .ifdef MIXER_FREQ_10512
        .equ MIXER_TIMER_VALUE, 63940
    .else
        .ifdef MIXER_FREQ_13379
            .equ MIXER_TIMER_VALUE, 64282
        .else
            .ifdef MIXER_FREQ_18157
                .equ MIXER_TIMER_VALUE, 64612
            .else
                .ifdef MIXER_FREQ_21024
                    .equ MIXER_TIMER_VALUE, 64738
                .else
                    .ifdef MIXER_FREQ_26758
                        .equ MIXER_TIMER_VALUE, 64909
                    .else
                        .ifdef MIXER_FREQ_31536
                            .equ MIXER_TIMER_VALUE, 65004
                        .else
                            .ifdef MIXER_FREQ_36314
                                .equ MIXER_TIMER_VALUE, 65073
                            .else
                                .ifdef MIXER_FREQ_40137
                                    .equ MIXER_TIMER_VALUE, 65118
                                .else
                                    .ifdef MIXER_FREQ_42048
                                        .equ MIXER_TIMER_VALUE, 65137
                                    .else
                                        .ifdef MIXER_FREQ_43959
                                            .equ MIXER_TIMER_VALUE, 65154
                                        .else
                                            .error "One of MIXER_FREQ_xxx must be defined."
                                        .endif
                                    .endif
                                .endif
                            .endif
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
.endif

@ Channels 1 and 2 are mixed in one pass to avoid double traverse of mix buffer.
mix_sound_channel1_and_2_rom:
    ldr r0, =tracks
    @ set up channel 1 in registers r1, r2, r3, r4
    ldr r1, =sound_status
    ldrb r1, [r1]
    tst r1, #1 @ channel 1 muted?
    ldr r1, =master_vol
    ldrb r1, [r1]
    movne r1, #0
    ldrb r2, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    mul r3, r1, r2
    ldrb r2, [r0, #TRACK_MASTERVOL_BYTE]
    mul r4, r3, r2 @ volume
    lsr r4, r4, #16
    strb r4, [r0, #TRACK_EFFECTIVE_VOL_BYTE]

    ldr r3, =square_sample_data
    ldrb r1, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    tst r1, #3
    bne 1f @ if counter is non-zero, use duty from bits 6-7
    and r1, r1, #0x30 @ use duty from bits 4-5
    lsl r1, r1, #4 @ must correspond to SQUARE_SAMPLE_SIZE
    b 2f
    1:
    and r1, r1, #0xc0 @ use duty from bits 6-7
    lsl r1, r1, #2 @ must correspond to SQUARE_SAMPLE_SIZE
    2:
    add r3, r3, r1 @ sample data pointer

    ldrh r1, [r0, #TRACK_PERIOD_HWORD]
    ldr r2, =square_step_table
    ldr r2, [r2, r1, lsl #2] @ convert period to sample step

    ldrb r1, [r0, #TRACK_PERIODINDEX_BYTE]
    tst r1, #0x80 @ check trigger flag
    beq 1f @ no trigger
    bic r1, r1, #0x80 @ clear trigger flag
    strb r1, [r0, #TRACK_PERIODINDEX_BYTE]
    eor r1, r1, r1
    b 2f
    1:
    ldr r1, [r0, #TRACK_SAMPLE_POS_WORD]
    2:

    @ set up channel 2 in registers r5, r6, r7, r8
    ldr r5, =sound_status
    ldrb r5, [r5]
    tst r5, #2 @ channel 2 muted?
    ldr r5, =master_vol
    ldrb r5, [r5]
    movne r5, #0
    ldrb r6, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*1)]
    mul r7, r5, r6
    ldrb r6, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*1)]
    mul r8, r7, r6 @ volume
    lsr r8, r8, #16
    strb r8, [r0, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*1)]

    ldr r7, =square_sample_data
    ldrb r5, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    tst r5, #3
    bne 1f @ if counter is non-zero, use duty from bits 6-7
    and r5, r5, #0x30 @ use duty from bits 4-5
    lsl r5, r5, #4 @ must correspond to SQUARE_SAMPLE_SIZE
    b 2f
    1:
    and r5, r5, #0xc0 @ use duty from bits 6-7
    lsl r5, r5, #2 @ must correspond to SQUARE_SAMPLE_SIZE
    2:
    add r7, r7, r5 @ sample data pointer

    ldrh r5, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*1)]
    ldr r6, =square_step_table
    ldr r6, [r6, r5, lsl #2] @ convert period to sample step

    ldrb r5, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*1)]
    tst r5, #0x80 @ check trigger flag
    beq 1f @ no trigger
    bic r5, r5, #0x80 @ clear trigger flag
    strb r5, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*1)]
    eor r5, r5, r5
    b 2f
    1:
    ldr r5, [r0, #(TRACK_SAMPLE_POS_WORD + TRACK_SIZEOF*1)]
    2:

    @ prepare to loop
    ldr r0, =current_mix_buffer
    ldr r0, [r0]
    ldr r9, =SOUND_BUFFER_SIZE

    3: @ loop
    lsr r10, r1, #16 @ integer part of channel 1 sample pos
    and r10, r10, #(SQUARE_SAMPLE_SIZE - 1)
    ldrsb r10, [r3, r10] @ get channel 1 signed sample byte
    mul r11, r4, r10

    lsr r10, r5, #16 @ integer part of channel 2 sample pos
    and r10, r10, #(SQUARE_SAMPLE_SIZE - 1)
    ldrsb r10, [r7, r10] @ get channel 2 signed sample byte
    mla r11, r8, r10, r11
    asr r11, r11, #10

    @ clamp
    cmp r11, #127
    movgt r11, #127
    cmp r11, #-128
    movlt r11, #-128

    strb r11, [r0], #1 @ output sample

    add r1, r1, r2 @ add step to channel 1 sample pos
    add r5, r5, r6 @ add step to channel 2 sample pos
    subs r9, r9, #1
    bne 3b

    ldr r0, =tracks
    str r1, [r0, #TRACK_SAMPLE_POS_WORD]
    str r5, [r0, #(TRACK_SAMPLE_POS_WORD + TRACK_SIZEOF*1)]

    @ update square 1 duty
    ldrb r2, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    tst r2, #3
    beq 4f @ skip_duty_update
    sub r2, r2, #1
    strb r2, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    4: @ skip_duty_update

    @ update square 2 duty
    ldrb r2, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    tst r2, #3
    beq 4f @ skip_duty_update
    sub r2, r2, #1
    strb r2, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*1)]
    4: @ skip_duty_update
    bx lr
.ltorg
mix_sound_channel1_and_2_rom_end:

mix_sound_channel4_rom:
    ldr r0, =tracks
    ldr r1, =sound_status
    ldrb r1, [r1]
    tst r1, #8 @ channel muted?
    ldr r1, =master_vol
    ldrb r1, [r1]
    movne r1, #0
    ldrb r2, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*3)]
    mul r3, r1, r2
    ldrb r2, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*3)]
    mul r4, r3, r2
    lsr r4, r4, #16
    strb r4, [r0, #(TRACK_EFFECTIVE_VOL_BYTE + TRACK_SIZEOF*3)]

    ldr r2, =noise_15bit_lfsr_step_table
    ldr r3, =noise_15bit_lfsr_sample_data
    ldr r8, =(NOISE_15BIT_LFSR_SAMPLE_SIZE-1)
    ldrb r1, [r0, #(TRACK_SQUARE_DUTYCTRL_BYTE + TRACK_SIZEOF*3)]
    tst r1, #0x80 @ LFSR width
    beq 1f @ no_regular_output
    ldr r2, =noise_7bit_lfsr_step_table
    ldr r3, =noise_7bit_lfsr_sample_data
    ldr r8, =(NOISE_7BIT_LFSR_SAMPLE_SIZE-1)
    1: @ no_regular_output

    ldrh r1, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*3)]
    lsr r1, r1, #6 @ divide by 64
    ldr r2, [r2, r1, lsl #2] @ convert period to sample step

    ldrb r1, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    tst r1, #0x80 @ check trigger flag
    beq 1f @ no trigger
    bic r1, r1, #0x80 @ clear trigger flag
    strb r1, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*3)]
    eor r1, r1, r1
    b 2f
    1:
    ldr r1, [r0, #(TRACK_SAMPLE_POS_WORD + TRACK_SIZEOF*3)]
    2:

    ldr r0, =current_mix_buffer
    ldr r0, [r0]
    ldr r5, =SOUND_BUFFER_SIZE
    3:
    lsr r6, r1, #16 @ integer part of sample pos
    and r6, r6, r8
    ldrsb r6, [r3, r6] @ get signed sample byte
    mul r7, r4, r6
    asr r7, r7, #10
    ldrsb r6, [r0]
    add r7, r7, r6
    cmp r7, #127
    movgt r7, #127
    cmp r7, #-128
    movlt r7, #-128
    strb r7, [r0], #1
    add r1, r1, r2 @ add step to sample pos
    subs r5, r5, #1
    bne 3b

    ldr r0, =tracks
    str r1, [r0, #(TRACK_SAMPLE_POS_WORD + TRACK_SIZEOF*3)]
    bx lr
.ltorg
mix_sound_channel4_rom_end:

init_sound:
    push {lr}
.ifdef COPY_SAMPLE_DATA_TO_RAM
    bl copy_square_sample_data_from_rom_to_ram
    bl copy_noise_7bit_lfsr_sample_data_from_rom_to_ram
    bl copy_noise_15bit_lfsr_sample_data_from_rom_to_ram
.endif
.ifdef COPY_MIXER_CODE_TO_RAM
    bl copy_mix_sound_channel1_and_2_from_rom_to_ram
    bl copy_mix_sound_channel4_from_rom_to_ram
.endif

    ldr r0, =SOUND_CONTROL_REGISTERS_BASE_ADDRESS
    ldr r1, =0x80
    strh r1, [r0, #SOUNDCNT_X] @ enable sound
    ldr r1, =0x4466 @ sound output on channel 3, vol 6
    strh r1, [r0, #SOUNDCNT_L]
    ldr r1, =0x0b06 @ full-range output sound A on L and R and 3, timer 0, clear and sequencer reset
    strh r1, [r0, #SOUNDCNT_H]

    ldr r0, =TIMER_REGISTERS_BASE_ADDRESS
    ldr r1, =MIXER_TIMER_VALUE
    strh r1, [r0, #TM0CNT_L]
    ldr r1, =0x80
    strh r1, [r0, #TM0CNT_H] @ enable timer

    ldr r0, =DMA_REGISTERS_BASE_ADDRESS
    ldr r1, =FIFO_A
    str r1, [r0, #DMA1DAD]
    eor r1, r1, r1
    str r1, [r0, #DMA1CNT]

    ldr r0, =current_mix_buffer
    ldr r1, =sound_buffer_data
    str r1, [r0]

    ldr r0, =sound_status
    mov r1, #0
    strb r1, [r0] @ unmute all channels
    ldr r0, =default_wav_ram
    bl copy_from_r0_into_waveram
    pop {lr}
    bx lr

.ifdef COPY_SAMPLE_DATA_TO_RAM
copy_square_sample_data_from_rom_to_ram:
    ldr r0, =square_sample_data_rom
    ldr r1, =square_sample_data_ram
    ldr r2, =((square_sample_data_rom_end - square_sample_data_rom) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    b dma3

copy_noise_7bit_lfsr_sample_data_from_rom_to_ram:
    ldr r0, =noise_7bit_lfsr_sample_data_rom
    ldr r1, =noise_7bit_lfsr_sample_data_ram
    mov r2, #((noise_7bit_lfsr_sample_data_rom_end - noise_7bit_lfsr_sample_data_rom) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    b dma3

copy_noise_15bit_lfsr_sample_data_from_rom_to_ram:
    ldr r0, =noise_15bit_lfsr_sample_data_rom
    ldr r1, =noise_15bit_lfsr_sample_data_ram
    mov r2, #((noise_15bit_lfsr_sample_data_rom_end - noise_15bit_lfsr_sample_data_rom) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    b dma3
.endif

.ifdef COPY_MIXER_CODE_TO_RAM
copy_mix_sound_channel1_and_2_from_rom_to_ram:
    ldr r0, =mix_sound_channel1_and_2_rom
    ldr r1, =mix_sound_channel1_and_2_ram
    mov r2, #((mix_sound_channel1_and_2_rom_end - mix_sound_channel1_and_2_rom) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    b dma3

copy_mix_sound_channel4_from_rom_to_ram:
    ldr r0, =mix_sound_channel4_rom
    ldr r1, =mix_sound_channel4_ram
    mov r2, #((mix_sound_channel4_rom_end - mix_sound_channel4_rom) / 4)
    orr r2, r2, #(DMA_ENABLE | DMA_START_NOW | DMA_32BIT | DMA_SRC_INC | DMA_DST_INC)
    b dma3
.endif

set_play_note_callback:
    ldr r1, =play_note_callback
    str r0, [r1]
    bx lr

call_play_note_callback:
    ldr r2, =play_note_callback
    ldr r2, [r2]
    tst r2, r2
    bxne r2
    bx lr

@ r0 = pointer to song
start_song:
    ldr r1, [r0], #4
    ldr r2, =instrument_table_ptr
    str r1, [r2]
    ldr r1, [r0], #4
    ldr r2, =pattern_table_ptr
    str r1, [r2]
    ldr r1, =tracks
    ldrb r2, =NUM_TRACKS
    1: @ loop
    ldrb r3, [r0], #1
    strb r3, [r1, #TRACK_ORDER_POS_BYTE]
    cmp r3, #0xff
    beq 2f @ skip
    ldrb r3, [r0], #1 @ fetch initial speed
@    lsl r3, r3, #3 @ slow it down by factor of 8 - useful for debugging
    2: @ skip
    strb r3, [r1, #TRACK_SPEED_BYTE]
    subs r3, r3, #1
    strb r3, [r1, #TRACK_TICK_BYTE]
    eor r3, r3, r3
    strb r3, [r1, #TRACK_EFFECT_KIND_BYTE]
    strb r3, [r1, #TRACK_PERIODINDEX_BYTE]
    strh r3, [r1, #TRACK_PERIOD_HWORD]
    strb r3, [r1, #TRACK_ENVELOPE_PHASE_BYTE]
    strb r3, [r1, #TRACK_PATTERN_ROW_BYTE]
    add r3, r3, #1
    strb r3, [r1, #TRACK_PATTERN_ROWCOUNT_BYTE]
    ldrb r3, =0xf0 @ max volume
    strb r3, [r1, #TRACK_MASTERVOL_BYTE]
    add r1, r1, #TRACK_SIZEOF
    subs r2, r2, #1
    bne 1b @ loop
    ldr r1, =order_table_ptr
    str r0, [r1]
    ldr r1, =master_vol
    strb r3, [r1] @ max volume
    bx lr

copy_from_r0_into_waveram:
    ldr r1, =(SOUND_CONTROL_REGISTERS_BASE_ADDRESS + WAVERAM)
@ bank 0
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
@ bank 1
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    ldrh r3, [r0], #2
    strh r3, [r1], #2
    bx lr

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

update_sound:
    push {r4-r12, lr}
    bl write_channel3_registers
    bl swap_sound_buffers
    ldr r0, =tracks
    ldrb r1, =NUM_TRACKS
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
    eor r3, r3, r3
    strb r3, [r0, #TRACK_TICK_BYTE]
    ldrb r2, [r0, #TRACK_PATTERN_ROWCOUNT_BYTE]
    ldrb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    add r3, r3, #1
    cmp r3, r2 @ row == rowCount?
    bne update_sound__no_new_pattern
    @ end of pattern
    eor r3, r3, r3
    strb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    ldr r2, =order_table_ptr
    ldr r2, [r2]
    ldrb r3, [r0, #TRACK_ORDER_POS_BYTE]
update_sound__order_loop:
    ldrb r4, [r2, r3] @ order_table[order_pos]
    add r3, r3, #1
    cmp r4, #0xf0
    bcs update_sound__order_special
    @ r4 = pattern index
    strb r3, [r0, #TRACK_ORDER_POS_BYTE]
    ldr r2, =pattern_table_ptr
    ldr r2, [r2]
    ldr r2, [r2, r4, lsl #2] @ pattern_table[index]
    ldrb r3, [r2], #1 @ first byte of pattern is the row count
    strb r3, [r0, #TRACK_PATTERN_ROWCOUNT_BYTE]
    b update_sound__fetch_row_status
update_sound__order_special:
    @ TODO: implement order commands. Assume 0xfe for now
    ldrb r3, [r2, r3] @ order_table[order_pos]
    b update_sound__order_loop
update_sound__no_new_pattern:
    strb r3, [r0, #TRACK_PATTERN_ROW_BYTE]
    ands r3, r3, #7
    ldrb r3, [r0, #TRACK_PATTERN_ROWSTATUS_BYTE]
    ldr r2, [r0, #TRACK_PATTERN_PTR_WORD]
    bne update_sound__check_row_status
update_sound__fetch_row_status:
    ldrb r3, [r2], #1
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
update_sound__check_row_status:
    lsrs r3, r3, #1
    strb r3, [r0, #TRACK_PATTERN_ROWSTATUS_BYTE]
    bcc update_sound__mixer_tick
update_sound__pattern_fetch_loop:
    ldrb r3, [r2], #1 @ fetch pattern byte
    cmp r3, #0xb0
    bcc update_sound__is_note
    cmp r3, #0xc0
    bcc update_sound__is_set_instrument_command
    cmp r3, #0xd0
    bcc update_sound__is_set_speed_command
    cmp r3, #0xe0
    bcc update_sound__is_set_volume_command
    cmp r3, #0xf0
    bcs update_sound__is_other_command
    @ set effect and param
    ands r3, r3, #0x0f
    strb r3, [r0, #TRACK_EFFECT_KIND_BYTE]
    beq update_sound__pattern_fetch_loop @ effect = 0 --> no parameter byte
    ldrb r3, [r2], #1
    strb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    b update_sound__pattern_fetch_loop
update_sound__is_note:
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
    eor r2, r2, r2
    str r2, [r0, #TRACK_SAMPLE_POS_WORD]
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    strh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    ldrb r2, [r0, #TRACK_MASTERVOL_BYTE]
    lsrs r2, r2, #1
    bcs 1f @ skip @ CF=1 if the volume has been overridden by a previous volume command
    ldrb r2, =0x78
    1: @ skip
    lsl r2, r2, #1
    strb r2, [r0, #TRACK_MASTERVOL_BYTE]
    ldrb r2, =ENV_RESET
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    ldrb r2, [r0, #TRACK_EFFECT_KIND_BYTE]
    cmp r2, #PORTAMENTO_EFFECT
    beq update_sound__init_slide
    @ no slide, set new period immediately
    add r3, r3, r3
    ldr r2, =period_table
    ldrh r2, [r2, r3] @ period_table[index]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    lsr r3, r3, #1
    orr r3, r3, #0x80 @ trigger channel
    strb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    ldrb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    and r2, r3, #0x0c @ initial counter
    lsr r2, r2, #2
    bic r3, r3, #0x03
    orr r3, r3, r2 @ copy initial counter to current counter
    strb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    bl call_play_note_callback
    b update_sound__mixer_tick
update_sound__is_set_instrument_command:
    and r3, r3, #0x0f @ instrument in lower 4 bits
    bl set_instrument
    b update_sound__pattern_fetch_loop
update_sound__is_set_speed_command:
    and r3, r3, #0x0f @ new speed - 1
    add r3, r3, #1
    push {r0}
    bl set_speed
    pop {r0}
    b update_sound__pattern_fetch_loop
update_sound__is_set_volume_command:
    and r3, r3, #0x0f
    lsl r3, r3, #4
    orr r3, r3, #1 @ indicates that volume was explicitly set
    strb r3, [r0, #TRACK_MASTERVOL_BYTE]
    b update_sound__pattern_fetch_loop
update_sound__is_other_command:
    push {r0, r1}
    and r0, r3, #0x0f
    bl go_pattern_command @ is responsible for pop {r0, r1}
    bcs update_sound__pattern_fetch_loop
    str r2, [r0, #TRACK_PATTERN_PTR_WORD]
    b update_sound__mixer_tick
update_sound__init_slide:
    ldrb r2, [r0, #TRACK_PERIODINDEX_BYTE]
    cmp r3, r2 @ CF = slide direction (0=down, 1=up)
    strb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    ldr r2, =0x80
    adc r2, r2, #0 @ bit 7 = 1 (active), bit 0 = direction (0=down, 1=up)
    strb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    add r3, r3, r3 @ note * 2
    ldr r2, =period_table
    ldrh r2, [r2, r3]
    strh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
update_sound__mixer_tick:
    bl effect_tick
    bl envelope_tick
update_sound__next_track:
    add r0, r0, #TRACK_SIZEOF
    subs r1, r1, #1
    bne update_sound__loop

    bl render_channel3_shadow_registers
    bl mix_sound

    pop {r4-r12, lr}
    bx lr

@@@@@@@@@@@@@@@@@@@@@@@@

@ To synchronize channel 3 output with the double-buffered direct sound output,
@ writes to channel 3 hardware registers should be delayed by one frame.
@ So we render the values to memory ("shadow registers") now, and write them to
@ hardware registers in the next vblank.

render_channel3_shadow_registers:
    ldr r0, =tracks
    @ NR32
    ldrb r2, [r0, #(TRACK_ENVELOPE_VOL_BYTE + TRACK_SIZEOF*2)]
    lsr r2, r2, #4
    ldrb r3, [r0, #(TRACK_MASTERVOL_BYTE + TRACK_SIZEOF*2)]
    orr r2, r2, r3
    ldr r4, =volume_table
    ldrb r2, [r4, r2] @ envelope volume scaled according to track volume (0..F)
    ldr r3, =master_vol
    ldrb r3, [r3]
    orr r2, r2, r3
    ldrb r2, [r4, r2] @ computed track volume scaled according to master volume (0..F)
    ldr r3, =shadow_nr32
    strb r2, [r3]
    @ SOUND3CNT_X (period)
    ldrh r2, [r0, #(TRACK_PERIOD_HWORD + TRACK_SIZEOF*2)]
    ldrb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*2)]
    tst r3, #0x80 @ check trigger flag
    beq 2f @ no_trigger
    orr r2, r2, #0x8000
    bic r3, r3, #0x80 @ clear trigger flag
    strb r3, [r0, #(TRACK_PERIODINDEX_BYTE + TRACK_SIZEOF*2)]
    2: @ no_trigger
    ldr r3, =shadow_sound3cnt_x
    strh r2, [r3]
    bx lr

write_channel3_registers:
    ldr r0, =tracks
    ldr r1, =SOUND_CONTROL_REGISTERS_BASE_ADDRESS
    ldr r2, =shadow_nr32
    ldrb r2, [r2]
    lsl r2, r2, #11 @ volume in bits 14-13
    ands r2, r2, #0x6000
    beq write_channel3_registers__write_nr32 @ mute (no sound)
    tst r2, #0x2000
    beq write_channel3_registers__write_nr32 @ 50% volume
    eor r2, r2, #0x4000 @ 100% or 25% volume
write_channel3_registers__write_nr32:
    strh r2, [r1, #SOUND3CNT_H]
    ldr r2, =sound_status
    ldrb r2, [r2]
    tst r2, #4 @ channel 3 muted?
    beq write_channel3_registers__not_muted
    ldr r2, =0x7fff
    strh r2, [r1, #SOUND3CNT_X]
    bx lr
write_channel3_registers__not_muted:
    ldr r2, =shadow_sound3cnt_x
    ldrh r2, [r2]
    strh r2, [r1, #SOUND3CNT_X]
    ldr r2, =0xc0
    strh r2, [r1, #SOUND3CNT_L]
    bx lr

@@@@@@@@@@@@@@@@@@@@@@@@

mix_sound:
    push {lr}
    adr lr, 1f
    ldr r0, =mix_sound_channel1_and_2
    bx r0
    1:
    adr lr, 1f
    ldr r0, =mix_sound_channel4
    bx r0
    1:
    pop {lr}
    bx lr

@@@@@@@@ effects @@@@@@@

effect_tick:
    push {r0, r1}
    ldrb r0, [r0, #TRACK_EFFECT_KIND_BYTE]
    ldr r1, =1f
    b jump_table
.align 4
    1:
.word null_effect_tick @ 0
.word slide_up_effect_tick @ 1
.word slide_down_effect_tick @ 2
.word portamento_effect_tick @ 3
.word vibrato_effect_tick @ 4
.word arpeggio_effect_tick @ 5
.word volume_slide_effect_tick @ 6
.word tremolo_effect_tick @ 7
.word cut_effect_tick @ 8
.word pulsemod_effect_tick @ 9

null_effect_tick:
    pop {r0, r1}
    bx lr

slide_up_effect_tick:
    @ slide up by adding slide amount to period value
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    add r3, r3, r2
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr

slide_down_effect_tick:
    @ slide down by subtracting slide amount from period value
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    sub r3, r3, r2
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr

portamento_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    tst r2, #0x80 @ active?
    beq 1f @ portamento_exit
    tst r2, #1 @ direction (0=down, 1=up)
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrh r3, [r0, #TRACK_PERIOD_HWORD]
    beq 2f @ portamento_down
    @ slide up (add delta to current period value)
    add r3, r3, r2
    @ check if target period has been reached (current period >= target period)
    ldrh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    cmp r3, r2
    bcs 3f @ portamento_done
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr
    2: @portamento_down
    @ slide down (subtract delta from current period value)
    sub r3, r3, r2
    @ check if target period has been reached (current period <= target period)
    ldrh r2, [r0, #TRACK_EFFECT_PORTAMENTO_TARGETPERIOD_HWORD]
    cmp r2, r3
    bcs 3f @ portamento_done
    strh r3, [r0, #TRACK_PERIOD_HWORD]
    bx lr
    3: @ portamento_done
    @ set final period
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ halt
    eor r2, r2, r2
    strb r2, [r0, #TRACK_EFFECT_PORTAMENTO_CTRL_BYTE]
    1: @portamento_exit
    bx lr

vibrato_effect_tick:
    pop {r0, r1}
    @ reset period value
    ldrb r2, [r0, #TRACK_PERIODINDEX_BYTE]
    bic r2, r2, #0x80 @ remove trigger flag
    add r2, r2, r2
    ldr r3, =period_table
    ldrh r2, [r2, r3]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ get sine value
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    and r2, r2, #0x1f
    ldr r3, =vibrato_table
    ldrb r2, [r3, r2]
    @ *** convert sine value to real delta freq, according to vibrato depth ***
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    and r3, r3, #0x0f @ VibratoDepth in lower 4 bits
    eor r4, r4, r4
    @ this loop performs SineValue*VibratoDepth, putting result in r4
    1:
    add r4, r2
    subs r3, r3, #1
    bne 1b
    @ compute (SineValue*VibratoDepth)/128
    lsr r3, r4, #7
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    tst r2, #0x20
    ldrh r2, [r0, #TRACK_PERIOD_HWORD]
    beq 2f @ vib_add
    @ subtract from period
    sub r2, r2, r3
    b 3f @ vib_done
    2: @ vib_add
    @ add to period
    add r2, r2, r3
    3: @ vib_done
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    @ increment pos
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    lsr r3, r3, #4 @ vibrato speed
    add r2, r2, r3
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    bx lr

arpeggio_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    add r3, r2, #1
    cmp r3, #6
    bcc 1f
    eor r3, r3, r3
    1:
    strb r3, [r0, #TRACK_EFFECT_POS_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    lsrs r2, r2, #1
    beq 2f @ set_period - use base note
    subs r2, r2, #1
    beq 3f @ use_mid_note
    @ use top note
    and r2, r3, #0x0f
    b 2f @ set_period
    3: @ use_mid_note
    lsr r2, r3, #4
    2: @ set_period
    ldrb r3, [r0, #TRACK_PERIODINDEX_BYTE]
    bic r3, r3, #0x80 @ remove trigger flag
    add r2, r2, r3
    add r2, r2, r2
    ldr r3, =period_table
    ldrh r2, [r3, r2]
    strh r2, [r0, #TRACK_PERIOD_HWORD]
    bx lr

volume_slide_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    cmp r2, #0x10
    bcc 1f @ sub_volume
    @ add to volume
    lsr r2, r2, #4
    lsl r2, r2, #2 @ delta * 4
    ldrb r3, [r0, #TRACK_MASTERVOL_BYTE]
    add r3, r3, r2
    cmp r3, #0xfc
    movgt r3, #0xfc @ set max volume
    b 2f @ set_volume
    1: @ sub_volume
    lsl r2, r2, #2 @ delta * 4
    ldrb r3, [r0, #TRACK_MASTERVOL_BYTE]
    subs r3, r3, r2
    movlt r3, #0
    2: @ set_volume
    strb r3, [r0, #TRACK_MASTERVOL_BYTE]
    bx lr

tremolo_effect_tick:
    pop {r0, r1}
    @ TODO: implement tremolo
    bx lr

cut_effect_tick:
    pop {r0, r1}
    ldrb r2, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrb r3, [r0, #TRACK_EFFECT_POS_BYTE]
    cmp r3, r2
    bcs 1f
    add r2, r3, #1
    strb r2, [r0, #TRACK_EFFECT_POS_BYTE]
    bx lr
    1: @ cut! (set volume to 0)
    eor r2, r2, r2
    strb r2, [r0, #TRACK_MASTERVOL_BYTE]
    bx lr

pulsemod_effect_tick:
    pop {r0, r1}
    @ TODO: implement pulsemod
    bx lr

@@@@@@@@ volume envelopes @@@@@@@

envelope_tick:
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    tst r2, #ENV_RESET
    bne envelope_init
    tst r2, #ENV_PROCESS
    bne envelope_process
    tst r2, #ENV_SUSTAIN
    bne envelope_sustain
    bx lr

envelope_init:
    lsr r2, r2, #1 @ ENV_PROCESS
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    ldr r2, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r4, [r2] @ 1st byte = start volume
    strb r4, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    ldr r3, =1
envelope_point_init:
    ldrb r4, [r2, r3] @ fetch envelope byte
    add r3, r3, #1
    cmp r4, #0xff @ end of envelope reached?
    beq 1f @ env_end
    @ point OK, set 3-tuple (step, dest, hold)
    strb r4, [r0, #TRACK_ENVELOPE_STEP_BYTE]
    ldrb r4, [r2, r3]
    add r3, r3, #1
    strb r4, [r0, #TRACK_ENVELOPE_DEST_BYTE]
    ldrb r4, [r2, r3]
    add r3, r3, #1
    strb r4, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    strb r3, [r0, #TRACK_ENVELOPE_POS_BYTE]
    bx lr @ b envelope_process

    1: @ env_end
    ldrb r3, [r2, r3]
    cmp r3, #0xff @ definitely end?
    bne envelope_point_init @ loop the envelope from the given offset
    eor r3, r3, r3
    strb r3, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    bx lr

envelope_process:
    ldrb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    ldrb r2, [r0, #TRACK_ENVELOPE_DEST_BYTE]
    ldrb r4, [r0, #TRACK_ENVELOPE_STEP_BYTE]
    cmp r2, r3
    bcc 1f @ dest < current --> sub_volume
    @ add step to vol
    add r3, r3, r4
    cmp r3, r2
    bcs 2f @ reached_dest
    strb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    bx lr
    1: @ sub_volume
    @ subtract step from volume
    subs r3, r3, r4
    bcc 2f @ reached_dest
    cmp r3, r2
    beq 2f @ reached_dest
    strb r3, [r0, #TRACK_ENVELOPE_VOL_BYTE]
    bx lr
    2: @ reached_dest
    strb r2, [r0, #TRACK_ENVELOPE_VOL_BYTE] @ dest
    ldrb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    orrs r2, r2, r2
    beq envelope_next_point
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    lsr r2, r2, #1 @ phase = sustain
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    bx lr
envelope_next_point:
    ldr r2, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r3, [r0, #TRACK_ENVELOPE_POS_BYTE]
    b envelope_point_init

envelope_sustain:
    ldrb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    cmp r2, #0xff @ hold forever?
    beq 1f @ keep_sustaining
    subs r2, r2, #1
    strb r2, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    bne 1f @ keep_sustaining
    ldrb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    lsl r2, r2, #1 @ ENV_PROCESS
    strb r2, [r0, #TRACK_ENVELOPE_PHASE_BYTE]
    b envelope_next_point
    1: @ keep_sustaining
    bx lr

@ r3 = new instrument
@ r4 is destroyed
set_instrument:
    lsl r3, r3, #3 @ each instrument is 8 bytes long
    ldr r4, =instrument_table_ptr
    ldr r4, [r4]
    add r4, r4, r3
    ldr r3, [r4, #INSTRUMENT_ENVELOPE_PTR_WORD]
    str r3, [r0, #TRACK_ENVELOPE_PTR_WORD]
    ldrb r3, [r4, #INSTRUMENT_EFFECT_KIND_BYTE]
    strb r3, [r0, #TRACK_EFFECT_KIND_BYTE]
    ldrb r3, [r4, #INSTRUMENT_EFFECT_PARAM_BYTE]
    strb r3, [r0, #TRACK_EFFECT_PARAM_BYTE]
    ldrb r3, [r4, #INSTRUMENT_SQUARE_DUTYCTRL_BYTE]
    strb r3, [r0, #TRACK_SQUARE_DUTYCTRL_BYTE]
    bx lr

@ r3 = new speed
@ r0 is destroyed
set_speed:
    ldr r0, =tracks
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*0)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*1)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*2)]
    strb r3, [r0, #(TRACK_SPEED_BYTE + TRACK_SIZEOF*3)]
    bx lr

@@@@@@ pattern commands @@@@@@

go_pattern_command:
    ldr r1, =1f
    b jump_table
.align 4
    1:
.word set_instr_command
.word release_command
.word set_speed_command
.word end_row_command
.word pan_left_command
.word pan_center_command
.word pan_right_command

set_instr_command:
    pop {r0, r1}
    ldrb r3, [r2], #1 @ instrument
    push {lr}
    bl set_instrument
    pop {lr}
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

release_command:
    pop {r0, r1}
    ldrb r3, =1
    strb r3, [r0, #TRACK_ENVELOPE_HOLD_BYTE]
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

set_speed_command:
    ldrb r3, [r2], #1 @ new speed
    push {lr}
    bl set_speed
    pop {lr}
    pop {r0, r1}
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

end_row_command:
    pop {r0, r1}
    ldrb r3, [r0, #TRACK_MASTERVOL_BYTE]
    bic r3, r3, #0x01 @ clear explicit set volume bit
    strb r3, [r0, #TRACK_MASTERVOL_BYTE]
    eor r3, r3, r3
    adds r3, r3, r3 @ clear carry flag to signal end of pattern data processing
    bx lr

pan_left_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

pan_center_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr

pan_right_command:
    pop {r0, r1}
    @ TODO: implement panning
    orrs r3, r3, #0 @ set carry to keep processing pattern data
    bx lr
