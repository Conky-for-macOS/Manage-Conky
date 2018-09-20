#!/bin/sh

#
# This script is part of ManageConky;
#
# Once compiled, ManageConky must be
# added into a .dmg and codesigned so
# that it can be easily distributed
# on macOS Sierra and later.

#
# Usage: distributeManageConky [new ManageConky's version number]
# eg. distributeManageConky 0.8.1
#
# NOTE: If you don't provide a version number this script will read
# from Info.plist and will increment by 0.1
#

function get_version_number()
{
    local version_number=0

    if [[ $1 ]]; then
        version_number=$1
    else
        version_number=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$symroot/Manage Conky/Info.plist")
        # increment
        version_number=$(bc -l <<< "$version_number + 0.1")
    fi

    # return
    echo $version_number
}

workdir="/tmp/ManageConkyDMG"                                                       # Temporary directory
builddir="/tmp/ManageConky.build"                                                   # Build directory
symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..           # Manage-Conky dir location
version=$(get_version_number $1)                                                    # dmg's version number

# check if npyl.github.io repo is in same dir as Manage-Conky
if [ ! -d "$symroot/../npyl.github.io" ]; then
    echo "Error: npyl.github.io repo MUST reside in the same directory as Manage-Conky!"
    exit 1
fi

##
## BEAUTIFY
##
bold=$(tput bold)
echo "${bold}DistributeManageConky.command | version 1.0 | by npyl"
echo "\n"
echo "${bold}Will create a ManageConky dmg in $HOME with version number: $version"
echo "\n"

# remove any previous files...
rm -rf "$builddir"
rm -rf "$workdir"

# create builddir & workdir
mkdir -p "$builddir"
mkdir -p "$workdir"

# change directory into project root
cd "$symroot"

# build project for RELEASE
xcodebuild -workspace "Manage Conky.xcworkspace" -scheme "Manage Conky" -configuration "Release" -derivedDataPath "$builddir" clean build

# Setup work directory
ln -s "/Applications" "$workdir/Applications"
cp -R "$builddir/Build/Products/Release/Manage Conky.app" "$workdir"

# create dmg
hdiutil create -fs HFS+ -srcfolder "$workdir" -volname "Manage Conky_v$version" "/tmp/Manage Conky_v$version.dmg"

# sign dmg
codesign -s "Mac Developer" "/tmp/Manage Conky_v$version.dmg"

echo "DSA Signature:"

# create DSA signature
~/Manage-Conky/Pods/Sparkle/bin/sign_update "/tmp/Manage Conky_v$version.dmg" "~/Documents/Private Key/dsa_priv.pem"

# move to ~
mv "/tmp/Manage Conky_v$version.dmg" ~

echo "Update your npyl.github.io with ManageConky.dmg and the DSA signature in appcast.xml"

open ~/npyl.github.io/Projects/ManageConky/Release
open ~/npyl.github.io/Projects/ManageConky/appcast.xml
