#!/usr/bin/env bash

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

cd /home/nnlc/nnlc

echo
if [ ! -s sunnypilot/tools/tuning/lat.py ]; then
  echo "*** Downloading sunnypilot fork for dataset pre-processing"
  echo
  git clone https://github.com/CHendrick00/sunnypilot.git
  bail_on_error
  cd sunnypilot
  git checkout origin/tuning-tools
  rm -rf ./.git
  bail_on_error
  cd ..
else
  echo "*** sunnypilot tree appears to already be present - skipping download"
fi
echo

echo
if [ ! -s OP_ML_FF/latmodel_temporal.jl ]; then
  echo "*** Downloading mmmorks NN training script fork"
  echo
  git clone https://github.com/mmmorks/OP_ML_FF
  bail_on_error
  cd OP_ML_FF
  git checkout 0116b9e3f0cfb49290936604b6b2f63325414bbc
  rm -rf ./.git
  bail_on_error
  cd ..
else
  echo "*** OP_ML_FF tree appears to already be present - skipping download"
fi
echo

exit 0