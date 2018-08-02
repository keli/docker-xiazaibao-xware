#!/bin/sh

# the script to be called by sysmonitor when network changed

# 1. stop the xzb_monitor/appmsh
/etc/init.d/appmsh stop

# 2. stop(restart) all relative process and service
/etc/init.d/nginxsh restart

# 3. start the monitor, let the monitor pull up all service which stopped
/etc/init.d/appmsh start

