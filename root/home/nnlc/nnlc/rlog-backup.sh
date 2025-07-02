#!/usr/bin/env bash

rlog_source_dir=/data/rlogs/$VEHICLE
rlog_backup_dir=/data/backups/rlogs/$VEHICLE

if [ ! -d $rlog_backup_dir ]; then
  mkdir -p $rlog_backup_dir
fi

# nnlc-process processing outputs
if [ -d $rlog_source_dir ]; then
  cd $rlog_source_dir
  echo
  files=$(find . -depth '(' -name "*.zst" ')' | sort)
  if [[ -n $files ]]; then
    echo "RLOGS"
    echo "---------------------------"
    echo "$files"
    echo
    cd $rlog_backup_dir
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
        filename="rlogs_${VEHICLE}_${timestamp}.tar.gz"
        echo "Using default name: $filename"
      fi

      existing_backup_file=$(find . -name "$filename")
      if [[ -n $existing_backup_file ]]; then
        read -p "A file with a matching name already exists. Overwrite? (y to overwrite, or Enter to choose a different name): " INP1
        if [[ $INP1 == 'y' ]]; then
          rm -f $rlog_backup_dir/$filename
        else
          echo
          continue
        fi
      fi

      cd $rlog_source_dir
      echo
      echo "Creating backup"
      echo "---------------------------"
      tar -czvf $rlog_backup_dir/$filename *.zst
      echo
      echo "Backup saved to $rlog_backup_dir/$filename"
      break
    done
  else
    echo
    echo "[$rlog_source_dir] doesn't contain any processing outputs. Nothing to do."
  fi
else
  echo
  echo "[$rlog_source_dir] doesn't exist. Nothing to do."
fi


echo
echo "Done!"
echo
exit 0