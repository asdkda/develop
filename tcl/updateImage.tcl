#!/usr/bin/expect -f
set TOP [exec dirname $argv0]
source $TOP/lib.tcl

set USER					admin
set SELF_IP					[exec $TOP/../shellScript/get_ip.sh]
set TARGET_IP				[lindex $argv 0]
set TYPE					[lindex $argv 1]
set PROTOCOL				[lindex $argv 2]
set ECHOCMD					[lindex $argv 3]
set timeout					30
set NEXT_BOOT_IMG			""
set PUBLIC					10.2.10.204
set TFTPBOOT				"tftpboot"
set FULL_IMAGE_NAME			[file tail [glob -directory "/${TFTPBOOT}" ${TYPE}*_u*.img]]


proc get_img_name {array} {
	set found 0
	for {set i 0} {$i < [llength $array]} {incr i} {
		set buf [string trim [lindex $array $i] " \r\n"]
		set index [string first "Alternative image:" $buf]
		if { $index != -1} {
			return [string range $buf [string last " " $buf]+1 end]
		}
	}
	if {$found == 0} {
		error_log	$::ERROR_LOG
		error_log	"should have (Alternative image:)"
		incr ::ERROR_FLAG
	}
	return ""
}

if { $ECHOCMD != "" } {
	puts "update boot system-image http://$SELF_IP/${TFTPBOOT}/$FULL_IMAGE_NAME"
	exit
}

switch $argc {
	3 {
		if { $PROTOCOL == "ssh" } {
			spawn ssh $USER@$TARGET_IP
		} else {
			spawn telnet $TARGET_IP
		}
	}
	4 {
		set PORT			[lindex $argv 3]
		if { $PROTOCOL == "ssh" } {
			spawn ssh $USER@$TARGET_IP $PORT
		} else {
			spawn telnet $TARGET_IP $PORT
		}
		escape_console_server
	}
	default {
		puts "Error! Syntax is: [file tail $argv0] ip \[marconi/lmc\] \[telnet/ssh\] \[port\]"
		exit
	}
}

# check if we behind NAT.
if { "[string range $SELF_IP 0 [string last "." $SELF_IP]]" == "192.168.1." } {
	set SELF_IP		$PUBLIC
}

login_device_ssh $USER
if { $TYPE == "lmc" || $TYPE == "dts" } {
	set timeout 600
} else {
	set timeout 300
}
config_command "update boot system-image http://$SELF_IP/${TFTPBOOT}/$FULL_IMAGE_NAME"

after 1000
config_try_command "update terminal paging disable"
set array [show_command "show boot system-image"]
set NEXT_BOOT_IMG [get_img_name $array]
config_command "config boot system-image $NEXT_BOOT_IMG"
config_command "reboot"
after 1000

puts "\n"

exit


