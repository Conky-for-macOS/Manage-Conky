#
# This script is part of ManageConky;
#
# Once compiled, ManageConky must be
# added into a .dmg and codesigned so
# that it can be easily distributed
# on macOS Sierra and later.
#
#
# Usage: distributeManageConky [source of ManageConky.app] [version number]
# eg. distributeManageConky /tmp/Manage\ Conky.app 0.8.1
#

workdir=/tmp/ManageConkyDMG

# Setup work directory
mkdir -p "$workdir"
ln -s /Applications "$workdir/Applications"
cp -R "$1" "$workdir"

# create dmg
hdiutil create -fs HFS+ -srcfolder "$workdir" -volname "Manage Conky_v$2" "/tmp/Manage Conky_v$2.dmg"

cd /tmp

# sign dmg
codesign -s Mac\ Developer "Manage Conky_v$2.dmg"

echo "DSA Signature:"

# create DSA signature
~/Manage-Conky/Pods/Sparkle/bin/sign_update "/tmp/Manage Conky_v$2.dmg" ~/Documents/Private\ Key/dsa_priv.pem

# move to ~
mv "/tmp/Manage Conky_v$2.dmg" ~

echo "Update your npyl.github.io with ManageConky.dmg and the DSA signature in appcast.xml"

open ~/npyl.github.io/Projects/ManageConky/Release
open ~/npyl.github.io/Projects/ManageConky/appcast.xml
