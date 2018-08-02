#!/bin/sh
SPATH="/data/UsbDisk2/Volume1"
DPATH="/data/UsbDisk1/Volume1"
SDNO=`ls -1 /sys/class/mmc_host/mmc0/ | grep mmc0`
SDNAME=`cat /sys/class/mmc_host/mmc0/${SDNO}/name`
SDCID=`cat /sys/class/mmc_host/mmc0/${SDNO}/serial | cut -c3-`

echo "0" > /tmp/sdbackup.pid
echo $SDNAME > /tmp/sdbackup.name
#/usr/sbin/pioctl status 2

#TOTAL=`ls -lR ${SPATH} | grep ^- | wc -l`
#echo $TOTAL > /tmp/sdbackup.totalfiles

FUNC_MKDIR() {
	filelist=`ls -1 $SPATH`
	for filename in $filelist ; do
		if [ -f $filename ] ; then
			echo Filename:$filename
		elif [ -d $filename ] ; then
			find ${filename} -type d -exec mkdir -p ${DPATH}/${DIRNAME}/${SDNAME}_${SDCID}/{} \;
		fi
	done
}

if [ -f /etc/autosdbackup.conf ]; then
	AUTOCP=`cat /etc/autosdbackup.conf | grep -i "auto" | awk -F '=' '{print $2}'`
	DIRNAME=`cat /etc/autosdbackup.conf | grep -i "dirname" | awk -F '=' '{print $2}'`

    if [ "$AUTOCP" -eq 1 ]; then
		echo "1" > /tmp/sdbackup.pid
		#mkdir -p ${DPATH}/"${DIRNAME}"/"${SDNAME}_${SDCID}"
        #echo "no" | cp -rpif /data/UsbDisk2/Volume1/* /data/UsbDisk1/Volume1/"${DIRNAME}"/"${SDNAME}_${SDCID}"/
		if [ $? -eq 0 ]; then
			#cd $SPATH
			#FUNC_MKDIR
			#/usr/sbin/rsync -av --include='*/' --exclude='*' ${SPATH} ${DPATH}/"${DIRNAME}"/"${SDNAME}_${SDCID}"/
			#echo "-2" > /tmp/sdbackup.pid
			if [ "${SDNAME}"x = x -o -z ${SDNAME} ]; then
				echo "${DIRNAME}"/"SD卡_${SDCID}" > /tmp/sdbackup.dir
			else
				echo "${DIRNAME}"/"${SDNAME}_${SDCID}" > /tmp/sdbackup.dir
			fi
		fi
    fi
fi
