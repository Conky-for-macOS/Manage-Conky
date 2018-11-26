#!/bin/sh

#  SetupStuff.sh
#  Manage Conky
#
#  Created by Nickolas Pylarinos Stamatelatos on 26/11/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

CONKY_X=$1

# create symlink to ConkyX in Applications
ln -s "$CONKY_X" /Applications

# Create /usr/local/bin dir;
# Ensure that we are going to get the symlink in place.
mkdir -p /usr/local/bin
