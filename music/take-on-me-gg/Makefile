CC = wla-z80
CFLAGS = -o
LD = wlalink
LDFLAGS = -S

OFILES = main.o
OUT = TakeOnMe.gg

$(OUT): $(OFILES) Makefile linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

main.o: main.s ball.bin flag.bin font.bin cloud.bin angel.bin star.bin heart.bin song.s song.inc
	$(CC) $(CFLAGS) $@ $<

song.inc: song.xm instruments.txt
	xm2gb --instruments-map=instruments.txt $< > $@

.PHONY: clean

clean:
	rm -f $(OFILES) *~ *.sym $(OUT)
