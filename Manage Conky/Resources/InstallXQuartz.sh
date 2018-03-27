#!/bin/sh

#  installXQuartz.sh
#  Manage Conky
#
#  Created by npyl on 24/03/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

#
# this script must be run with sudo
#

# download XQuartz
# (CONKYX_XQUARTZ_DOWNLOAD_URL is an environment variable set by ManageConky internally.)
curl -L -s -o /tmp/XQuartz.dmg $CONKYX_XQUARTZ_DOWNLOAD_URL

# mount dmg
# (make it invisible to Finder)
hdiutil attach /tmp/XQuartz.dmg -mountpoint /Volumes/XQuartz -nobrowse

# run the intstaller
installer -pkg /Volumes/XQuartz/XQuartz.pkg -target /

# umnount
hdiutil detach /Volumes/XQuartz -force

# cleanup
rm -f /tmp/XQuartz.dmg
