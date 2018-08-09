#!/bin/sh

#  createDefaultThemepack.sh
#  Manage Conky
#
#  Created by Nickolas Pylarinos on 09/08/2018.
#  Copyright © 2018 Nickolas Pylarinos. All rights reserved.

# zip up default-themes
7z a /tmp/default-themes-2.1.cmtp.7z ~/default-themes/*

# replace the one we are using with the new one
rm ../Manage\ Conky/Resources/default-themes-2.1.cmtp.7z
mv /tmp/default-themes-2.1.cmtp.7z ../Manage\ Conky/Resources

# git commit change
git add ../Manage\ Conky/Resources/default-themes-2.1.cmtp.7z
git commit -m "Update default themepack!"
