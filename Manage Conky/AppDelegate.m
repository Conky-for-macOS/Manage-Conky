//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "PreferencesController.h"
#import "MCObjects/MCObjects.h"
#import "PFMoveApplication.h"
#import <Sparkle/Sparkle.h>

#include "Shared.h" /* logging */

@implementation AppDelegate

- (NSWindow *)mainWindow
{
    /* ** USE THIS INSTEAD of [NSApp mainWindow] **
     *
     * WHY?
     * [NSApp mainWindow] can be nil if mainWindow is hidden,
     * (usually happens when you start ManageConky and immediately
     * click away before it shows up)
     * thus, getting the list of the app's windows and choosing
     * the first should always return the mainWindow, hidden or not.
     */
    return [[NSApp windows] firstObject];
}

- (NSSize)windowWillResize:(NSWindow *) window toSize:(NSSize)newSize
{
    NSNumber *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"CanResizeWindow"];
    return (!b || b.boolValue) ? newSize : [window frame].size;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    NSNumber *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"CanResizeWindow"];
    return (!b) ? NO : b.boolValue;
}

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
    //MCForciblyMoveToApplicationsFolder();
#endif

    /* take care of resizing */
    [[self mainWindow] setDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /* First window created is mainWindow; push it to our vector */
    [[MCSettings sharedSettings] pushWindow:[self mainWindow]];
}

- (IBAction)openPreferences:(id)sender
{
    [[[PreferencesController alloc] initWithWindowNibName:@"Preferences"] loadOnWindow:[MCSettings sharedSettings].currentWindow];
}

@end
