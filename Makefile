CC=m68k-amigaos-gcc
LINK=m68k-amigaos-gcc
ASS=vasmm68k_mot
VLINK=vlink
STRIP=m68k-amigaos-strip

CFLAGS = -noixemul -O3 --std=c99
LFLAGS = -noixemul

# Allow instructions to be emitted in runtime detection cases
AFLAGS = -Fhunk -m68030 -linedebug -chklabels -align -L listing.txt
AFLAGS += -I../../../../amiga/m68k-amigaos/ndk-include

VFLAGS = -b amigahunk -sc -l amiga -L m68k-amigaos/ndk/lib/libs

OBJS = main.o \
	   c2p.o \
	   c2p1x1_8_c5_030_2.o
akiko: c2p.o
	$(VLINK) $(VFLAGS) $< -o $@

akiko:	${OBJS}
	$(LINK) $(LFLAGS) $^ -o $@


clean:
	rm -f *.o
	rm -f ${OBJS}

c/%.o: %.s Makefile
	$(ASS) $(AFLAGS) $< -o $@

%.o: %.s Makefile
	$(ASS) $(AFLAGS) $< -o $@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

