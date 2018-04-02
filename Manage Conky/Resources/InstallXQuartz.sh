#!/bin/sh

#  installXQuartz.sh
#  Manage Conky
#
#  Created by npyl on 24/03/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

#
# this script must be run with sudo
#

#
# Fix PATH for tools search paths
#
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

echo "Downloading XQuartz..."

#
# download XQuartz
# (CONKYX_XQUARTZ_DOWNLOAD_URL is an environment variable set by ManageConky internally.)
#
curl -L -s -o /tmp/XQuartz.dmg $CONKYX_XQUARTZ_DOWNLOAD_URL

echo "Mounting XQuartz.dmg"

#
# mount dmg
# (make it invisible to Finder)
#
hdiutil attach /tmp/XQuartz.dmg -mountpoint /Volumes/XQuartz -nobrowse

echo "Running Installer"

#
# run the intstaller
#
installer -pkg /Volumes/XQuartz/XQuartz.pkg -target /

#
# umnount
#
hdiutil detach /Volumes/XQuartz -force

echo "Cleaning up"

# cleanup
rm -f /tmp/XQuartz.dmg
