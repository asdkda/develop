#!/bin/bash

if [ -d ".git" ]; then
	echo "already exist .git! Skip it."
	exit 1
fi

echo "start init git"
git init

# make some config
git config user.name $name
git config user.email $email

# make .gitignore file
cat > .gitignore << "eof"
*.[oad]
*.so
*.so.[0-9]*
*.ko
*.lo
*.la
*.depend
*.[oa].flags
*.map
*.gif
*.ico
# *.xml
*.cmd
*.svn
*.list
*.old
*.gz
*.bz
*.tgz
*.tar
*.img
*.md5sum
*[a-z].[0-9]
*.rpm
*.dat
*.doc
*.vcproj
*.dsp
cscope.*
.*
vmlinuz*
*.ad
*.ao
*.rd
*.ro
*.ld
*.dtb
*.mod.c
*~
*.unsigned
*.tab.[ch]
*.yy.[ch]
*.marker
*.mod
*.module
*.image
*.output

# file
.gitignore
README
TODO
NEWS
COPYING
AUTHORS
CHANGES
LICENCE
LICENSE
RELEASE-NOTES
ISSUES
README.txt
config.status
config.log
build.log
lilee-release
Module.symvers
modules.order
Documentation
stamp-h
stamp-h1

# autogen
libtool
aclocal.m4
hugehelp.c
Module.markers
applications/platformd/ext/product_specific.[ch]
modules/lilee_info/lib/config.h
modules/lilee_info/lilee_info.mod.c
modules/ptc/ptc.mod.c
modules/ptc/unittest/ptc_freq_algo.c
modules/wifi/apps/wpa2/hostapd/driver_conf.c
modules/wifi/apps/wpa2/wireless_tools/wireless.h
modules/wifi/drivers/wlan/adf/adf.mod.c
modules/wifi/drivers/wlan/asf/asf.mod.c
modules/wifi/drivers/wlan/lmac/ath_dev/ath_dev.mod.c
modules/wifi/drivers/wlan/lmac/ath_pktlog/ath_pktlog.mod.c
modules/wifi/drivers/wlan/lmac/dfs/ath_dfs.mod.c
modules/wifi/drivers/wlan/lmac/ratectrl/ath_rate_atheros.mod.c
modules/wifi/drivers/wlan/os/linux/ath_hal/ath_hal.mod.c
modules/wifi/drivers/wlan/os/linux/ath_hal/opt_ah.h
modules/wifi/drivers/wlan/umac/umac.mod.c
tools/cdl/tools/clish_xml
tools/cdl/cdl.tab.[ch]
tools/cdl/cdl_lexer.[ch]
tools/cdl/fcaps_table.[ch]
modules/lilee_info/linfo/linfo_lexer.[ch]
modules/lilee_info/userlib/seclist_lexer.[ch]
modules/lilee_info/component.[ch]


# bin
uImage
u-boot.bin
initramfs.bootflash.uboot
applications/dhcpcfg/dhcpcfg
applications/fcapsd/code/make/make_cli_transfer/fcaps_cmd
applications/fcapsd/code/make/make_cli_cmd_async/fcaps_cmd_async
applications/fcapsd/code/make/make_daemon_monitor/daemon_monitor
applications/fcapsd/code/make/make_fcapsd/fcapsd
applications/fcapsd/code/make/make_http_fcapsd_cmd/http_fcaps_cmd
applications/fcapsd/code/make/make_lilee_log_d/lilee_log_d
applications/fcapsd/code/make/make_log_scanf_tool/lilee.logfileinfo
applications/fcapsd/code/make/make_log_scanf_tool/lilee.loginfo
applications/fcapsd/code/make/make_log_scanf_tool/log_scanf_tool
applications/fcapsd/code/make/make_log_translate_tool/log_translate_tool
applications/fcapsd/code/make/make_log_translate_tool/show_log
applications/fcapsd/code/make/make_json_cmd/json_cmd
applications/fcapsd/code/make/make_metadata_tool/obj_metadata_tool
applications/gpsd.fcaps/ublox_cmd
applications/gpsd.fcaps/gps_test
applications/ipsec.fcaps/ac-connect
applications/intf_mgmt/intf_mgmt.fcaps/wvstatus
applications/ipsec.fcaps/ipsec_pwenc
applications/ipsec.fcaps/seringe
applications/lcd/lcd_config
applications/lilee_osutils/unitest/test_ifmon
applications/lilee_osutils/unitest/test_user
applications/license_mgmt.fcaps/licensetool
applications/mobilityd/mobilityd.fcaps/mobilityd
applications/mobilityd/test/mobilitytest
applications/network/network.fcaps/dhcp_config
applications/platformd/platformd
applications/snmp/interfaceTable/snmpwalk
applications/user_mgmt.fcaps/lilee_su
applications/user_mgmt.fcaps/usermgmt_crypt
modules/lilee_info/tools/common/lilee_info_reader
modules/lilee_info/tools/common/lilee_info_writer
modules/lilee_info/tools/lilee_write_eeprom
modules/lilee_info/tools/mk_image
modules/lilee_info/tools/write_image
modules/lilee_info/tools/write_mac
modules/lilee_info/linfo/linfo
modules/ptc/tools/lib/unitest/test_histogram
modules/ptc/tools/lib/unitest/test_wfr
modules/ptc/tools/ptc_adcdecode
modules/ptc/tools/ptc_config
modules/ptc/tools/ptc_config_nl
modules/ptc/tools/ptc_debug
modules/ptc/tools/ptc_regrw
modules/ptc/unittest/chrdev-nb-read
modules/ptc/unittest/dbgdma
modules/ptc/unittest/dg_check
modules/ptc/unittest/test-freq-reg
modules/wifi/apps/hostap-0.7.2/wpa_supplicant/wpa_cli
modules/wifi/apps/hostap-0.7.2/wpa_supplicant/wpa_supplicant
modules/wifi/apps/wpa2/apstart/apstart
modules/wifi/apps/wpa2/hostapd/hostapd
modules/wifi/apps/wpa2/tags
modules/wifi/apps/wpa2/wireless_tools/ifrename
modules/wifi/apps/wpa2/wireless_tools/iwconfig
modules/wifi/apps/wpa2/wireless_tools/iwevent
modules/wifi/apps/wpa2/wireless_tools/iwgetid
modules/wifi/apps/wpa2/wireless_tools/iwlist
modules/wifi/apps/wpa2/wireless_tools/iwpriv
modules/wifi/apps/wpa2/wireless_tools/iwspy
modules/wifi/apps/wpa2/wpa_supplicant/wpa_supplicant
modules/wifi/apps/wpa2/wpatalk/wpatalk
modules/wifi/drivers/wlan/os/linux/tools/wlanconfig
tools/bison/src/bison
tools/bison/src/yacc
tools/checksum/md5
tools/cdl/tools/cdlang
tools/cdl/collect/packages
tools/flex/flex

# dir
docs
doc
bin
target
img_file
opt
toolchain
fpga
fpga_image
# rootfs_build
*.tmp
m4
po
bootloader
autom4te.cache
applications/jansson/test
applications/cdl_output
applications/mtd-utils/mtd-utils-d37fcc0/arm-none-linux-gnueabi
bootflash_build/bootflash.rootfs.target/etc/clish
modules/bison_build
modules/flex_build
modules/wifi/build/marconi/tools
modules/wifi/drivers/wlan/hal/linux/obj
modules/build/wifi/tools/
tools/bison/tests
tools/cli_gen_tool/clish_xml
tools/bison/examples
tools/flex/examples
tools/flex/tests

applications/i2c-tools/i2c-tools-3.0.3/eepromer/eeprog
applications/i2c-tools/i2c-tools-3.0.3/eepromer/eeprom
applications/i2c-tools/i2c-tools-3.0.3/eepromer/eepromer
applications/i2c-tools/i2c-tools-3.0.3/tools/i2cdetect
applications/i2c-tools/i2c-tools-3.0.3/tools/i2cdump
applications/i2c-tools/i2c-tools-3.0.3/tools/i2cget
applications/i2c-tools/i2c-tools-3.0.3/tools/i2cset
applications/pcre/pcre-8.31/Makefile
applications/pcre/pcre-8.31/config.h
applications/pcre/pcre-8.31/libpcre.pc
applications/pcre/pcre-8.31/libpcre16.pc
applications/pcre/pcre-8.31/libpcrecpp.pc
applications/pcre/pcre-8.31/libpcreposix.pc
applications/pcre/pcre-8.31/pcre-config
applications/pcre/pcre-8.31/pcre.h
applications/pcre/pcre-8.31/pcre_chartables.c
applications/pcre/pcre-8.31/pcre_stringpiece.h
applications/pcre/pcre-8.31/pcrecpparg.h
applications/pcre/pcre-8.31/pcregrep
applications/pcre/pcre-8.31/pcretest
applications/pwauth/config_pwauth
applications/pwauth/pwauth-2.3.10/pwauth
applications/mod_authnz_external/config_mod
applications/mod_authnz_external/mod_authnz_external-3.2.6/mod_authnz_external.slo

bootflash_build/mk_uboot_env
bootflash_build/u-boot_env0.bin
bootflash_build/u-boot_env1.bin
kernel/patch_kernel

# ptc
rootfs_build/config.jffs2.256
rootfs_build/initramfs.new.uboot
rootfs_build/config.jffs2

# wms
applications/eepromcfg/eepromcfg
applications/gobi/App/gobisw3g
applications/gobi/App/gobiutils

# lmc
mv_img.sh
salamanca/flash/initrd_src/opt/lilee/etc/clish
salamanca/flash/dracut/dracut
salamanca/flash/dracut/dracut-functions
salamanca/flash/dracut/src/

copyright/
etc.non-volatile/
image/
kirkwood_apx2_rootfs/
mvl_drivers/
root_fs/

eof

# add file to watch
git add .

echo "start commit..."
git commit -m "initial"


