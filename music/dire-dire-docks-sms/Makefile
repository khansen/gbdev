CC = wla-z80
CFLAGS = -o
LD = wlalink
LDFLAGS = -S

CHRS = ball.bin flag.bin font.bin scenery.bin fish.bin blooper.bin
OFILES = main.o
OUT = DireDireDocks.sms

$(OUT): $(OFILES) Makefile linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

main.o: main.s $(CHRS) song.s song.inc
	$(CC) $(CFLAGS) $@ $<

song.inc: song.xm instruments.txt
	xm2gb --channels=0,1,2,3,4,5,6,7,8,9,10,11,12 --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm -f $(OFILES) *~ *.sym $(OUT)
