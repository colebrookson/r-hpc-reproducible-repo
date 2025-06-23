#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
# Minimal build tools + libs used by tidyverse & data.table
apt-get install -y --no-install-recommends \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev
apt-get clean
rm -rf /var/lib/apt/lists/*