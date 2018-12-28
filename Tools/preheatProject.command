#!/bin/sh

#
# This script creates an Xcode project out of conky-for-macOS
# in order for ManageConky to compile on a new development workspace.
# (this is for when you first clone ManageConky, etc...)
#

symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..           # Manage-Conky dir location

##
## BEAUTIFY
##
bold=$(tput bold)
echo "${bold}preheat | version 1.0 | by npyl"
echo "\n"

cd "$symroot"/ConkyX/conky-for-macOS/forConkyX
rm -rf *

#
# We enable WLAN, 
#
cmake .. -DBUILD_WLAN=ON -G Xcode