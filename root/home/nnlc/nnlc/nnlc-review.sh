#!/usr/bin/env bash

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# bail on nonzero RC function
bail_on_error() {
  RC=$?
  if [ $RC -ne 0 ]; then
    echo
    echo "*** bailing with RC=$RC"
    echo
    exit 1
  fi
}

if [[ ! -n $VEHICLE ]]; then
  echo "Required environment variable VEHICLE not set. Cannot continue."
  exit 1
fi

# Set directory to folder where the project
# assets like sunnypilot and OP_ML_FF dirs are
cd /home/nnlc/nnlc

# activate nnlc env
. /home/nnlc/.bash_functions
conda activate nnlc

# set variables for required operating directories
tools_dir=/home/nnlc/nnlc
process_dir=/data/output/$VEHICLE
review_dir=/data/review/$VEHICLE
rlog_source_dir=/data/rlogs/$VEHICLE
review_rlog_dir=$review_dir/rlogs
review_rlog_route_dir=$review_dir/rlogs_route

# Create directories if they don't exist
if [[ ! -d $review_rlog_dir ]]; then
  mkdir -p $review_rlog_dir
fi
if [[ ! -d $review_rlog_route_dir ]]; then
  mkdir -p $review_rlog_route_dir
fi

echo
echo "Copying/updating rlog.zst files from $rlog_source_dir to $review_rlog_dir..."
echo
rsync --mkpath -avh --prune-empty-dirs --info=progress2 --include '*rlog.zst' $rlog_source_dir/ $review_rlog_dir
bail_on_error

echo
echo "Preprocessing rlogs in $review_rlog_dir..."
echo

cd $tools_dir/sunnypilot
# Update hardcoded paths on processing and training scripts
## Updating from original
sed -i "s:home, 'Downloads':'/$review_dir':g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:~/Downloads:$review_dir:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:os.path.join(os.path.expanduser('~'), 'Downloads/rlogs/output/'):'/data/output/$VEHICLE/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s: and has_upper_word(dir_name)::g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\"GENESIS\":\"review\":g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

## Updating from after running nnlc-process
sed -i "s:$process_dir:$review_dir:g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:$process_dir/plots:$review_dir/plots:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:$process_dir/':$review_dir/':g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:'/data/output/':'/data/output/$VEHICLE/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\"$VEHICLE\":\"review\":g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

# Generate list of routes
cd $review_rlog_dir
for logfile in $(find . -depth -name "*--rlog.zst")
do
  echo $logfile | sed -E 's/--[0-9]+--rlog.zst//g' | sed -E 's/[./a-zA-Z0-9]*_//g'
done |
sort |
uniq > "$review_dir/routes.txt"

# Cleanup from previous runs
rm -r $review_rlog_route_dir/*.zst $review_dir/*.lat $review_dir/*.csv $review_dir/*.feather $review_dir/latfiles.txt $review_dir/plots $review_dir/plots_torque > /dev/null 2>&1

cd $tools_dir/sunnypilot
while IFS= read -r line; do
  cp $(echo $(find $review_rlog_dir -depth -name "*$line*--rlog.zst")) $review_rlog_route_dir

  sed -i 's/PREPROCESS_ONLY = False/PREPROCESS_ONLY = True/' tools/tuning/lat_settings.py > /dev/null 2>&1
  PYTHONPATH=. tools/tuning/lat.py --path $review_rlog_route_dir --outpath $review_dir
  bail_on_error

  # Check if any lat files were generated from the logs
  lat_count=`ls -1 $review_dir/*.lat 2>/dev/null | wc -l`
  if [ $lat_count != 0 ]; then
    echo
    echo "Processing step 1..."
    echo

    sed -i 's/PREPROCESS_ONLY = True/PREPROCESS_ONLY = False/' tools/tuning/lat_settings.py > /dev/null 2>&1
    PYTHONPATH=. tools/tuning/lat.py --path $review_dir --outpath $review_dir
    bail_on_error

    echo
    echo "Processing step 2..."
    echo

    tools/tuning/lat_to_csv_torquennd.py
    bail_on_error
  else
    echo "No valid .lat files generated from route: $line"
  fi

  route_name="${line/|/_}" ## XX: May not be needed anymore
  mv "$review_dir/review lat_accel_vs_torque.png" "$review_dir/$route_name-lat_accel_vs_torque.png"
  rm $review_dir/$route_name-plots_torque > /dev/null 2>&1
  mv $review_dir/plots_torque $review_dir/$route_name-plots_torque
  rm $review_rlog_route_dir/*.zst $review_dir/*.lat $review_dir/*.csv $review_dir/*.feather $review_dir/latfiles.txt > /dev/null 2>&1

done < "$review_dir/routes.txt"

echo
echo "Done!"
echo
exit 0