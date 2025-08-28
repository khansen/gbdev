PROGRAM = SuperMario64StaffRoll

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
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
	screwattack.bin
	rgbasm -o $(PROGRAM).o main.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
