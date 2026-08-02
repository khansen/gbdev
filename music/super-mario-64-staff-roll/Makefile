.DELETE_ON_ERROR:

PROGRAM = SuperMario64StaffRoll
SHARED_GB_LIB := ../../lib/gb
SOUND_ENGINE_FLAGS ?= -D NO_SONG_SPEED_ADJUSTMENT

$(PROGRAM).gb: $(PROGRAM).o sound-engine.o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o sound-engine.o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s song.s song.inc hardware.inc \
	flip.bin \
	egg.bin \
	elf.bin \
	dragon.bin \
	money.bin \
	turtle.bin \
	jumpman.bin \
	hand.bin \
	boots.bin \
	oh.bin \
	knight.bin \
	1up.bin \
	star.bin \
	fish.bin \
	lamp.bin \
	start.bin \
	question.bin \
	heart.bin \
	heart2.bin \
	axe.bin \
	kirby.bin \
	pow.bin \
	mario.bin \
	screwattack.bin $(SHARED_GB_LIB)/sound-engine.inc
	rgbasm -I $(SHARED_GB_LIB)/ -o $(PROGRAM).o main.s

sound-engine.o: $(SHARED_GB_LIB)/sound-engine.s $(SHARED_GB_LIB)/sound-engine.inc hardware.inc
	rgbasm $(SOUND_ENGINE_FLAGS) -I . -I $(SHARED_GB_LIB)/ -o $@ $(SHARED_GB_LIB)/sound-engine.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o sound-engine.o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
