#!/usr/bin/env bash

# It's impossible to specify more than two option in the shebang
# Otherwise I would've put #!/usr/bin/env bash -e
set -e

which 7z > /dev/null || {
    echo "You need to install 7z:"
    echo "  * For Fedora: dnf install p7zip-plugins"
    echo "  * For Debian: apt-get install p7zip-full"
    exit 127
} > /dev/stderr

which genisoimage > /dev/null || {
    echo "You need to install genisoimage:"
    echo "  * For Fedora: dnf install genisoimage"
    echo "  * For Debian: apt-get install genisoimage"
    exit 127
} > /dev/stderr

if [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
    echo "Usage: $0 [debian.iso [debian-preseeded.iso [preseed.cfg]]]"
fi

SOURCE="${1:-debian.iso}"
DEST="${2:-debian-preseeded.iso}"
PRESEED="${3:-preseed.cfg}"


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

TMP="$(mktemp -d)"

echo "Extracting the iso..."
7z x -o"$TMP" "$SOURCE" > /dev/null

echo "Copying the preseed file..."
cp "$PRESEED" "$TMP"

pushd "$TMP" > /dev/null
echo "Update isolinux config..."
# Replace timeout 0 by timeout 1 to quickly launch the installer
sed -i -e 's/^timeout .*$/timeout 1/' isolinux/isolinux.cfg
# Replace append preseed/file=/cdrom/preseed.cfg to the kernel command line
#sed -i -e 's/^\(\s\+append .*\)\(---\)/\1preseed\/file=\/cdrom\/preseed.cfg \2/' isolinux/txt.cfg
sed -i -e 's/^\(\s\+append .*\)\(---\)/\1auto=true file=\/cdrom\/preseed.cfg \2/' isolinux/txt.cfg

echo "Update the checksums..."
find -follow -type f -print0 | xargs --null md5sum > md5sum.txt
popd > /dev/null

echo "Generate the iso..."
genisoimage -o "$DEST" -r -J -quiet -no-emul-boot -boot-load-size 4 \
    -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat "$TMP"

echo "Removing the temporary directory..."
rm -rf "$TMP"

echo "Done..."
