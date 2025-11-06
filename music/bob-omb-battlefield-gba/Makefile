.DELETE_ON_ERROR:

PROGRAM = BobOmbBattlefield

$(PROGRAM).gba: $(PROGRAM).elf
	arm-none-eabi-objcopy -O binary $(PROGRAM).elf $(PROGRAM).gba

OBJECTS = main.o sound_engine.o image_data.o song_instrument_table.o song_data.o

$(PROGRAM).elf: $(OBJECTS) gba.ld
	arm-none-eabi-ld -T gba.ld -o $(PROGRAM).elf $(OBJECTS) -Map=$(PROGRAM).map

main.o: main.s font.bin
	arm-none-eabi-as -o $@ $<

sound_engine.o: sound_engine.s
	arm-none-eabi-as -o $@ $<

image_data.o: image_data.s
	arm-none-eabi-as -o $@ $<

song_instrument_table.o: song_instrument_table.s
	arm-none-eabi-as -o $@ $<

song_data.o: song_data.s
	arm-none-eabi-as -o $@ $<

song_data.s: song.xm instruments.txt
	xm2gba --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm -f $(OBJECTS) $(PROGRAM).elf $(PROGRAM).gba $(PROGRAM).map
