.DELETE_ON_ERROR:

PROGRAM = Duel

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s duelsong.s duelsong.inc drawsong.s drawsong.inc drewsong.s drewsong.inc shootsong.s shootsong.inc youwinsong.s youdiesong.inc youwinsong.s youwinsong.inc silentsong.s silentsong.inc hardware.inc
	rgbasm -o $(PROGRAM).o main.s

duelsong.inc: duel.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

drawsong.inc: draw.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

drewsong.inc: drew.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

shootsong.inc: shoot.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

youdiesong.inc: youdie.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

youwinsong.inc: youwin.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

silentsong.inc: silent.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
