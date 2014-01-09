
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include "dhcp_protocol.h"

#define TIMEOUT         10
#define MSGSIZE         10240
#define BUFSIZE         (MSGSIZE + 1)
#define SPORT           68
#define DPORT           67

#define gprintf(fmt, args...)  printf(fmt, ## args)

unsigned char mac[ETH_ALEN];

typedef struct _options {
	char *intf;
	int timeout;
} options;

struct pseudohdr {
	u_int32_t src_addr;
	u_int32_t dst_addr;
	u_int8_t padding;
	u_int8_t proto;
	u_int16_t length;
};

struct dhcp_packet {
	u_int8_t op, htype, hlen, hops;
	u_int32_t xid;
	u_int16_t secs, flags;
	struct in_addr ciaddr, yiaddr, siaddr, giaddr;
	u_int8_t chaddr[DHCP_CHADDR_MAX], sname[64], file[128];
	u_int32_t cookie;
	u_int8_t options[308];	/* magic cookie included */
};


static void usage(FILE *out)
{
	fputs("\nUsage:\n", out);
	fprintf(out, " dhcptester -i interface\n");
	fputs("\nOptions:\n", out);
	fputs("     -i <interface>     set interface\n", out);
	fputs("     -t <timeout>       set timeout\n", out);
	fputs("     -h                 display this help and exit\n", out);
	fputs("\n", out);

	exit(out == stderr ? EXIT_FAILURE : EXIT_SUCCESS);
}

/*
 * Convert Ethernet address binary data to string representation
 * @param	e	binary data
 * @param	a	string in xx:xx:xx:xx:xx:xx notation
 * @return	a
 */
static char *ether_etoa(const unsigned char *e, char *a)
{
	char *c = a;
	int i;

	for (i = 0; i < ETHER_ADDR_LEN; i++) {
		if (i)
			*c++ = ':';
		c += sprintf(c, "%02X", e[i] & 0xff);
	}
	return a;
}

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

static unsigned char getOption(unsigned char* source, unsigned char opt, unsigned char optlen, void* optvalptr)
{
	unsigned char i;

	memset(optvalptr, 0, optlen);

	for (;;) {
		/* skip pad characters */
		if(*source == OPTION_PAD)
			source++;
		else if(*source == OPTION_END)
			break;

		else if(*source == opt) {
			/* found desired option limit size to actual option length */
			optlen = (optlen - 1 < *(source+1)) ? optlen - 1 : *(source+1);

			for(i = 0; i < optlen; i++)
				*(((unsigned char*)optvalptr)+i) = *(source+i+2);

			/* return length of option */
			return *(source+1);
		}
		else {
			/* skip to next option */
			source++;
			source+=*source;
			source++;
		};
	};

	/* failed to find desired option */
	return 0;
}

static unsigned char *setOption(unsigned char *dest, int *space, char opt, char len, unsigned char *val)
{
	int i;

	if (*space < len)
		return NULL;

	if (!dest)
		return NULL;

	*dest++ = opt;
	*dest++ = len;
	for (i = 0 ; i < len ; i++)
		*dest++ = val[i];

	return dest;
}

static int dhcpSetDiscover(struct dhcp_packet *dhcp, int payloadLen, u_int32_t xid)
{
	unsigned char *s = dhcp->options;
	int space = sizeof(struct dhcp_packet);
	unsigned char value[100];

	if (payloadLen < space) {
		fprintf(stderr, "Payload length is too small!\n");
		return -1;
	}

	memset(dhcp, 0, sizeof(struct dhcp_packet));
	dhcp->op = BOOTREQUEST;
	dhcp->htype = HARDWARD_TYPE_ETH;
	dhcp->hlen = ETH_ALEN;
	dhcp->hops = 0;
	dhcp->xid = htonl(xid);
	memcpy(dhcp->chaddr, mac, ETH_ALEN);
	dhcp->cookie = htonl(DHCP_COOKIE);

	value[0] = DHCPDISCOVER;
	s = setOption(s, &space, OPTION_MESSAGE_TYPE, 1, value);

	value[0] = HARDWARD_TYPE_ETH;
	memcpy(&value[1], mac, ETH_ALEN);
	s = setOption(s, &space, OPTION_CLIENT_ID, 7, value);

	snprintf((char *)value, sizeof(value), "test client");
	s = setOption(s, &space, OPTION_VENDOR_ID, strlen((char *)value), value);

	value[0] = OPTION_NETMASK;
	value[1] = OPTION_ROUTER;
	value[2] = OPTION_DNSSERVER;
	value[3] = OPTION_HOSTNAME;
	value[4] = OPTION_DOMAINNAME;
	value[5] = OPTION_BROADCAST;
	value[6] = OPTION_NETBIOS;
	s = setOption(s, &space, OPTION_REQUESTED_OPTIONS, 7, value);
	*s++ = OPTION_END;

	return ((char *)s - (char *)dhcp);
}

// Encapsulation data with ethernet header
static int sendDHCPDiscover(int sock, char *intf, u_int32_t xid)
{
	struct sockaddr addr;		/* for interface name */
	char buffer[BUFSIZE];
	struct pseudohdr pshd;
	struct ether_header *eth = (struct ether_header *) buffer;
	struct iphdr *ip = (struct iphdr *) ((char *)eth + sizeof(struct ether_header));
	struct udphdr *udp = (struct udphdr *) ((char *)ip + sizeof(struct iphdr));
	char *payload = (char *)udp + sizeof(struct udphdr);
	int payloadLen = sizeof(buffer) - sizeof(struct ether_header) - sizeof(struct iphdr) - sizeof(struct udphdr);
	int packetSize;

	memset(buffer, 0, BUFSIZE);
	memset(&pshd, 0, sizeof(pshd));
	memset(&addr, 0, sizeof(addr));

	strcpy(addr.sa_data, intf);

	memcpy(eth->ether_shost, mac, ETH_ALEN);
	memset(eth->ether_dhost, 0xffffffff, ETH_ALEN);

	/* Init ethhdr */
	eth->ether_type = htons(ETHERTYPE_IP);

	/* Init iphdr */
	ip->ihl = 5;
	ip->version = 4;
	ip->tos = 0;
	ip->ttl = 64;
	ip->protocol = 17; // UDP
	ip->saddr = INADDR_ANY;
	ip->daddr = INADDR_BROADCAST;

	/* Init udphdr */
	udp->source = htons(SPORT);
	udp->dest = htons(DPORT);

	pshd.src_addr = ip->saddr;
	pshd.dst_addr = ip->daddr;
	pshd.proto = ip->protocol;

	payloadLen = dhcpSetDiscover((struct dhcp_packet *)payload, payloadLen, xid);

	ip->id = rand();
	packetSize = sizeof(struct iphdr) + sizeof(struct udphdr) + payloadLen;
	ip->tot_len = htons(packetSize);
	ip->check = 0;
	ip->check = in_cksum(NULL, (uint16_t *)ip, sizeof(struct iphdr));
	udp->len = htons(sizeof(struct udphdr) + payloadLen);
	pshd.length = udp->len;
	udp->check = 0;
	udp->check = in_cksum(&pshd, (uint16_t *)udp, sizeof(struct udphdr) + payloadLen);

	if(sendto(sock, buffer, sizeof(struct ether_header) + packetSize, 0, &addr, sizeof(addr)) < 0) {
		perror("sendto");
	}

	return 0;
}

static int analysePacket(int s, char *buf, int xid)
{
	struct ether_header *eptr = (struct ether_header *) &buf[0];
	struct iphdr *ip = (struct iphdr *) &buf[ETH_HLEN];
	struct dhcp_packet *dhcp = (struct dhcp_packet *) &buf[ETH_HLEN + sizeof(struct iphdr) + sizeof(struct udphdr)];
	char server_hwaddr[20];
	char options[100];

	ether_etoa(eptr->ether_shost, server_hwaddr);

	if(eptr->ether_type == htons(ETH_P_IP) && ip->protocol == IPPROTO_UDP &&
	   dhcp->xid == htonl(xid) && dhcp->op == BOOTREPLY) {			// Add chaddr compare.

		getOption(dhcp->options, OPTION_MESSAGE_TYPE, sizeof(options), options);
		if (options[0] == DHCPOFFER) {
			gprintf("\n   ***   Match DHCP Offer from %s   ***\n", server_hwaddr);
			if (getOption(dhcp->options, OPTION_SERVER_IDENTIFIER, sizeof(options), options))
				gprintf("   DHCP server IP:  %s\n", inet_ntoa(*(struct in_addr *)options));
			gprintf("   Release IP:      %s\n", inet_ntoa(dhcp->yiaddr));
			if (getOption(dhcp->options, OPTION_NETMASK, sizeof(options), options))
				gprintf("           Netmask: %s\n", inet_ntoa(*(struct in_addr *)options));
			if (getOption(dhcp->options, OPTION_ROUTER, sizeof(options), options))
				gprintf("           Getway:  %s\n", inet_ntoa(*(struct in_addr *)options));
			if (getOption(dhcp->options, OPTION_DNSSERVER, sizeof(options), options))
				gprintf("           DNS:     %s\n", inet_ntoa(*(struct in_addr *)options));
			gprintf("\n");
		}
	}

	return 0;
}

static int taskLoop(int sock, options *op)
{
	int n;
	int nbytes=0;
	struct timeval tv;    /* timed out every second */
	int MSGBUFSIZE = 1000;
	char msgbuf[MSGBUFSIZE];
	struct sockaddr_in svrAddress;
	socklen_t size = sizeof(struct sockaddr_in);
	fd_set  fds;
	time_t now, til;
	u_int32_t xid;

	mac[5]++;
	xid = rand();
	gprintf("Send DHCP Discover xid %08X\n", xid);
	sendDHCPDiscover(sock, op->intf, xid);

	time(&til);
	til += op->timeout;

	while(1)
	{
		FD_ZERO(&fds);
		/* Set select sockets */
		FD_SET(sock, &fds);
		tv.tv_sec = 1;
		tv.tv_usec = 0;
		n = select(FD_SETSIZE, &fds, (fd_set *)NULL, (fd_set *)NULL, &tv);
		if(n > 0) {
			if (FD_ISSET(sock, &fds)) {
				nbytes = recvfrom(sock, msgbuf, MSGBUFSIZE, 0, (struct sockaddr *)&svrAddress, &size);
				if(nbytes > sizeof(struct ether_header) + sizeof(struct iphdr) + sizeof(struct udphdr))
					analysePacket(sock, msgbuf, xid);
			}
		}
		time(&now);
		if(now > til)
			break;
	}
	return 0;
}

static int getSock(char *intf)
{
	int sock;
	char buffer[BUFSIZE];

	memset(buffer, 0, sizeof(buffer));

	if ((sock = socket(PF_PACKET, SOCK_PACKET, htons(ETH_P_IP))) < 0) {
		perror("socket");
		return -1;
	}

	if (setsockopt(sock, SOL_SOCKET, SO_BINDTODEVICE, intf, strlen(intf)) < 0) {
		perror("setsockopt");
		close(sock);
		return -1;
	}

	return sock;
}

/* Create a random xid and mac address */
static void randomSeed(void)
{
	int fd;
	unsigned long seed;

	fd = open("/dev/urandom", 0);
	if (fd < 0 || read(fd, &seed, sizeof(seed)) < 0) {
		seed = time(NULL);
	}
	if (fd >= 0)
		close(fd);
	srand(seed);
}

static void init(options *op)
{
	int i;

	op->intf = "eth0";
	op->timeout = TIMEOUT;

	for (i=1 ; i<6 ; i++)
		mac[i] = rand()%256;
	mac[0] = 0;
}

int main(int argc, char *argv[])
{
	int c;
	options option;
	int sock;

	init(&option);

	while( (c=getopt(argc, argv, "i:t:h")) != -1 )
	{
		switch (c)
		{
			case 'i':
				option.intf = optarg;
				break;

			case 't':
				option.timeout = atoi(optarg);
				break;

			case 'h':
				usage(stdout);
				break;

			default:
				usage(stderr);
				break;
		}
	}

	randomSeed();

	sock = getSock(option.intf);
	if (sock < 0)
		return -1;

	taskLoop(sock, &option);

	close(sock);

	return 0;
}
