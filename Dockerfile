# GDAL-PYTHON image base
ARG BASE_IMAGE=python:3.8.6-slim-buster

## ==================================
## STAGE 1 - GDAL BUILD FROM SOURCE
## ==================================
FROM $BASE_IMAGE as builder

# GDAL Version
ARG GDAL_VERSION=v2.4.1

# Install proj, geos, libkml and build tools needed to compile gdal
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
    g++ make\
    libkml-dev libproj-dev libgeos-dev \
    curl autoconf automake bash-completion \
    && rm -rf /var/cache/apt/lists

RUN ldconfig

# Build GDAL
RUN mkdir gdal \
    && curl -L https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz | tar xz -C gdal --strip-components=1 \
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

## ============================================
## STAGE 2 - Final image with GDAL and Python
## ============================================
FROM $BASE_IMAGE as runner

COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

# Dependencies for GDAL
RUN apt-get update -y && apt-get install -y --fix-missing --no-install-recommends \
    libkml-dev libproj-dev libgeos-dev \
    curl autoconf automake bash-completion \
    && rm -rf /var/cache/apt/lists

RUN ldconfig
