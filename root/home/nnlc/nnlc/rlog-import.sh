#!/usr/bin/env bash

# Copies all rlog files from your comma device, over LAN or comma SSH,
# to the specified local directory.
# devicehostname must match a defined ssh host setup for passwordless access using ssh keys
# You can prevent redundant transfers in two ways:
# If the to-be-transferred rlog already exists in the destination
# it will not be transferred again, so you can use the same directory
# and leave the files there

# Load environment variables if running from cron
. /home/nnlc/nnlc.env 2>&1

#=============================================
# MODIFY THESE
diroutbase="/data/rlogs"
# EACH LINE OF `device_car_list` is an ssh host followed by a subfolder name to be created within `diroutbase`
device_car_list=(
"comma $VEHICLE"
)
#=============================================
if [[ ! -d $diroutbase ]]; then
  echo "Creating $diroutbase"
  mkdir $diroutbase
fi

check_dir="$diroutbase"
cd "$check_dir"
check_list=$(find . -name "*rlog*")

fetch_rlogs () {
  echo "$1 ($2): Fetching dongle ID"
  devicehostname="$1"
  DONGLEID=`ssh $devicehostname cat /data/params/d/DongleId`
  if [ $? -ne 0 ]; then
    echo "$1 ($2): device not online..."
    return 1
  fi
  isoffroad=`ssh $devicehostname cat /data/params/d/IsOffroad`
  if [ $isoffroad -ne 1 ]; then
    echo "$1 ($2): skipping: *** DEVICE IS ONROAD ***"
    return
  fi

  # Don't need to check below as docker container should be running on bridge network mode

  # output=$(ifconfig)
  # if echo "$output" | grep -q "netmask"; then
  #   if ! echo "$output" | grep -Eq "inet (10\.0\.|10\.1\.|192\.168\.|200\.200\.)"; then
  #     echo "Not connected to home WiFi."
  #     return
  #   else
  #     echo "Connected to home WiFi"
  #   fi
  # else
  #   echo "ifconfig command did not run correctly."
  #   return
  # fi

  dirout="$diroutbase/$2/$DONGLEID"
  delete_transferred_files=false

  # NO TOUCHING
  devicedirin="/data/media/0/realdata"
  i=1
  r=1
  iter=0
  tot=0
  r_old=0
  while [ $i -gt 0 ] || [ $r -ne $r_old ]; do
    r_old=$r
    i=0
    r=0
    skipped=0
    iter=$((iter + 1))

    echo "$1 ($2): Starting copy of rlogs from device (dongleid $DONGLEID; iteration $iter) to $dirout"

    echo "$1 ($2): Fetching list of candidate files to be transferred"
    # get list of files to be transferred
    remotefilelist=$(ssh $devicehostname "if find / -maxdepth 0 -printf \"\" 2>/dev/null; then
        nice -19 find \"$devicedirin\" -name \"*rlog*\" -printf \"%T@ %Tc ;;%p\n\" | sort -n | sed 's/.*;;//'
      elif stat --version | grep -q 'GNU coreutils'; then
        nice -19 find \"$devicedirin\" -name \"*rlog*\" -exec stat -c \"%Y %y %n\" {} \; | sort -n | cut -d ' ' -f 5-
      else
        echo \"Neither -printf nor GNU coreutils stat is available\" >&2
        exit 1
      fi")

    if [ $? -eq 0 ]; then
      mkdir -p "$dirout"
    else
      echo "$1 ($2): $remotefilelist"
      break
    fi

    echo "$1 ($2): Check for duplicate files"

    fileliststr="
    "
    for f in $remotefilelist; do
      fstr="${f#$devicedirin/}" # strip off the input directory
      if [[ $fstr == *.zst ]]; then
        route="${fstr%%/rlog.zst}"
      else
        route="${fstr%%/rlog}"
      fi
      ext="${fstr#$route/}"
      lfn="$dirout/$DONGLEID"_"$route"--"$ext"
      lfnbase="$dirout/$DONGLEID"_"$route"--rlog

      if [[ "$f" != *.zst ]] && [[ -f "$lfnbase".zst ]] ; then
        skipped=$((skipped+1))
        continue
      elif [[ "$check_list" == *"$route"* ]] || [ -f "$lfnbase" ] || [ -f "$lfnbase".zst ]; then
        fileliststr="$fileliststr get -a \"$f\" \"$lfn\"
        "
        r=$((r+1))
      else
        fileliststr="$fileliststr get \"$f\" \"$lfn\"
        "
        i=$((i+1))
      fi
    done

    if [ $r -eq $r_old ]; then
      return 0
    fi

    echo "$1 ($2): Total transfers: $((i+r)) = $i new + $r resumed"
    echo "$1 ($2): Skipped transfers: $skipped"
    tot=$((tot + i))

    # perform transfer
    if [[ $i -gt 0  || ( $r -gt 0 && $r -ne $r_old ) ]]; then
      echo "$1 ($2): Beginning transfer"
      sftp -C $devicehostname << EOF
"$fileliststr"

EOF
      echo "$1 ($2): Transfer complete (returned $?)"
    fi
  done

  return 0
}

for d in "${device_car_list[@]}"; do
  echo "Beginning device rlog fetch for $d"
  fetch_rlogs $d &
  sleep 30
done
wait

echo "zipping any unzipped rlogs"
find "$diroutbase" -not -path '*/\.*' -type f -name "*rlog" -print -exec zstd -f --verbose {} \;

echo "Done"