#!/bin/sh
unset VER MANUAL
while getopts ":v::m" OPTION >/dev/null 2>&1; do
	case $OPTION in
	v) VER=$OPTARG ;;
	m) MANUAL=true ;;
	:) echo >&2 "Option '-$OPTARG' requires a version to be specified." && exit 1 ;;
	\?) echo >&2 "Unknown option: '$OPTARG'." && echo "Usage: ${0##*/} [-v 'version'] [-m]" && exit 1 ;;
	esac
done
if [ -z "$VER" ]; then
	echo >&2 "The '-v' option is mandatory and requires a version to be specified." && exit 1
fi

Cleanup() { rm -R "$TEMP_DIR" >/dev/null 2>&1 && exit; }
trap "Cleanup" INT

PKG_NAME=deb-tools
PKG_VER=$VER+deepines
PKG_DEV="Isaías Gätjens M <igatjens@gmail.com>"
PKG_ARCH=all
PKG_FULL_NAME=${PKG_NAME}_${PKG_VER}_${PKG_ARCH}
SH_DIR="$(pwd -P)"
TEMP_DIR="$(mktemp -d)"
WORK_DIR="$TEMP_DIR/$PKG_FULL_NAME"

echo "Welcome to '$PKG_NAME' packaging assistant!" && sleep 1
echo "This script will help you in the packaging process." && sleep 1
echo "Press Ctrl+C at any time to cancel the process.

Packaging details:
Name: $PKG_NAME
Version: $PKG_VER
Architecture: $PKG_ARCH
Final package name: $PKG_FULL_NAME.deb
"
printf "%s" 'Starting in ' && i=5 && while [ $i -gt 0 ]; do
	printf "%u... " "$i" && i=$((i - 1)) && sleep 1
done && printf "%s\n" 'Now!'

echo
mkdir -p "$WORK_DIR/DEBIAN"
cd "$WORK_DIR" || exit 1

Open() { # Create file (if needed), open and wait to finish...
	if [ "$MANUAL" = true ]; then
		touch "$1" >/dev/null 2>&1
		echo "Manually checking '$1'..."
		mimeopen -n "$1" >/dev/null 2>&1
	fi
}

echo "Copying scripts..."
mkdir -p usr/bin
cp -a "$SH_DIR/Src/." usr/bin

DOC_PATH="usr/share/doc/$PKG_NAME"
echo "Copying docs..."
mkdir -p $DOC_PATH
cp -a "$SH_DIR/Data/Doc/." $DOC_PATH

MAN_PATH="usr/share/man/man1"
echo "Copying manual pages..."
mkdir -p $MAN_PATH
cp -a "$SH_DIR/Data/ManPage/." $MAN_PATH
gzip -r9n "$MAN_PATH/."

echo "Updating changelog..."
CLOG="$DOC_PATH/changelog.Debian"
gunzip "$CLOG.gz"
Open "$CLOG" # (-m) Manually update the changelog file.
# Use dch (devscripts package) if available.
gzip -9n "$CLOG"

# Generate md5sums
find . -not \( -path ./DEBIAN -prune \) -type f -exec md5sum {} \; |
	sed "s|\./||" >DEBIAN/md5sums

# Generate 'Installed-Size' variable.
INSIZE=$(du -s --exclude='DEBIAN/*' | grep -Eo "[0-9]*")
Open "./DEBIAN/" # (-m) Manually update preinst, postinst, etc.

# TODO: Maybe change the section back to "admin" when the new store is available.
GenerateControl() {
	cat <<EOF
Package: $PKG_NAME
Version: $PKG_VER
Architecture: $PKG_ARCH
Installed-Size: $INSIZE
Section: devel
Maintainer: $PKG_DEV
Homepage: https://github.com/igatjens/deb-tools
Priority: optional
Pre-Depends: dpkg (>= 1.5)
Depends: dpkg (>= 1.5), sed (>=4.5), grep (>=3.1), fakeroot (>=1.20), coreutils (>=8.20)
Description: Packaging tools
 Tools to create, maintain, audit and manage .deb files.
EOF
}

echo "Generating control file..."
GenerateControl >DEBIAN/control
Open "./DEBIAN/control" # (-m) Manually update the control file.

echo "Fixing permissions..."                     # For lintian mainly.
find . -type d -exec chmod 755 {} \;             # Set all directory permissions to 755 (non-standard-dir-perm).
find . -executable -type f -exec chmod 755 {} \; # Set all executable files permissions to 755 (non-standard-executable-perm).
find usr/share -type f -exec chmod 644 {} \;     # Set all usr/share file permissions to 644 (non-standard-file-perm).

echo "Build package..."
fakeroot dpkg-deb --build "$WORK_DIR" "$SH_DIR" # Should use "dpkg-buildpackage -rfakeroot" instead, but no.

#echo "Updating changes made to docs and changelog..."

echo "Finished!"
Cleanup
