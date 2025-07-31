#!/usr/bin/env bash

clean() {
  header=$1
  prompt=$2
  base_dir=$3
  files=$4
  find_pattern=$5

  echo
  if [ ! -d $base_dir ]; then
    echo
    echo "[$base_dir] doesn't exist. Nothing to do."
    echo
  elif [[ ! -n $files ]]; then
    echo
    echo "[$base_dir] already clean. Nothing to do."
    echo
  else
    echo $header
    echo "---------------------------"
    files_cleaned=$(echo "$files" | sed "s:/$base_dir/::")
    echo "$files_cleaned"
    echo
    sleep 1 &
    wait
    while true; do
      read -p "Clean $prompt? This action is irreversable. (y/n): " INP
      case $INP in
        [Yy])
          echo
          rm -f $files > /dev/null 2>&1
          empty_dirs=$(find $base_dir -mindepth 1 -type d -empty | sed "s:$base_dir/:./:")
          cd $base_dir
          rmdir -P $empty_dirs --parents --ignore-fail-on-non-empty > /dev/null 2>&1
          cd /home/nnlc/setup # random safe dir
          count_post=$(find $base_dir -depth -type f $find_pattern | wc -l)
          if [[ $count_post -gt 0 ]]; then
            echo "An error occurred and [$count_post] files could not be deleted. Please clean [$base_dir] manually."
          else
            echo "[$base_dir] cleaned."
          fi
        break;;
        [Nn])
          echo
          echo "Skipping [$base_dir]..."
          echo
          echo
          break;;
        *)
        echo
        echo "Invalid response. Please answer y or n."
        sleep 0 &
        wait
        ;;
      esac
    done
  fi
}

process_dir=/data/output/$VEHICLE
process_rlog_dir=$process_dir/rlogs/$DEVICE_ID
review_dir=/data/review/$VEHICLE
review_rlog_dir=$review_dir/rlogs/$DEVICE_ID
review_rlog_route_dir=$review_dir/rlogs_route

pattern_process_outputs="( -iname *.lat -o -name *.csv -o -name *.feather -o -name *.txt -o -name *.png -o -wholename plots*/* -o -wholename *steer_cmd/* -o -wholename *torque_adjusted_eps/* )"
pattern_review_outputs="( -iname *.lat -o -name *.csv -o -name *.feather -o -name *.txt -o -name *.png -o -wholename plots*/* ) -not -path $VEHICLE-plots_torque/* -not -path $VEHICLE-torque_vs_lat_accel/*"
pattern_review_plots="( -wholename $VEHICLE-plots_torque/* -o -wholename $VEHICLE-torque_vs_lat_accel/* )"
pattern_rlogs="( -iname *.zst )"


while true; do
  files_process_outputs=$(find $process_dir -depth $pattern_process_outputs | sort -f)
  files_process_rlogs=$(find $process_rlog_dir -depth $pattern_rlogs | sort -f)
  files_review_outputs=$(find $review_dir -depth $pattern_review_outputs | sort -f)
  files_review_rlogs=$(find $review_rlog_dir -depth $pattern_rlogs | sort -f)
  files_review_rlogs_route=$(find $review_rlog_route_dir -depth $pattern_rlogs | sort -f)
  files_review_plots=$(find $review_dir -depth $pattern_review_plots | sort -f)

  count_process_outputs=$(echo "$files_process_outputs" | grep . | wc -l )
  count_process_rlogs=$(echo "$files_process_rlogs" | grep . | wc -l )
  count_review_outputs=$(echo "$files_review_outputs" | grep . | wc -l )
  count_review_rlogs=$(echo "$files_review_rlogs" | grep . | wc -l )
  count_review_rlogs_route=$(echo "$files_review_rlogs_route" | grep . | wc -l )
  count_review_plots=$(echo "$files_review_plots" | grep . | wc -l )

  echo
  echo "NNLC-CLEAN"
  echo "---------------------------"
  echo "[1] nnlc-process processing outputs and lat files:    [$count_process_outputs] files"
  echo "[2] nnlc-process cached rlogs:                        [$count_process_rlogs] files"
  echo "[3] nnlc-review processing outputs and lat files:     [$count_review_outputs] files"
  echo "[4] nnlc-review cached rlogs:                         [$(($count_review_rlogs+$count_review_rlogs_route))] files"
  echo "[5] nnlc-review route plots:                          [$count_review_plots] files"
  echo "[q] Quit"
  sleep 0 &
  wait
  read -p "Please select an option: " INP
  case $INP in
    [1])
      # nnlc-process processing outputs and lat files
      clean \
      "NNLC-PROCESS OUTPUTS" \
      "nnlc-process processing outputs and lat files" \
      $process_dir \
      "$files_process_outputs" \
      "$pattern_process_outputs"
      ;;
    [2])
      clean \
      "NNLC-PROCESS RLOGS" \
      "nnlc-process cached rlogs" \
      $process_rlog_dir \
      "$files_process_rlogs" \
      "$pattern_rlogs"
      ;;
    [3])
      clean \
      "NNLC-REVIEW OUTPUTS" \
      "nnlc-review processing outputs and lat files" \
      $review_dir \
      "$files_review_outputs" \
      "$pattern_review_outputs"
      ;;
    [4])
      clean \
      "NNLC-REVIEW RLOGS" \
      "nnlc-process cached rlogs" \
      $review_rlog_dir \
      "$files_review_rlogs" \
      "$pattern_rlogs"

      clean \
      "NNLC-REVIEW ROUTE RLOGS" \
      "nnlc-process cached route rlogs" \
      $review_rlog_route_dir \
      "$files_review_rlogs_route" \
      "$pattern_rlogs"
      ;;
    [5])
      clean \
      "NNLC-REVIEW ROUTE PLOTS" \
      "nnlc-review route plots" \
      $review_dir \
      "$files_review_plots" \
      "$pattern_review_plots"
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