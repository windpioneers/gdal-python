#!/bin/sh
set -eu

debug_root="$1"
shift

for path in "$@"; do
    if [ -L "$path" ] || [ ! -f "$path" ] || ! readelf -h "$path" >/dev/null 2>&1; then
        continue
    fi
    build_id=$(readelf -n "$path" | awk '/Build ID/ {print $3}')
    if [ -z "$build_id" ]; then
        strip -s "$path"
        continue
    fi
    prefix=$(echo "$build_id" | cut -c1-2)
    suffix=$(echo "$build_id" | cut -c3-)
    debug_file="${debug_root}/usr/lib/debug/.build-id/${prefix}/${suffix}.debug"
    mkdir -p "$(dirname "$debug_file")"
    objcopy --only-keep-debug "$path" "$debug_file"
    strip -s "$path"
    objcopy --add-gnu-debuglink="$debug_file" "$path"
done
