#!/usr/bin/env bash

OP=/data/output/$VEHICLE
OP_BACKUP=/data/backups/nnlc-process
RLD=/data/output/$VEHICLE/rlogs

if [ ! -d $OP_BACKUP ]; then
  mkdir -p $OP_BACKUP
fi

# nnlc-process processing outputs
if [ -d $OP ]; then
  cd $OP
  echo
  OUTFILES=$(find . -depth '(' -name "*.csv" -o -name "*.feather" -o -name "*.png" -o -wholename "plots_torque/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' -not -path "./review/*" -not -path "./plots_torque-/*"  | sort)
  LATFILES=$(find . -depth '(' -name "*.lat" ')' -not -path "./review/*" | sort)
  FILES="$LATFILES"$'\n'"$OUTFILES" # force latfiles to top of list
  if [[ -n $FILES ]]; then
    echo "NNLC-PROCESS OUTPUTS"
    echo "---------------------------"
    echo "$FILES"
    echo
    cd $OP_BACKUP
    while true; do
      read -p "Enter a custom backup name, or press Enter for default with timestamp: " INP
      if [[ -n $INP ]]; then
        if [[ $INP =~ [^a-zA-Z0-9_-] ]]; then
          echo "Filename contains invalid characters. Please provide a filename with no extension containing only letters, numbers, _, or -"
          echo
          continue
        fi
        FILENAME="$INP.tar.gz"
        echo "Using filename: $FILENAME"
      else
        TIMESTAMP=$(date -u "+%Y%m%dT%H%M%SZ")
        FILENAME="nnlc-process_${VEHICLE}_${TIMESTAMP}.tar.gz"
        echo "Using default name: $FILENAME"
      fi

      EXISTING_FILE=$(find . -name "$FILENAME")
      if [[ -n $EXISTING_FILE ]]; then
        read -p "A file with a matching name already exists. Overwrite? (y to overwrite, or Enter to choose a different name): " INP1
        if [[ $INP1 == 'y' ]]; then
          rm -f $OP_BACKUP/$FILENAME
        else
          echo
          continue
        fi
      fi

      cd $OP
      echo
      echo "Saving list of latfiles to latfiles_backup.txt"
      echo $(find . '(' -name "*.lat" -o -name "*.LAT" ')' | sort) > "$OP/latfiles_backup.txt"
      echo

      cd $RLD
      echo "Saving list of rlogs to rlogs_backup.txt"
      echo $(find . '(' -name "*.zst" -o -name "*.ZST" ')' | sort) > "$OP/rlogs_backup.txt"
      echo

      cd $OP
      read -p "Exclude .lat files? This results in a much smaller backup size, however you will not be able to recover the inputs for future processing. (y to exclude, or Enter to include): " INP1
      if [[ $INP1 == 'y' ]]; then
        echo
        echo "Creating backup"
        echo "---------------------------"
        tar -czvf $OP_BACKUP/$FILENAME *.csv *.feather *.png plots_torque *steer_cmd *torque_adjusted_eps
        echo
        echo "Backup saved to $OP_BACKUP/$FILENAME"
      else
        echo
        echo "Creating backup"
        echo "---------------------------"
        tar -czvf $OP_BACKUP/$FILENAME *.csv *.feather *.png plots_torque *steer_cmd *torque_adjusted_eps *.lat
        echo
        echo "Backup saved to $OP_BACKUP/$FILENAME"
      fi
      rm -f "$OP/latfiles_backup.txt" "$OP/rlogs_backup.txt"
      break
    done
  else
    echo
    echo "[$OP] doesn't contain any processing outputs. Nothing to do."
  fi
else
  echo
  echo "[$OP] doesn't exist. Nothing to do."
fi


echo
echo "Done!"
echo
exit 0