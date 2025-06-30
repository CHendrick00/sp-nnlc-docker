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

# Project - directory and conda environment name (default)
NNLC=nnlc

# Directory path for project assets
NNLCD=/home/nnlc/$NNLC

echo
echo "*** Creating $NNLCD directory"
echo
if [ ! -d $NNLCD ]; then
  mkdir -v $NNLCD
  bail_on_error
else
  echo "Warning: $NNLCD already exists - continuing"
fi

cd $NNLCD

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
  echo ". /home/nnlc/miniconda3/bin/activate" >> /home/nnlc/.bash_functions
  . /home/nnlc/.bash_functions
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

echo
if [ ! -d /home/nnlc/.julia ]; then
  echo "*** Downloading Julia"
  echo
  wget https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.5-linux-x86_64.tar.gz
  bail_on_error
  tar zxf julia-1.11.5-linux-x86_64.tar.gz
  bail_on_error
  rm julia-1.11.5-linux-x86_64.tar.gz
  bail_on_error
  echo "export PATH=$PATH:/home/nnlc/nnlc/julia-1.11.5/bin" >> /home/nnlc/.bashrc
  echo "export PATH=$PATH:/home/nnlc/nnlc/julia-1.11.5/bin" >> /home/nnlc/.bash_functions
  bail_on_error
else
  echo "*** Julia appears to already be installed - assuming julia in \$PATH "
fi
echo

exit 0