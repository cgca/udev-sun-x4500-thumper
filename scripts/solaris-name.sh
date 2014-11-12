#!/bin/bash

# AUTHOR: Tom Downes <thomas.downes@ligo.org>
# Wed, 12 Nov 2014 16:30:51 -0600
#
# This script accepts 1 or 2 arguments:
# $1 = DEVPATH as reported by "udevadm info /sys/block/sd[a-z]"
#      and provided by %p in a udev rule
# $2 = kernel number (udev %n) or partition number in table
#  
# It returns a single string of form c#t#d#{-part#} that
# uniquely identifies each disk by its controller and
# position within the controller. In addition, it is
# compatible with ZFS on linux pool creation.

# 1st argument to function: string you're looking for
# within the remaining arguments. Return 0-based
# position relative to beginning of remainder. 
function get_index () {
  devices=($@)
  for (( i = 1; i < ${#devices[@]}; i++ )); do
    if [ "${devices[$i]}" = "${devices[0]}" ]; then
      echo $(($i-1))
    fi
  done
}

# identify the controller (0-5)
pcidev=$(echo $1 | awk -F '/' '{print $5}')
allpcidev=$(find /sys/devices -regex '.*sd[a-z]+$' | awk -F '/' '{print $6}' | sort | uniq)
controller_id=$(get_index ${pcidev} ${allpcidev})

# identify this disk's position within the controller (0-7)
diskdev=$(echo $1 | awk -F '/' '{print $7}')
alldiskdev=$(find /sys/devices -regex '.*sd[a-z]+$' | grep "${pcidev}" | awk -F '/' '{print $8}' | sort | uniq)
disk_id=$(get_index ${diskdev} ${alldiskdev})

# print Solaris name to stdout for capture by udev 
if [ -n "$2" ]; then
  echo "c${controller_id}t${disk_id}d0-part$2"
else
  echo "c${controller_id}t${disk_id}d0"
fi
