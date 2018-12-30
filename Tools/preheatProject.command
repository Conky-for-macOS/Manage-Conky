#!/bin/sh

#
# This script creates an Xcode project out of conky-for-macOS
# in order for ManageConky to compile on a new development workspace.
# (this is for when you first clone ManageConky, etc...)
#

# Get ManageConky directory location
symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..

##
## BEAUTIFY
##
bold=$(tput bold)
echo "${bold}preheat | version 1.0 | by npyl"
echo "\n"

# refresh conky-for-macOS's build files on new workspace
cd "$symroot"/ConkyX/conky-for-macOS/forConkyX
rm -rf *

#
# We enable WLAN, CAIRO
#
cmake .. -DBUILD_WLAN=ON -DBUILD_LUA_CAIRO=ON -G Xcode