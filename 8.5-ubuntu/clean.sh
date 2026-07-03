#!/bin/sh
set -e

copy_dependencies() {
    local target="$1"
    local dest_dir="$2"

    # libtree get the dependencies of the target binary/library
    libtree -pv "$target" \
        | sed 's/.*── \(.*\) \[.*/\1/' \
        | grep -v "^$target" \
        | while IFS= read -r lib; do
            [ -z "$lib" ] && continue

            local base
            base=$(basename "$lib")
            local destfile="$dest_dir/$base"

            if [ ! -f "$destfile" ]; then
                cp "$lib" "$destfile"
            fi
        done
}

# install libtree
apt-get update
apt-get install -y libtree

# get path
EXT_DIR="$(php -r 'echo ini_get("extension_dir");')"
FRANKENPHP_BIN="$(which frankenphp)"
LIBS_TMP_DIR="/tmp/libs"

mkdir -p "$LIBS_TMP_DIR"

# save dependencies for frankenphp
echo "Sichere Abhängigkeiten für FrankenPHP..."
copy_dependencies "$FRANKENPHP_BIN" "$LIBS_TMP_DIR"

# save dependencies for php extensions
echo "Sichere Abhängigkeiten für PHP-Erweiterungen..."
find "$EXT_DIR" -maxdepth 2 -type f -name "*.so" | while read -r ext; do
    copy_dependencies "$ext" "$LIBS_TMP_DIR"
done

# cleanup
apt-get remove -y --purge libtree python gcc g++ make
apt-get autoremove -y --purge
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp
