.DELETE_ON_ERROR:

CC = wla-gb
CFLAGS = -o
LD = wlalink
LDFLAGS = -S

PROGRAM = LiveAndLearn

$(PROGRAM).gb: $(PROGRAM).o
	$(LD) $(LDFLAGS) linkfile $@

$(PROGRAM).o: main.s song.s song.inc hardware.inc ball.bin flag.bin font.bin
	$(CC) $(CFLAGS) $@ main.s

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm $(PROGRAM).o $(PROGRAM).gb
