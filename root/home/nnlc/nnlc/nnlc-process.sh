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

if [[ ! -n $VEHICLE ]] || [[ ! -n $DEVICE_ID ]]; then
  echo "Required environment variables VEHICLE and/or DEVICE_ID not set. Cannot continue."
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
process_rlog_dir=$process_dir/rlogs/$DEVICE_ID
review_dir=/data/review/$VEHICLE
rlog_source_dir=/data/rlogs/$VEHICLE/$DEVICE_ID

# Create directories if they don't exist
if [ ! -d $process_rlog_dir ]; then
  mkdir -p $process_rlog_dir
  bail_on_error
fi

echo
echo "Copying/updating rlog.zst files from $rlog_source_dir to $process_rlog_dir..."
echo
cd $rlog_source_dir
ls -1f *.zst | while read source_file; do
  new_filename="${source_file/_/|}"
  new_file="$process_rlog_dir/$new_filename"
  if [ ! -s $new_file ]; then
    ln -v $source_file $new_file
    bail_on_error
  fi
done

echo
echo "Preprocessing rlogs in $process_rlog_dir..."
echo

# Archive previous plots_torque
plots_dir=$process_dir/plots_torque
if [ -d $plots_dir ]; then
  rm -rf ${plots_dir}-
  mv $plots_dir ${plots_dir}-
fi
bail_on_error

cd $tools_dir/sunnypilot
# Update hardcoded paths on processing and training scripts
## Updating from original
sed -i "s:home, 'Downloads':'/$process_dir':g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:~/Downloads:$process_dir:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:os.path.join(os.path.expanduser('~'), 'Downloads/rlogs/output/'):'/data/output/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s: and has_upper_word(dir_name)::g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\"GENESIS\":\"$VEHICLE\":g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\$home_dir/Downloads/rlogs/output/GENESIS:/$process_dir:g" $tools_dir/OP_ML_FF/latmodel_temporal.jl > /dev/null 2>&1

## Updating from after running nnlc-review
sed -i "s:$review_dir:$process_dir:g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:$review_dir/plots:$process_dir/plots:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:$review_dir/':$process_dir/':g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:'/data/review/':'/data/output/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

# Begin processing
sed -i 's/PREPROCESS_ONLY = False/PREPROCESS_ONLY = True/' tools/tuning/lat_settings.py > /dev/null 2>&1
PYTHONPATH=. tools/tuning/lat.py --path $process_rlog_dir --outpath $process_dir
bail_on_error

echo
echo "Processing step 1..."
echo

sed -i 's/PREPROCESS_ONLY = True/PREPROCESS_ONLY = False/' tools/tuning/lat_settings.py > /dev/null 2>&1
PYTHONPATH=. tools/tuning/lat.py --path $process_dir --outpath $process_dir
bail_on_error

echo
echo "Processing step 2..."
echo

tools/tuning/lat_to_csv_torquennd.py
bail_on_error

echo
echo "Before proceeding with training, please review [$VEHICLE lat_accel_vs_torque.png] and validate that the data is well-represented across all speed bands and torque levels."
echo "Additionally, pay special attention to the driver torque events in columns 3 and 5, especially at higher speeds. An excessive amount of data in these columns may lead to irregular driving behavior."
echo "For an example of a good [$VEHICLE lat_accel_vs_torque.png] plot, see https://github.com/sunnypilot/sunnypilot/pull/925."
echo -n "After reviewing, press Enter to continue with training, or Ctrl-C to exit: "
read INP

echo "Checking for available GPUs"
if (command -v nvidia-smi) >/dev/null 2>&1 && (nvidia-smi -q | grep 'Attached GPUs') >/dev/null 2>&1; then
  echo "Supported NVIDIA GPU found."
  echo
  nvidia-smi -q | grep 'Attached GPUs'
  echo 
  nvidia-smi
  echo
else 
  echo "NVIDIA GPU (nvidia-smi) not found."
  echo "Training cannot be performed. Aborting..."
  exit 1
fi

echo
cd $process_dir
# Set CUDA runtime version if not latest supported by driver
installed_cuda_version=$(julia -e 'using CUDA;print(CUDA.runtime_version())')
echo "Current CUDA runtime version: $installed_cuda_version"
max_supported_cuda_version=$(julia -e 'using CUDA;print(CUDA.driver_version())')
echo "Latest CUDA runtime version supported by installed drivers: $max_supported_cuda_version"
if [[ $(version $installed_cuda_version) -ne $(version $max_supported_cuda_version) ]]; then
  echo "Setting CUDA runtime version to latest supported version: $max_supported_cuda_version"
  cuda_update_string=$(printf 'using CUDA; CUDA.set_runtime_version!(v\"%s\");' "$max_supported_cuda_version")
  julia $cuda_update_string
  echo "Updated CUDA runtime version"
  echo
fi
julia $tools_dir/OP_ML_FF/latmodel_temporal.jl
bail_on_error

echo
echo "Done!"
echo
exit 0