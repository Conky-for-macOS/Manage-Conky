#!/bin/sh

#
# This script is part of ManageConky;
#
# Once compiled, ManageConky must be
# added into a .dmg and codesigned so
# that it can be easily distributed
# on macOS Sierra and later.

#
# Usage: distributeManageConky [ManageConky project location] [new ManageConky's version number]
# eg. distributeManageConky ~/Manage-Conky 0.8.1
#

workdir="/tmp/ManageConkyDMG"
builddir="/tmp/ManageConky.build"
symroot=$1

# remove any previous files...
rm -rf "$builddir"
rm -rf "$workdir"

# create builddir & workdir
mkdir -p "$builddir"
mkdir -p "$workdir"

# change directory into project root
cd "$symroot"

# build project for RELEASE
xcodebuild -workspace "Manage Conky.xcworkspace" -scheme "Manage Conky" -configuration "Release" -derivedDataPath "/tmp/ManageConky.build" clean build

# Setup work directory
ln -s "/Applications" "$workdir/Applications"
cp -R "$builddir/Build/Products/Release/Manage Conky.app" "$workdir"

# create dmg
hdiutil create -fs HFS+ -srcfolder "$workdir" -volname "Manage Conky_v$2" "/tmp/Manage Conky_v$2.dmg"

# sign dmg
codesign -s "Mac Developer" "/tmp/Manage Conky_v$2.dmg"

echo "DSA Signature:"

# create DSA signature
~/Manage-Conky/Pods/Sparkle/bin/sign_update "/tmp/Manage Conky_v$2.dmg" ~/Documents/Private\ Key/dsa_priv.pem

# move to ~
mv "/tmp/Manage Conky_v$2.dmg" ~

echo "Update your npyl.github.io with ManageConky.dmg and the DSA signature in appcast.xml"

open ~/npyl.github.io/Projects/ManageConky/Release
open ~/npyl.github.io/Projects/ManageConky/appcast.xml
