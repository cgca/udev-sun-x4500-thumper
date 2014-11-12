#!/bin/bash

function get_index () {
  my_elt=$1
  my_array=($2)
  for (( i = 0; i < ${#my_array[@]}; i++ )); do
    if [ "${my_array[$i]}" = "${my_elt}" ]; then
      echo $i;
    fi
  done
}

pcidev=$(echo $1 | awk -F '/' '{print $5}')
allpcidev=($(find /sys/devices -regex '.*sd[a-z]+$' | awk -F '/' '{print $6}' | sort | uniq))

for (( i = 0; i < ${#allpcidev[@]}; i++ )); do 
  if [ "${allpcidev[$i]}" = "${pcidev}" ]; then
    controller_id=$i;
  fi
done

diskdev=$(echo $1 | awk -F '/' '{print $7}')
alldiskdev=($(find /sys/devices -regex '.*sd[a-z]+$' | grep "${pcidev}" | awk -F '/' '{print $8}' | sort | uniq))

for (( i = 0; i < ${#alldiskdev[@]}; i++ )); do 
  if [ "${alldiskdev[$i]}" = "${diskdev}" ]; then
    disk_id=$i;
  fi
done

if [ -n "$2" ]; then
  echo "c${controller_id}t${disk_id}d0-part$2"
else
  echo "c${controller_id}t${disk_id}d0"
fi
