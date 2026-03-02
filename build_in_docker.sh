#!/bin/bash
set -e

# In jcsda docker, common paths:
# ESMF_ROOT = /opt/views/view
# PIO_PATH = /opt/views/view

mkdir -p build-docker
cd build-docker
cmake .. \
  -DCMAKE_BUILD_TYPE=DEBUG \
  -DWERROR=OFF \
  -DPIO_PATH=/opt/views/view \
  -DCMAKE_Fortran_FLAGS="-DCPRGNU -g -Wall -ffree-form -ffree-line-length-none -fallow-argument-mismatch"
make -j$(nproc)
