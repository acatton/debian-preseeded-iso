#!/usr/bin/env bash
# Copyright (c) 2000 Your Name <your@address>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.
#
# Updated to add hybrid boot & UEFI by an Internet citizen
#
set -eu
declare -r ISOLINUX_HYBRID_BIN=/usr/lib/ISOLINUX/isohdpfx.bin

command -v 7z > /dev/null || {
    echo "You need to install 7z:"
    echo "  * For Fedora: sudo dnf install p7zip-plugins"
    echo "  * For Debian: sudo apt-get install p7zip-full"
    exit 127
} > /dev/stderr

command -v xorriso > /dev/null || {
    echo "You need to install xorriso:"
    echo "  * For Fedora: sudo dnf install xorriso"
    echo "  * For Debian: sudo apt-get install xorriso"
    exit 127
} > /dev/stderr

[ -f "$ISOLINUX_HYBRID_BIN" ] || {
    echo "You need to install isolinux:"
    echo "  * For Fedora: sudo dnf install isolinux"
    echo "  * For Debian: sudo apt-get install isolinux"
    exit 127
} > /dev/stderr

if [ $# -lt 2 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
    echo "Usage: $0 [debian.iso [debian-preseeded.iso [preseed.cfg]]]"
fi

declare -r SOURCE="${1:-debian.iso}"
declare -r DEST="${2:-debian-preseeded.iso}"
declare -r PRESEED="${3:-preseed.cfg}"


if [ ! -f "$SOURCE" ]
then
    echo "error: $SOURCE not found" > /dev/stderr
    exit 127
fi

if [ -f "$DEST" ]
then
    echo "error: $DEST already exists" > /dev/stderr
    exit 127
fi

if [ ! -f "$PRESEED" ]
then
    echo "error: $PRESEED not found" > /dev/stderr
    exit 127
fi

declare -r TMP="$(mktemp -d)"
echo USING $TMP ...
trap "rm -rf '$TMP'" EXIT ERR

echo "Extracting the iso..."
7z x -o"$TMP" "$SOURCE" > /dev/null

echo "Copying the preseed file..."
cp "$PRESEED" "$TMP"

pushd "$TMP" > /dev/null
echo "Update isolinux config..."
# Replace timeout 0 by timeout 1 to quickly launch the installer
sed -i -e 's/^timeout .*$/timeout 1/' isolinux/isolinux.cfg
# Replace append preseed/file=/cdrom/preseed.cfg to the kernel command line
# sed -i -e 's/^\(\s\+append .*\)\(---\)/\1preseed\/file=\/cdrom\/preseed.cfg \2/' isolinux/txt.cfg
sed -i -e 's/^\(\s\+append .*\)\(---\)/\1auto=true file=\/cdrom\/preseed.cfg \2/' isolinux/txt.cfg

echo "Update the checksums..."
find -follow -type f -print0 | xargs --null md5sum > md5sum.txt
popd > /dev/null

echo "Generate the iso..."
xorriso -as mkisofs \
    -isohybrid-mbr "$ISOLINUX_HYBRID_BIN" \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$DEST" \
    "$TMP"

echo "Done, implicitly cleaning up $TMP ..."
