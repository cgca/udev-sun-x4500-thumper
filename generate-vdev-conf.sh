#!/bin/sh

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

declare -A slot_map=( \
["c3t0"]="00" \
["c3t4"]="01" \
["c2t0"]="02" \
["c2t4"]="03" \
["c5t0"]="04" \
["c5t4"]="05" \
["c4t0"]="06" \
["c4t4"]="07" \
["c1t0"]="08" \
["c1t4"]="09" \
["c0t0"]="10" \
["c0t4"]="11" \
["c3t1"]="12" \
["c3t5"]="13" \
["c2t1"]="14" \
["c2t5"]="15" \
["c5t1"]="16" \
["c5t5"]="17" \
["c4t1"]="18" \
["c4t5"]="19" \
["c1t1"]="20" \
["c1t5"]="21" \
["c0t1"]="22" \
["c0t5"]="23" \
["c3t2"]="24" \
["c3t6"]="25" \
["c2t2"]="26" \
["c2t6"]="27" \
["c5t2"]="28" \
["c5t6"]="29" \
["c4t2"]="30" \
["c4t6"]="31" \
["c1t2"]="32" \
["c1t6"]="33" \
["c0t2"]="34" \
["c0t6"]="35" \
["c3t3"]="36" \
["c3t7"]="37" \
["c2t3"]="38" \
["c2t7"]="39" \
["c5t3"]="40" \
["c5t7"]="41" \
["c4t3"]="42" \
["c4t7"]="43" \
["c1t3"]="44" \
["c1t7"]="45" \
["c0t3"]="46" \
["c0t7"]="47" )

alldisks=($(find /sys/devices -regex '.*sd[a-z]+$' -exec basename {} \;))

# count controllers
n_controllers=$(find /sys/devices -regex '.*sd[a-z]+$' | awk -F '/' '{print $6}' | sort | uniq | wc -)

# count disks
n_disks=$(find /sys/devices -regex '.*sd[a-z]+$' | awk -F '/' '{print $10}' | awk -F ':' '{print $1}' | sort -g | wc -l)

if [ n_controllers -ne 6 && n_disks -ne 48]; then
  echo "The correct number of controllers and disks are not present!"
  exit 1
fi

for disk in "${alldisks[@]}"; do
  # info unique to this disk
  devpath=$(udevadm info --query=path /sys/block/$disk)
  wwn=$(udevadm info --query=symlink /sys/block/$disk | grep wwn | awk '{for (i=1;i<=NF;i++) {if ($i ~/wwn/) {print $i}}}' | awk -F '/' '{print $3}')

  # identify the controller
  pcidev=$(echo ${devpath} | awk -F '/' '{print $5}')
  allpcidev=$(find /sys/devices -regex '.*sd[a-z]+$' | awk -F '/' '{print $6}' | sort | uniq)
  controller_id=$(get_index ${pcidev} ${allpcidev})

  #identify the disk
  diskdev=$(echo ${devpath} | awk -F '/' '{print $9}' | awk -F ':' '{print $1}')
  alldiskdev=$(find /sys/devices -regex '.*sd[a-z]+$' | grep "${pcidev}" | awk -F '/' '{print $10}' | awk -F ':' '{print $1}' | sort -g)
  disk_id=$(get_index ${diskdev} ${alldiskdev})

  # figure out the mapping of this disk to slot number
  slot_id=${slot_map[c${controller_id}t${disk_id}]}

  # create a good alias file that relies on unique identifications of the disk
  echo alias c${controller_id}t${disk_id}slot${slot_id} ${wwn} 
done
