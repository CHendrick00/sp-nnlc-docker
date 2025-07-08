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

# directory path for project assets
cd /home/nnlc/nnlc

echo
echo "*** Installing Julia package requirements for training, as needed"
echo "    NOTE: takes a while and writes about 5.6 GB to /home/nnlc/.julia"
echo
wget -O julia_packages.jl https://raw.githubusercontent.com/mmmorks/OP_ML_FF/5c3e5a39620f8822acf01bed3bf484ffc187f31a/latmodel_temporal.jl
head -35 julia_packages.jl | sed 's/# //' > deps.jl
julia deps.jl
bail_on_error
rm -f julia_packages.txt deps.jl

echo
echo "*** Installing Julia GPU support"
echo "    See comments in this part of the script if you have another GPU type."
echo
#		package name(s)
# CUDA		CUDA and cuDNN
# AMD		AMDGPU
# Apple Metal	Metal
# Intel oneAPI	oneAPI

# CUDA
julia -e 'import Pkg; Pkg.add("CUDA"); Pkg.add("cuDNN");'
julia -e 'using CUDA; CUDA.set_runtime_version!(v"12.8.0");' # Set a default runtime version to prevent errors on first processing run
julia -e 'using CUDA;' # Force precompile
julia -e 'using cuDNN;' # Force precompile

# Apple Metal
# julia -e 'import Pkg; Pkg.add("Metal");'
# julia -e 'using Metal;' # Force precompile

# AMD, Intel not supported by tools at this time

bail_on_error

exit 0