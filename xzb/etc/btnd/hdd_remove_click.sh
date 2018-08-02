#!/bin/sh

. /lib/ramips.sh

xlogger "script: power button pressed, umount the USB connected disk"

xzb_mach=$(ramips_hardware_model)

# blink white LED when umounting USB HDD
if [ "$xzb_mach" == "xiazaibao_pro" ]; then
	usb_hdd=$(judge_usb_hdd_exist)

	# do nothing if no USB HDD
	[ "$usb_hdd" -eq 0 ] && exit 1

	# blink white led
        [ "$usb_hdd" -eq 1 ] && gpio white_blink
fi

#kill__save__data
/etc/init.d/appmsh     	stop
/etc/init.d/xctlsh 	stop
/etc/init.d/lighttpdsh 	stop
/etc/init.d/mpssh      	stop
/etc/init.d/etmsh      	stop
/etc/init.d/dlnash	stop
/etc/waittime.sh close 	&

if [ "$xzb_mach" == "xiazaibao" ]; then
	/etc/init.d/samba  	stop
fi

sleep 2
sync

if [ "$xzb_mach" == "xiazaibao_pro" ]; then
	# only umount point belong to USB connected HDD
	sd_dev_list=`ls /sys/block/ | grep sd`

	for sd_dev in $sd_dev_list
	do
		/usr/sbin/sdtype.sh &>/dev/null $sd_dev
		if [ $? -eq 2 ]; then
			echo "USB connected drive \"$sd_dev\" found"
			mnt_point_path=`mount | grep $sd_dev | head -1 | cut -d ' ' -f3`
				
			# umount this volume
			echo "umountall /dev/$sd_dev"
			/bin/umountall /dev/$sd_dev
			umount -lf /dev/$sd_dev*
				
			# delete fs path
			# case umount fail,only del after umount success to keep data safe
			mnt_point_dir_now=`mount | grep $sd_dev`
			if [ -z "$mnt_point_dir_now" ]; then
				mnt_point_path=`dirname $mnt_point_path`
				echo "del $mnt_point_path"
				rm -rf $mnt_point_path
			fi
		fi
	done
		
	update_LED_static_status
elif [ "$xzb_mach" == "xiazaibao" ]; then
	/sbin/block umount /dev/sd*
	rm -rf /data/UsbDisk1
	gpio orange_on_white_off
fi

[ -f /tmp/quick_umount ] ||  touch /tmp/quick_umount

/etc/init.d/dlnash	start &
/etc/init.d/xctlsh 	start &
/etc/init.d/etmsh      	start &
/etc/init.d/mpssh      	start &
/etc/init.d/lighttpdsh 	start &
/etc/init.d/appmsh     	start &

