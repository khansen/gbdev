PROGRAM = AFewKnightsInGerudoValley

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -t -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s song.s song.inc hardware.inc font.bin ball.bin
	rgbasm -h -L -o $(PROGRAM).o main.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
