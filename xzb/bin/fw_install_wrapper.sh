#!/bin/sh

. /lib/ramips.sh

echo "args cnt $#"
echo "args is  [$@]"

export firmware_bin=""
export firmware_md5=""
export from_version=""
export to_version=""
export entry_trigger=""
export firmware_size=""

xzb_mach=$(ramips_hardware_model)

while getopts "b:t:f:m:e:l:" arg
do
    case ${arg} in
    b)
        firmware_bin=${OPTARG}
        echo "firmware binary is ${firmware_bin}"
        ;;
    t)
        to_version=${OPTARG}
        echo "to version is ${to_version}"
        ;;
    f)
        from_version=${OPTARG}
        echo "from version is ${from_version}"
        ;;
    m)
        firmware_md5=${OPTARG}
        echo "firmware md5 is ${firmware_md5}"
        ;;
    e)
        entry_trigger=${OPTARG}
        echo "entry trigger is ${entry_trigger}"
        ;;
	l)
		firmware_size=${OPTARG}
		echo "firmware size is ${firmware_size}"
		;;
    ?)
        echo "unknown option"
        exit 1
        ;;
    esac
done

if [ "${firmware_bin}" == "" ]; then
    echo "usage: $0 -b firmware-bin [-f from-version] [-t to-version] [-m firmware-md5] -e entry"
    exit 1
fi

if [ "${entry_trigger}" == "" ]; then
    echo "usage: $0 -b firmware-bin [-f from-version] [-t to-version] [-m firmware-md5] -e entry"
    exit 1
fi

xlogger "script: start upgrading firmware, from ${from_version}, to ${to_version}, md5sum ${firmware_md5}, size ${firmware_size}"

nginx_port_file="/tmp/nginx/conf/nginx.port"
if [ -e "${nginx_port_file}" ]; then
	nginx_port=`cat ${nginx_port_file}`
	wget -q -O /dev/null "http://127.0.0.1:${nginx_port}/xlog.csp?opt=uploadlog"
fi

echo "entry tigger is ${entry_trigger}"

export entry_trigger="-e ${entry_trigger}"

if [ ! -f ${firmware_bin} ]; then
    echo "firmware file not exit, ${firmware_bin}"
    exit 2
fi

echo "firmware bin is ${firmware_bin}"

export firmware_bin="-b ${firmware_bin}"

echo "firmware md5 is ${firmware_md5}"
if [ "${firmware_md5}" != "" ]; then
    export firmware_md5="-m ${firmware_md5}"
fi

if [ "${from_version}" == "" ]; then
    # get the from version
    if [ ! -f /etc/firmware ]; then
        echo "may not a xiazaibao firmware"
        from_version="x.x.x"
    else
        from_version=`grep "CURVER" /etc/firmware | awk -F= '{ print $2 }'`
        if [ "${from_version}" == "" ]; then
            echo "can not get current version"
            from_version="0.0.0"
        fi
    fi
fi

echo "from version is ${from_version}"
export from_version="-f ${from_version}"

echo "to   version is ${to_version}"
if [ "${to_version}" != "" ]; then
    export to_version="-t ${to_version}"
fi

if [ "${firmware_size}" == "" ]; then
	echo "need set firmware size"
	exit 1
fi

export firmware_size="-l ${firmware_size}"

. /lib/functions.sh
. /lib/upgrade/common.sh

kill_remaining SIGTERM
sync
sleep 2
kill_remaining SIGKILL
sync
/bin/umountall /dev/sd

if [ "$xzb_mach" == "xiazaibao" ]; then
	gpio orange_blink_white_off
elif [ "$xzb_mach" == "xiazaibao_pro" ]; then
	gpio red_blue_blink
fi

run_ramfs '. /lib/functions.sh; include /lib/upgrade; do_fw_install'
