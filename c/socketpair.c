#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>

#define DATA1 "Data from child"
#define DATA2 "Data from parent"

/*
 * This program creates a pair of connected sockets, 
 * then forks and communicates over them. While this
 * is very similar to communication with pipes, socketpairs
 * are two-way communications objects. Therefore, I can
 * send messages in both directions.
 */

int main()
{
	int sockets[2], childpid;
	char buf[1024];

	if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockets) < 0) {
		perror("opening stream socket pair");
		exit(1);
	}

	if ((childpid = fork()) == -1)
		perror("fork");
	else if (childpid) {       /* This is the parent. */
		close(sockets[0]);
		if (read(sockets[1], buf, sizeof(buf)) < 0)
			perror("reading stream message");
		printf("-->%s\n", buf);
		if (write(sockets[1], DATA2, sizeof(DATA2)) < 0)
			perror("writing stream message");
		close(sockets[1]);
	} else {                /* This is the child. */
		close(sockets[1]);
		if (write(sockets[0], DATA1, sizeof(DATA1)) < 0)
			perror("writing stream message");
		if (read(sockets[0], buf, sizeof(buf)) < 0) 
			perror("reading stream message");
		printf("-->%s\n", buf);
		close(sockets[0]);
	}
	return 0;
}
