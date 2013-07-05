#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

// http://www.linux.org.tw/CLDP/OLD/Serial-Programming-HOWTO-2.html

struct Speedtab {
	long speed;
	speed_t code;
};

static const struct Speedtab speedtab[] = {
	{50, B50},
	{75, B75},
	{110, B110},
	{134, B134},
	{150, B150},
	{200, B200},
	{300, B300},
	{600, B600},
	{1200, B1200},
	{1800, B1800},
	{2400, B2400},
	{4800, B4800},
	{9600, B9600},
#ifdef	B19200
	{19200, B19200},
#endif
#ifdef	B38400
	{38400, B38400},
#endif
#ifdef	EXTA
	{19200, EXTA},
#endif
#ifdef	EXTB
	{38400, EXTB},
#endif
#ifdef B57600
	{57600, B57600},
#endif
#ifdef B115200
	{115200, B115200},
#endif
#ifdef B230400
	{230400, B230400},
#endif
	{0, 0},
};

struct options {
	int timeout;		/* time-out period */
	char *tty;			/* name of tty */
//	char *term;			/* terminal type */
	char *initstring;	/* modem init string */
	speed_t speeds;		/* baud rates */
};

static void usage(FILE *out)
{
	fputs("\nUsage:\n", out);
	fprintf(out, " lilee_agetty [options] line baud_rate\n");
//	fprintf(out, " lilee_agetty [options] line baud_rate [termtype]\n");
	fputs("\nOptions:\n", out);
	fputs("     -I <string>        set init string\n", out);
	fputs("     -t <number>        login process timeout\n", out);
	fputs("     -h                 display this help and exit\n", out);

	exit(out == stderr ? EXIT_FAILURE : EXIT_SUCCESS);
}

/* Convert speed string to speed code; return 0 on failure. */
static speed_t bcode(char *s)
{
	const struct Speedtab *sp;
	long speed = atol(s);

	for (sp = speedtab; sp->speed; sp++)
		if (sp->speed == speed)
			return sp->code;
	return 0;
}

static void parse_args(int argc, char **argv, struct options *op)
{
	int c;

	while ((c = getopt(argc, argv, "I:t:Lh")) != -1) {
		switch (c) {
		case 'I':
			op->initstring = optarg;
			break;
		case 't':
			if ((op->timeout = atoi(optarg)) <= 0)
				usage(stdout);
			break;
		case 'h':
			usage(stdout);
		}
	}

	if (argc < optind + 1) {
		usage(stderr);
	}

	/* Accept "tty", "baudrate tty", and "tty baudrate". */
	if ('0' <= argv[optind][0] && argv[optind][0] <= '9') {
		/* Assume BSD style speed. */
		op->speeds = bcode(argv[optind++]);
		if (argc < optind + 1) {
			usage(stderr);
		}
		op->tty = argv[optind++];
	} else {
		op->tty = argv[optind++];
		if (argc > optind) {
			char *v = argv[optind++];
			if ('0' <= *v && *v <= '9')
				op->speeds = bcode(v);
			else
				op->speeds = bcode("9600");
		}
	}

//	if (argc > optind && argv[optind])
//		op->term = argv[optind];
}

int main(int argc, char **argv)
{
	int fd, res, count, ret = EXIT_FAILURE;
	struct termios oldtio, newtio;
	char buf[255];
	fd_set fds;
	struct timeval tv;
	struct options options = {
		.tty    = "/dev/ttyS0",
		.speeds = 0
	};

	parse_args(argc, argv, &options);

	fd = open(options.tty, O_RDWR | O_NOCTTY);
	if (fd < 0) {
		perror(options.tty);
		exit(EXIT_FAILURE);
	}

	/* Backup */
	tcgetattr(fd, &oldtio);
	bzero(&newtio, sizeof(newtio));

	/* man termios(3) */
	newtio.c_cflag = options.speeds | CRTSCTS | CS8 | CLOCAL | CREAD;
	newtio.c_iflag = IGNPAR | ICRNL;
	newtio.c_oflag = OCRNL;
	newtio.c_lflag = ICANON;

	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &newtio);

	if (options.initstring)
	{
		write(fd, "\r\n", 2);
		write(fd, options.initstring, strlen(options.initstring));
		write(fd, "\r\n", 2);
	}

	for (count = 1 ; ; count++)
	{
		FD_ZERO(&fds);
		FD_SET(fd, &fds);

        tv.tv_sec = 1;
        tv.tv_usec = 0;

		if (select(fd+1, &fds, 0, 0, &tv) == 1)
		{
			res = read(fd, buf, 255);
			buf[res]=0;
			if (strncmp(buf, "lilee", 5) == 0)
			{
				ret = EXIT_SUCCESS;
				break;
			}
		}

		if (options.timeout && count == options.timeout)
			break;
	}

	/* Restore */
	tcsetattr(fd, TCSANOW, &oldtio);

	exit(ret);
}
