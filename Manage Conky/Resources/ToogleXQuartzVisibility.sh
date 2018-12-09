#!/bin/sh

#  ToogleXQuartzVisibility.sh
#  Manage Conky
#
#  Created by Nickolas Pylarinos Stamatelatos on 07/12/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

# This needs to be run as ROOT
mv -f /tmp/Info.plist /Applications/Utilities/XQuartz.app/Contents

exit $?
