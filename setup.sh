#! /usr/local/bin/bash

echo "Setting up environment on [$HOSTNAME]..."

output_dir="$(hostname -s)_output"
mkdir -p $output_dir

# load necessary modules
module unload cmake*
module unload gcc*
module unload cuda*

echo "Loading modules..."

module load cmake-3
module load gcc-9.2
module load cuda-11.4

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
cmake -B build
cd build
echo `pwd`
make