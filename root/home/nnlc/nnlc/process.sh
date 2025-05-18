#!/bin/bash

# Set directory to folder where the project
# assets like sunnypilot and OP_ML_FF dirs are
cd /home/nnlc/nnlc

# activate nnlc env
conda activate nnlc

# dir containing rlogs downloaded from Comma device using included rlog collection script - will copy rlog.zst files to $RLOGS
RD=/input/$VEHICLE/$DEVICE_ID

# rlogs processing dir - input path to preprocessing
RLD=/home/nnlc/Downloads/rlogs
RLOGS=$RLD/$DEVICE_ID

# Output path - note this is hard-coded as ~/Downloads in processing step 2
# and training steps.  To change this, edit the processing and training scripts.
OP=/output/$VEHICLE

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

# Create output dir for various plots
PD=$RLD/plots_torque
if [ -d $PD ]; then
	rm -rf ${PD}-
	mv $PD ${PD}-
fi
mkdir $PD
bail_on_error

echo
echo "Preprocessing rlogs in $RLOGS..."
echo

if [ ! -d $OP ]; then
	mkdir $OP
	bail_on_error
fi

# Updating hardcoded paths on processing scripts
cd $PROCDIR/sunnypilot
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

# echo
# echo -n "Press Enter to continue with training, or Ctrl-C to exit: "
# read INP

echo
cd $OP
julia $PROCDIR/OP_ML_FF/latmodel_temporal.jl
bail_on_error

echo
echo "Done!"
echo
exit 0