#
#   $pyl
#   Script to build conky on macOS
#   NOTE: assuming all libraries have properly been installed via Homebrew
#

# Get ManageConky directory
symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..

# Get conky-for-macOS directory
conky="$symroot/conky-for-macOS"

# avoid system libraries such as libffi
# and/or force use of custom made ones such as cairo-xlib.
#
# We export:
# - default pkg-config path
# - curl
# - iconv
# - ical
# - libffi
# - cairo-xlib (instead of cairo)
# - x11
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/opt/libiconv/lib/pkgconfig:/usr/local/opt/libical/lib/pkgconfig:/usr/local/opt/curl/lib/pkgconfig:/usr/local/opt/libffi/lib/pkgconfig:/usr/local/opt/cairo-xlib/lib/pkgconfig:/usr/X11/lib/pkgconfig"

# Create Temporary Build Directory (avoid directory-already-exists errors)
tmpdir="$(mktemp -d -t "MC")"

# Start Building
cd "$tmpdir"

MACOSX_DEPLOYMENT_TARGET=10.10 cmake "$conky"   \
       -DBUILD_WLAN=ON                          \
       -DBUILD_MYSQL=ON                         \
       -DBUILD_LUA_IMLIB2=OFF                   \
       -DBUILD_LUA_RSVG=ON                      \
       -DBUILD_LUA_CAIRO=ON                     \
       -DBUILD_ICAL=OFF	                        \
       -DBUILD_IRC=ON                           \
       -DBUILD_HTTP=ON                          \
       -DBUILD_ICONV=OFF                        \
       -DBUILD_RSS=ON                           \
       -DBUILD_IRC=ON                           \
       -DBUILD_CURL=ON                          \
       -DBUILD_PULSEAUDIO=ON                    \
       -DCMAKE_BUILD_TYPE=Release

make -j8
