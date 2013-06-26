#include <sys/ioctl.h>
#include <sys/file.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "string.h"
#include <sys/stat.h>
#include <errno.h>

char *fifo_name;

const char *get_fifo()
{
	char *name;

	int res;

	if (fifo_name) {
		if (0 == access(fifo_name, R_OK | W_OK))
			return fifo_name;
		unlink(fifo_name);
		fifo_name = NULL;
	}

	do {
		static char template[] = "/tmp/klish.fifo.XXXXXX";
		if (mkstemp(template) <= 0)
			return NULL;
		else
			unlink(template);
		res = mkfifo(template, 0600);
		if (res == 0)
			fifo_name = template;
	} while ((res < 0) && (EEXIST == errno));

	return fifo_name;
}

int main (int argc, char **argv)
{
	struct winsize w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);

	printf ("lines %d\n", w.ws_row);
	printf ("columns %d\n", w.ws_col);

	get_fifo();
	printf("%s\n", fifo_name);
	unlink(fifo_name);

	return 0;  // make sure your main returns int
}

