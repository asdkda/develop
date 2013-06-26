

all: test.c test2.c
	#gcc test.c -Wall -o test
	gcc test2.c -Wall -o test2

test.c test.h: test.l
	#flex test.l

test2.c test2.h: test2.l
	flex test2.l

clean:
	rm -f *.c *.h test test2





