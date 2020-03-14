#
#   $pyl
#   Script to build conky on macOS
#   NOTE: assuming all libraries have properly been installed via Homebrew
#

# Get ManageConky directory
symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..

# Get conky-for-macOS directory
conky="$symroot/conky-for-macOS"

export PKG_CONFIG_PATH="/usr/local/opt/curl/lib/pkgconfig:/usr/local/opt/lua/lib/pkgconfig:/usr/local/opt/imlib2/lib/pkgconfig"

# Create Temporary Build Directory (avoid directory-already-exists errors)
tmpdir="$(mktemp -d -t "MC")"

# Start Building
cd "$tmpdir"
cmake "$conky"
make -j8
