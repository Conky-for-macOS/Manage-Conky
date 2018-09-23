#!/bin/sh

#  createDefaultThemepack.sh
#  Manage Conky
#
#  Created by Nickolas Pylarinos on 09/08/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

symroot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/..           # Manage-Conky dir location

# zip up default-themes
7z a "/tmp/default-themes-2.1.cmtp.7z" "$symroot/default-themes/*" -x!README.md

# replace the one we are using with the new one
mv -f "/tmp/default-themes-2.1.cmtp.7z" "$symroot/Manage Conky/Resources"

# open Github Desktop
open "/Applications/Github Desktop.app"
