
set REDF		"\033\[31m"
set GREENF		"\033\[32m"
set RESET		"\033\[0m"

set ERROR_LOG		"\n   ===== FAIL ====="
set ERROR_FLAG    0

# debug
#puts "--------\n" ; puts "$expect_out(buffer)"; puts "-------\n"

#set fd [open /tmp/kkkk a+]
#puts $fd $buf
#close $fd

proc escape_console_server {} {
	expect -re "Escape character is.*"
	send "\r"
}

proc login_device {user passwd} {
	set timeout		2
	expect {
		"Login incorrect"	{error_log $::ERROR_LOG ; exit}
		" login:"			{
			send "$user\r"
			expect "Password:"			{send "$passwd\r"}
			exp_continue
		}
		"Password:"			{send "$passwd\r" ; exp_continue}
		" >"				{}
		"# "				{}
		"$ "				{}
	}
}

proc logout_device {user} {
	expect {
		" login:"			{send "$user\r" ; exp_continue}
		"Password:"			{send "$user\r" ; exp_continue}
		" >"				{}
		"root@localhost"	{send "exit\r" ; interact}
	}
}

proc login_device_ssh {passwd} {
	expect {
		"Permission denied"		{error_log $::ERROR_LOG ; exit}
		" password:"			{send "$passwd\r" ; exp_continue}
		" >"					{}
		"# "					{}
		"$ "					{}
	}
}

proc process_file {filename} {
	set fp [open $filename r]
	while { [gets $fp data] >= 0 } {
		set data [string trim $data]
		if {[string length $data ] == 0} {
			#puts line
		} elseif {[string index $data 0] == "#"} {
			#puts comment
		} elseif {[string range $data 0 5 ] == "config"
				  || [string range $data 0 5 ] == "create"
				  || [string range $data 0 1 ] == "no"} {
			set cmd "config_command \"$data\""
			eval $cmd
		} elseif {[string range $data 0 4 ] == "show "} {
			set cmd "show_command \"$data\""
			eval $cmd
		} elseif {[string index $data 0] == "X"} {
			set cmd "config_fail_command \"[string range $data 2 end]\""
			eval $cmd
		} else {
			eval $data
		}
	}
	close $fp
}

proc config_command {command} {
	send "$command\r"
	expect {
		"Command succeeded"								{exp_continue}
		"The system is going down for reboot NOW!"		{}
		"Command format is error"						{error_log $::ERROR_LOG ; exit}
		"Command failed"								{error_log $::ERROR_LOG ; exit}
		"Failed"										{error_log $::ERROR_LOG ; exit}
		"Error"											{error_log $::ERROR_LOG ; exit}
		"lilee: \[ FAILED \]"							{error_log $::ERROR_LOG ; after 1000 ; exit}
		"The system is not ready"						{error_log $::ERROR_LOG ; exit}
		" >"											{}
		"# "											{}
		"Checking TFTP server"							{}
		"Proceed anyway? (yes/no)"						{send "yes\r" ; exp_continue}
		"Proceed with disk update? (yes/no)"			{send "yes\r" ; exp_continue}
	}
}

proc config_try_command {command} {
	set try 0
	send "$command\r"
	expect {
		"Error"										{incr try ; exp_continue}
		" >"										{}
	}
	#expect -re $
	
	if {$try == 1} {
		send "\x03"
		expect " >"
	}
}

proc config_fail_command {command} {
	set errlog 0
	send "$command\r"
	expect {
		"Command succeeded"								{error_log $::ERROR_LOG ; exit}
		"The system is not ready"						{error_log $::ERROR_LOG ; exit}
		"Command format is error"						{error_log $::ERROR_LOG ; exit}
		"Command failed"								{incr errlog ; exp_continue}
		" >"											{}
		"# "											{}
	}
	
	if {$errlog == 0} {
		error_log $command
		error_log $::ERROR_LOG ; exit
	}
}

proc show_command {command} {
	list set array {}
	send "$command\r"
	expect {
		"\r"		{
			set buf [string trim $expect_out(buffer)]
			set lists [regexp -inline {^[ -~]+} $buf]
			for {set i 0} {$i < [llength $lists]} {incr i} {
				set line [string trim [lindex $lists $i]]
				if {[string length $line] != 0} {
					lappend array $line
				}
			}
			exp_continue
		}
		" >"		{}
		"# "		{}
	}
	
	if {[info exists array]} {
		return $array
	}
}

proc check_output {array string} {
	set found 0
	for {set i 0} {$i < [llength $array]} {incr i} {
		set buf [lindex $array $i]
		if {[string first $string $buf] == 0} {
			incr found
			break
		} else {
			#error_log	"$i route ($buf)"
		}
	}
	if {$found == 0} {
		error_log	$::ERROR_LOG
		error_log	"should have ($string)"
		incr ::ERROR_FLAG
	}
}

proc check_output_i {array index string} {
	set found 0
	for {set i 0} {$index < [llength $array]} {incr i} {
		set buf [lindex $array $i]
		if {[string first $string $buf] == 0} {
			incr found
			break
		} else {
			#error_log	"$i route ($buf)"
		}
	}
	if {$found == 0} {
		error_log	$::ERROR_LOG
		error_log	"should have ($string)"
		incr ::ERROR_FLAG
	}
}

proc check_no_output {array string} {
	set found 0
	for {set i 0} {$i < [llength $array]} {incr i} {
		set buf [string trim [lindex $array $i] " \r\n"]
		if {[string first $string $buf] == 0} {
			incr found
			break
		} else {
			#error_log	"$i route ($buf)"
		}
	}
	if {$found == 1} {
		error_log	$::ERROR_LOG
		error_log	"should not be ($string)"
		incr ::ERROR_FLAG
	}
}

proc check_array_size {array expect_len command} {
	if {[llength $array] != $expect_len} {
		error_log	$::ERROR_LOG
		error_log	"wrong list number [llength $array], should be $expect_len ($command)"
		exit
	}
}

proc info_log {log} {
	puts "${::GREENF}$log${::RESET}"
}

proc error_log {log} {
	puts "${::REDF}$log${::RESET}"
}

proc output_result {log} {
	set length [expr [string length $log]+22]
	if {$::ERROR_FLAG == 0} {
		puts "\n${::GREENF}   [string repeat "=" $length]"
		puts "     Test case: $log PASS!!"
		puts "   [string repeat "=" $length]${::RESET}\n"
	} else {
		puts "\n${::REDF}   [string repeat "=" $length]"
		puts "     Test case: $log FAIL!!"
		puts "   [string repeat "=" $length]${::RESET}\n"
		exit
	}
}

