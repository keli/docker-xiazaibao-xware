#!/bin/sh

. /lib/ramips.sh

xzb_mach=$(ramips_hardware_model)

xlogger "script: reset button pressed, reset the board"
if [ "$xzb_mach" == "xiazaibao" ]; then
        gpio orange_blink_white_off
elif [ "$xzb_mach" == "xiazaibao_pro" ]; then
        gpio red_blue_blink
fi

wget -q -O /dev/null "http://localhost:19100/xlog.csp?opt=uploadlog"
/bin/resetboot -e
/bin/resetboot -U
find /data -type f -name i4dlna.db -o -name etm.db |xargs rm -f
sleep 5
sync && jffs2mark -y && reboot
