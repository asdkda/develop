#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{
	/* 即要解析的域名或主机名 */
	char ptr[100] = "ipv6.ntp.mattnordhoff.com", **pptr;
	struct hostent *hptr;
	char str[32];

	///////////////
	struct addrinfo hints, *res;
	int errcode;
	int family = AF_INET;
	char addrstr[100];
	struct in6_addr *ptr6;

	memset (&hints, 0, sizeof (hints));
	hints.ai_family = AF_INET; // query IPv4 DNS information
	hints.ai_flags = AI_CANONNAME;

	errcode = getaddrinfo (ptr, NULL, &hints, &res);
	if (errcode != 0)
	{
		memset (&hints, 0, sizeof (hints));
		hints.ai_family = AF_INET6; // query IPv6 DNS information
		hints.ai_flags = AI_CANONNAME;

		errcode = getaddrinfo (ptr, NULL, &hints, &res);
		if (errcode != 0)
		{
			printf("Unknown host\n");
			return -1;
		}
	}

	printf("getaddrinfo:\n");
	struct addrinfo *pf = res;
	while (pf)
	{
		if(pf->ai_family == AF_INET6)
		{
			family = AF_INET6;
			/* Fix E2500-137, ping tool and trace tool does not work with URL */
			ptr6 = &((struct sockaddr_in6 *) res->ai_addr)->sin6_addr;
			inet_ntop (res->ai_family, ptr6, addrstr, sizeof(addrstr));
			fprintf (stderr, "IPv6 address: %s (%s)\n", addrstr, res->ai_canonname);
			break;
		}
		pf = pf->ai_next;
	}
	freeaddrinfo(res); // no longer needed
	/////////////////////////
	printf("\n\n");
	printf("gethostbyname2:\n");
	/* 调用gethostbyname2()。调用结果都存在hptr中 */
	if( (hptr = gethostbyname2(ptr, family) ) == NULL )
	{
		printf("gethostbyname error for host:%s\n", ptr);
		return 0; /* 如果调用gethostbyname发生错误，返回1 */
	}
	/* 将主机的规范名打出来 */
	printf("official hostname:%s\n",hptr->h_name);
	/* 主机可能有多个别名，将所有别名分别打出来 */
	for(pptr = hptr->h_aliases; *pptr != NULL; pptr++)
		printf("  alias:%s\n",*pptr);
	/* 根据地址类型，将地址打出来 */
	switch(hptr->h_addrtype)
	{
	case AF_INET:
	case AF_INET6:
		pptr=hptr->h_addr_list;
		/* 将刚才得到的所有地址都打出来。其中调用了inet_ntop()函数 */
		for(;*pptr!=NULL;pptr++)
			printf("  address:%s\n", inet_ntop(hptr->h_addrtype, *pptr, str, sizeof(str)));
		break;
	default:
		printf("unknown address type\n");
		break;
	}
	return 0;
}

