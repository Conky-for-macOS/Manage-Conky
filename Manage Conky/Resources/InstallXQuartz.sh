#!/bin/sh

#  installXQuartz.sh
#  Manage Conky
#
#  Created by npyl on 24/03/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

#
# this script must be run with sudo
#

echo "Downloading XQuartz..."

# download XQuartz
# (CONKYX_XQUARTZ_DOWNLOAD_URL is an environment variable set by ManageConky internally.)
/usr/bin/curl -L -s -o /tmp/XQuartz.dmg $CONKYX_XQUARTZ_DOWNLOAD_URL

echo "Mounting XQuartz.dmg"

# mount dmg
# (make it invisible to Finder)
/usr/bin/hdiutil attach /tmp/XQuartz.dmg -mountpoint /Volumes/XQuartz -nobrowse

echo "Running Installer"

# run the intstaller
/usr/sbin/installer -pkg /Volumes/XQuartz/XQuartz.pkg -target /

# umnount
/usr/bin/hdiutil detach /Volumes/XQuartz -force

echo "Cleaning up"

# cleanup
rm -f /tmp/XQuartz.dmg
