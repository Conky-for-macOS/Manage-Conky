//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "PFMoveApplication.h"
#import <Sparkle/Sparkle.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    /*
     * Homebrew doesn't allow using your own updating
     * mechanism; thus disable Sparkle if we are building
     * for Homebrew.
     */
    SUUpdater *updater = [SUUpdater sharedUpdater];
    
#ifdef BUILDS_FOR_HOMEBREW_CASK
    NSLog(@"Disabling Updater as part of Homebrew-Cask terms.");
    [updater setAutomaticallyChecksForUpdates:NO];
    
    [updater setFeedURL:[NSURL URLWithString:@"https://npyl.github.io/Projects/ManageConky/Homebrew-Cask/appcast.xml"]];
#else
    [updater setFeedURL:[NSURL URLWithString:@"https://npyl.github.io/Projects/ManageConky/Release/appcast.xml"]];
#endif
    
    CXForciblyMoveToApplicationsFolder();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
