#!/usr/bin/expect -f
source [file dirname $argv0]/lib.tcl

set timeout			5
set USER				admin
set CONSOLE_IP			10.2.10.21


puts "What do you want to setup ?"
puts "  1. 85"
puts "  2. 87"
puts "  3. 71"
puts "  4. 100"
puts "  5. 101"

set choice [gets stdin]

switch $choice {
	1 {
		set TARGET_IP		10.2.10.85
		set CONSOLE_PORT	3001
		set INDEX			1

	}
	2 {
		set TARGET_IP		10.2.10.87
		set CONSOLE_PORT	3002
		set INDEX			1
	}
	3 {
		set CONSOLE_IP		10.2.10.50
		set TARGET_IP		10.2.10.71
		set CONSOLE_PORT	3009
		set INDEX			1
	}
	4 {
		set TARGET_IP		10.2.10.100
		set CONSOLE_PORT	3008
		set INDEX			0

	}
	5 {
		set TARGET_IP		10.2.10.101
		set CONSOLE_PORT	3001
		set INDEX			0

	}
	default {
		puts "Error!"
		exit
	}
}

spawn telnet $CONSOLE_IP $CONSOLE_PORT

escape_console_server

# if root already login, exit it!
expect {
	"login:"			{send "$USER\r" ; exp_continue}
	"Password:"			{send "$USER\r" ; exp_continue}
	" >"				{}
	"root@localhost"	{send "exit\r" ; exp_continue}
	"Error: Unknown command."	{send "\003\r" ; exp_continue}
}

after 1500
# control+c
send "\003\r"
expect " >"

config_command "config interface eth $INDEX ip address $TARGET_IP netmask 255.255.252.0"
#after 1500
config_command "config interface eth $INDEX enable"
#after 1500

send "exit\r"
expect "login:"

exit


