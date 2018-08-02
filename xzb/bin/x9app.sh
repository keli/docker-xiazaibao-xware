#!/bin/sh

. /lib/ramips.sh

xzb_mach=$(ramips_hardware_model)

xl_reject_hdisk()
{
	xlogger "script: app call software umount the disk"
    #kill&save data
	/etc/init.d/appmsh     stop
	/etc/init.d/xctlsh     stop
	/etc/init.d/lighttpdsh stop
	/etc/init.d/mpssh      stop
	/etc/init.d/etmsh      stop
	
	/etc/waittime.sh close &
	[ "$xzb_mach" = "xiazaibao" ] && /etc/init.d/samba  stop

	sleep 2
	sync
	
	if [ "$xzb_mach" == "xiazaibao_pro" ]; then
		# only umount point belong to USB connected HDD
		sd_dev_list=`ls /sys/block/ | grep sd`

		for sd_dev in $sd_dev_list
		do
			/usr/sbin/sdtype.sh $sd_dev
			if [ $? -eq 2 ]; then
				echo "USB connected drive \"$sd_dev\" found"
				mnt_point_path=`mount | grep $sd_dev | head -1 | cut -d ' ' -f3`
					
				# umount this volume
				echo "umountall /dev/$sd_dev"
				/bin/umountall /dev/$sd_dev

				# case umount fail,only del after umount success to ensure data safe
				mnt_point_dir_now=`mount | grep $sd_dev`
				 if [ -z "$mnt_point_dir_now" ]; then
					mnt_point_path=`dirname $mnt_point_path`
					echo "del $mnt_point_path"
					rm -rf $mnt_point_path
				fi   
			fi
		done
	elif [ "$xzb_mach" == "xiazaibao" ]; then
		/bin/umountall /dev/sd
	fi

	# after state
	# white --> orange light on
	if [ "$xzb_mach" == "xiazaibao" ]; then
		gpio orange_on_white_off
	elif [ "$xzb_mach" == "xiazaibao_pro" ]; then
		update_LED_static_status
	fi

	/etc/init.d/xctlsh	start &
	/etc/init.d/etmsh	start &
	/etc/init.d/mpssh	start &
	/etc/init.d/lighttpdsh	start &
	/etc/init.d/appmsh	start &
	 [ -f /tmp/quick_umount ] ||  touch /tmp/quick_umount
}

xl_factory_reset()
{
	frt=`date`
	logger "${frt} factory reset"
	xlogger "script: app call software reset board"
	if [ "$xzb_mach" == "xiazaibao" ]; then
		gpio orange_blink_white_off
	elif [ "$xzb_mach" == "xiazaibao_pro" ]; then
		gpio red_blue_blink
	fi
	wget -q -O /dev/null "http://localhost:19100/xlog.csp?opt=uploadlog"
	/bin/resetboot -e
	find /data -type f -name i4dlna.db -o -name etm.db |xargs rm -f	
	sync 
	mtd erase rootfs_data && jffs2mark -y
	sync
	reboot -f
}

case $1 in
	reject_hdisk)
		xl_reject_hdisk
		;;
	factory_reset)
		xl_factory_reset
		;;
	*)
		echo "Usage: x9app.sh [reject_hdisk|factory_reset]"
		;;
esac

