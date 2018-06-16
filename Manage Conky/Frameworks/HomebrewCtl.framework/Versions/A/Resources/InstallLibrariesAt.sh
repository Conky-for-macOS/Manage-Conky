#!/bin/sh

#  InstallLibrariesAt.sh
#  HomebrewCtl
#
#  Created by npyl on 15/06/2018.
#  Copyright © 2018 npyl. All rights reserved.

LOCATION=$1
LIBS=${@:2}

$LOCATION/Homebrew/bin/brew install $LIBS
