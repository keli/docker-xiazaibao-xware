#!/bin/sh
#NAME="/data/UsbDisk1/Volume1/.Thumbs/stats.info"
#PKG="timecloud"
#MAC=`ifconfig eth3 | grep HWaddr | awk '{print $NF}'`
#VER=`cat /etc/firmware  | grep CURVER | awk -F'=' '{print $NF}'`

echo "0" > /tmp/sdbackup.pid
echo "0,0,0" > /tmp/sdbackup.totalfiles
echo "0,0" > /tmp/sdbackup.backupedfiles
echo "" > /tmp/sdbackup.name
echo "" > /tmp/sdbackup.dir
#pioctl internet 1

#TIME=`date +%s`
#EXDATA="act_id%3D%27sdclose%27"
#echo "/$PKG?u1='$MAC'&u2='sd'&u3=&u4=&u5=&u6=&u7=&u8='act'&u9=$EXDATA&u10=$TIME&u11='$VER'" >> $NAME

