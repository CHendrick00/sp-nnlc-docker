#!/usr/bin/env bash

conda_env=nnlc
nnlc_dir=/home/nnlc/nnlc

echo
echo "*** Creating $nnlc_dir directory"
echo
mkdir -v $nnlc_dir
cd $nnlc_dir

echo
echo "*** Installing miniconda3"
mkdir -p /home/nnlc/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/nnlc/miniconda3/miniconda.sh
bash /home/nnlc/miniconda3/miniconda.sh -b -u -p /home/nnlc/miniconda3
rm -f /home/nnlc/miniconda3/miniconda.sh
conda tos accept
echo ". /home/nnlc/miniconda3/bin/activate" >> /home/nnlc/.bashrc
echo ". /home/nnlc/miniconda3/bin/activate" >> /home/nnlc/.bash_functions
. /home/nnlc/.bash_functions

echo
echo "*** Creating conda environment $conda_env and installing Python requirements"
echo
conda config --add channels conda-forge
conda create -y -n $conda_env
. /home/nnlc/miniconda3/bin/activate
conda activate $conda_env
conda install -y python==3.12 numpy tqdm p-tqdm scons pycapnp zstandard smbus2 requests scipy matplotlib pandas scikit-learn pyarrow
pip install zmq

echo
echo "*** Downloading Julia"
echo
wget https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.5-linux-x86_64.tar.gz
tar zxf julia-1.11.5-linux-x86_64.tar.gz
rm julia-1.11.5-linux-x86_64.tar.gz
echo "export PATH=$PATH:/home/nnlc/nnlc/julia-1.11.5/bin" >> /home/nnlc/.bashrc
echo "export PATH=$PATH:/home/nnlc/nnlc/julia-1.11.5/bin" >> /home/nnlc/.bash_functions
echo

exit 0