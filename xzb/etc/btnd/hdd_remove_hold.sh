#!/bin/sh

xlogger "script: power button hold, umount all disk and sd card, finally shutdown"
. /lib/ramips.sh

xzb_mach=$(ramips_hardware_model)
if [ "$xzb_mach" == "xiazaibao" ]; then
	exit 0
fi

gpio green_blink

killall lua
killall etm_monitor

#kill__save__data
/etc/init.d/appmsh     	stop
/etc/init.d/xctlsh 	stop
/etc/init.d/lighttpdsh 	stop
/etc/init.d/mpssh      	stop
/etc/init.d/etmsh      	stop
/etc/init.d/dlnash	stop
/etc/init.d/racdsh      stop
/etc/waittime.sh close 	&

/etc/init.d/samba  	stop
/etc/init.d/nginxsh	stop
/etc/init.d/xldpsh	stop



sleep 2
sync
sleep 2

# umount all mounted-point
/sbin/block umount /dev/sd*
umount -lf /dev/sd*

rmmod xhci_hcd
rmmod ahci

pro2kill="lua xctl dlna mps"
xzb_mach=$(ramips_hardware_model)
if [ "$xzb_mach" == "xiazaibao_pro" ]; then
	# shutdown power supply
	#btnd poweroff 14
	btnd sataoff 14
	gpio led_off
	btnd ledoff 14
	fanup 0
	
	while [ 1 -eq 1 ]
	do
		sleep 10
		for pro in $pro2kill
		do
			findpro=`ps | grep $pro | grep -v grep`
			echo "check $pro if exist $findpro"
			while [ -n "$findpro" ]
			do
				echo "find $pro to kill"
				killall $pro
				sleep 1
				findpro=`ps | grep $pro | grep -v grep`
			done
		done
		break
	done
fi

