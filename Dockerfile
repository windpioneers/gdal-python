
# STAGE 1 - GDAL BUILD FROM SOURCE
# ================================

# Set the base image with an arg, e.g.
#   python:3.9-slim-buster
#   mcr.microsoft.com/vscode/devcontainers/python:0-3.9
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS builder
LABEL stage=builder

ARG PROJ_VERSION=9.5.0
ARG GDAL_VERSION=3.9.3
ARG UV_VERSION=0.5.1

# This is the verison of numpy against which gdal python/numpy bindings are built.
# It won't be copied into your stack. If you install numpy in a python project that
# uses this container, you should be able to vary the numpy version according to 
# your needs, *provided the C headers are compatible*. Sometimes, the numpy C headers
# change, so if you get segmentation faults ensure you have a compatible version of
# numpy installed.
ARG NUMPY_VERSION=2.1.3

# Install proj, geos, libkml and build tools needed to compile gdal
RUN apt-get update -y && \
    apt-get upgrade -y && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --fix-missing --no-install-recommends \
        g++ cmake build-essential ninja-build \
        python3-numpy python3-setuptools \
        libkml-dev libgeos-dev libtiff-dev libgeotiff-dev \
        libhdf5-dev \
        libopenjp2-7-dev libjpeg-dev libwebp-dev libpng-dev \
        libdeflate-dev zlib1g-dev libzstd-dev libexpat-dev \
        libpq-dev libsqlite3-dev sqlite3 \
        pkg-config patchelf curl swig && \
    apt-get clean && \
    rm -rf /var/cache/apt/lists


# libpython3.12-dev is not in bookworm so we have to add debian's cutting edge repo
# TODO in subsequent updates to debian's build lists it should be possible to subsume
# this into the prior step.
RUN export PYTHON_SHORT_VERSION=$(python --version | sed 's/Python //' | cut -d. -f1,2) && \
    echo "deb http://deb.debian.org/debian sid main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends libpython${PYTHON_SHORT_VERSION}-dev && \
    sed -i '/sid/d' /etc/apt/sources.list && \
    apt-get clean && \
    rm -rf /var/cache/apt/lists

RUN ldconfig

# Install the specified version of numpy; cmake will pick up the header files and build gdal against them
RUN pip install --root-user-action ignore numpy==${NUMPY_VERSION}

ENV PROJ_INSTALL_PREFIX=/proj

RUN mkdir -p proj \
    && curl -L https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz | tar xz -C proj --strip-components=1\
    && export PROJ_DB_CACHE_PARAM="" \
    && cd proj \
    && CFLAGS='-DPROJ_RENAME_SYMBOLS -O2' CXXFLAGS='-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2' \
        cmake . \
            -G Ninja \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=${PROJ_INSTALL_PREFIX} \
            -DBUILD_TESTING=OFF \
            $PROJ_DB_CACHE_PARAM \
    && ninja \
    && DESTDIR="/build" ninja install \
    && cd .. \
    && rm -rf proj \
    && PROJ_SO=$(readlink -f /build${PROJ_INSTALL_PREFIX}/lib/libproj.so | awk 'BEGIN {FS="libproj.so."} {print $2}') \
    && PROJ_SO_FIRST=$(echo $PROJ_SO | awk 'BEGIN {FS="."} {print $1}') \
    && mv /build${PROJ_INSTALL_PREFIX}/lib/libproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO} \
    && ln -s libinternalproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO_FIRST} \
    && ln -s libinternalproj.so.${PROJ_SO} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so \
    && rm /build${PROJ_INSTALL_PREFIX}/lib/libproj.*  \
    && export GCC_ARCH="$(uname -m)" \
    && ${GCC_ARCH}-linux-gnu-strip -s /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO} \
    && for i in /build${PROJ_INSTALL_PREFIX}/bin/*; do ${GCC_ARCH}-linux-gnu-strip -s $i 2>/dev/null || /bin/true; done \
    && patchelf --set-soname libinternalproj.so.${PROJ_SO_FIRST} /build${PROJ_INSTALL_PREFIX}/lib/libinternalproj.so.${PROJ_SO} \
    && for i in /build${PROJ_INSTALL_PREFIX}/bin/*; do patchelf --replace-needed libproj.so.${PROJ_SO_FIRST} libinternalproj.so.${PROJ_SO_FIRST} $i; done

# Build GDAL
RUN export PYTHON_EXACT_VERSION=$(python --version | sed 's/Python //')\
    && mkdir -p /gdal/build \
    && curl -L https://github.com/OSGeo/gdal/archive/refs/tags/v${GDAL_VERSION}.tar.gz | tar xz -C gdal --strip-components=1 \
    && cd /gdal/build \
    # -Wno-psabi avoid 'note: parameter passing for argument of type 'std::pair<double, double>' when C++17 is enabled changed to match C++14 in GCC 10.1' on arm64
    && CFLAGS='-DPROJ_RENAME_SYMBOLS -O2' CXXFLAGS='-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -Wno-psabi' \
        cmake .. \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DGDAL_FIND_PACKAGE_PROJ_MODE=MODULE \
        -DPROJ_INCLUDE_DIR="/build${PROJ_INSTALL_PREFIX-/usr/local}/include" \
        -DPROJ_LIBRARY="/build${PROJ_INSTALL_PREFIX-/usr/local}/lib/libinternalproj.so" \
        -DBUILD_TESTING=OFF \
        -DPython_LOOKUP_VERSION=$PYTHON_EXACT_VERSION \
        -DBUILD_PYTHON_BINDINGS=ON \
    && ninja \
    && DESTDIR="/build" ninja install \
    && cd ../.. \
    && rm -rf gdal \
    && mkdir -p /build_gdal_python/usr/lib \
    && mkdir -p /build_gdal_python/usr/bin \
    && mkdir -p /build_gdal_version_changing/usr/include \
    && mv /build/usr/lib/python*            /build_gdal_python/usr/lib \
    && mv /build/usr/lib                    /build_gdal_version_changing/usr \
    && mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include \
    && mv /build/usr/bin/*.py               /build_gdal_python/usr/bin \
    && mv /build/usr/bin                    /build_gdal_version_changing/usr \
    && export GCC_ARCH="$(uname -m)" \
    && for i in /build_gdal_version_changing/usr/lib/${GCC_ARCH}-linux-gnu/*; do ${GCC_ARCH}-linux-gnu-strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do ${GCC_ARCH}-linux-gnu-strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_version_changing/usr/bin/*; do ${GCC_ARCH}-linux-gnu-strip -s $i 2>/dev/null || /bin/true; done


## ===========================================================
## STAGE 2 - Final image with built GDAL and optional devtools
## ===========================================================
FROM ${BASE_IMAGE} AS slim
LABEL stage=slim

COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_python/usr/ /usr/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

# Dependencies for working with geo tools, KML libraries, HDF5 (for pytables) and some useful others 
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
    libkml-dev libgeos-dev \
    curl autoconf automake bash-completion libpq-dev gcc git \
    libhdf5-dev \
    && rm -rf /var/cache/apt/lists
    
RUN ldconfig

# Install uv package manager
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# TODO consider a different stage `FROM slim as dev`, using the `USER` docker command to install all development
# dependencies without the need for a flag and all these conditionals. Next time!

# [Option] Install development tools
# Note: this option will only work on an MS vscode devcontainer because it assumes a non-root vscode user
ARG INSTALL_DEV_TOOLS="true"

# Install Node.js (useful to run some dev tools like prettier)
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1" \
    ; fi

# Install Oh-My-Zsh shell
#    - af-magic theme because it's most similar to the git colour scheme
#    - git, ssh mapped to your local machine
#    - command history search enabled
#    - command history file file mapped into the .devcontainer folder to enable reuse between container builds
ARG ZSH_HISTORY_FILE="/workspace/.devcontainer/.zsh_history"
ENV HISTFILE="${ZSH_HISTORY_FILE}"
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.1/zsh-in-docker.sh)" -- \ 
    -t af-magic \
    -p git -p ssh-agent -p 'history-substring-search' \
    -a 'bindkey "\$terminfo[kcuu1]" history-substring-search-up' \
    -a 'bindkey "\$terminfo[kcud1]" history-substring-search-down' \
    ; fi
    
# Install spaceship theme and terminal prompt onto oh-my-zsh
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "/home/vscode/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1 && \
    ln -s "/home/vscode/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "/home/vscode/.oh-my-zsh/custom/themes/spaceship.zsh-theme" \
    ; fi
COPY ./.zshrc /home/vscode

# The non-root user defined in the devcontainer.json file needs write permission to /usr/local/src
# in order for poetry to install git dependencies (this is where it clones them).
# Other installers (e.g. the austin profiling tool) will also require access to this directory
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    mkdir -p /usr/local && chown -R vscode /usr/local \
    ; fi

# Install austin for code profiling
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    cd /usr/local/src && \
    git clone --depth=1 https://github.com/P403n1x87/austin.git && \
    cd /usr/local/src/austin && \
    autoreconf --install && \
    ./configure && \
    make && \
    make install \
    ; fi

# Install the specific version of prettier that we have in pre-commit-config to avoid style flip-flopping
#  Note that the devcontainer settings require a static path to resolve the prettier module, so we add a symlink here
ARG PRETTIER_VERSION=2.2.1
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    npm install -g prettier@${PRETTIER_VERSION} && \
    ln -s $(npm root -g)/prettier /usr/local/prettier \
    ; fi  

# Make sure that if you install requests, it can find the Certificate Authority bundle.
# Overcomes this issue: https://github.com/python-poetry/poetry/issues/1012
RUN if [ "${INSTALL_DEV_TOOLS}" = "true" ]; then \
    export PYTHON_VERSION=`python -c 'import sys; print("{0}.{1}".format(*sys.version_info[:2]))'` && \
    mkdir -p /home/vscode/.local/lib/python${PYTHON_VERSION}/site-packages/certifi/ && \
    ln -s $(python -c "import certifi; print(certifi.where())") /home/vscode/.local/lib/python${PYTHON_VERSION}/site-packages/certifi/cacert.pem \
    ; fi

# Setting this ensures print statements and log messages promptly appear
ENV PYTHONUNBUFFERED TRUE

# Tell zsh where you want to store history
#     This folder is mapped into the container, so that history will persist over container rebuilds.
#
#     !!!IMPORTANT!!!
#     Make sure your .zsh_history file is NOT committed into your repository, as it can contain
#     sensitive information. You should add
#         .devcontainer/.zsh_history
#     to your .gitignore file.
#
WORKDIR /workspace
ENV HISTFILE="/workspace/.devcontainer/.zsh_history"

# # Overcome the fact that yarn don't bother putting their keys on the ring (required for installing sshd feature)...
# # https://github.com/yarnpkg/yarn/issues/7866#issuecomment-1404052064
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmour -o "/usr/share/keyrings/yarn-keyring.gpg" & \
#     echo "deb [signed-by=/usr/share/keyrings/yarn-keyring.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list & \
#     gpg --refresh-keys & \
#     apt-get update -y
