CC = wla-gb
CFLAGS = -o
LD = wlalink
LDFLAGS = -S

PROGRAM = RisaFuranku420

$(PROGRAM).gb: $(PROGRAM).o
	$(LD) $(LDFLAGS) linkfile $@

$(PROGRAM).o: main.s song.s song.inc hardware.inc ball.bin flag.bin font.bin bust.bin katakana.bin
	$(CC) $(CFLAGS) $@ main.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).gb $(PROGRAM).sym
