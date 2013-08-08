#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/types.h>

int main()
{
	int sock, length;
	struct sockaddr_in name;
//	struct sockaddr name;
	char buf[1024];

	/* Create socket from which to read. */
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0) {
		perror("opening datagram socket");
		exit(1);
	}

	/* Create name with wildcards. */
	name.sin_family = AF_INET;
	name.sin_addr.s_addr = INADDR_ANY;
	name.sin_port = 0;
	if (bind(sock, (struct sockaddr *)&name, sizeof(name))) {
		perror("binding datagram socket");
		exit(1);
	}

	/* Find assigned port value and print it out. */
	length = sizeof(name);
	if (getsockname(sock, (struct sockaddr *)&name, (socklen_t *)&length)) {
		perror("getting socket name");
		exit(1);
	}
	printf("Socket has port #%d\n", ntohs(name.sin_port));

	/* Read from the socket */
	if (read(sock, buf, sizeof(buf)) < 0)
		perror("receiving datagram packet");
	printf("-->%s\n", buf);
	close(sock);
	
	return 0;
}

