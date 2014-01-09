
#define BOOTREQUEST              1
#define BOOTREPLY                2
#define DHCP_COOKIE              0x63825363

#define OPTION_PAD               0
#define OPTION_NETMASK           1
#define OPTION_ROUTER            3
#define OPTION_DNSSERVER         6
#define OPTION_HOSTNAME          12
#define OPTION_DOMAINNAME        15
#define OPTION_BROADCAST         28
#define OPTION_VENDOR_CLASS_OPT  43
#define OPTION_NETBIOS           44
#define OPTION_REQUESTED_IP      50
#define OPTION_LEASE_TIME        51
#define OPTION_OVERLOAD          52
#define OPTION_MESSAGE_TYPE      53
#define OPTION_SERVER_IDENTIFIER 54
#define OPTION_REQUESTED_OPTIONS 55
#define OPTION_MESSAGE           56
#define OPTION_MAXMESSAGE        57
#define OPTION_VENDOR_ID         60
#define OPTION_CLIENT_ID         61
#define OPTION_ARCH              93
#define OPTION_PXE_UUID          97
#define OPTION_SUBNET_SELECT     118
#define OPTION_DOMAIN_SEARCH     119
#define OPTION_END               255

#define DHCPDISCOVER             1
#define DHCPOFFER                2
#define DHCPREQUEST              3
#define DHCPDECLINE              4
#define DHCPACK                  5
#define DHCPNAK                  6
#define DHCPRELEASE              7
#define DHCPINFORM               8

#define HARDWARD_TYPE_ETH        1

#define DHCP_CHADDR_MAX 16

//struct dhcp_packet {
//	u_int8_t op, htype, hlen, hops;
//	u_int32_t xid;
//	u_int16_t secs, flags;
//	struct in_addr ciaddr, yiaddr, siaddr, giaddr;
//	u_int8_t chaddr[DHCP_CHADDR_MAX], sname[64], file[128];
//	u_int32_t xid;
//	u_int8_t options[312];
//};
