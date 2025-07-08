#!/usr/bin/env bash

cd /home/nnlc/nnlc

echo
echo "*** Installing Julia package requirements for training, as needed"
echo
wget -O julia_packages.jl https://raw.githubusercontent.com/mmmorks/OP_ML_FF/5c3e5a39620f8822acf01bed3bf484ffc187f31a/latmodel_temporal.jl
head -35 julia_packages.jl | sed 's/# //' > deps.jl
julia deps.jl
rm -f julia_packages.txt deps.jl

echo
echo "*** Installing Julia GPU support"
echo

# NVIDIA - CUDA and cuDNN
julia -e 'import Pkg; Pkg.add("CUDA"); Pkg.add("cuDNN");'
julia -e 'using CUDA; CUDA.set_runtime_version!(v"12.8.0");' # Set a default runtime version to prevent errors on first processing run
julia -e 'using CUDA;' # Force precompile
julia -e 'using cuDNN;' # Force precompile

# Below GPUs not currently supported by tools

# Apple Metal - Metal
# julia -e 'import Pkg; Pkg.add("Metal");'
# julia -e 'using Metal;' # Force precompile

# AMD - AMDGPU
# julia -e 'import Pkg; Pkg.add("AMDGPU");'
# julia -e 'using AMDGPU;' # Force precompile

# Intel - oneAPI
# julia -e 'import Pkg; Pkg.add("oneAPI");'
# julia -e 'using oneAPI;' # Force precompile

exit 0