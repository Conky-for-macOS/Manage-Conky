//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "Shared.h"
#import "PFMoveApplication.h"
#import "MCObjects/MCObjects.h"
#import "PreferencesController.h"
#import "Extensions/NSApplication+mainWindowForSure.h"

@implementation AppDelegate

- (NSSize)windowWillResize:(NSWindow *) window toSize:(NSSize)newSize
{
    return [[MCSettings sharedSettings] canResizeWindow] ? newSize : [window frame].size;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    return [[MCSettings sharedSettings] canResizeWindow];
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
    MCForciblyMoveToApplicationsFolder();
#endif

    /* take care of resizing */
    [[NSApp mainWindow] setDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /* First window created is mainWindow; push it to our vector */
    [[MCSettings sharedSettings] pushWindow:[NSApp mainWindow]];
}

- (void)updaterDidRelaunchApplication:(SUUpdater *)updater
{
    /*
     * Update MC filesystem after update.
     * (see: added cairo support)
     */
    NSLog(@"Refreshing MC filesystem after update...");
    [[MCSettings sharedSettings] uninstallManageConkyFilesystem:usesHomebrewConky()];
    [[MCSettings sharedSettings] installManageConkyFilesystem:usesHomebrewConky()];
    NSLog(@"Refreshing MC filesystem: DONE");
}

- (IBAction)openPreferences:(id)sender
{
#define PREFERENCES_SHEET_NIB @"Preferences"
    
    NSString *currentWindowNibName = [MCSettings sharedSettings].currentWindow.windowController.windowNibName;
    
    /*
     * Load Preferences sheet only if not already loaded!
     */
    if (![currentWindowNibName isEqualToString:PREFERENCES_SHEET_NIB])
        [[[PreferencesController alloc] initWithWindowNibName:PREFERENCES_SHEET_NIB] loadOnWindow:[MCSettings sharedSettings].currentWindow];
}

@end
