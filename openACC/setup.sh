#! /usr/local/bin/bash

echo "Setting up environment on [$HOSTNAME]..."

# load necessary modules
echo "Loading modules..."

module load cmake-3
module load nvhpc/20.9

echo "Following modules loaded:"
module list

# cmake and build
echo "Cmaking and building..."
build_dir="$(hostname -s)_openACC_build"
cmake -B $build_dir
cd $build_dir
cp ../run_tests.sh .
echo `pwd`
make
