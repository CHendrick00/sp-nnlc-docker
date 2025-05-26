#!/usr/bin/env bash

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

# Remaining steps are under project directory
cd $NNLCD/OP_ML_FF

echo
echo "*** Installing Julia package requirements for training, as needed"
echo "    NOTE: takes a while and writes about 5.6 GB to /home/nnlc/.julia"
echo
head -35 latmodel_temporal.jl | sed 's/# //' > deps.jl
julia deps.jl
bail_on_error
rm -f deps.jl

echo
echo "*** Installing Julia GPU support"
echo "    See comments in this part of the script if you have another GPU type."
echo
#		package name(s)
# CUDA		CUDA and cuDNN
# AMD		AMDGPU
# Apple Metal	Metal
# Intel oneAPI	oneAPI
julia -e 'import Pkg; Pkg.add("CUDA"); Pkg.add("cuDNN");'
# julia -e 'import Pkg; Pkg.add("AMDGPU")'
bail_on_error

exit 0