CC = wla-z80
CFLAGS = -o
LD = wlalink
LDFLAGS = -S

OFILES = main.o
OUT = DoubleDragonII.sms

$(OUT): $(OFILES) Makefile linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

main.o: main.s ball.bin flag.bin font.bin song.s song.inc
	$(CC) $(CFLAGS) $@ $<

song.inc: song.xm instruments.txt
	xm2gb --channels=0,1,2,3,4,5,6,7,8,9,10,11,12 --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm -f $(OFILES) *~ *.sym $(OUT)
