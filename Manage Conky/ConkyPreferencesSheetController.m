//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#import <ServiceManagement/ServiceManagement.h>
#import "NSAlert+runModalSheet.h"
#import "PFMoveApplication.h"
#import "ViewController.h"
#import <unistd.h>

#include "Shared.h" /* logging */

/* defines */
#define kConkyAgentPlistName @"org.npyl.conky.plist"

#define CONKY_BUNDLE_IDENTIFIER "org.npyl.conky"
#define CONKYX_PATH             "/Applications/ConkyX.app"

#define kConkyLaunchAgentLabel      @"org.npyl.conky"
#define kConkyExecutablePath        @"/Applications/ConkyX.app/Contents/Resources/conky"

#define MC_XQUARTZ_VISIBLE      NO
#define MC_XQUARTZ_INVISIBLE    YES

#define STARTUP_DELAY_MAX 100
#define STARTUP_DELAY_MIN 0

@implementation OnlyIntegerValueFormatter

- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if ([partialString length] == 0) return NO;
    if ([partialString intValue] > STARTUP_DELAY_MAX) return NO;
    
    NSScanner* scanner = [NSScanner scannerWithString:partialString];
    
    if (!([scanner scanInt:0] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }
    
    return YES;
}

@end

@implementation ConkyPreferencesSheetController

- (void)initStuff
{
    /* Is Conky installed? */
    conkyXInstalled = [[NSFileManager defaultManager] fileExistsAtPath:CONKYX];
    conkyInstalled = [[NSFileManager defaultManager] fileExistsAtPath:CONKY_SYMLINK];
    
    // Install / Uninstall Button
    [_un_in_stallConkyButton setTitle:(conkyXInstalled && conkyInstalled) ? @"Uninstall Conky" : @"Install Conky"];
    [_un_in_stallConkyButton setEnabled:YES];
    
    // Startup Delay
    _startupDelayField.intValue = 0;    /* default value */
    
    // keepAlive
    keepAlive = YES;    /* default value */
    
    // mustInstall/RemoveAgent
    mustEnableConkyForStartup = NO;   /* default value */
    mustDisableConkyForStartup = NO;   /* default value */
    mustAddSearchPaths = NO;    /* default value */
    
    if (conkyXInstalled && conkyInstalled)
    {
        /* first try to read already written information */
        
        _searchLocationsTableContents = [[[NSUserDefaults standardUserDefaults] objectForKey:@"additionalSearchPaths"] mutableCopy];
        
        if (!_searchLocationsTableContents)
            _searchLocationsTableContents = [NSMutableArray array];
        
        /*
         * Conky is Set to run at startup?
         * set checkbox state accordingly
         */
        MCSettings *t = [MCSettings sharedInstance];
        BOOL conkyRunsAtStartup = [t conkyRunsAtStartup];
        [_runConkyAtStartupCheckbox setState:conkyRunsAtStartup];
        
        /*
         * Conky configsLocation textfield
         */
        NSString *conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
        [_conkyConfigLocationTextfield setStringValue:conkyConfigsPath];
        
        /*
         * xquartz quit warning
         */
        NSUserDefaults *xquartzPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"org.macosforge.xquartz.X11"];
        xquartzQuitAlertDisabled = [[xquartzPreferences objectForKey:@"no_quit_alert"] boolValue];
        
        if (xquartzQuitAlertDisabled)
            [_disableXQuartzWarningsCheckbox setState:NSControlStateValueOn];
        
        /*
         * xquartz icon shows up on dock?
         */
        NSDictionary *xquartzInfoPlist = [[NSDictionary alloc] initWithContentsOfFile:@"/Applications/Utilities/XQuartz.app/Contents/Info.plist"];
        NSNumber *xquartzVisibility = [xquartzInfoPlist objectForKey:@"LSBackgroundOnly"];
        
        if (!xquartzVisibility || (xquartzVisibility && xquartzVisibility.boolValue == MC_XQUARTZ_VISIBLE))
        {
            [_toggleXQuartzIconVisibilityCheckbox setState:NSOnState];
        }
    }
    else
    {
        [self toggleControls:NSOffState];
    }
}

- (void)toggleControls:(NSControlStateValue)state
{
    [_runConkyAtStartupCheckbox setEnabled:state];
    
    [_conkyConfigLocationTextfield setEnabled:state];
    [_setConkyConfigFilesLocationButton setEnabled:state];
    
    [_startupDelayStepper setEnabled:state];
    [_startupDelayField setEnabled:state];
    
    [_addSearchLocationButton setEnabled:state];
    [_removeSearchLocationButton setEnabled:state];
    
    [_disableXQuartzWarningsCheckbox setEnabled:state];
    [_toggleXQuartzIconVisibilityCheckbox setEnabled:state];
}

- (void)enableMustInstallAgentMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustEnableConkyForStartup = YES;
    mustDisableConkyForStartup = NO;   /* disable if enabled */
}
- (void)enableMustRemoveAgentMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustDisableConkyForStartup = YES;
    mustEnableConkyForStartup = NO;  /* disable if enabled */
}
- (void)enableMustAddSearchPathsMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustAddSearchPaths = YES;
}

- (IBAction)runConkyAtStartupCheckboxAction:(id)sender
{
    if ([sender state] == NSOffState)
    {
        NSLog(@"Request to remove the Agent!");
        [self enableMustRemoveAgentMode];
    }
    else
    {
        NSLog(@"Request to add the Agent!");
        
        NSAlert *keepAlivePrompt = [[NSAlert alloc] init];
        [keepAlivePrompt setMessageText:@"Select your preference"];
        [keepAlivePrompt setInformativeText:@"Always restart conky when for some reason it quits?"];
        [keepAlivePrompt setAlertStyle:NSAlertStyleInformational];
        [keepAlivePrompt addButtonWithTitle:@"Yes"];
        [keepAlivePrompt addButtonWithTitle:@"No"];
        
        NSModalResponse response = [keepAlivePrompt runModalSheetForWindow:self.window];
        switch (response)
        {
            case NSAlertSecondButtonReturn:
                keepAlive = NO;
                break;
        }
        
        [self enableMustInstallAgentMode];
        [[NSApp mainWindow] setDocumentEdited:YES];
    }
}

/**
 * disableXQuartzWarningsCheckboxAction
 *
 * Disable/Enable the "Do you really want to quit X11?" dialog when
 *  XQuartz needs to quit.  This way, avoid XQuartz's annoying DEFAULT
 *  behaviour.
 */
- (IBAction)disableXQuartzWarningsCheckboxAction:(id)sender
{
    BOOL onOrOff = [sender state];
    NSUserDefaults *xquartzPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"org.macosforge.xquartz.X11"];
    [xquartzPreferences setObject:[NSNumber numberWithBool:onOrOff] forKey:@"no_quit_alert"];
}

- (IBAction)toggleXQuartzVisibilityAction:(id)sender
{
    NSDictionary *errorDict = nil;

    NSString *boolean = ([sender state] == NSOnState) ? @"NO" : @"YES";

    NSString *formatFilePath = [[NSBundle mainBundle] pathForResource:@"toggleXquartzVisibilityScript"
                                                               ofType:@"fmt"];
    
    NSString *format = [NSString stringWithContentsOfFile:formatFilePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    
    NSString *script = [NSString stringWithFormat:format, boolean];
    
    NSAppleScript *object = [[NSAppleScript alloc] initWithSource:script];
    
    [object executeAndReturnError:&errorDict];
    
    if (errorDict)
    {
        NSLog(@"Error when executing applescript: %@", errorDict);
        [sender setState:![sender state]];
    }
}

- (IBAction)setConkyConfigsLocation:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseFiles = NO;
    panel.showsHiddenFiles = YES;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.canSelectHiddenExtension = NO;
    
    /*
     * display the panel
     */
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK)
        {
            NSURL *theDocument = [[panel URLs] objectAtIndex:0];
            NSString *theDocumentInString = [theDocument path];
            
            [self->_conkyConfigLocationTextfield setStringValue:theDocumentInString];
            
            [self conkyConfigLocationFieldEnterPressed:self->_conkyConfigLocationTextfield];
        }
    }];
}

/*
 * catch changes to _startupDelayField
 */
- (void)controlTextDidChange:(NSNotification *)obj
{
    [self enableMustInstallAgentMode];
}

- (IBAction)modifyStartupDelay:(id)sender
{
    _startupDelayField.integerValue = [sender integerValue];
    [self enableMustInstallAgentMode];
}

- (IBAction)conkyConfigLocationFieldEnterPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:@"configsLocation"];
    
    /*
     * Get pointer to the one-and-only ViewController instance,
     *  which is also the table's delegate and data-source.
     *
     *  Call the method `fillWidgetsThemesArrays` and fill the arrays
     *  with data in order to reload table, with newly installed themes/widgets.
     */
    ViewController *pVC = (ViewController *)[_themesOrWidgetsTable delegate];
    [pVC emptyWidgetsThemesArrays];
    [pVC fillWidgetsThemesArrays];
    [_themesOrWidgetsTable reloadData];
}

- (IBAction)un_in_stallConky:(id)sender
{
    /* disable the Install/Uninstall button */
    [_un_in_stallConkyButton setEnabled:NO];
    
    if (conkyXInstalled && conkyInstalled)
    {
        /*
         * Uninstall conky
         */
        
        [self toggleControls:NSOffState];

        [[MCSettings sharedInstance] uninstallCompletelyManageConkyFilesystem];
        
        /* create Successfully Installed message */
        NSAlert *successfullyUninstalled = [[NSAlert alloc] init];
        [successfullyUninstalled setMessageText:@"Successfully uninstalled!"];
        [successfullyUninstalled setInformativeText:@"conky (ConkyX and ManageConky) was successfully uninstalled from your computer. Manage Conky will now quit"];
        [successfullyUninstalled runModal];
        
        /* exit */
        exit(0);
    }
    else
    {
        /*
         * Install Conky
         */
        
        /* uninstall old & install new */
        [[MCSettings sharedInstance] uninstallManageConkyFilesystem];
        [[MCSettings sharedInstance] installManageConkyFilesystem];
        
        [self close];
        [self loadOnWindow:self.targetWindow];
        [self initStuff];   // XXX try to remove this
        [self toggleControls:NSOnState];
    }
}

- (IBAction)applyChanges:(id)sender
{
    MCSettings *MCSettingsHolder = [MCSettings sharedInstance];
    
    BOOL changesApplied = YES;
    
    NSString *userLaunchAgentPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents"];
    NSString *conkyAgentPlistPath = [userLaunchAgentPath stringByAppendingPathComponent:kConkyAgentPlistName];
    
    if (mustDisableConkyForStartup)
    {
        /* revert */
        mustDisableConkyForStartup = NO;
        
        unlink([conkyAgentPlistPath UTF8String]);
        
        [MCSettingsHolder setConkyRunsAtStartup:NO];
    }
    else if (mustEnableConkyForStartup)
    {
        /* revert */
        mustEnableConkyForStartup = NO;
        
        NSWindow *sheet = self.window;
        NSInteger startupDelay_ = [_startupDelayField integerValue];
        static BOOL shownX11TakesAlotTimeWarning = NO;
        
        /*
         * show X11 warning
         */
        if (!shownX11TakesAlotTimeWarning && (startupDelay_ != 0))
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Warning"];
            [alert setInformativeText:@"Keep in mind that X11 takes aloooot time to open. You may want to recalculate your startup delay."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModalSheetForWindow:sheet];
            
            shownX11TakesAlotTimeWarning = YES;
        }
        
        [MCSettingsHolder setConkyRunsAtStartup:YES];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:keepAlive]
                                                  forKey:@"keepAlive"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:startupDelay_]
                                                  forKey:@"startupDelay"];
        
        [[NSApp mainWindow] setDocumentEdited:NO];
    }
    
    /*
     * We should be able to add/remove search paths to our list
     *  whether mustInstallAgent or mustRemoveAgent modes are enabled.
     */
    if (mustAddSearchPaths)
    {
        /* revert */
        mustAddSearchPaths = NO;
        
        /*
         * Write the Additional Search Locations
         */
        [[NSUserDefaults standardUserDefaults] setObject:_searchLocationsTableContents forKey:@"additionalSearchPaths"];
    }
    
    [_changesSavedLabel setStringValue:changesApplied ? @"Changes applied successfully" : @"Failed to apply changes!"];
    [_changesSavedLabel setHidden:NO];
    [_doneButton setTitle:@"OK"];
    [_applyChangesButton setHidden:YES];
}

- (IBAction)okButtonPressed:(id)sender
{
    BOOL worksAsCancelButton = mustEnableConkyForStartup || mustDisableConkyForStartup || mustAddSearchPaths;
    
    if (worksAsCancelButton)
    {
        if (mustAddSearchPaths)
        {
            [_searchLocationsTableContents removeAllObjects];   // XXX remove all newly added ONLY
            [_searchLocationsTable reloadData];
        }
        
        mustEnableConkyForStartup = NO;
        mustDisableConkyForStartup = NO;
        mustAddSearchPaths = NO;
        [_doneButton setTitle:@"OK"];
        [_applyChangesButton setHidden:YES];
        [_changesSavedLabel setHidden:YES];
    }
    else
    {
        /*
         * Close the sheet
         */
        [self close];
    }
}

//
//
// SEARCH LOCATIONS
//
//

- (IBAction)addSearchLocation:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseFiles = NO;
    panel.showsHiddenFiles = YES;
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.canSelectHiddenExtension = NO;
    
    /*
     * display the panel
     */
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK)
        {
            NSURL *theDocument = [[panel URLs] objectAtIndex:0];
            NSString *theDocumentInString = [theDocument path];
            
            /* add to table contents array */
            [self->_searchLocationsTableContents addObject:theDocumentInString];
            [self->_searchLocationsTable reloadData];
            
            [self enableMustAddSearchPathsMode];
        }
    }];
}

- (IBAction)removeSearchLocation:(id)sender
{
    NSInteger selectedRow = [_searchLocationsTable selectedRow];
    
    if (selectedRow < 0)
        return;
        
    [_searchLocationsTableContents removeObjectAtIndex:selectedRow];
    [_searchLocationsTable reloadData];
    
    [self enableMustAddSearchPathsMode];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_searchLocationsTableContents count];
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *searchLocation = _searchLocationsTableContents[row];
    
#define IDENTIFIER_SET_IN_INTERFACE_BUILDER @"SearchPathCellID"
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:IDENTIFIER_SET_IN_INTERFACE_BUILDER owner:nil];
    cellView.textField.stringValue = searchLocation;
    return cellView;
}

@end
