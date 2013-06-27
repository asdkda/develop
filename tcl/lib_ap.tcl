
proc config_ap {profile ssid ip} {
	# gateway will be X.Y.Z.1
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]1

	config_command "create wifi-profile $profile"
	config_command "config wifi-profile $profile ssid $ssid"
	config_command "config wifi-profile $profile authentication key-management wpa-psk"
	config_command "config wifi-profile $profile authentication wpa-psk ascii 1111111111"
	config_command "config add interface wlan 0 ap"
	config_command "config interface wlan 0 ip address $ip netmask 255.255.255.128"
	config_command "config interface wlan 0 channel 8"
	config_command "config interface wlan 0 profile $profile"
	config_command "config interface wlan 0 enable"

	config_command "config interface eth 0 ip proxy-arp enable"
	config_command "config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Set AP config"
}

proc no_config_ap {profile ssid ip} {
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]1

	config_command "no create wifi-profile $profile"
	config_command "no config interface wlan 0 ip address $ip netmask 255.255.255.128"
	config_command "no config interface wlan 0 channel 8"
	config_command "no config interface wlan 0 profile $profile"
	config_command "no config interface wlan 0 enable"
	config_command "no config add interface wlan 0 ap"

	config_command "no config interface eth 0 ip proxy-arp enable"
	config_command "no config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Clear AP config"
}

proc config_client {profile ssid ip} {
	# gateway will be X.Y.Z.150
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]150

	config_command "create wifi-profile $profile"
	config_command "config wifi-profile $profile ssid $ssid"
	config_command "config wifi-profile $profile authentication key-management wpa-psk"
	config_command "config wifi-profile $profile authentication wpa-psk ascii 1111111111"
	config_command "config add interface wlan 0 sta"
	config_command "config interface wlan 0 ip address $ip netmask 255.255.255.128"
	config_command "config interface wlan 0 channel 8"
	config_command "config interface wlan 0 profile $profile"
	config_command "config interface wlan 0 enable"

	config_command "config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Set AP client config"
}

proc no_config_client {profile ssid ip} {
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]150

	config_command "no create wifi-profile $profile"
	config_command "no config interface wlan 0 ip address $ip netmask 255.255.255.128"
	config_command "no config interface wlan 0 channel 8"
	config_command "no config interface wlan 0 profile $profile"
	config_command "no config interface wlan 0 enable"
	config_command "no config add interface wlan 0 ap"

	config_command "no config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Clear AP client config"
}

proc my_config_ap {profile ssid ip} {
	# gateway will be X.Y.Z.1
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]1

	config_command "create wifi-profile $profile"
	config_command "config wifi-profile $profile ssid $ssid"
	config_command "config interface wlan 0 ip address $ip netmask 255.255.255.0"
	config_command "config interface wlan 0 channel 8"
	config_command "config interface wlan 0 profile $profile"
	config_command "config interface wlan 0 enable"

	config_command "config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Set AP config"
}

proc no_my_config_ap {profile ssid ip} {
	set DEFAULT_GATEWAY			[string range $ip 0 [string last "." $ip]]1

	config_command "no create wifi-profile $profile"
	config_command "no config interface wlan 0 ip address $ip netmask 255.255.255.0"
	config_command "no config interface wlan 0 channel 8"
	config_command "no config interface wlan 0 profile $profile"
	config_command "no config interface wlan 0 enable"

	config_command "no config route ip default gateway $DEFAULT_GATEWAY"

	show_command "show running-configuration"


	output_result "Clear AP config"
}

