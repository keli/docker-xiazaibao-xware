#!/bin/sh

####################################################################################################
# The script to diagnostic the system and the result is writed to sdcard or harddisk, the log file
# name is .xiazaibao-diag.txt
#
# Author : Xiong Dibin, xiongdibin@xunlei.com
#
# the items to diag :
# .) software status
#    firmware version
#    application status (xctl, etm, mps, lighttpd, xldp, dlna)
# .) disk infomation : 
#    volume info, partition, mount point, mount options, fs type, capacity, and free space
# .) network status
#    link status, up or down, link speed
#    IP address, netmask, gateway, DNS
#    connect to internet status
# .) system status
#    dmesg, syslog, ifconfig, etc
#
####################################################################################################

# Usage
# diag.sh [-c]
# -c   check it now

VOL=
DIAG_LOG=/tmp/etm/.xiazaibao-diag.txt
DIAG_LOG2=""
diag_ok=0
CHECK_NOW=0

mkdir -p /tmp/etm

if [ $# -gt 0 ]; then
	if [ $1 == "-c" -a $# -eq 2 ]; then
		echo "Check it now, result to /tmp/etm/$2 !"
		CHECK_NOW=1
		DIAG_LOG=/tmp/etm/$2
	else
		echo "Usage: $0 [-c output]"
		echo "-c output  check it now, and write the result to output"
		exit 1
	fi
else
	if [ -e /tmp/mnt.info -o -e /tmp/mnt2.info ]; then
		# the diag had already runned
		echo "the diag had already runned"
		exit 0
	fi
	# wait the application to start
	echo "wait the application to start"
	sleep 30
fi

echo "Diagnostic Start ......"

volume_get()
{
	# arg1 the storage file
	#echo "args cnt $#"
	#echo "0 $0, 1 $1, 2 $2"
	
	while read line 
	do
		#echo "check line ${line}"
		VOL=`echo ${line} | awk -F'[ ]' '{ print $2 }'`
		#echo "VOL = ${VOL}"
		# check if writeable ?
		local opt_rw=`echo "${line}" | grep rw`
		if [ "${opt_rw}" == "" ]; then
			echo "not writeable, ${line}"
			continue
		fi
		# check really write ?
		#echo "test write ${VOL}"
		DIAG_LOG2=${VOL}/.xiazaibao-diag.txt
		# test for write 1MB
		dd if=/dev/zero of=${DIAG_LOG2} bs=1024 count=1024 > /dev/null 2>&1
		if [ -f ${DIAG_LOG2} ]; then
			diag_ok=1
			#echo "diag_ok = ${diag_ok}"
			return
		fi
	done < $1
}


external_storage_get()
{
	local MNT_INFO="`grep UsbDisk1 /proc/mounts`"
	if [ "${MNT_INFO}" != "" ]; then
		# hdd found
		echo "${MNT_INFO}" > /tmp/mnt.info
		volume_get /tmp/mnt.info
		if [ ${diag_ok} -eq 1 ]; then
			return
		fi
	fi
	
	# check if any sdcard plugged
	local MNT_INFO2="`grep UsbDisk2 /proc/mounts`"
	if [ "${MNT_INFO2}" != "" ]; then
		# sd card found
		echo "${MNT_INFO2}" > /tmp/mnt2.info
		volume_get /tmp/mnt2.info
		if [ ${diag_ok} -eq 1 ]; then
			return
		fi
	fi	
}


#echo "diag_ok = ${diag_ok}"
#echo "DIAG_LOG2 = ${DIAG_LOG2}"

#echo "Write log to ${DIAG_LOG}"
echo "Diagnostic information for xiazaibao" > ${DIAG_LOG} 2>&1
echo "Date : `date`" >> ${DIAG_LOG} 2>&1


diag_software()
{
	FIRMWARE_VERSION=`grep "CURVER=" /etc/firmware | awk -F"=" '{ print $2}'`
	echo "Firmware version ${FIRMWARE_VERSION}" >> ${DIAG_LOG}
	uptime >> ${DIAG_LOG} 2>&1	
	uname -a >> ${DIAG_LOG} 2>&1
	echo "================== Application Status ==================" >> ${DIAG_LOG}
	# check xctl
	echo "Application Name : XCTL" >> ${DIAG_LOG}
	if [ "`ps | grep xctl | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -ant | grep 8200`" != "" ]; then
			echo "    bind 8200    : YES" >> ${DIAG_LOG}
			wget -q -O /dev/null "http://127.0.0.1:8200/dlna.csp?fname=dlna&opt=getusbinfo&userid=0" & > /dev/null 2>&1
		else
			echo "    bind 8200    : NO" >> ${DIAG_LOG}
		fi
	fi
	
	# check etm
	echo "Application Name : ETM" >> ${DIAG_LOG}
	if [ "`ps | grep etm | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -ant | grep 8002`" != "" ]; then
			echo "    bind 8002    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 8002    : NO" >> ${DIAG_LOG}
		fi
		if [ "`netstat -anu | grep 9000`" != "" ]; then
			echo "    bind 9000    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 9000    : NO" >> ${DIAG_LOG}
		fi
	fi
	
	#check mps
	echo "Application Name : MPS" >> ${DIAG_LOG}
	if [ "`ps | grep mps | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -ant | grep 81`" != "" ]; then
			echo "    bind 81      : YES" >> ${DIAG_LOG}
		else
			echo "    bind 81      : NO" >> ${DIAG_LOG}
		fi
	fi
	
	echo "Application Name : RACD" >> ${DIAG_LOG}
	if [ "`ps | grep racd | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -antl | grep 10000`" != "" ]; then
			echo "    connected    : YES" >> ${DIAG_LOG}
		else
			echo "    connected    : NO" >> ${DIAG_LOG}
		fi
	fi
	
	#check lighttpd
	echo "Application Name : HTTPD" >> ${DIAG_LOG}
	if [ "`ps | grep lighttpd | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -ant | grep 80`" != "" ]; then
			echo "    bind 80      : YES" >> ${DIAG_LOG}
		else
			echo "    bind 80      : NO" >> ${DIAG_LOG}
		fi
	fi
	
	#check xldp
	echo "Application Name : XLDP" >> ${DIAG_LOG}
	if [ "`ps | grep xldp | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -anu | grep 19000`" != "" ]; then
			echo "    bind 19000   : YES" >> ${DIAG_LOG}
		else
			echo "    bind 19000   : NO" >> ${DIAG_LOG}
		fi
	fi
	
	echo "Application Name : APPM" >> ${DIAG_LOG}
	if [ "`ps | grep appmonitor | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
	fi

	echo "Application Name : SAMBA" >> ${DIAG_LOG}
	if [ "`ps | grep smbd | grep -v grep`" == "" ]; then
		echo "    running(smbd): NO" >> ${DIAG_LOG}
	else
		echo "    running(smbd): YES" >> ${DIAG_LOG}
	fi
	if [ "`ps | grep nmbd | grep -v grep`" == "" ]; then
		echo "    running(nmbd): NO" >> ${DIAG_LOG}
	else
		echo "    running(nmbd): YES" >> ${DIAG_LOG}
	fi

	echo "Application Name : DLNA" >> ${DIAG_LOG}
	if [ "`ps | grep dlna | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}	
		# check status, binding port
		if [ "`netstat -anu | grep 1900`" != "" ]; then
			echo "    bind 1900    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 1900    : NO" >> ${DIAG_LOG}
		fi
		if [ "`netstat -ant | grep 8202`" != "" ]; then
			echo "    bind 8202    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 8202    : NO" >> ${DIAG_LOG}
		fi
	fi
}

diag_disk()
{
	echo "================== Disk Status ==================" >> ${DIAG_LOG}
	
	if [ ! -d /proc/scsi/usb-storage ]; then
		echo "USB cable not plugged" >> ${DIAG_LOG}
	else
		cd /proc/scsi/usb-storage
		file=`ls `
		for loop in $file
		do
		if [ -e "$loop" ];then
		cat $loop >> ${DIAG_LOG}
		fi
		done


		echo "Disk mounting information :" >> ${DIAG_LOG}
		cat /tmp/mnt.info >> ${DIAG_LOG} 2>&1
		echo "Disk capacity and free space :" >> ${DIAG_LOG}
		FREE_SPACE=`df -h | grep "Volume"`
		echo "${FREE_SPACE}" >> ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "Volume and Label(UTF-8 encode) information :" >> ${DIAG_LOG}
		volume_info >>  ${DIAG_LOG} 2>&1
		echo "(type: 1 ntfs, 2 fat, 3 fat32, 4 exfat, 5 hfs, 6 hfs+, 7 ext, 8 ext2, 9 ext3, 10 ext4, 11 xfs)" >> ${DIAG_LOG}
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		if [ -e /dev/sda ]; then
			echo "HardDisk partition infomation :" >> ${DIAG_LOG}
			fdisk -l /dev/sda >> ${DIAG_LOG} 2>&1
		fi
	fi

	if [ -e /dev/mmcblk0 ]; then
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "SDCard partition infomation :" >> ${DIAG_LOG}
		fdisk -l /dev/mmcblk0 >> ${DIAG_LOG} 2>&1
	fi
}

IP_ADDR=""
NETMASK_ADDR=""
GATEWAY=""
DNS=""

diag_network()
{
	echo "================== Network Status ==================" >> ${DIAG_LOG}
	PHY_STAT_INFO="`swconfig dev switch0 port 4 show | tail -n 1`"
	if [ "`echo ${PHY_STAT_INFO} | grep link:up`" != "" ]; then
		PHY_SPEED="`echo ${PHY_STAT_INFO} | awk '{ print $4 }'`"
		PHY_DUPLEX="`echo ${PHY_STAT_INFO} | awk '{ print $5 }'`"
		echo "    PHY link     : UP ${PHY_SPEED} ${PHY_DUPLEX}" >> ${DIAG_LOG}

		IFCONFIG_INFO=`ifconfig br-lan`
		if [ "`echo ${IFCONFIG_INFO} | grep RUNNING`" == "" ]; then
			echo "    Logic link   : DOWN" >> ${DIAG_LOG}
		else
			echo "    Logic link   : UP" >> ${DIAG_LOG}
			IP_ADDR="`ifconfig br-lan | grep 'inet' | awk -F":" '{ print $2 }' | awk '{ print $1}'`"
			NETMASK_ADDR="`ifconfig br-lan | grep 'inet' | awk -F":" '{ print $4 }'`"
			GATEWAY="`route -n |  grep UG | awk '{ print $2 }'`"
			DNS="`grep nameserver /etc/resolv.conf  | awk '{ print $2 }'`"
			echo "    IP address   : ${IP_ADDR}" >> ${DIAG_LOG} 2>&1
			echo "    Netmask      : ${NETMASK_ADDR}" >> ${DIAG_LOG} 2>&1
			echo "    Gateway      : ${GATEWAY}" >> ${DIAG_LOG} 2>&1
			for d in ${DNS}
			do
				echo "    DNS          : ${d}" >> ${DIAG_LOG} 2>&1
			done
		fi
	else
		echo "    PHY link     : DOWN (check the cable)" >> ${DIAG_LOG}
	fi
	
	PYH_MAC="`ifconfig eth0 | grep HWaddr | awk '{ print $5 }'`"
	LOGIC_MAC="`ifconfig br-lan | grep HWaddr | awk '{ print $5 }'`"
	echo "    PHY MAC      : ${PYH_MAC}" >> ${DIAG_LOG}
	echo "    Logic MAC    : ${LOGIC_MAC}" >> ${DIAG_LOG}

	# check internet
	
	echo "check internet :" >> ${DIAG_LOG}
	
	if [ "${IP_ADDR}" != "" -a "${GATEWAY}" != "" ]; then
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "Ping gateway ${GATEWAY}" >> ${DIAG_LOG}
		ping ${GATEWAY} -c 4 -W 1 -w 2 >> ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping xzb.xunlei.com -c 4 -W 1 -w 2 >> ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping baidu.com -c 4 -W 1 -w 2 >> ${DIAG_LOG} 2>&1

		echo "racd statistic :" >> ${DIAG_LOG}
		cat /tmp/racd.stat >> ${DIAG_LOG} 2>&1
	fi
}

diag_system()
{
	echo "================== System Status ==================" >> ${DIAG_LOG}
	echo "All interface status :" >> ${DIAG_LOG}
	ifconfig -a >> ${DIAG_LOG} 2>&1
	
	echo "All socket status :" >> ${DIAG_LOG}
	netstat -anp >> ${DIAG_LOG} 2>&1

	echo "All route table :" >> ${DIAG_LOG}
	route -n >> ${DIAG_LOG} 2>&1
	
	echo "All kernel message :" >> ${DIAG_LOG}
	dmesg >> ${DIAG_LOG} 2>&1
	
	echo "All syslog message :" >> ${DIAG_LOG}
	logread >> ${DIAG_LOG} 2>&1
	
	echo "process info :" >> ${DIAG_LOG}
	ps >> ${DIAG_LOG} 2>&1
	top -b -n 1 >> ${DIAG_LOG} 2>&1

	echo "firmware upgrade history :" >> ${DIAG_LOG}                                                                           
	/bin/fw_install -s >> ${DIAG_LOG} 2>&1
}

diag_etm()
{
	#etm info
	echo "" >> ${DIAG_LOG} 2>&1
	echo "================== etm sysinfo "================== >> ${DIAG_LOG} 2>&1
	wget 'http://127.0.0.1:9000/getsysinfo?v=2' -O /tmp/sysinfo.txt &> /dev/null && cat /tmp/sysinfo.txt >> ${DIAG_LOG} 2>&1
	echo "" >> ${DIAG_LOG} 2>&1
	echo "================== etm boxspace "================== >> ${DIAG_LOG} 2>&1
	wget 'http://127.0.0.1:9000/boxSpace' -O /tmp/boxspace.txt &> /dev/null && cat /tmp/boxspace.txt >> ${DIAG_LOG} 2>&1
	echo "" >> ${DIAG_LOG} 2>&1
}

diag_domain()
{
	echo "==================== ping download domain name =========================" >> ${DIAG_LOG}  
	ping license.yuancheng.xunlei.com -c 3 -w 4 >> ${DIAG_LOG} 2>&1
        ping session.remote.xiazaibao.xunlei.com -c 3 -w 4 >> ${DIAG_LOG} 2>&1
	nslookup license.yuancheng.xunlei.com  >> ${DIAG_LOG} 2>&1
        nslookup session.remote.xiazaibao.xunlei.com  >> ${DIAG_LOG} 2>&1

	echo "====================== ping xiazaibao transfer domain name :===================" >> ${DIAG_LOG}  
	ping dt.xiazaibao.xunlei.com  -c 3 -w 4 >> ${DIAG_LOG} 2>&1
        nslookup dt.xiazaibao.xunlei.com   >> ${DIAG_LOG} 2>&1
}

if [ ${CHECK_NOW} -ne 1 ]; then
	external_storage_get
fi
diag_software
diag_etm
diag_network
diag_system
diag_disk

diag_domain

echo "Diagnostic over ......"

if [ ${CHECK_NOW} -eq 1 ]; then
	# return now
	exit 0
fi

if [ ${diag_ok} -eq 1 ]; then
	# copy a log to external hdd or sd
	echo "Copy log to ${DIAG_LOG2}"
	cp -f ${DIAG_LOG} ${DIAG_LOG2}
	rm -f ${DIAG_LOG}
else
	echo "Not found any external storage"
fi

