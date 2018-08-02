#!/bin/sh

. /lib/ramips.sh

IMAGE=$1
LOG_FILE="/tmp/firmware.log"
FW_DEV="/dev/mtd4"
FW_FILE_READ="/tmp/fw_read.bin"
DL_FIRMWARE_FILE_MD5="/tmp/firmware.md5"
DL_FIRMWARE_FILE="/tmp/firmware.bin"

xzb_mach=$(ramips_hardware_model)

[ -z "$1" ] && echo "USG: $0 <image>" && exit 1

[ ! -f "$IMAGE" ] && echo "upgrade fw not fond $IMAGE image file." && exit 1

rm_dlfile() {
		[ -f $DL_FIRMWARE_FILE_MD5 ] && rm -rf $DL_FIRMWARE_FILE_MD5
		[ -f $DL_FIRMWARE_FILE ]     && rm -rf $DL_FIRMWARE_FILE
		[ -f $FW_FILE_READ ]         && rm -rf $FW_FILE_READ
}

stop_xl_server() {
	/etc/init.d/appmonitor stop
	/etc/init.d/xctlsh stop
	/etc/init.d/lighttpdsh stop
	/etc/init.d/mpssh stop
	/etc/init.d/etmsh stop
	/etc/init.d/racdsh stop
	/etc/init.d/samba  stop
}

restart_xl_server() {
	/etc/init.d/xctlsh start
	/etc/init.d/lighttpdsh start
	/etc/init.d/mpssh start
	/etc/init.d/etmsh start
	/etc/init.d/racdsh start
	/etc/init.d/samba  start
	/etc/init.d/appmonitor start

	[ -f $IMAGE ] && rm -rf $IMAGE
	echo "upgrade .tar.gz failed."
	exit 1
}

stop_xl_server

tar -zvxf $IMAGE -C /tmp
if [ $? != 0 ];
then
	restart_xl_server
fi

[ -f $DL_FIRMWARE_FILE_MD5 ] || exit 1
[ -f $DL_FIRMWARE_FILE ]     || exit 1

PKG_DIR=`basename "$IMAGE" .tar.gz`
echo $PKG_DIR > /tmp/au.cfg

server_fw_md5=`cat $DL_FIRMWARE_FILE_MD5 | awk '{print $1}'`
local_fw_md5=`md5sum $DL_FIRMWARE_FILE   | awk '{print $1}'`
fw_count=`ls -l $DL_FIRMWARE_FILE        | awk '{print $5}'`

# 判断strleng不为空
[ -z "$server_fw_md5" ] && echo "server_fw_md5 is  NULL" && restart_xl_server && exit 1
[ -z "$local_fw_md5" ]    && echo "local_fw_md5 is  NULL" && restart_xl_server  && exit 1

#del all .tar.gz
PKG_DIR=`dirname "$IMAGE"`
[ -f $IMAGE ] && rm -rf $PKG_DIR/*.tar.gz
sync

while true
do
	#比较md5数值是否 相等

    if [ "$server_fw_md5" = "$local_fw_md5" ];
    then
		#write log
		echo `date`	>	$LOG_FILE
		echo "server_fw_md5=$server_fw_md5"	>>	$LOG_FILE
		echo "local_fw_md5=$local_fw_md5"	>>	$LOG_FILE
		mtd  write  $LOG_FILE  /dev/mtd8

		#display  led status;
		if [ "$xzb_mach" == "xiazaibao" ]; then
		       gpio orange_blink_white_off
		elif [ "$xzb_mach" == "xiazaibao_pro" ]; then
		       gpio red_blue_blink
		fi

		sysupgrade -n $DL_FIRMWARE_FILE
    else
		rm_dlfile
		break
    fi
done

# shou wei work
#del upgrade.tar.gz
reboot -f

exit 0
