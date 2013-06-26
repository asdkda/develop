/*
 *********************************************************
 *   Copyright 2003, CyberTAN  Inc.  All Rights Reserved *
 *********************************************************

 This is UNPUBLISHED PROPRIETARY SOURCE CODE of CyberTAN Inc.
 the contents of this file may not be disclosed to third parties,
 copied or duplicated in any form without the prior written
 permission of CyberTAN Inc.

 This software should be used as a reference only, and it not
 intended for production use!


 THIS SOFTWARE IS OFFERED "AS IS", AND CYBERTAN GRANTS NO WARRANTIES OF ANY
 KIND, EXPRESS OR IMPLIED, BY STATUTE, COMMUNICATION OR OTHERWISE.  CYBERTAN
 SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE

 * detect.c
 *
 *  Created on: 2011/3/3
 *      Author: Ethan
 */

#include <signal.h>
#include <sys/socket.h>
#include <linux/if_ether.h>
#include <stdio.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/time.h>
#include <netinet/udp.h>
#include <netinet/ip.h>
#include <net/ethernet.h>
//#include <shutils.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <syslog.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


//#define DEBUG

#define IF_ETH_PORT		 "eth0"
#define DHCP_OFFER	0x02
#define	DHCP_XID_LOC	46
#define IP_LEN	  sizeof(struct iphdr)
#define UDP_LEN	sizeof(struct udphdr)
#define TIMEOUT  3
unsigned char mac[6];
int count = 0;

#ifdef DEBUG
#define ad_dbg(fmt, arg...)	printf("%s: " fmt, __FUNCTION__, ## arg)
#else
#define ad_dbg(fmt, arg...)
#endif

struct dhcpMessage {
        u_int8_t op;
        u_int8_t htype;
        u_int8_t hlen;
        u_int8_t hops;
        u_int32_t xid;
        u_int16_t secs;
        u_int16_t flags;
        u_int32_t ciaddr;
        u_int32_t yiaddr;
        u_int32_t siaddr;
        u_int32_t giaddr;
        u_int8_t chaddr[16];
        u_int8_t sname[64];
        u_int8_t file[128];
        u_int32_t cookie;
        u_int8_t options[308]; /* 312 - cookie */
};

/* Create a random xid */
void random_seed(void)
{
	int fd;
	int i;
	unsigned long seed;

	fd = open("/dev/urandom", 0);
	if (fd < 0 || read(fd, &seed, sizeof(seed)) < 0) {
		seed = time(0);
	}
	if (fd >= 0) close(fd);
	srand(seed);
	
	for (i=1 ; i<6 ; i++)
		mac[i] = rand()%256;
	mac[0]=0;
}

u_int16_t checksum(void *addr, int count)
{
        /* Compute Internet Checksum for "count" bytes
         *         beginning at location "addr".
         */
        register int32_t sum = 0;
        u_int16_t *source = (u_int16_t *) addr;

        while( count > 1 )  {
                /*  This is the inner loop */
                sum += *source++;
                count -= 2;
        }

        /*  Add left-over byte, if any */
        if( count > 0 ){
                /* Make sure that the left-over byte is added correctly both
                   with little and big endian hosts */
                u_int16_t tmp = 0;
                *(unsigned char *)(&tmp) = *(unsigned char *)source;
                sum += tmp;
        }
        /*  Fold 32-bit sum to 16 bits */
        while (sum>>16)
                sum = (sum & 0xffff) + (sum >> 16);

        return ~sum;
}
/*
 * Convert Ethernet address binary data to string representation
 * @param	e	binary data
 * @param	a	string in xx:xx:xx:xx:xx:xx notation
 * @return	a
 */
char *
ether_etoa(const unsigned char *e, char *a)
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


static int
send_dhcp(int s, int auto_xid)
{
	int ret;
	struct sockaddr addr;		/* for interface name */
	unsigned char dhcp[590];
	unsigned char data1[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x45, 0x00,
				  0x02, 0x40, 0x00, 0x00, 0x00, 0x00, 0x40, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff,
				  0xff, 0xff, 0x00, 0x44, 0x00, 0x43, 0x02, 0x2c, 0x00, 0x00, 0x01, 0x01, 0x06, 0x00, 0x00, 0x00,
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x17, 0x37, 0x66, 0x29, 0x00, 0x00, 0x00, 0x00 };
	unsigned char data2[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x82, 0x53, 0x63, 0x35, 0x01, 0x01, 0x3d, 0x07, 0x01,
				  0x00, 0x12, 0x17, 0x37, 0x66, 0x29, 0x3c, 0x0b, 0x75, 0x64, 0x68, 0x63, 0x70, 0x20, 0x30, 0x2e,
				  0x39, 0x2e, 0x38, 0x37, 0x07, 0x01, 0x03, 0x06, 0x0c, 0x0f, 0x1c, 0x2c, 0xff, 0x00, 0x00, 0x00 };
	unsigned long sum=0;
	memset(&addr, 0, sizeof(addr));
	memset(&dhcp, 0, sizeof(dhcp));

	strcpy(addr.sa_data, IF_ETH_PORT);

	memcpy(&dhcp[0], data1, sizeof(data1));
	memcpy(&dhcp[272], data2, sizeof(data2));

	memcpy(&dhcp[6], mac, ETH_ALEN);	// Source
	memcpy(&dhcp[70], mac, ETH_ALEN);	// Client hardware address
	memcpy(&dhcp[288], mac, ETH_ALEN);	// Client hardware address

	ad_dbg("wan_xid= 0x%8lx\n", auto_xid);

	dhcp[DHCP_XID_LOC] = auto_xid;
	dhcp[DHCP_XID_LOC+1] = auto_xid >> (unsigned long)8;
	dhcp[DHCP_XID_LOC+2] = auto_xid >> 16;
	dhcp[DHCP_XID_LOC+3] = auto_xid >> 24;

	/* Calculate IP checksum */
	sum = checksum(&dhcp[ETH_HLEN], IP_LEN);

	dhcp[24] = sum;
	dhcp[25] = sum >> 8;

	ad_dbg("IP checksum=[%lx]\n", sum);

	/* Calculate UDP checksum */
	sum = checksum(&dhcp[ETH_HLEN+IP_LEN], sizeof(dhcp)-ETH_HLEN-IP_LEN);

	/* The UDP checksum is always zero. (Change later) */
	//dhcp[40] = sum;
	//dhcp[41] = sum >> 8;

	ad_dbg("UDP checksum=[%lx]\n", sum);

	//printHEX(dhcp, sizeof(dhcp));

	ad_dbg("Send DHCP Discover to find router/AP...\n");
	ret = sendto(s, &dhcp, sizeof(dhcp), 0, &addr, sizeof(addr));
	if(ret>0) ad_dbg("Send %d bytes\n", ret);
	//return wait_reply(s, mac, PROTO_DHCP, detect,retry_count);
	return ret;
}
//
//char *find_option(char *dhcp_option, char option, char length)
//{
//	int found = 0, end_value=0xff00;
//	char *ptr=dhcp_option;
//	
//	for (; memcmp(ptr, &end_value, 2) ; ptr++)
//	{
//		if (memcmp(ptr, &option, 1) && memcmp((ptr+1), &length, 1))
//		{
//			found = 1;
//			break;
//		}
//	}
//	
//	printf("found=%d\n", found);
//	if(found)
//		return ptr;
//	else
//		return "";
//}

static int
send_request(int s, char *buf, int auto_xid)
{
	int ret;
	struct sockaddr addr;		/* for interface name */
	struct dhcpMessage *dhcpptr = (struct dhcpMessage *) &buf[ETH_HLEN+IP_LEN+UDP_LEN];
	unsigned char dhcp[590];
	unsigned char data1[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x45, 0x00,
				  0x02, 0x40, 0x00, 0x00, 0x00, 0x00, 0x40, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff,
				  0xff, 0xff, 0x00, 0x44, 0x00, 0x43, 0x02, 0x2c, 0x00, 0x00, 0x01, 0x01, 0x06, 0x00, 0x00, 0x00,
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x17, 0x37, 0x66, 0x29, 0x00, 0x00, 0x00, 0x00 };
	unsigned char data2[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x82, 0x53, 0x63,/*dhcp message type*/ 0x35, 0x01, 0x03 };
	unsigned char data3[] = { /*Client identifier*/0x3d, 0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
							  /*Requested IP*/0x32, 0x04, 0x00, 0x00, 0x00, 0x00,
							  /*Server identifier 192.168.1.1*/0x36, 0x04, 0xc0, 0xa8, 0x01, 0x01,
							  /*Host name(Client01, length=8)*/0x0c, 0x08, 0x43, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x30, 0x31,
							  /*Vendor class identifier*/0x3c, 0x0b, 0x75, 0x64, 0x68, 0x63, 0x70, 0x20, 0x30, 0x2e, 0x39, 0x2e, 0x38,
							  /*Parameter request list*/ 0x37, 0x07, 0x01, 0x03, 0x06, 0x0c, 0x0f, 0x1c, 0x2c,/*End*/ 0xff };
	unsigned long sum=0;
	char hostname[] = "Client01";
	
	memset(&addr, 0, sizeof(addr));
	memset(&dhcp, 0, sizeof(dhcp));

	strcpy(addr.sa_data, IF_ETH_PORT);

	memcpy(&dhcp[0], data1, sizeof(data1));
	memcpy(&dhcp[272], data2, sizeof(data2));
	memcpy(&dhcp[285], data3, sizeof(data3));

	memcpy(&dhcp[6], mac, ETH_ALEN);	// Source
	memcpy(&dhcp[70], mac, ETH_ALEN);	// Client hardware address
	memcpy(&dhcp[288], mac, ETH_ALEN);	// Client hardware address
	memcpy(&dhcp[296], &(dhcpptr->yiaddr), 4);	// Requested IP
	sprintf(hostname, "%s%02d", "Client", count);
	memcpy(&dhcp[308], hostname, 8);	// Host name

	ad_dbg("wan_xid= 0x%8lx\n", auto_xid);

	dhcp[DHCP_XID_LOC] = auto_xid;
	dhcp[DHCP_XID_LOC+1] = auto_xid >> (unsigned long)8;
	dhcp[DHCP_XID_LOC+2] = auto_xid >> 16;
	dhcp[DHCP_XID_LOC+3] = auto_xid >> 24;

	/* Calculate IP checksum */
	sum = checksum(&dhcp[ETH_HLEN], IP_LEN);

	dhcp[24] = sum;
	dhcp[25] = sum >> 8;

	ad_dbg("IP checksum=[%lx]\n", sum);

	/* Calculate UDP checksum */
	sum = checksum(&dhcp[ETH_HLEN+IP_LEN], sizeof(dhcp)-ETH_HLEN-IP_LEN);

	/* The UDP checksum is always zero. (Change later) */
	//dhcp[40] = sum;
	//dhcp[41] = sum >> 8;

	ad_dbg("UDP checksum=[%lx]\n", sum);

	//printHEX(dhcp, sizeof(dhcp));

	ad_dbg("Send DHCP Request to found router/AP...\n");
	ret = sendto(s, &dhcp, sizeof(dhcp), 0, &addr, sizeof(addr));
	if(ret>0) ad_dbg("Send %d bytes\n", ret);
	//return wait_reply(s, mac, PROTO_DHCP, detect,retry_count);
	return ret;
}

static
int analyse_packet(int s, char *buf, int auto_xid)
{
	struct ether_header *eptr = (struct ether_header *) &buf[0];
	struct iphdr *ip = (struct iphdr *) &buf[ETH_HLEN];
	struct dhcpMessage *dhcp = (struct dhcpMessage *) &buf[ETH_HLEN+IP_LEN+UDP_LEN];
	char server_hwaddr[20];

	ether_etoa(eptr->ether_shost, server_hwaddr);

	if(eptr->ether_type == htons(ETH_P_IP) &&
			ip->protocol == IPPROTO_UDP &&
			dhcp->xid == auto_xid &&
			dhcp->op == DHCP_OFFER) {			// Add chaddr compare.

		ad_dbg("\n\n   ***   Match DHCP Offer from %s   ***\n\n", server_hwaddr);
		send_request(s, buf, auto_xid);

		return 1;
	}

	return 0;
}

int check_dhcp(void)
{
	int sendsock, n;
	int nbytes=0;
	struct timeval tv;    /* timed out every second */
	int MSGBUFSIZE = 1000;
	char msgbuf[MSGBUFSIZE];
	struct sockaddr_in svrAddress;
	socklen_t size = sizeof(struct sockaddr_in);
	unsigned long int auto_xid;
	fd_set  fds;
	time_t now, til;

	if ((sendsock = socket(PF_PACKET, SOCK_PACKET, htons(ETH_P_IP))) == -1)
	{
		perror("socket");
		exit(1);
	}

	/* Create xid */
	auto_xid = rand();
	ad_dbg("wan_xid= 0x%8lx\n", auto_xid);
	
	mac[5]++;

	send_dhcp(sendsock, auto_xid);
	time(&til);
	til += TIMEOUT;

	while(1)
	{
		FD_ZERO(&fds);
		/* Set select sockets */
		FD_SET(sendsock, &fds);
		tv.tv_sec = 1;
		tv.tv_usec = 0;
		n = select(FD_SETSIZE, &fds, (fd_set *)NULL, (fd_set *)NULL, &tv);
		if(n > 0)
		{
			if (FD_ISSET(sendsock, &fds)) {
				nbytes = recvfrom(sendsock, msgbuf, MSGBUFSIZE, 0, (struct sockaddr *)&svrAddress, &size);
				if(nbytes > (ETH_HLEN+IP_LEN+UDP_LEN))
					if(analyse_packet(sendsock, msgbuf, auto_xid))
					{
						close(sendsock);
						return 1;
					}
			}
		}
		time(&now);
		if(now > til)
			break;
	}
	close(sendsock);
	return 0;
}

int main (int argc, char **argv)
{
	int i, ret, number = 3;
	random_seed();
	
	if (argc > 1)
		number = atoi(argv[1]);
	
	if (number >= 100)
		number = 99;
	else if (number <= 0)
		number = 1;
	
	for (i=0 ; i<number ; i++)
	{
		count++;
		ret = check_dhcp();
		if (ret)
			printf("Client %2d, Get DHCP successfully!\n", count);
		else
			printf("Client %2d, FAIL\n", count);
		sleep(1);
	}

	return 0;
}

//int main()
//{
//#if 0
//	struct itimerval tick;
//
//	signal(SIGALRM, check_cable_dhcp);
//
//	memset(&tick, 0, sizeof(tick));
//	tick.it_value.tv_sec = 1;  // sec
//	tick.it_value.tv_usec = 0; // micro sec.
//	tick.it_interval.tv_sec = 5;
//	tick.it_interval.tv_usec = 0;
//	setitimer(ITIMER_REAL, &tick, NULL);
//#endif
//
//}

