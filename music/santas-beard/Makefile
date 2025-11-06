.DELETE_ON_ERROR:

PROGRAM = SantasBeard

$(PROGRAM).gba: $(PROGRAM).elf
	arm-none-eabi-objcopy -O binary $(PROGRAM).elf $(PROGRAM).gba

OBJECTS = main.o dma.o sound_engine.o song_instrument_table.o song_data.o image_data.o

$(PROGRAM).elf: $(OBJECTS) gba.ld
	arm-none-eabi-ld -T gba.ld -o $(PROGRAM).elf $(OBJECTS) -Map=$(PROGRAM).map

main.o: main.s dma_constants.s track_constants.s
	arm-none-eabi-as -o $@ $<

dma.o: dma.s
	arm-none-eabi-as -o $@ $<

sound_engine.o: sound_engine.s square_step_table_256_42048.inc dma_constants.s track_constants.s
	arm-none-eabi-as -o $@ $<

song_instrument_table.o: song_instrument_table.s
	arm-none-eabi-as -o $@ $<

song_data.o: song_data.s
	arm-none-eabi-as -o $@ $<

song_data.s: song.xm instruments.txt
	xm2gba --instruments-map=instruments.txt $< > $@

image_data.o: image_data.s background.bin
	arm-none-eabi-as -o $@ $<

.PHONY: clean

clean:
	rm -f $(OBJECTS) $(PROGRAM).elf $(PROGRAM).gba $(PROGRAM).map
