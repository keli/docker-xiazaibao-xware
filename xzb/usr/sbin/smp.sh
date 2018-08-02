#!/bin/sh

#=============================================================================
# smp_affinity: 1 = CPU1, 2 = CPU2, 3 = CPU3, 4 = CPU4
# rps_cpus: wxyz = CPU3 CPU2 CPU1 CPU0 (ex:0xd = 0'b1101 = CPU1, CPU3, CPU4)
#=============================================================================

#. /sbin/config.sh

if [ ! -n "$1" ]; then
  echo "insufficient arguments!"
  echo "Usage: $0 <mode>"
  exit 0
fi

OPTIMIZED_FOR="$1"
LIST=`cat /proc/interrupts | sed -n '1p'`
NUM_OF_CPU=0; for i in $LIST; do NUM_OF_CPU=`expr $NUM_OF_CPU + 1`; done;

#wifiChannel1=`nvram_get 2860 Channel`
#wifiChannel2=`nvram_get rtdev Channel`
#if [ "$wifiChannel1" -gt "14" ]; then
#        wifiDomain1="5G"
#        echo "Wi-Fi(1): 5G"
#else
#        wifiDomain1="2_4G"
#        echo "Wi-Fi(1): 2.4G"
#fi
#
#if [ "$wifiChannel2" -gt "14" ]; then
#        wifiDomain2="5G"
#        echo "Wi-Fi(2): 5G"
#else
#        wifiDomain2="2_4G"
#        echo "Wi-Fi(2): 2.4G"
#fi

# xiazaibao without wireless
#wifiDomain1=`uci get wireless.@wifi-device[0].band`
#wifiDomain2=`uci get wireless.@wifi-device[1].band`

case `cat /proc/cpuinfo | grep MT76` in
  *7621*)
    CONFIG_RALINK_MT7621=y
    ;;
  *7623*)
    CONFIG_ARCH_MT7623=y
    ;;
esac

echo "OPTIMIZED_FOR -> $OPTIMIZED_FOR"
echo "NUM_OF_CPU -> $NUM_OF_CPU"
echo "wifiDomain1 -> $wifiDomain1"
echo "wifiDomain2 -> $wifiDomain2"
echo "CONFIG_RALINK_MT7621 -> $CONFIG_RALINK_MT7621"
echo "CONFIG_ARCH_MT7623 -> $CONFIG_ARCH_MT7623"

#
# $1 - value
# $2 - proc path
#
write_proc() {
    [ -f $2 ] && {
        echo $1 > $2
        echo -n $1 ">" $2, "= "
        cat $2
    }
}


if [ $OPTIMIZED_FOR == "wifi" ]; then

    if [ $NUM_OF_CPU == "4" ]; then

        if [ "$CONFIG_RALINK_MT7621" = "y" ]; then
            write_proc 2 /proc/irq/3/smp_affinity  #GMAC
            write_proc 4 /proc/irq/4/smp_affinity  #PCIe0
            write_proc 8 /proc/irq/24/smp_affinity #PCIe1
            write_proc 8 /proc/irq/25/smp_affinity #PCIe2
            write_proc 8 /proc/irq/19/smp_affinity #VPN
            write_proc 8 /proc/irq/20/smp_affinity #SDXC
            write_proc 8 /proc/irq/22/smp_affinity #USB

            write_proc 3 /sys/class/net/ra0/queues/rx-0/rps_cpus
            write_proc 2 /sys/class/net/rai0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/apcli0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/apclii0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wds0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wds1/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wds2/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wds3/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wdsi0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wdsi1/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wdsi2/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/wdsi3/queues/rx-0/rps_cpus

            if [ "$wifiDomain1" == "$wifiDomain2" ]; then
                write_proc d /sys/class/net/eth0/queues/rx-0/rps_cpus
                write_proc d /sys/class/net/eth1/queues/rx-0/rps_cpus
                echo "eth0 RPS: CPU0/2/3"
            else
                if [ "$wifiDomain1" == "5G" ]; then
                    write_proc 9 /sys/class/net/eth0/queues/rx-0/rps_cpus
                    write_proc 9 /sys/class/net/eth1/queues/rx-0/rps_cpus
                    echo "eth0 RPS: CPU0/3"
                else
                    write_proc 5 /sys/class/net/eth0/queues/rx-0/rps_cpus
                    write_proc 5 /sys/class/net/eth1/queues/rx-0/rps_cpus
                    echo "eth0 RPS: CPU0/CPU2"
                fi
            fi
        elif [ "$CONFIG_ARCH_MT7623" = "y" ]; then
            write_proc 2 /proc/irq/232/smp_affinity    #GMAC
            write_proc 1 /proc/irq/231/smp_affinity     #GMAC
            write_proc 2 /proc/irq/230/smp_affinity     #GMAC
            write_proc 4 /proc/irq/225/smp_affinity    #PCIe0
            write_proc 8 /proc/irq/226/smp_affinity    #PCIe1
            write_proc 8 /proc/irq/227/smp_affinity    #PCIe2
            write_proc 8 /proc/irq/72/smp_affinity    #SDXC
            write_proc 8 /proc/irq/228/smp_affinity    #USB P0
            write_proc 8 /proc/irq/229/smp_affinity    #USB P1

            write_proc 3 /sys/class/net/ra0/queues/rx-0/rps_cpus
            write_proc 3 /sys/class/net/rai0/queues/rx-0/rps_cpus
            if [ "$wifiDomain1" == "$wifiDomain2" ]; then
                write_proc d /sys/class/net/eth0/queues/rx-0/rps_cpus
                write_proc d /sys/class/net/eth1/queues/rx-0/rps_cpus
                echo "eth0/eth1 RPS: CPU0/2/3"
            else
                if [ "$wifiDomain1" == "5G" ]; then
                    write_proc 9 /sys/class/net/eth0/queues/rx-0/rps_cpus
                    write_proc 9 /sys/class/net/eth1/queues/rx-0/rps_cpus
                    echo "eth0/eth1 RPS: CPU0/3"
                else
                    write_proc 5 /sys/class/net/eth0/queues/rx-0/rps_cpus
                    write_proc 5 /sys/class/net/eth1/queues/rx-0/rps_cpus
                    echo "eth0/eth1 RPS: CPU0/2"
                fi
            fi
        fi

    elif [ $NUM_OF_CPU == "2" ]; then

        if [ "$CONFIG_RALINK_MT7621" = "y" ]; then
            write_proc 2 /proc/irq/3/smp_affinity  #GMAC
            write_proc 1 /proc/irq/4/smp_affinity  #PCIe0
            write_proc 2 /proc/irq/24/smp_affinity #PCIe1
            write_proc 2 /proc/irq/25/smp_affinity #PCIe2
            write_proc 1 /proc/irq/19/smp_affinity #VPN
            write_proc 1 /proc/irq/20/smp_affinity #SDXC
            write_proc 1 /proc/irq/22/smp_affinity #USB

            write_proc 2 /sys/class/net/ra0/queues/rx-0/rps_cpus
            write_proc 1 /sys/class/net/rai0/queues/rx-0/rps_cpus
        elif [ "$CONFIG_ARCH_MT7623" = "y" ]; then
            write_proc 2 /proc/irq/232/smp_affinity    #GMAC
            write_proc 1 /proc/irq/225/smp_affinity    #PCIe0
            write_proc 2 /proc/irq/226/smp_affinity    #PCIe1
            write_proc 2 /proc/irq/227/smp_affinity    #PCIe2
            write_proc 1 /proc/irq/72/smp_affinity    #SDXC
            write_proc 1 /proc/irq/228/smp_affinity    #USB P0
            write_proc 1 /proc/irq/229/smp_affinity    #USB P1

            write_proc 2 /sys/class/net/ra0/queues/rx-0/rps_cpus
            write_proc 1 /sys/class/net/rai0/queues/rx-0/rps_cpus
        fi

        write_proc 2 /sys/class/net/eth0/queues/rx-0/rps_cpus
        write_proc 2 > /sys/class/net/eth1/queues/rx-0/rps_cpus
    fi

elif [ $OPTIMIZED_FOR == "storage" ]; then

    if [ $NUM_OF_CPU == "4" ]; then
        if [ "$CONFIG_RALINK_MT7621" = "y" ]; then
            write_proc 1 /proc/irq/3/smp_affinity  #GMAC Tx/Rx
            write_proc 2 /proc/irq/4/smp_affinity  #PCIe0
            write_proc 2 /proc/irq/24/smp_affinity #PCIe1
            write_proc 2 /proc/irq/25/smp_affinity #PCIe2
            write_proc 4 /proc/irq/19/smp_affinity #VPN
            write_proc 4 /proc/irq/20/smp_affinity #SDXC
            write_proc 4 /proc/irq/22/smp_affinity #USB
        elif [ "$CONFIG_ARCH_MT7623" = "y" ]; then
            write_proc 1 /proc/irq/231/smp_affinity     #GMAC Tx
            write_proc 2 /proc/irq/230/smp_affinity     #GMAC Rx
            write_proc 2 /proc/irq/232/smp_affinity    #GMAC Tx/Rx
            write_proc 4 /proc/irq/228/smp_affinity     #USB P0
            write_proc 4 /proc/irq/229/smp_affinity     #USB P1
            write_proc 4 /proc/irq/225/smp_affinity    #PCIe0
            write_proc 4 /proc/irq/226/smp_affinity    #PCIe1
            write_proc 4 /proc/irq/227/smp_affinity    #PCIe2
            write_proc 4 /proc/irq/72/smp_affinity    #SDXC
        fi

        write_proc 2 /sys/class/net/eth0/queues/rx-0/rps_cpus
        write_proc 2 /sys/class/net/eth1/queues/rx-0/rps_cpus
        write_proc 2 /sys/class/net/ra0/queues/rx-0/rps_cpus
        write_proc 2 /sys/class/net/rai0/queues/rx-0/rps_cpus
    elif [ $NUM_OF_CPU == "2" ]; then
        if [ "$CONFIG_RALINK_MT7621" = "y" ]; then
            write_proc 1 /proc/irq/3/smp_affinity  #GMAC
            write_proc 1 /proc/irq/4/smp_affinity  #PCIe0
            write_proc 1 /proc/irq/24/smp_affinity #PCIe1
            write_proc 1 /proc/irq/25/smp_affinity #PCIe2
            write_proc 1 /proc/irq/19/smp_affinity #VPN
            write_proc 1 /proc/irq/20/smp_affinity #SDXC
            write_proc 1 /proc/irq/22/smp_affinity #USB
            write_proc 1 /sys/class/net/eth0/queues/rx-0/rps_cpus
            #write_proc 1 /sys/class/net/eth1/queues/rx-0/rps_cpus
        elif [ "$CONFIG_ARCH_MT7623" = "y" ]; then
            write_proc 1 /proc/irq/228/smp_affinity     #USB
            write_proc 1 /proc/irq/229/smp_affinity     #USB
            write_proc 1 /proc/irq/230/smp_affinity     #GMAC
            write_proc 1 /proc/irq/231/smp_affinity     #GMAC
            write_proc 1 /proc/irq/232/smp_affinity    #GMAC
            write_proc 1 /proc/irq/225/smp_affinity    #PCIe0
            write_proc 1 /proc/irq/226/smp_affinity    #PCIe1
            write_proc 1 /proc/irq/227/smp_affinity    #PCIe2
            write_proc 1 /proc/irq/72/smp_affinity    #SDXC
            write_proc 1 /sys/class/net/eth0/queues/rx-0/rps_cpus
            write_proc 1 /sys/class/net/eth1/queues/rx-0/rps_cpus
        fi

        write_proc 1 /sys/class/net/ra0/queues/rx-0/rps_cpus
        write_proc 1 /sys/class/net/rai0/queues/rx-0/rps_cpus

    fi

else

    echo "unknow arguments!"
    exit 0

fi
