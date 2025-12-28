.DELETE_ON_ERROR:

PROGRAM = DPadHero

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s song.s song.inc silentsong.s silentsong.inc hardware.inc buttonsprites.bin explosionsprites.bin gamescreentiles.bin gamescreentilemap.bin pushstarttiles.bin
	rgbasm -o $(PROGRAM).o main.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

silentsong.inc: silent.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

gamescreentiles.bin gamescreen.nam: gamescreen.chr
	packchr --character-output=gamescreentiles.bin --nametable-output=gamescreen.nam gamescreen.chr

gamescreentilemap.bin: gamescreen.nam
	packnam --width=20 --vram-address=0x9800 --output=gamescreentilemap.bin gamescreen.nam

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
