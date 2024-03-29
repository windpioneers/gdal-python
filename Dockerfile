
# STAGE 1 - GDAL BUILD FROM SOURCE
# ================================

# Set the base image with an arg, e.g.
#   python:3.9-slim-buster
#   mcr.microsoft.com/vscode/devcontainers/python:0-3.9
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as builder
LABEL stage=builder

# GDAL Version
ARG GDAL_VERSION

# Install proj, geos, libkml and build tools needed to compile gdal
RUN apt-get update -y && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --fix-missing --no-install-recommends \
    g++ make \
    libkml-dev libproj-dev libgeos-dev \
    curl autoconf automake \
    && apt-get clean \
    && rm -rf /var/cache/apt/lists

RUN ldconfig

# Build GDAL
RUN mkdir gdal \
    && curl -L https://github.com/OSGeo/gdal/archive/v${GDAL_VERSION}.tar.gz | tar xz -C gdal --strip-components=1 \
    && cd gdal/gdal \
    && ./configure  --prefix=/usr \
        --without-libtool \
        --with-geos=yes \
        --with-libkml \
        --with-proj \
    && make \
    && make install DESTDIR="/build" \
    && cd ../.. \
    && rm -rf gdal \
    && mkdir -p /build_gdal_version_changing/usr/include \
    && mv /build/usr/lib                    /build_gdal_version_changing/usr \
    && mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include \
    && mv /build/usr/bin                    /build_gdal_version_changing/usr \
    && for i in /build_gdal_version_changing/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_gdal_version_changing/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

## ===========================================================
## STAGE 2 - Final image with built GDAL and optional devtools
## ===========================================================
FROM ${BASE_IMAGE} as slim
LABEL stage=slim

COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

# Dependencies for working with geo tools, KML libraries, HDF5 (for pytables) and some useful others 
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
    libkml-dev libproj-dev libgeos-dev \
    curl autoconf automake bash-completion libpq-dev gcc git \
    libhdf5-dev \
    && rm -rf /var/cache/apt/lists
    
RUN ldconfig

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
ENV PRETTIER_VERSION=2.2.1
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

# Install poetry
# USER vscode
# ENV POETRY_HOME=/home/vscode/.poetry
# RUN curl -sSL https://install.python-poetry.org | python -
# ENV PATH "$POETRY_HOME/bin:$PATH"
# RUN poetry config virtualenvs.create false

# # Overcome the fact that yarn don't bother putting their keys on the ring (required for installing sshd feature)...
# # https://github.com/yarnpkg/yarn/issues/7866#issuecomment-1404052064
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmour -o "/usr/share/keyrings/yarn-keyring.gpg" & \
#     echo "deb [signed-by=/usr/share/keyrings/yarn-keyring.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list & \
#     gpg --refresh-keys & \
#     apt-get update -y
