.DELETE_ON_ERROR:

PROGRAM = SaveYourTears
SHARED_GB_LIB := ../../lib/gb
SOUND_ENGINE_FLAGS ?= -D NO_SONG_SPEED_ADJUSTMENT

$(PROGRAM).gb: $(PROGRAM).o sound-engine.o
	rgblink -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o sound-engine.o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s song.s song.inc hardware.inc font.bin ball.bin $(SHARED_GB_LIB)/sound-engine.inc
	rgbasm -I $(SHARED_GB_LIB)/ -o $(PROGRAM).o main.s

sound-engine.o: $(SHARED_GB_LIB)/sound-engine.s $(SHARED_GB_LIB)/sound-engine.inc hardware.inc
	rgbasm $(SOUND_ENGINE_FLAGS) -I . -I $(SHARED_GB_LIB)/ -o $@ $(SHARED_GB_LIB)/sound-engine.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o sound-engine.o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
