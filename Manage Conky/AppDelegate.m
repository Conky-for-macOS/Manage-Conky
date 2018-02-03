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
    CXForciblyMoveToApplicationsFolder();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
