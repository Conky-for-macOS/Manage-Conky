//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "PreferencesController.h"
#import "PFMoveApplication.h"
#import <Sparkle/Sparkle.h>

#include "Shared.h" /* logging */

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    /*
     * Homebrew doesn't allow using your own updating
     * mechanism; thus disable Sparkle if we are building
     * for Homebrew.
     */
#ifdef BUILDS_FOR_HOMEBREW_CASK
    NSLog(@"Disabling Updater as part of Homebrew-Cask terms.");
    SUUpdater *updater = [SUUpdater sharedUpdater];
    [updater setAutomaticallyChecksForUpdates:NO];
#endif

#ifndef DEBUG
    MCForciblyMoveToApplicationsFolder();
#endif
}

- (IBAction)openPreferences:(id)sender
{
    [[[PreferencesController alloc] initWithWindowNibName:@"Preferences"] loadOnWindow:[NSApp mainWindow]];
}

@end
