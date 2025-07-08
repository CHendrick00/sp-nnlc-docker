#!/usr/bin/env bash

nnlc_dir=/home/nnlc/nnlc

cd $nnlc_dir
echo "*** Downloading sunnypilot fork for dataset pre-processing"
echo
git clone https://github.com/CHendrick00/sunnypilot.git
cd sunnypilot
git checkout tuning-tools
rm -rf ./.git
echo

cd $nnlc_dir
echo "*** Downloading mmmorks NN training script fork"
echo
git clone https://github.com/mmmorks/OP_ML_FF
cd OP_ML_FF
git checkout 5c3e5a39620f8822acf01bed3bf484ffc187f31a
rm -rf ./.git
echo

exit 0