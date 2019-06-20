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

echo "${bold}applying patches to conky..."

# clone our repo of conky-patches
git clone https://github.com/Conky-for-macOS/conky-patches /tmp/conky-patches

# cd into conky
cd "$symroot"/ConkyX/conky-for-macOS

# apply patches
for p in /tmp/conky-patches/*; do
        echo "${bold}applying patch: $p...\n"
        /usr/bin/patch -p1 < "$p"
done

# refresh conky-for-macOS's build files on new workspace
cd "$symroot"/ConkyX/conky-for-macOS/forConkyX
rm -rf *

# create an Xcode project using cmake
MACOSX_DEPLOYMENT_TARGET=10.10 cmake ..      \
		-DBUILD_WLAN=ON 		     		 \
		-DBUILD_MYSQL=ON 		     		 \
        -DBUILD_LUA_IMLIB2=ON                \
        -DBUILD_LUA_RSVG=ON                  \
        -DBUILD_LUA_CAIRO=ON                 \
        -DBUILD_ICAL=ON                      \
        -DBUILD_IRC=ON                       \
        -DBUILD_HTTP=ON                      \
        -DBUILD_ICONV=ON                     \
        -DBUILD_RSS=ON                       \
        -DBUILD_IRC=ON                       \
        -DBUILD_PULSEAUDIO=ON 				 \
        -DCMAKE_BUILD_TYPE=Release           \
 -G Xcode

#
# There must be a problem with TravisCI.
# XXX, remove this later...
#
cd "$symroot"

# Refresh our cocoapods
pod install
