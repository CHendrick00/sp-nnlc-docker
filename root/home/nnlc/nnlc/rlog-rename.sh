#!/usr/bin/env bash

# Only use this script if you're manually copying rlogs from the comma device with the same directory structure.
# Files MUST be located under /data/rlogs/$VEHICLE/$DEVICE_ID/data/media/0/realdata
# Files will be renamed and placed in /data/rlogs/$VEHICLE/$DEVICE_ID

dirin="/data/rlogs/$VEHICLE/$DEVICE_ID/data/media/0/realdata"
if [[ ! -d $dirin ]]; then
  echo "Directory $dirin not found. Please make sure you have copied to the correct"
fi

dirout="/data/rlogs/$VEHICLE/$DEVICE_ID"

check_dir="$dirin"
cd "$check_dir"
check_list=$(find . -maxdepth 0 -name "*rlog*")

fetch_rlogs () {
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

    echo "$1 ($2): Fetching list of candidate files to be transferred"
    # get list of files to be transferred
    remotefilelist=$(bash -c "if find / -maxdepth 0 -printf \"\" 2>/dev/null; then
        nice -19 find \"$dirin\" -name \"*rlog*\" -printf \"%T@ %Tc ;;%p\n\" | sort -n | sed 's/.*;;//'
      elif stat --version | grep -q 'GNU coreutils'; then
        nice -19 find \"$dirin\" -name \"*rlog*\" -exec stat -c \"%Y %y %n\" {} \; | sort -n | cut -d ' ' -f 5-
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

    fileliststr=""
    for f in $remotefilelist; do
      fstr="${f#$dirin/}" # strip off the input directory
      if [[ $fstr == *.zst ]]; then
        route="${fstr%%/rlog.zst}"
      else
        route="${fstr%%/rlog}"
      fi
      ext="${fstr#$route/}"
      lfn="$dirout/$DEVICE_ID"_"$route"--"$ext"
      lfnbase="$dirout/$DEVICE_ID"_"$route"--rlog

      if [[ "$f" != *.zst ]] && [[ -f "$lfnbase".zst ]] ; then
        skipped=$((skipped+1))
        continue
      elif [[ "$check_list" == *"$route"* ]] || [ -f "$lfnbase" ] || [ -f "$lfnbase".zst ]; then
        fileliststr+="$f $lfn"
        fileliststr+=$'\n'
        r=$((r+1))
      else
        fileliststr+="$f $lfn"
        fileliststr+=$'\n'
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
      while IFS= read -r line; do
        if [[ -n $line ]]; then
          echo "Copying: "$line
          rsync -avP --dry-run $line >/dev/null
        fi
      done <<< "$fileliststr"
      echo "$1 ($2): Transfer complete (returned $?)"
    fi
  done

  return 0
}

echo "Beginning device rlog fetch for $d"
fetch_rlogs $d &
sleep 30

echo "zipping any unzipped rlogs"
find "$dirout" -not -path '*/\.*' -type f -name "*rlog" -print -exec zstd -f --verbose {} \;

echo "Done"