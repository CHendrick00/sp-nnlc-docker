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
RVW=$OP/review
RLOGS_ROUTE=$RVW/rlogs_route

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

if [ ! -d $RVW ]; then
  mkdir -p $RVW
  bail_on_error
fi

if [ ! -d $RLOGS_ROUTE ]; then
  mkdir -p $RLOGS_ROUTE
  bail_on_error
fi

cd $PROCDIR/sunnypilot
# Update hardcoded paths on processing and training scripts

## Updating from original
sed -i "s:home, 'Downloads':'/$RVW':g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:~/Downloads:$RVW:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:os.path.join(os.path.expanduser('~'), 'Downloads/rlogs/output/'):'/data/output/$VEHICLE/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s: and has_upper_word(dir_name)::g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1
sed -i "s:\"GENESIS\":\"review\":g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

## Updating from after running nnlc-process
sed -i "s:$OP:$RVW:g" tools/tuning/lat.py > /dev/null 2>&1
sed -i "s:$OP/plots:$RVW/plots:g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:$OP':$RVW':g" tools/tuning/lat_plot.py > /dev/null 2>&1
sed -i "s:'/data/output/':'/data/output/$VEHICLE/':g" tools/tuning/lat_to_csv_torquennd.py > /dev/null 2>&1

# Generate list of routes
cd $RLOGS
for f in *--rlog.zst
do
    printf "%s\n" "${f%--*--rlog.zst}"
done |
sort |
uniq > "$RVW/routes.txt"

rm $RLOGS_ROUTE/*.zst
rm $RVW/*.lat

while IFS= read -r line; do
  cd $PROCDIR/sunnypilot

  cp $RLOGS/$line*.zst $RLOGS_ROUTE

  sed -i 's/PREPROCESS_ONLY = False/PREPROCESS_ONLY = True/' tools/tuning/lat_settings.py > /dev/null 2>&1
  PYTHONPATH=. tools/tuning/lat.py --path $RLOGS_ROUTE --outpath $RVW
  bail_on_error

  # Check if any lat files were generated from the logs
  lat_count=`ls -1 $RVW/*.lat 2>/dev/null | wc -l`
  if [ $lat_count != 0 ]; then
    echo
    echo "Processing step 1..."
    echo

    sed -i 's/PREPROCESS_ONLY = True/PREPROCESS_ONLY = False/' tools/tuning/lat_settings.py > /dev/null 2>&1
    PYTHONPATH=. tools/tuning/lat.py --path $RVW --outpath $RVW
    bail_on_error

    echo
    echo "Processing step 2..."
    echo

    tools/tuning/lat_to_csv_torquennd.py
    bail_on_error
  else
    echo "No valid .lat files generated from route: $line"
  fi

  mv "$RVW/review lat_accel_vs_torque.png" "$RVW/$line-lat_accel_vs_torque.png"
  rm $RLOGS_ROUTE/*.zst
  rm $RVW/*.LAT

done < "$RVW/routes.txt"

echo
echo "Done!"
echo
exit 0