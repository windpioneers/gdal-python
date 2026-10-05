#!/bin/sh
set -eu

libgdal=$(find /usr/lib -name "libgdal.so.*" -type f | head -n 1)
if readelf -d "$libgdal" | grep NEEDED | grep -E "libtiff\.so|libgeotiff\.so"; then
    echo "libgdal links a system libtiff or libgeotiff; expected GDAL's internal copies" >&2
    exit 1
fi
if ldd "$libgdal" | grep -E "libproj\.so"; then
    echo "libgdal loads a system libproj alongside the internal PROJ" >&2
    exit 1
fi
if [ -n "$(find /usr/lib -name "libproj.so.*")" ]; then
    echo "A system libproj is installed alongside the internal PROJ" >&2
    exit 1
fi
