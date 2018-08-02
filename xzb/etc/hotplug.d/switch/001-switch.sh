#!/bin/sh
logger -t switch "ACTION=$ACTION  PORT=$PORT  SPEED=$SPEED DUPLEX=$DUPLEX"
xlogger "script: network interface change, ACTION=$ACTION  PORT=$PORT  SPEED=$SPEED DUPLEX=$DUPLEX"
killall -16 udhcpc

if [ "$ACTION" = "UP" ]; then
		mkdir -p /tmp/dlna
		chmod -R 777 /tmp/dlna
		[ -f /tmp/dlna/net_change ] || touch /tmp/dlna/net_change
		chmod 777 /tmp/dlna/net_change
#        echo "/tmp/dlna/net_change" > /dev/console
else
		[ -f /tmp/dlna/net_change ] && rm -f /tmp/dlna/net_change
fi
