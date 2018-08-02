#!/bin/sh /etc/rc.common 
# Copyright (C) 2008-2015 time.xunlei.com

START=98

PROG=/bin/olddatamv

start()
{
	/etc/init.d/appmsh stop
	/etc/init.d/xctlsh stop
	/etc/init.d/dlnash stop
	/etc/init.d/mpssh  stop
	/etc/init.d/samba  stop
	${PROG}
        /etc/init.d/xctlsh start
	/etc/init.d/mpssh  start
	/etc/init.d/dlnash start
	/etc/init.d/samba  start
	/etc/init.d/appmsh start
}

stop()
{
	killall -9 olddatamv 
}

restart()
{
	stop
	sleep 2
	start
}
