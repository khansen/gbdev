.DELETE_ON_ERROR:

PROGRAM = SaveYourKissesForTheOleRubberDuck

$(PROGRAM).gb: $(PROGRAM).o
	rgblink -n $(PROGRAM).sym -m $(PROGRAM).map -o $(PROGRAM).gb $(PROGRAM).o
	rgbfix -v -p 0xFF $(PROGRAM).gb

$(PROGRAM).o: main.s song.s song.inc hardware.inc font.bin ball.bin
	rgbasm -o $(PROGRAM).o main.s

song.inc: SONG.XM instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).sym $(PROGRAM).map $(PROGRAM).gb
