#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
# Minimal build tools + libs used by tidyverse & data.table
apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    liblapack-dev \
    libopenblas-dev 
apt-get clean
rm -rf /var/lib/apt/lists/*