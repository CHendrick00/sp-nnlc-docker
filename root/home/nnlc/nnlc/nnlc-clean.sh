#!/usr/bin/env bash

process_dir=/data/output/$VEHICLE
process_rlog_dir=$process_dir/rlogs/$DEVICE_ID
review_dir=/data/review/$VEHICLE
review_rlog_dir=$review_dir/rlogs/$DEVICE_ID
review_rlog_route_dir=$review_dir/rlogs_route

# nnlc-process processing outputs
if [ -d $process_dir ]; then
  cd $process_dir
  echo
  files=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' | sort)
  if [[ -n $files ]]; then
    echo "NNLC-PROCESS OUTPUTS"
    echo "---------------------------"
    echo "$files"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean nnlc-process outputs directory? This action is irreversable. (y/n) " INP
      case $INP in
          [Yy])
            echo
            rm -rf $process_dir/*.lat $process_dir/*.LAT $process_dir/*.csv $process_dir/*.feather $process_dir/*.txt $process_dir/*.png $process_dir/plots* $process_dir/*steer_cmd $process_dir/*torque_adjusted_eps
            files=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" -o -wholename "plots*/*" -o -wholename "*steer_cmd/*" -o -wholename "*torque_adjusted_eps/*" ')' | sort)
            if [[ -n $files ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$process_dir] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$process_dir]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$process_dir] already clean. Nothing to do."
  fi
else
  echo
  echo "[$process_dir] doesn't exist. Nothing to do."
fi

# nnlc-process processing rlogs
if [ -d $process_rlog_dir ]; then
  cd $process_rlog_dir
  echo
  files=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
  if [[ -n $files ]]; then
    echo "NNLC-PROCESS RLOGS"
    echo "---------------------------"
    echo "$files"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean rlogs in nnlc-process processing directory? This action is irreversable. (y/n) " INP
      case $INP in
          [Yy])
            echo
            rm -rf $process_rlog_dir/*.zst $process_rlog_dir/*.ZST
            files=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' | sort)
            if [[ -n $files ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$process_rlog_dir] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$process_rlog_dir]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$process_rlog_dir] already clean. Nothing to do."
  fi
else
  echo
  echo "[$process_rlog_dir] doesn't exist. Nothing to do."
fi

# nnlc-review route plots
if [ -d $review_dir ]; then
  cd $review_dir
  echo
  files=$(find . -depth '(' -wholename "plots*/*" ')' | sort)
  if [[ -n $files ]]; then
    echo "NNLC-REVIEW ROUTE PLOTS"
    echo "---------------------------"
    echo "$files"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean nnlc-review output plots? This action is irreversable. (y/n) " INP
      case $INP in
          [Yy])
            echo
            rm -rf $review_dir/*plots*
            files=$(find . -depth '(' -wholename "*plots*/*" ')' | sort)
            if [[ -n $files ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$review_dir] cleaned of plots."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$review_dir]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$review_dir] already clean of plots. Nothing to do."
  fi
else
  echo
  echo "[$review_dir] doesn't exist. Nothing to do."
fi

# The below 2 should generally never have files present unless nnlc-review failed or was stopped before completing.

# nnlc-review processing outputs
if [ -d $review_dir ]; then
  cd $review_dir
  echo
  files=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" ')' | sort)
  if [[ -n $files ]]; then
    echo "NNLC-REVIEW OUTPUTS"
    echo "---------------------------"
    echo "$files"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean nnlc-review outputs directory? This action is irreversable. (y/n) " INP
      case $INP in
          [Yy])
            echo
            rm -rf $review_dir/*.lat $review_dir/*.LAT $review_dir/*.csv $review_dir/*.feather $review_dir/*.txt $review_dir/*.png
            files=$(find . -depth '(' -name "*.lat" -o -name "*.LAT" -o -name "*.csv" -o -name "*.feather" -o -name "*.txt" -o -name "*.png" ')' | sort)
            if [[ -n $files ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$review_dir] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$review_dir]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$review_dir] already clean. Nothing to do."
  fi
else
  echo
  echo "[$review_dir] doesn't exist. Nothing to do."
fi

# nnlc-review processing rlogs
if [ -d $review_rlog_dir ] || [ -d $review_rlog_route_dir ]; then
  echo
  cd $review_dir
  files=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' -path "$review_rlog_dir/*" -path "$review_rlog_route_dir/*"  | sort)
  if [[ -n $files ]]; then
    echo "NNLC-REVIEW RLOGS"
    echo "---------------------------"
    echo "$files"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean rlogs in nnlc-review processing directory? This action is irreversable. (y/n) " INP
      case $INP in
          [Yy])
            echo
            rm -rf $review_rlog_route_dir/*.zst $review_rlog_route_dir/*.ZST $review_rlog_dir/*.zst $review_rlog_dir/*.ZST
            files=$(find . -depth '(' -name "*.zst" -o -name "*.ZST" ')' -path "$review_rlog_dir/*" -path "$review_rlog_route_dir/*"  | sort)
            if [[ -n $files ]]; then
              echo "An error occurred and some or all files could not be deleted. Please clean this directory manually."
            else
              echo "[$review_rlog_dir] and [$review_rlog_route_dir] cleaned."
            fi
            break;;
          [Nn])
            echo
            echo "Skipping [$review_rlog_dir] and [$review_rlog_route_dir]..."
            break;;
          *)
            echo "Invalid response. Please answer y or n.";;
      esac
    done
  else
    echo
    echo "[$review_rlog_dir] and [$review_rlog_route_dir] already clean. Nothing to do."
  fi
else
  echo
  echo "[$review_rlog_dir] and [$review_rlog_route_dir] don't exist. Nothing to do."
fi

echo
echo "Done!"
echo
exit 0