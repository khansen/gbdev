INSTALL = install
CFLAGS = -Wall -g
LFLAGS =
OBJS = xm2cues.o xm.o main.o

prefix = /usr/local
datarootdir = $(prefix)/share
datadir = $(datarootdir)
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
infodir = $(datarootdir)/info
mandir = $(datarootdir)/man
docbookxsldir = /sw/share/xml/xsl/docbook-xsl

xm2cues: $(OBJS)
	$(CC) $(LFLAGS) $(OBJS) -o xm2cues

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

install: xm2cues
	$(INSTALL) -m 0755 xm2cues $(bindir)

clean:
	rm -f $(OBJS) xm2cues xm2cues.exe

.PHONY: clean install
