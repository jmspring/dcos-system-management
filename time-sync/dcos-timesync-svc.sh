#!/bin/bash

while true; do
    NEED_SYNC=1

    which ntpstat >& /dev/null
    if [ $? -eq 0 ]; then
        ntpstat >& /dev/null
        if [ $? -eq 0 ]; then
            ntpstat | grep "synchronised to" >& /dev/null
            if [ $? -eq 0 ]; then
                ENABLE_CHECK_TIME=true /opt/mesosphere/bin/check-time |& grep "Time is in sync"
                if [ $? -eq 0 ]; then
                    NEED_SYNC=0
                fi
            fi
        fi
    fi

    if [ $NEED_SYNC -eq 1 ]; then
        sudo apt-get -y install ntp ntpstat
        sudo echo 2dd1ce17-079e-403c-b352-a1921ee207ee | sudo tee /sys/bus/vmbus/drivers/hv_util/unbind
        sudo sed -i "13i\echo 2dd1ce17-079e-403c-b352-a1921ee207ee > /sys/bus/vmbus/drivers/hv_util/unbind\n" /etc/rc.local
        sudo systemctl stop systemd-timesyncd
        sudo service ntp stop
        sudo ntpd -gq
        sudo service ntp start
        ENABLE_CHECK_TIME=true /opt/mesosphere/bin/check-time
        sudo systemctl disable systemd-timesyncd
        sudo systemctl enable ntp
    fi

    # sleep periodically to check
    sleep 30
done
