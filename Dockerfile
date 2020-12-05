# Base on the heroku:18-build stack (ubuntu bionic) which has some helpers to compile libraries
# and install node and python ourselves
FROM heroku/heroku:18-build as build

LABEL maintainer="Tom Clark <tom@octue.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Possible useful extras from cookiecutter
#RUN apt-get update \
#  # dependencies for building Python packages
#  && apt-get install -y build-essential \
#  # psycopg2 dependencies
#  && apt-get install -y libpq-dev \
#  # Translations dependencies
#  && apt-get install -y gettext \
#  # cleaning up unused files
#  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
#  && rm -rf /var/lib/apt/lists/*


# GDAL / GEOS / PROJ LIBRARIES
# ============================

# These libraries should always be done first. GDAL takes *ages* to build, so if done later in the Dockerfile, then any
# change that invalidates the cache will trigger an extremely long rebuild.

ARG GDAL_VERSION=v2.4.1

# Install proj, geos, libkml and build tools needed to compile gdal
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
        libkml-dev libproj-dev libgeos-dev \
        curl autoconf automake bash-completion

RUN ldconfig

# Some other install options if we need additional gdal features (may not be exhaustive)
#       python3-dev python3-numpy libboost-dev  libpng-dev libjpeg-dev libgif-dev \
#       libcharls-dev libopenjp2-7-dev libcairo2-dev \
#       liblzma-dev curl libcurl4-gnutls-dev libxml2-dev libexpat-dev libxerces-c-dev \
#       libnetcdf-dev libpoppler-dev libpoppler-private-dev \
#       libspatialite-dev swig libhdf4-alt-dev libhdf5-serial-dev \
#       libfreexl-dev unixodbc-dev libwebp-dev libepsilon-dev \
#       liblcms2-2 libpcre3-dev libcrypto++-dev libdap-dev libfyba-dev \
#       libmysqlclient-dev libogdi3.2-dev \
#       libcfitsio-dev openjdk-8-jdk libzstd1-dev \
#       libpq-dev libssl-dev

# Build GDAL
RUN mkdir gdal \
    && curl -L https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz | tar xz -C gdal --strip-components=1 \
    && cd gdal/gdal \
    && ./configure \
        --without-libtool \
        --with-geos=yes \
        --with-libkml \
        --with-proj \
    && make \
    && make install \
    && cd ../.. \
    && rm -rf gdal

RUN ldconfig

# PYTHON RUNTIME ENVIRONMENT
# ==========================
#
# Note: If compiling GDAL with python bindings, this needs to be done prior to the GDAL build.

ARG PYTHON_RUNTIME_VERSION=3.6.9

# Python installs for cpython
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
    git build-essential libbz2-dev libssl-dev libreadline-dev  libffi-dev libsqlite3-dev tk-dev

# Optional scientific package headers (useful for Numpy, Matplotlib, SciPy, etc)
RUN apt-get update -y && apt-get install libpng-dev libfreetype6-dev

# Run subsequent commands using bash, rather than the default bin/sh, which ensures that .bashrc is correctly sourced for users
# (see extensive discussion at https://stackoverflow.com/questions/20635472/using-the-run-instruction-in-a-dockerfile-with-source-does-not-work/39777387#39777387)
SHELL ["/bin/bash", "-c"]

# Install pyenv and add its shims and binaries to PATH
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT /root/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Set C.UTF-8 locale for Python 3 interpreters. You can remove these for python 3.7 and later
# (see https://click.palletsprojects.com/en/7.x/python3/)
ENV LANG "C.UTF-8"
ENV LC_ALL "C.UTF-8"

# Install our python runtime
RUN pyenv update \
    && pyenv install $PYTHON_RUNTIME_VERSION \
    && pyenv global $PYTHON_RUNTIME_VERSION