#!/bin/sh

if [ -e /tmp/smb.flag ];
then
  smp.sh storage
else
  smp.sh wifi
fi

