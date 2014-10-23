#!/usr/bin/expect -f
set TOP [exec dirname $argv0]
source $TOP/lib.tcl

set USER			[lindex $argv 0]
set PASSWD			[lindex $argv 1]
set TARGET_IP		[lindex $argv 2]
set mod_name 		[lindex $argv 3]
set cdl				[lindex $argv 4]
set SELF_IP			[exec $TOP/../shellScript/get_ip.sh]
set TFTPBOOT		"tftpboot"
set folder 			""
set so_name_path	""
set so_name 		""
set device_so_path	""
set killDaemon		"killall -q ipsec udhcpc wpa_supplicant imgupd_updater wvdial fcapsd fcaps_cmd mobilityd platformd daemon_monitor gpsd imgupd_scheduler ; killall -9 fcapsd recorder platformd gobisierra slqssdk"
set restartDaemon	"sleep 5; /opt/lilee/sbin/daemon_monitor"

# debug <target dir> <copy xml ?> <is wms ?>
#if {$argc < 1} {
#	puts "Usage: This tool should be run under ../applications/"
#	puts "Syntax is: debug \[module name\]"
#	exit
#} elseif {$argc == 3} {
#	set TARGET_IP		10.2.10.56
#}

# Code start!
set folder "$mod_name/${mod_name}.fcaps"
if { $mod_name == "fcapsd" } {
	set folder "$mod_name/code/make/make_fcapsd_so"
} elseif { [file isdirectory $folder] == 0 } {
	set folder "${mod_name}.fcaps"
	if { [file isdirectory $folder] == 0 } {
		set folder "${mod_name}"
	}
}

# remove if so exist
if { [catch {set so_name_path [glob -directory $folder *.so]} msg] } {
	# not found
#	error_log "$msg in $folder"
} else {
	file delete $so_name_path
}

# check envsetup.sh
set env_path "../envsetup.sh"
if { [file isfile $env_path] == 0 } {
	set env_path "../build/envsetup.sh"
	if { [file isfile $env_path] == 0 } {
		error_log "can't find env_path"
		exit
	}
}

# make & copy so to tftp server
if { [catch {exec sh -c ". $env_path $ && make -C $folder > /dev/null"} msg] } {
	error_log "Build warning/error!"
} else {
	info_log "Build Success!"
}
if { [catch {set so_name_path [glob -directory $folder *.so]} msg] } {
	# not found
	error_log "$msg in $folder"
	exit 1
}
set so_name [file tail $so_name_path]
puts "file copy -force $so_name_path /${TFTPBOOT}"
file copy -force $so_name_path /${TFTPBOOT}

# build extra bin
if { $mod_name == "fcapsd" } {
	set folder "$mod_name/code/make/make_fcapsd"
	if { [catch {exec sh -c ". $env_path $ && make -C $folder > /dev/null"} msg] } {
		error_log "Build warning/error!"
	}
	puts "file copy -force $folder/fcapsd /${TFTPBOOT}"
	file copy -force $folder/fcapsd /${TFTPBOOT}
#	file delete $mod_name/code/make/make_fcapsd/fcapsd
#	file delete $mod_name/code/make/make_cli_transfer/fcaps_cmd
#	file delete $mod_name/code/make/make_daemon_monitor/daemon_monitor
#	file delete $mod_name/code/make/make_fcapsd_so/libfcapsd.so
#	set folder "$mod_name/code/make/make_fcapsd_so"
} elseif { $mod_name == "mobilityd" } {
	puts "file copy -force $folder/$mod_name /${TFTPBOOT}"
	file copy -force $folder/$mod_name /${TFTPBOOT}
} elseif { $mod_name == "platformd" } {
	set folder "$mod_name"
	if { [catch {exec sh -c ". $env_path $ && make -C $folder > /dev/null"} msg] } {
		error_log "Build warning/error!"
	}
	puts "file copy -force $folder/$mod_name /${TFTPBOOT}"
	file copy -force $folder/$mod_name /${TFTPBOOT}
	if { [file exist $folder/libplatformd.so] } {
		puts "file copy -force $folder/libplatformd.so /${TFTPBOOT}"
		file copy -force $folder/libplatformd.so /${TFTPBOOT}
	}
	if { [file exist $folder/ext/product_specific.so] } {
		puts "file copy -force $folder/ext/product_specific.so /${TFTPBOOT}"
		file copy -force $folder/ext/product_specific.so /${TFTPBOOT}
	}
} elseif { $mod_name == "intf_mgmt" } {
	set folder "$mod_name/intfindex"
	if { [catch {exec sh -c ". $env_path $ && make -C $folder > /dev/null"} msg] } {
		error_log "Build warning/error!"
	}
	if { [file exist $folder/libintfindex.so] } {
		puts "file copy -force $folder/libintfindex.so /${TFTPBOOT}"
		file copy -force $folder/libintfindex.so /${TFTPBOOT}
	}
}

# cdl
if {$cdl == 1} {
	exec sh -c "make cdl > /dev/null 2>&1 && rm -rf tmp.*"
	exec sh -c "cd cdl_output && tar -cvf cdl.tar ./*"
}


# connect to TARGET device
spawn ssh $USER@$TARGET_IP
login_device_ssh $PASSWD

if {$cdl == 1} {
	puts "file copy -force cdl_output/cdl.tar /${TFTPBOOT}"
	file copy -force cdl_output/cdl.tar /${TFTPBOOT}
	config_command "rm -rf /opt/lilee/etc/clish/* ; curl -O http://$SELF_IP/${TFTPBOOT}/cdl.tar ; tar xf cdl.tar -C /opt/lilee/etc/clish"
	
	# gen cdl iface.xml
	#config_command "ln -s /tmp/iface.xml /opt/lilee/etc/clish/"
}

if {[string range $so_name 0 5 ] != "lilee_" } {
	set device_so_path "/opt/lilee/lib/$so_name"
} else {
	set device_so_path "/opt/lilee/lib/fcaps/$so_name"
}

info_log "\nkill all daemons"
config_command "$killDaemon"
if { $mod_name == "fcapsd" } {
	config_command "curl http://$SELF_IP/${TFTPBOOT}/$mod_name -o /opt/lilee/bin/$mod_name"
} elseif { $mod_name == "mobilityd" } {
	config_command "curl http://$SELF_IP/${TFTPBOOT}/$mod_name -o /opt/lilee/bin/$mod_name"
} elseif { $mod_name == "platformd" } {
	config_command "curl http://$SELF_IP/${TFTPBOOT}/$mod_name -o /opt/lilee/bin/$mod_name"
	if { [file exist $folder/libplatformd.so] } {
		config_command "curl http://$SELF_IP/${TFTPBOOT}/libplatformd.so -o /opt/lilee/lib/libplatformd.so"
	}
	if { [file exist $folder/ext/product_specific.so] } {
		config_command "curl http://$SELF_IP/${TFTPBOOT}/product_specific.so -o /opt/lilee/lib/platformd/ext/product_specific.so"
	}
} elseif { $mod_name == "intf_mgmt" } {
	config_command "curl http://$SELF_IP/${TFTPBOOT}/$mod_name -o /opt/lilee/bin/$mod_name"
	if { [file exist $folder/libintfindex.so] } {
		config_command "curl http://$SELF_IP/${TFTPBOOT}/libintfindex.so -o /opt/lilee/lib/libintfindex.so"
	}
}

info_log "\nrestart fcapsd"
config_command "ulimit -c unlimited; ulimit -s 1024; export UV_THREADPOOL_SIZE=2"
config_command "curl http://$SELF_IP/${TFTPBOOT}/$so_name -o $device_so_path ; $restartDaemon"

puts "\n"

exit

