#!/bin/sh

#  UninstallHomebrewAt.sh
#  HomebrewCtl
#
#  Created by npyl on 04/06/2018.
#  Copyright © 2018 npyl. All rights reserved.

LOCATION=$1

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall > /tmp/uninstall
chmod +x /tmp/uninstall
/tmp/uninstall --path=$LOCATION/Homebrew --force

exit $?
