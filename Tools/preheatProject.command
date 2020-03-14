#!/bin/sh

# Avoid Some STUPID Homebrew failures
set -e;

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
echo "${bold}preheat | version 2.0 | by npyl"
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

# Export some of our libraries into pkg-config in order to avoid system libraries such as libffi
# and/or force use of custom made ones such as cairo-xlib.
#
# We export:
# - default pkg-config path
# - libffi
# - cairo-xlib (instead of cairo)
# - x11
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/opt/libffi/lib/pkgconfig:/usr/local/opt/cairo-xlib/lib/pkgconfig:/usr/X11/lib/pkgconfig/:"

# create an Xcode project using cmake
MACOSX_DEPLOYMENT_TARGET=10.10 cmake ..      \
		-DBUILD_WLAN=ON 		     		 \
		-DBUILD_MYSQL=ON 		     		 \
        -DBUILD_LUA_IMLIB2=OFF               \
        -DBUILD_LUA_RSVG=ON                  \
        -DBUILD_LUA_CAIRO=ON                 \
        -DBUILD_ICAL=ON                      \
        -DBUILD_IRC=ON                       \
        -DBUILD_HTTP=ON                      \
        -DBUILD_ICONV=ON                     \
        -DBUILD_RSS=ON                       \
        -DBUILD_IRC=ON                       \
        -DBUILD_CURL=ON                      \
        -DBUILD_PULSEAUDIO=ON 				 \
        -DCMAKE_BUILD_TYPE=Release           \
 -G Xcode

#
# Return to project Root
#
cd "$symroot"

# Xcode fails to build toluapp for some unknown reason
# Workaround this by installing (before compilation) a
# precompiled version of toluapp.
toluapp_build_dir="ConkyX/conky-for-macOS/forConkyX/3rdparty/toluapp"

mkdir -p "$toluapp_build_dir/Debug"
mkdir -p "$toluapp_build_dir/Release"

cp -R Binaries/* "$toluapp_build_dir/Debug"
cp -R Binaries/* "$toluapp_build_dir/Release"

# Refresh our cocoapods
pod install
