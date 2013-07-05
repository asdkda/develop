
sources = main.c interface.c
CFLAGS = -Wall

all : out

out: $(sources:.c=.o)
	$(CC) -o out $(sources:.c=.o)

%.depend: %.c
	@$(CC) $(CFLAGS) -M $< > $@

-include $(sources:%.c=%.depend)

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean :
	rm -f out *.o *.depend
