#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq

# build tools + system headers for:
#   * tidyverse     (libcurl, libssl, libxml2, libgit2)
#   * clustermq     (pkg-config, libzmq3-dev)
#   * rstanarm      (g++, gfortran, BLAS/LAPACK)
apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    pkg-config \
    libzmq3-dev \
    liblapack-dev \
    libopenblas-dev

apt-get clean
rm -rf /var/lib/apt/lists/*