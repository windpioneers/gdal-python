#!/bin/sh
set -eu

apt-get update -y
apt-get install -y --fix-missing --no-install-recommends \
    libkml-dev \
    libgeos-dev \
    libtiff6 libopenjp2-7 libjpeg62-turbo libwebp7 libpng16-16 \
    libzstd1 libdeflate0 libexpat1 libxml2 \
    libhdf5-103-1 \
    libsqlite3-0 \
    libpq5 \
    curl autoconf automake bash-completion build-essential cmake gcc git python3-dev
apt-get clean
rm -rf /var/cache/apt/lists
