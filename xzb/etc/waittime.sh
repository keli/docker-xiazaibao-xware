#!/bin/sh

WAIT_FILE="/tmp/settime"
HDD=$1 

NAME="/tmp/timeplug.info"
PKG="timecloud"
VER=`cat /etc/firmware  | grep CURVER | awk -F'=' '{print $NF}'`

timeout()
{
        waitfor=60
        command=$*
        $command &
        commandpid=$!

        ( sleep $waitfor ; kill -9 $commandpid > /dev/null 2>&1 ) &

        watchdog=$!
        #sleeppid=$PPID
        sleeppid=`ps 2>&1 | awk '/$watchdog/ {print $1}'`
        #下面一行加上重定向是避免在被KILL的时候，报出被kill的提示
        #当然带来的副作用是重定向不一定符合预期
        wait $commandpid > /dev/null 2>&1

        kill $sleeppid > /dev/null 2>&1
}


runwait()
{
	count=0
	while :; do
		if [ -e "$WAIT_FILE" ]; then
			MAC=`ifconfig br-lan | grep HWaddr | awk '{print $NF}' | tr [A-Z] [a-z]`
			TIME=`date +%s`
			if [ x"$HDD" == x"close" ]; then
				EXDATA="act_id%3Dhdclose"
				echo "/$PKG?u1=$MAC&u2=hd&u3=&u4=&u5=&u6=&u7=&u8=act&u9=$EXDATA&u10=$TIME&u11=$VER&u12=0x01" >> $NAME
			elif [ x"$HDD" == x"open" ]; then
				EXDATA="act_id%3Dhdopen"
				echo "/$PKG?u1=$MAC&u2=hd&u3=&u4=&u5=&u6=&u7=&u8=act&u9=$EXDATA&u10=$TIME&u11=$VER&u12=0x01" >> $NAME
			elif [ x"$HDD" == x"sdclose" ]; then
				EXDATA="act_id%3Dsdclose"
				echo "/$PKG?u1=$MAC&u2=sd&u3=&u4=&u5=&u6=&u7=&u8=act&u9=$EXDATA&u10=$TIME&u11=$VER&u12=0x01" >> $NAME
			elif [ x"$HDD" == x"sdopen" ]; then
				EXDATA="act_id%3Dsdopen"
				echo "/$PKG?u1=$MAC&u2=sd&u3=&u4=&u5=&u6=&u7=&u8='act'&u9=$EXDATA&u10=$TIME&u11=$VER&u12=0x01" >> $NAME
			else
				EXDATA="act_id%3Dstart"
				echo "/$PKG?u1=$MAC&u2=hd&u3=&u4=&u5=&u6=&u7=&u8=act&u9=$EXDATA&u10=$TIME&u11=$VER&u12=0x01" >> $NAME
			fi
			break
		else
			[ $count == 3 ] && break;
			let count+=1
			sleep 3
		fi
		sleep 5
	done
}

#timeout runwait
runwait
