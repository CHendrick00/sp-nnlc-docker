#!/usr/bin/env bash

process_backup_dir=/data/backups/nnlc-process
process_dir=/data/output/$VEHICLE
process_rlog_dir=/data/output/$VEHICLE/rlogs

if [ ! -d $process_backup_dir ]; then
  mkdir -p $process_backup_dir
fi

# nnlc-process processing outputs
if [ -d $process_dir ]; then
  cd $process_dir
  echo
  process_files=$(find . -depth '(' -name "*.csv" -o -name "*.feather" -o -name "*.png" -o -wholename "plots_torque/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' -not -path "./review/*" -not -path "./plots_torque-/*"  | sort)
  lat_files=$(find . -depth '(' -name "*.lat" ')' -not -path "./review/*" | sort)
  files="$lat_files"$'\n'"$process_files" # force latfiles to top of list
  if [[ -n $files ]]; then
    echo "NNLC-PROCESS OUTPUTS"
    echo "---------------------------"
    echo "$files"
    echo
    cd $process_backup_dir
    while true; do
      read -p "Enter a custom backup name, or press Enter for default with timestamp: " INP
      if [[ -n $INP ]]; then
        if [[ $INP =~ [^a-zA-Z0-9_-] ]]; then
          echo "Filename contains invalid characters. Please provide a filename with no extension containing only letters, numbers, _, or -"
          echo
          continue
        fi
        filename="$INP.tar.gz"
        echo "Using filename: $filename"
      else
        timestamp=$(date -u "+%Y%m%dT%H%M%SZ")
        filename="nnlc-process_${VEHICLE}_${timestamp}.tar.gz"
        echo "Using default name: $filename"
      fi

      existing_backup_file=$(find . -name "$filename")
      if [[ -n $existing_backup_file ]]; then
        read -p "A file with a matching name already exists. Overwrite? (y to overwrite, or Enter to choose a different name): " INP1
        if [[ $INP1 == 'y' ]]; then
          rm -f $process_backup_dir/$filename
        else
          echo
          continue
        fi
      fi

      cd $process_dir
      echo
      echo "Saving list of latfiles to latfiles_backup.txt"
      echo $(find . '(' -name "*.lat" -o -name "*.LAT" ')' | sort) > "$process_dir/latfiles_backup.txt"
      echo

      cd $process_rlog_dir
      echo "Saving list of rlogs to rlogs_backup.txt"
      echo $(find . '(' -name "*.zst" -o -name "*.ZST" ')' | sort) > "$process_dir/rlogs_backup.txt"
      echo

      cd $process_dir
      read -p "Exclude .lat files? This results in a much smaller backup size, however you will not be able to recover the inputs for future processing. (y to exclude, or Enter to include): " INP1
      if [[ $INP1 == 'y' ]]; then
        echo
        echo "Creating backup"
        echo "---------------------------"
        tar -czvf $process_backup_dir/$filename *.csv *.feather *.png plots_torque *steer_cmd *torque_adjusted_eps
        echo
        echo "Backup saved to $process_backup_dir/$filename"
      else
        echo
        echo "Creating backup"
        echo "---------------------------"
        tar -czvf $process_backup_dir/$filename *.csv *.feather *.png plots_torque *steer_cmd *torque_adjusted_eps *.lat
        echo
        echo "Backup saved to $process_backup_dir/$filename"
      fi
      rm -f "$process_dir/latfiles_backup.txt" "$process_dir/rlogs_backup.txt"
      break
    done
  else
    echo
    echo "[$process_dir] doesn't contain any processing outputs. Nothing to do."
  fi
else
  echo
  echo "[$process_dir] doesn't exist. Nothing to do."
fi


echo
echo "Done!"
echo
exit 0