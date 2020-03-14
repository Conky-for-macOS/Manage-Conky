#
#   $pyl
#   Script to build conky on macOS
#   NOTE: assuming all libraries have properly been installed via Homebrew
#

# Get ManageConky directory
symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..

# Get conky-for-macOS directory
conky="$symroot/conky-for-macOS"

cd "$conky"

# Start Building
mkdir build
cd build
cmake ..
make
