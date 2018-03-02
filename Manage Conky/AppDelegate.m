//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "PFMoveApplication.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    //CXForciblyMoveToApplicationsFolder();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /*
     * Check if conky/ConkyX is installed actually
     */
    //if (access("/Applications/ConkyX.app", F_OK) != 0)
    //{
        /*
         * Download latest release from GitHub
         * Place into /Applications
         * Install conky from /Applications/ConkyX/Resources/conky
         */
    //}
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
