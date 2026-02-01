.DELETE_ON_ERROR:

PROGRAM = DPadHero

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
	rgbfix -v -p 0xFF $(PROGRAM).gb

CHRS = targetsprites.bin \
	explosionsprites.bin \
	gamescreentiles.bin \
	gamescreentilemap.bin \
	playtestsettingsfont.bin \
	progressbartiles.bin \
	hilitehitzonetiles.bin \
	misstiles.bin \
	healthbartiles.bin

$(PROGRAM).o: main.s \
	whiskeysong.s \
	whiskeysong.inc \
	whiskeycues.inc \
	maplesong.s \
	maplesong.inc \
	maplecues.inc \
	silentsong.s \
	silentsong.inc \
	hardware.inc \
	$(CHRS)
	rgbasm -o $(PROGRAM).o main.s

whiskeysong.inc: whiskey.xm whiskey-instruments.txt
	xm2gb --instruments-map=whiskey-instruments.txt $< > $@

whiskeycues.inc: whiskey.xm
	xm2cues/xm2cues $< > whiskeycues.inc

maplesong.inc: maple.xm maple-instruments.txt
	xm2gb --instruments-map=maple-instruments.txt $< > $@

maplecues.inc: maple.xm
	xm2cues/xm2cues $< > maplecues.inc

silentsong.inc: silent.xm whiskey-instruments.txt
	xm2gb --instruments-map=whiskey-instruments.txt $< > $@

gamescreentiles.bin gamescreen.nam: gamescreen.chr
	packchr --character-output=gamescreentiles.bin --nametable-output=gamescreen.nam gamescreen.chr

gamescreentilemap.bin: gamescreen.nam
	packnam --width=20 --vram-address=0x9800 --output=gamescreentilemap.bin gamescreen.nam

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
