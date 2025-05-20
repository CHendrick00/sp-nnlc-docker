#!/bin/bash

# project - directory and conda environment name (default)
NNLC=nnlc

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

echo
echo "*** This script installs all the prerequisites to run NNLC training"
echo "    on an Ubuntu Linux 24.04 system.  It is intended to only be run once."

# directory path for project assets
NNLCD=/home/nnlc/$NNLC

echo
echo "*** Creating $NNLCD and /home/nnlc/Downloads/plots directories"
echo
if [ ! -d $NNLCD ]; then
	mkdir -v $NNLCD
	bail_on_error
else
	echo "Warning: $NNLCD already exists - continuing"
fi
mkdir -pv /home/nnlc/Downloads/plots 2> /dev/null

echo
if [ ! -d /home/nnlc/miniconda3 ]; then
 echo "** Installing miniconda3"
 mkdir -p /home/nnlc/miniconda3
 bail_on_error
 wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/nnlc/miniconda3/miniconda.sh
 bail_on_error
 bash /home/nnlc/miniconda3/miniconda.sh -b -u -p /home/nnlc/miniconda3
 bail_on_error
 rm -f /home/nnlc/miniconda3/miniconda.sh
 echo ". /home/nnlc/miniconda3/bin/activate" >> /home/nnlc/.bashrc
 . /home/nnlc/.bashrc
else
 echo "** Miniconda3 appears to already be installed - assuming conda in \$PATH"
fi
echo

echo
echo "** Creating conda environment $NNLC and installing Python requirements"
echo
conda config --add channels conda-forge
bail_on_error
conda create -y -n $NNLC
bail_on_error
. /home/nnlc/miniconda3/bin/activate
bail_on_error
conda activate $NNLC
bail_on_error
conda install -y python==3.12 numpy tqdm p-tqdm scons pycapnp zstandard smbus2 requests scipy matplotlib pandas scikit-learn pyarrow
bail_on_error
pip install zmq
bail_on_error

# Remaining steps are under project directory
cd $NNLCD

echo
if [ ! -s sunnypilot/tools/tuning/lat.py ]; then
 echo "*** Downloading mmmorks sunnypilot fork for dataset pre-processing"
 echo
 git clone https://github.com/mmmorks/sunnypilot.git
 bail_on_error
 cd sunnypilot
 git checkout 4084ee5e895bc97ca3cef369a3e866a59cef1adf
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
 git checkout 5c3e5a39620f8822acf01bed3bf484ffc187f31a
 bail_on_error
 cd ..
else
 echo "*** OP_ML_FF tree appears to already be present - skipping download"
fi
echo

echo
if [ ! -d /home/nnlc/.julia ]; then
 echo "*** Downloading Julia"
 echo
 wget https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.5-linux-x86_64.tar.gz
 bail_on_error
 tar zxf julia-1.11.5-linux-x86_64.tar.gz
 bail_on_error
else
 echo "*** Julia appears to already be installed - assuming julia in \$PATH "
fi
echo

exit 0