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
curl -L -s -o /tmp/XQuartz.dmg https://dl.bintray.com/xquartz/downloads/XQuartz-2.7.11.dmg

# mount dmg
# (make it invisible to Finder)
hdiutil attach /tmp/XQuartz.dmg -mountpoint /Volumes/XQuartz -nobrowse

# run the intstaller
installer -pkg /Volumes/XQuartz/XQuartz.pkg -target /

# umnount
hdiutil detach /Volumes/XQuartz -force

# cleanup
rm -f /tmp/XQuartz.dmg
