#!/usr/bin/expect -f
source [file dirname $argv0]/lib.tcl

set timeout		30

set USER			[lindex $argv 0]
set PASSWD			[lindex $argv 1]
set TARGET_IP		[lindex $argv 2]
set PROTOCOL		[lindex $argv 3]

switch $argc {
	4 {
		if { $PROTOCOL == "ssh" } {
			spawn ssh $USER@$TARGET_IP
		} else {
			spawn telnet $TARGET_IP
		}
	}
	5 {
		set PORT	[lindex $argv 4]
		if { $PROTOCOL == "ssh" } {
			spawn ssh $USER@$TARGET_IP -p $PORT
		} else {
			spawn telnet $TARGET_IP $PORT
		}
		escape_console_server
	}
	default {
		puts "Error! Syntax is: [file tail $argv0] name passwd ip \[telnet/ssh\] \[port\]"
		exit
	}
}

if { $PROTOCOL == "ssh" } {
	login_device_ssh $PASSWD
} else {
	login_device $USER $PASSWD
}

interact


