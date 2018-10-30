//
//  AppDelegate.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "AppDelegate.h"

#import "Shared.h"
#import <Sparkle/Sparkle.h>
#import "PFMoveApplication.h"
#import "MCObjects/MCObjects.h"
#import "PreferencesController.h"
#import "Extensions/NSApplication+mainWindowForSure.h"

@implementation AppDelegate

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
    [[NSApp mainWindow] setDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /* First window created is mainWindow; push it to our vector */
    [[MCSettings sharedSettings] pushWindow:[NSApp mainWindow]];
}

- (IBAction)openPreferences:(id)sender
{
    NSString *currentWindowNibName = [MCSettings sharedSettings].currentWindow.windowController.windowNibName;
    
    /*
     * Load Preferences sheet only if not already loaded!
     */
    if (![currentWindowNibName isEqualToString:@"Preferences"])
        [[[PreferencesController alloc] initWithWindowNibName:@"Preferences"] loadOnWindow:[MCSettings sharedSettings].currentWindow];
}

@end
