#!/usr/bin/env bash

backup() {
  header=$1
  prompt=$2
  default_prefix=$3
  base_dir=$4
  backup_dir=$5
  files=$6
  find_pattern=$7

  if [ ! -d $backup_dir ]; then
    mkdir -p $backup_dir
  fi

  if [ -d $base_dir ]; then
    echo
    if [[ -n $files ]]; then
      echo "$header"
      echo "---------------------------"
      echo "$files"
      echo
      sleep 1 &
      wait
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
          filename="${default_prefix}_${VEHICLE}_${timestamp}.tar.gz"
          echo "Using default name: $filename"
        fi

        existing_backup_file=$(find $backup_dir -name "$filename")
        if [[ -n $existing_backup_file ]]; then
          read -p "A file with a matching name already exists. Overwrite? (y to overwrite, or Enter to choose a different name): " INP1
          if [[ $INP1 == 'y' ]]; then
            rm -f $backup_dir/$filename
          else
            echo
            continue
          fi
        fi

        echo
        echo "Creating backup $filename"
        echo "---------------------------"
        formatted_files=$(sed "s:$base_dir/::g" <<< $files)
        cd $base_dir
        tar -czvf $backup_dir/$filename $(ls latfiles_backup.txt rlogs_backup.txt 2>/dev/null) -T - <<< $formatted_files
        cd $backup_dir
        echo
        echo "Backup saved to $backup_dir/$filename"
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
}

process_backup_dir=/data/backups/nnlc-process
process_dir=/data/output/$VEHICLE
process_rlog_dir=/data/output/$VEHICLE/rlogs

review_backup_dir=/data/backups/nnlc-review
review_dir=/data/review/$VEHICLE

rlog_backup_dir=/data/backups/rlogs
rlog_dir=/data/rlogs/$VEHICLE

pattern_process_outputs="( -name *.csv -o -name *.feather -o -name *.txt -o -name *.png -o -wholename plots_torque/* -o -wholename *steer_cmd/* -o -wholename *torque_adjusted_eps/* )"
pattern_process_all="( -iname *.lat -o -name *.csv -o -name *.feather -o -name *.txt -o -name *.png -o -wholename plots_torque/* -o -wholename *steer_cmd/* -o -wholename *torque_adjusted_eps/* )"
pattern_review_plots="( -wholename *plots*/* -o -name *--*.png )"
pattern_latfiles="( -iname *.lat )"
pattern_rlogs="( -iname *.zst )"

while true; do
  cd ~
  files_process_outputs=$(find $process_dir -depth $pattern_process_outputs | sort -f)
  files_process_latfiles=$(find $process_dir -depth $pattern_latfiles | sort -f)
  files_process_all="$files_process_latfiles"$'\n'"$files_process_outputs" # force latfiles to top of list
  files_review_plots=$(find $review_dir -depth $pattern_review_plots | sort -f)
  files_rlogs=$(find $rlog_dir -depth $pattern_rlogs | sort -f)

  count_process_outputs=$(echo "$files_process_outputs" | grep . | wc -l )
  count_process_all=$(echo "$files_process_all" | grep . | wc -l )
  count_review_plots=$(echo "$files_review_plots" | grep . | wc -l )
  count_rlogs=$(echo "$files_rlogs" | grep . | wc -l )

  echo
  echo "NNLC-BACKUP"
  echo "---------------------------"
  echo "[1] nnlc-process processing outputs:                [$count_process_outputs] files"
  echo "[2] nnlc-process processing outputs w/ latfiles:    [$count_process_all] files"
  echo "[3] nnlc-review route plots:                        [$count_review_plots] files"
  echo "[4] rlog-import rlogs:                              [$count_rlogs] files"
  echo "[q] Quit"
  sleep 0 &
  wait
  read -p "Please select an option: " INP
  case $INP in
    [1])
      echo
      echo "Saving list of latfiles to latfiles_backup.txt"
      echo "$(find $process_dir -depth $pattern_latfiles | sort -f | sed 's:.*/::')" > "$process_dir/latfiles_backup.txt"
      echo

      echo "Saving list of rlogs to rlogs_backup.txt"
      echo "$(find $process_rlog_dir -depth $pattern_rlogs | sort -f | sed 's:.*/::')" > "$process_dir/rlogs_backup.txt"
      echo

      backup \
      "NNLC-PROCESS" \
      "nnlc-process processing outputs w/o latfiles" \
      "nnlc-process" \
      $process_dir \
      $process_backup_dir \
      "$files_process_outputs" \
      "$pattern_process_outputs"

      rm -f "$process_dir/latfiles_backup.txt" "$process_dir/rlogs_backup.txt" > /dev/null 2>&1
      ;;
    [2])
      echo
      echo "Saving list of latfiles to latfiles_backup.txt"
      echo "$(find $process_dir -depth $pattern_latfiles | sort -f | sed 's:.*/::')" > "$process_dir/latfiles_backup.txt"
      echo

      echo "Saving list of rlogs to rlogs_backup.txt"
      echo "$(find $process_rlog_dir -depth $pattern_rlogs | sort -f | sed 's:.*/::')" > "$process_dir/rlogs_backup.txt"
      echo

      backup \
      "NNLC-PROCESS W/ LATFILES" \
      "nnlc-process processing outputs w/ latfiles" \
      "nnlc-process-all" \
      $process_dir \
      $process_backup_dir \
      "$files_process_all" \
      "$pattern_process_all"

      rm -f "$process_dir/latfiles_backup.txt" "$process_dir/rlogs_backup.txt" > /dev/null 2>&1
      ;;
    [3])
      backup \
      "NNLC-REVIEW ROUTE PLOTS" \
      "nnlc-review route plots" \
      "nnlc-review" \
      $review_dir \
      $review_backup_dir \
      "$files_review_plots" \
      "$pattern_review_plots"
      ;;
    [4])
      backup \
      "RLOG-IMPORT RLOGS" \
      "rlog-import saved rlogs" \
      "rlog-import" \
      $rlog_dir \
      $rlog_backup_dir \
      "$files_rlogs" \
      "$pattern_rlogs"
      ;;
    [Qq])
      break
      ;;
    *)
      echo "Invalid response. Please select one of the listed options."
      ;;
  esac
done

echo
echo "Done!"
echo
exit 0