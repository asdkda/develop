#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>


#define RESPONSE_BUFFER_LEN 1024
#define SSDP_MULTICAST      "239.255.255.250"
#define SSDP_PORT           1900

int main (int argc, const char * argv[])
{
	int sock;
	size_t ret;
	unsigned int socklen;
	struct sockaddr_in sockname;
	struct sockaddr clientsock;
	struct hostent *hostname;
	char data[] =
			"M-SEARCH * HTTP/1.1\r\n"
			"Host: 239.255.255.250:1900\r\n"
			"Man: \"ssdp:discover\"\r\n"
			"ST:upnp:rootdevice\r\n"
			"MX:3\r\n"
			"\r\n";
	char buffer[RESPONSE_BUFFER_LEN];
	unsigned int len = RESPONSE_BUFFER_LEN;
	fd_set fds;
	struct timeval timeout;

	hostname = gethostbyname(SSDP_MULTICAST);
	hostname->h_addrtype = AF_INET;

	if((sock = socket(PF_INET, SOCK_DGRAM, 0)) == -1){
		perror("socket()");
		return -1;
	}

	memset((char*)&sockname, 0, sizeof(struct sockaddr_in));
	sockname.sin_family=AF_INET;
	sockname.sin_port=htons(SSDP_PORT);
	sockname.sin_addr.s_addr=*((unsigned long*)(hostname->h_addr_list[0]));

	ret=sendto(sock, data, strlen(data), 0, (struct sockaddr*) &sockname,
			sizeof(struct sockaddr_in));
	if(ret != strlen(data)){
		perror("sendto");
		return -1;
	}

	/* Get response */
	FD_ZERO(&fds);
	FD_SET(sock, &fds);
	timeout.tv_sec=10;
	timeout.tv_usec=10;

	if(select(sock+1, &fds, NULL, NULL, &timeout) < 0){
		perror("select");
		close(sock);
		return -1;
	}
	if(FD_ISSET(sock, &fds)){
		socklen=sizeof(clientsock);
		if((len = recvfrom(sock, buffer, len, MSG_PEEK,
				&clientsock, &socklen)) == (size_t)-1){
			perror("recvfrom");
			close(sock);
			return -1;
		}
		buffer[len]='\0';
		close(sock);

		/* Check the HTTP response code */
		if(strncmp(buffer, "HTTP/1.1 200 OK", 12) != 0){
			printf("err: ssdp parsing\n");
			return -1;
		}

		printf(buffer);
		return 0;
	}else{
		printf("err: no ssdp answer\n");
		close(sock);
		return -1;
	}
}
