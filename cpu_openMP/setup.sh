#! /usr/local/bin/bash

echo "Setting up OpenMP environment on [$HOSTNAME]..."

# load necessary modules
echo "Loading modules..."

module load cmake-3
module load gcc-11.2

echo "Following modules loaded:"
module list

# export environment variables
echo "Exporting environment variables..."
export CC=`which gcc`
export CXX=`which g++`

echo "CC = $CC"
echo "CXX = $CXX"

# cmake and build
echo "Cmaking and building..."
build_dir="$(hostname -s)_openmp_build"
cmake -B $build_dir
cd $build_dir
cp ../run_tests.sh .
echo `pwd`
make
