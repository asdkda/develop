
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>

#define DEFAULT_IF      "p3p1"
#define MSGSIZE         10240
#define BUFSIZE         (MSGSIZE + 1)
#define SOURCEIP        "192.168.1.50"
#define DESTIP          "192.168.1.1"
#define SPORT           1234
#define DPORT           4321

#define MY_DEST_MAC0    0x01
#define MY_DEST_MAC1    0x02
#define MY_DEST_MAC2    0x03
#define MY_DEST_MAC3    0x04
#define MY_DEST_MAC4    0x05
#define MY_DEST_MAC5    0x06

struct pseudohdr {
	u_int32_t src_addr;
	u_int32_t dst_addr;
	u_int8_t padding;
	u_int8_t proto;
	u_int16_t length;
};

/*
 * in_cksum --
 * Checksum routine for Internet Protocol
 */
static uint16_t in_cksum(struct pseudohdr *pshd, uint16_t *addr, int len)
{
	uint32_t sum = 0;
	uint16_t *w = addr;
	/*
	 * Our algorithm is simple, using a 32 bit accumulator (sum), we add
	 * sequential 16 bit words to it, and at the end, fold back all the
	 * carry bits from the top 16 bits into the lower 16 bits.
	 */
	if (pshd) {
		sum += pshd->src_addr;
		/* keep carry */
		sum += *(uint16_t *) &pshd->dst_addr;
		sum += *((uint16_t *) &pshd->dst_addr + 1);
		sum += *(uint32_t *) &(pshd->padding);
//		sum += (pshd->proto << 16) + pshd->length;
	}
	while (len > 1) {
		sum += *w++;
		len -= 2;
	}
	/* mop up an odd byte, if necessary */
	if (len)
		sum += (uint16_t)*(uint8_t *) w;

	sum = (sum >> 16) + (sum & 0xffff);
	/* add back carry outs from top 16 bits to low 16 bits */
	sum += (sum >> 16);
	return ~sum;
}

static int get_stdin_input(char *buf, int len)
{
	int n;

	if ((n = read(STDIN_FILENO, buf, len)) <= 0) {
		perror("read");
		return n;
	}
	// Remove \n
	buf[--n] = 0;

	return n;
}

static int bind_device(int sock)
{
	/* Bind the socket to one network device */
	if (setsockopt(sock, SOL_SOCKET, SO_BINDTODEVICE, DEFAULT_IF, sizeof(DEFAULT_IF)) < 0) {
		perror("setsockopt");
		return -1;
	}

	return 0;
}

// Encapsulation data with ethernet header
static int udpEthIPSendto(struct sockaddr_in *to)
{
	int sock;
	struct ifreq ifreq;
	struct sockaddr_ll socket_address;
	int len;
	char buffer[BUFSIZE];
	struct pseudohdr pshd;
	struct ether_header *eth = (struct ether_header *) buffer;
	struct iphdr *ip = (struct iphdr *) ((char *)eth + sizeof(struct ether_header));
	struct udphdr *udp = (struct udphdr *) ((char *)ip + sizeof(struct iphdr));
	char *payload = (char *)udp + sizeof(struct udphdr);
	int payloadLen = sizeof(buffer) - sizeof(struct ether_header) - sizeof(struct iphdr) - sizeof(struct udphdr);

	memset(buffer, 0, BUFSIZE);
	memset(&pshd, 0, sizeof(pshd));

	/* Open RAW socket to send on */
	if ((sock = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) < 0) {
		perror("socket");
		return EXIT_FAILURE;
	}

	/* Get the index of the interface to send on */
	memset(&ifreq, 0, sizeof(struct ifreq));
	snprintf(ifreq.ifr_name, IFNAMSIZ, DEFAULT_IF);
	if (ioctl(sock, SIOCGIFHWADDR, &ifreq) < 0) {
		perror("SIOCGIFHWADDR");
		close(sock);
		return EXIT_FAILURE;
	}
	memcpy(eth->ether_shost, ifreq.ifr_hwaddr.sa_data, ETH_ALEN);
	eth->ether_dhost[0] = MY_DEST_MAC0;
	eth->ether_dhost[1] = MY_DEST_MAC1;
	eth->ether_dhost[2] = MY_DEST_MAC2;
	eth->ether_dhost[3] = MY_DEST_MAC3;
	eth->ether_dhost[4] = MY_DEST_MAC4;
	eth->ether_dhost[5] = MY_DEST_MAC5;

	/* Get the MAC address of the interface to send on */
	memset(&ifreq, 0, sizeof(struct ifreq));
	snprintf(ifreq.ifr_name, IFNAMSIZ, DEFAULT_IF);
	if (ioctl(sock, SIOCGIFINDEX, &ifreq) < 0) {
		perror("SIOCGIFINDEX");
		close(sock);
		return EXIT_FAILURE;
	}
	/* Index of the network device */
	socket_address.sll_ifindex = ifreq.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MY_DEST_MAC0;
	socket_address.sll_addr[1] = MY_DEST_MAC1;
	socket_address.sll_addr[2] = MY_DEST_MAC2;
	socket_address.sll_addr[3] = MY_DEST_MAC3;
	socket_address.sll_addr[4] = MY_DEST_MAC4;
	socket_address.sll_addr[5] = MY_DEST_MAC5;

	/* Init ethhdr */
	eth->ether_type = htons(ETHERTYPE_IP);

	/* Init iphdr */
	ip->ihl = 5;
	ip->version = 4;
	ip->tos = 0;
	ip->ttl = 64;
	ip->protocol = 17; // UDP
	ip->saddr = inet_addr(DESTIP);
	ip->daddr = to->sin_addr.s_addr;

	/* Init udphdr */
	udp->source = htons(SPORT);
	udp->dest = to->sin_port;

	pshd.src_addr = ip->saddr;
	pshd.dst_addr = ip->daddr;
	pshd.proto = ip->protocol;

	while (1) {
		if ((len = get_stdin_input(payload, payloadLen)) < 0)
			break;

		if (strcmp(payload, "quit") == 0)
			break;

		ip->id = random();
		ip->tot_len = sizeof(struct iphdr) + sizeof(struct udphdr) + len;
		ip->check = 0;
		ip->check = in_cksum(NULL, (uint16_t *)ip, sizeof(struct iphdr));
		udp->len = htons(sizeof(struct udphdr) + len);
		pshd.length = udp->len;
		udp->check = 0;
		udp->check = in_cksum(&pshd, (uint16_t *)udp, sizeof(struct udphdr) + len);

		if(sendto(sock, buffer, sizeof(struct ether_header) + ip->tot_len, 0, (struct sockaddr *)&socket_address, sizeof(struct sockaddr_ll)) < 0) {
			perror("send");
			break;
		}
		printf("Send: %s\n", payload);
	}

	close(sock);

	return 0;
}

// Encapsulation data without ethernet header
static int udpIPSendto(struct sockaddr_in *to)
{
	int sock;
	int on = 1;
	int len;
	char buffer[BUFSIZE];
	struct pseudohdr pshd;
	struct iphdr *ip = (struct iphdr *) buffer;
	struct udphdr *udp = (struct udphdr *) ((char *)ip + sizeof(struct iphdr));
	char *payload = (char *)udp + sizeof(struct udphdr);
	int payloadLen = sizeof(buffer) - sizeof(struct iphdr) - sizeof(struct udphdr);

	memset(buffer, 0, BUFSIZE);
	memset(&pshd, 0, sizeof(pshd));

	if ((sock = socket(AF_INET, SOCK_RAW, SOCK_DGRAM)) < 0) {
		perror("socket");
		return EXIT_FAILURE;
	}

	if (setsockopt(sock, IPPROTO_IP, IP_HDRINCL, &on, sizeof(on)) < 0) {
		perror("setsockopt");
		close(sock);
		return EXIT_FAILURE;
	}

	if (bind_device(sock) < 0)
	{
		close(sock);
		return EXIT_FAILURE;
	}

	/* Init iphdr */
	ip->ihl = 5;
	ip->version = 4;
	ip->tos = 0;
	ip->ttl = 64;
	ip->protocol = 17; // UDP
	ip->saddr = inet_addr(DESTIP);
	ip->daddr = to->sin_addr.s_addr;

	/* Init udphdr */
	udp->source = htons(SPORT);
	udp->dest = to->sin_port;

	pshd.src_addr = ip->saddr;
	pshd.dst_addr = ip->daddr;
	pshd.proto = ip->protocol;

	while (1) {
		if ((len = get_stdin_input(payload, payloadLen)) < 0)
			break;

		if (strcmp(payload, "quit") == 0)
			break;

		ip->id = random();
		ip->tot_len = sizeof(struct iphdr) + sizeof(struct udphdr) + len;
		ip->check = 0;
		ip->check = in_cksum(NULL, (uint16_t *)ip, sizeof(struct iphdr));
		udp->len = htons(sizeof(struct udphdr) + len);
		pshd.length = udp->len;
		udp->check = 0;
		udp->check = in_cksum(&pshd, (uint16_t *)udp, sizeof(struct udphdr) + len);

		if(sendto(sock, buffer, ip->tot_len, 0, (struct sockaddr *)to, sizeof(struct sockaddr_in)) < 0) {
			perror("send");
			break;
		}
		printf("Send: %s\n", payload);
	}

	close(sock);

	return 0;
}

static int udpSendto(struct sockaddr_in *to)
{
	int sock, len;
	char buffer[BUFSIZE];

	memset(buffer, 0, sizeof(buffer));

	if((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("socket");
		return EXIT_FAILURE;
	}

	if (bind_device(sock) < 0)
	{
		close(sock);
		return EXIT_FAILURE;
	}

	while (1) {
		if ((len = get_stdin_input(buffer, sizeof(buffer))) < 0)
			break;

		if (strcmp(buffer, "quit") == 0)
			break;

		sendto(sock, buffer, len, 0, (struct sockaddr *)to, sizeof(struct sockaddr_in));
		printf("Send: %s\n", buffer);
	}

	close(sock);

	return 0;
}

int main(int argc, char *argv[])
{
	struct sockaddr_in to;

	srand(time(NULL));

	bzero(&to, sizeof(to));
	to.sin_family = AF_INET;
	to.sin_port = htons(DPORT);
	to.sin_addr.s_addr = inet_addr(SOURCEIP);

	udpEthIPSendto(&to);
	udpIPSendto(&to);
	udpSendto(&to);

	return 0;
}
