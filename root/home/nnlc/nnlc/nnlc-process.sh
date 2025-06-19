#!/usr/bin/env bash

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [[ ! -n $VEHICLE ]] || [[ ! -n $DEVICE_ID ]]; then
  echo "Required environment variables VEHICLE and/or DEVICE_ID not set. Cannot continue."
  exit 1
fi

# Set directory to folder where the project
# assets like sunnypilot and OP_ML_FF dirs are
cd /home/nnlc/nnlc

# activate nnlc env
. /home/nnlc/.bashrc
conda activate nnlc

# dir containing nnlc tools
PROCDIR=/home/nnlc/nnlc

# dir containing rlogs downloaded from Comma device using included rlog import script - will copy rlog.zst files to $RLOGS
RD=/data/rlogs/$VEHICLE/$DEVICE_ID

# rlogs processing dir - input path to preprocessing
RLD=/data/output/$VEHICLE/rlogs
RLOGS=$RLD/$DEVICE_ID

# Create processing directories if they don't exist
if [[ ! -d $RLD ]]; then
  mkdir -p $RLD
fi
if [[ ! -d $RLOGS ]]; then
  mkdir -p $RLOGS
fi

# Output path - note this is hard-coded as ~/Downloads in processing step 2
# and training steps.  To change this, edit the processing and training scripts.
OP=/data/output/$VEHICLE

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

if [ ! -d sunnypilot -o ! -d OP_ML_FF ]; then
  echo
  echo "*** Before using this script, make sure you're cd-ed into a"
  echo "    prepared NNLC training project directory."
  echo
  exit 1
fi

echo
echo "Copying/updating rlog.zst files from $RD to $RLOGS..."
echo
cd $RD
ls -1f *.zst | while read SD; do
  NF="${SD/_/|}"
  RLF="$RLOGS/$NF"
  if [ ! -s $RLF ]; then
    cp -v $SD $RLF
    bail_on_error
  fi
done

echo
echo "Preprocessing rlogs in $RLOGS..."
echo

if [ ! -d $OP ]; then
  mkdir -p $OP
  bail_on_error
fi

# Archive previous plots_torque
PD=$OP/plots_torque
if [ -d $PD ]; then
  rm -rf ${PD}-
  mv $PD ${PD}-
fi
bail_on_error

cd $PROCDIR/sunnypilot
# Update hardcoded paths on processing and training scripts
sed -i "s:home, 'Downloads':'/$OP':g" tools/tuning/lat.py > /dev/null 2>&1

sed -i "s:~/Downloads:$OP:g" tools/tuning/lat_plot.py > /dev/null 2>&1

sed -i "s:os.path.join(os.path.expanduser('~'), 'Downloads/rlogs/output/'):'/data/output/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s: and has_upper_word(dir_name)::g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\"GENESIS\":\"$VEHICLE\":g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

sed -i "s:\$home_dir/Downloads/rlogs/output/GENESIS:/$OP:g" $PROCDIR/OP_ML_FF/latmodel_temporal.jl > /dev/null 2>&1

# Begin processing
sed -i 's/PREPROCESS_ONLY = False/PREPROCESS_ONLY = True/' tools/tuning/lat_settings.py > /dev/null 2>&1

cd $PROCDIR/sunnypilot
sed -i 's/PREPROCESS_ONLY = False/PREPROCESS_ONLY = True/' tools/tuning/lat_settings.py > /dev/null 2>&1
PYTHONPATH=. tools/tuning/lat.py --path $RLOGS --outpath $OP
bail_on_error

echo
echo "Processing step 1..."
echo

sed -i 's/PREPROCESS_ONLY = True/PREPROCESS_ONLY = False/' tools/tuning/lat_settings.py > /dev/null 2>&1
PYTHONPATH=. tools/tuning/lat.py --path $OP --outpath $OP
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
cd $OP
# Set CUDA runtime version if not latest supported by driver
CUDAVER=$(julia -e 'using CUDA;print(CUDA.driver_version())')
CURRVER=$(julia -e 'using CUDA;print(CUDA.runtime_version())')
if [[ $(version $CURRVER) -lt $(version $CUDAVER) ]]; then
  echo "Setting CUDA runtime version"
  CUDASTR=$(printf 'using CUDA; CUDA.set_runtime_version!(v\"%s\");' "$CUDASTR")
  julia $CUDASTR
  echo "Updated CUDA runtime version:"
  echo $(julia -e 'using CUDA;print(CUDA.runtime_version())')
fi
julia $PROCDIR/OP_ML_FF/latmodel_temporal.jl
bail_on_error

echo
echo "Done!"
echo
exit 0