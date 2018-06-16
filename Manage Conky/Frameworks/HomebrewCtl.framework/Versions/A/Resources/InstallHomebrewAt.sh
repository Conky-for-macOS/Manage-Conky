#!/bin/sh

#  InstallHomebrewAt.sh
#  HomebrewCtl
#
#  Created by npyl on 03/06/2018.
#  Copyright © 2018 npyl. All rights reserved.

LOCATION=$1

mkdir -p $LOCATION/Homebrew

# check exit status
if [ $? != 0 ]
then
    exit $?
fi

curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $LOCATION/Homebrew

exit $?
