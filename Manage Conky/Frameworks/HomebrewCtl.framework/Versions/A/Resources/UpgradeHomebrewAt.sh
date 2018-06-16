#!/bin/sh

#  UpgradeHomebrewAt.sh
#  HomebrewCtl
#
#  Created by npyl on 03/06/2018.
#  Copyright © 2018 npyl. All rights reserved.

LOCATION=$1

$LOCATION/Homebrew/bin/brew upgrade

exit $?
