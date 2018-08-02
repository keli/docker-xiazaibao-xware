#!/bin/sh
#
# Copyright (C) 2010-2013 OpenWrt.org
#

RAMIPS_BOARD_NAME=
RAMIPS_MODEL=

ramips_board_detect() {
	local machine
	local name
	machine=$(cat /proc/cpuinfo | grep -i MT76)
	case $machine in
		*"MT7620"*)
			name="MT7620"
			;;
		*"MT7621"*)
			name="MT7621"
			;;
		*"MT7628"*)
			name="MT7628"
			;;
		*"MT7688"*)
			name="MT7688"
			;;
		*"MT7623"*)
			name="MT7623"
			;;
		*) # actually this is *NOT* acceptable.
			name="generic"
			;;
	esac

	[ -z "$RAMIPS_BOARD_NAME" ] && RAMIPS_BOARD_NAME="$name"
	# FIXME: define customer models here
	[ -z "$RAMIPS_MODEL" ] && RAMIPS_MODEL="mtk-apsoc-demo"

	[ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"

	echo "$RAMIPS_BOARD_NAME" > /tmp/sysinfo/board_name
	echo "$RAMIPS_MODEL" > /tmp/sysinfo/model
}

ramips_board_name() {
	local name

	[ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}


ramips_model_name() {
	local name

	[ -f /tmp/sysinfo/model ] && name=$(cat /tmp/sysinfo/model)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}

ramips_hardware_model() {
	local model
	local machine
	
        machine=$(cat /proc/cpuinfo | grep -i machine)
        model=`echo $machine | awk '{print $3}'`
        echo "$model"
}

esw_get_port_status() {
        tmp=`mii_mgr -g -p 31 -r 13320`
        var=`echo $tmp |awk '{print $4}'`
        status=$(( 0x$var % 2 ))
        echo "$status"
}

judge_hdd_exist() {
        hdd_exist="0"

	# judge if there is one HDD at least
        #sd_dev_list=`ls /sys/block/ | grep sd`
        #for sd_dev in $sd_dev_list
        #do
        #        sys_blk=`ls /sys/block/ | grep $sd_dev | head -1`
        #        if [ -z "$sys_blk" ] || [ ! -h /sys/block/$sd_dev ]; then
        #                continue
        #        fi

        #        if [ -n "$(readlink -f /sys/block/$sys_blk | grep ata)" ] ||
        #           [ -n "$(readlink -f /sys/block/$sys_blk | grep xhci)" ]; then
        #                hdd_exist="1"
        #                break;
        #        fi
        #done
	
	# actually judge if there is one HDD mounted at least
	hdd_status=`mount | grep "/dev/sd"`
	if [ "$hdd_status" != "" ]; then
		hdd_exist="1"		
	fi

	echo "$hdd_exist"
}

judge_usb_hdd_exist() {
        hdd_exist="0"

        sd_dev_list=`ls /sys/block/ | grep sd`
        for sd_dev in $sd_dev_list
        do
                sys_blk=`ls /sys/block/ | grep $sd_dev | head -1`
                if [ -z "$sys_blk" ] || [ ! -h /sys/block/$sd_dev ]; then
                        continue
                fi

                if [ -n "$(readlink -f /sys/block/$sys_blk | grep xhci)" ]; then
                        hdd_exist="1"
                        break;
                fi
        done

        echo "$hdd_exist"
}

judge_pcie_hdd_standby()
{
	pcie_hdd_standby="0"
	pcie2sata_hdd=""
	sd_dev_list=`ls /sys/block/ | grep sd`
	
	# get pcie connected drive
	for sd_dev in $sd_dev_list
	do
		/usr/sbin/sdtype.sh $sd_dev &> /dev/null
		if [ $? -eq 1 ]; then
			pcie2sata_hdd=$sd_dev
			break
		fi
	done
	
	if [ -n "$pcie2sata_hdd" ]; then
		hdd_status=`hdparm -C /dev/$pcie2sata_hdd 2>&1 | grep standby`
		
		if [ -n "$hdd_status" ]; then
			pcie_hdd_standby="1"
		fi
	fi
	
	echo "$pcie_hdd_standby"
}

# do not consider HDD sleep state yet,should be added later
update_LED_static_status() {
	net_status=$(esw_get_port_status)
	hdd_exist=$(judge_hdd_exist)
	pcie_hdd_standby=$(judge_pcie_hdd_standby)

	if [ "$net_status" -eq 1 ] && [ "$hdd_exist" -eq 0 ]; then
		gpio white_on
	elif [ "$net_status" -eq 1 ] && [ "$hdd_exist" -eq 1 ]; then
		if [ "$pcie_hdd_standby" -eq 1 ]; then
			gpio green_on
		else
			gpio blue_on
		fi
	elif [ "$net_status" -eq 0 ]; then
		gpio red_on
	fi
}
