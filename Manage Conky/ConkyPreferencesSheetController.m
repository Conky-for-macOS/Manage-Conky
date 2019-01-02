//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#import <unistd.h>
#import "Shared.h"
#import "ViewController.h"
#import "PFMoveApplication.h"
#import "NSAlert+runModalSheet.h"
#import <NPTask/NSAuthenticatedTask.h>
#import <ServiceManagement/ServiceManagement.h>


/* defines */
#define kConkyAgentPlistName @"org.npyl.conky.plist"

#define CONKY_BUNDLE_IDENTIFIER "org.npyl.conky"
#define CONKYX_PATH "/Applications/ConkyX.app"

#define kConkyLaunchAgentLabel @"org.npyl.conky"
#define kConkyExecutablePath @"/Applications/ConkyX.app/Contents/Resources/conky"

#define MC_XQUARTZ_VISIBLE NO
#define MC_XQUARTZ_INVISIBLE YES

#define INFO_PLIST_TMP @"/tmp/Info.plist"
#define INFO_PLBAK_TMP @"/tmp/Info.plist.backup"
#define INFO_PLIST_DST @"/Applications/Utilities/XQuartz.app/Contents/Info.plist"

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
    _oldStartupDelay = _startupDelayField.intValue;
    
    // keepAlive
    keepAlive = YES;    /* default value */
    
    // mustInstall/RemoveAgent
    mustEnableConkyForStartup = NO;   /* default value */
    mustDisableConkyForStartup = NO;   /* default value */
    mustAddSearchPaths = NO;    /* default value */
    
    if (conkyXInstalled && conkyInstalled)
    {
        /*
         * first try to read already written information
         */

        _searchLocationsTableContents = [MCSettings sharedSettings].additionalSearchPaths.mutableCopy;
        
        if (!_searchLocationsTableContents)
            _searchLocationsTableContents = [NSMutableArray array];
        
        [_searchLocationsTable reloadData];
        
        /* initialise the Backup array */
        _oldSearchLocationsTableContents = [NSMutableArray arrayWithArray:_searchLocationsTableContents];
        
        /*
         * Conky is Set to run at startup?
         * set checkbox state accordingly
         */
        MCSettings *t = [MCSettings sharedSettings];
        BOOL conkyRunsAtStartup = [t conkyRunsAtStartup];
        [_runConkyAtStartupCheckbox setState:conkyRunsAtStartup];
        
        /*
         * Conky configsLocation textfield
         */
        NSString *conkyConfigsPath = [[MCSettings sharedSettings] configsLocation];
        [_conkyConfigLocationTextfield setStringValue:conkyConfigsPath];
        _oldConfigsLocation = _conkyConfigLocationTextfield.stringValue;
        
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
        NSDictionary *xquartzInfoPlist = [[NSDictionary alloc] initWithContentsOfFile:INFO_PLIST_DST];
        BOOL xquartzVisibility = ![[xquartzInfoPlist objectForKey:@"LSBackgroundOnly"] boolValue];
        
        [_toggleXQuartzIconVisibilityCheckbox setState:xquartzVisibility];
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
    
    NSColor *labelColor = (state) ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
    
    [_startupDelayLabel setTextColor:labelColor];
    [_conkyConfigFilesLocationLabel setTextColor:labelColor];
    [_additionalLocationsToSearchLabel setTextColor:labelColor];
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
    /*
     * Allow enabling logging, only if MC is being operated in testing mode...
     * (`conky runs at startup` means that MC is NOT operating in test mode)
     */
    [[[[MCSettings sharedSettings] mainViewController] toggleLoggerButton] setEnabled:![sender state]];
    
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

        switch ([keepAlivePrompt runModalSheetForWindow:self.window])
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
- (IBAction)toggleXQuartzWarningsCheckboxAction:(id)sender
{
    BOOL onOrOff = [sender state];
    NSUserDefaults *xquartzPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"org.macosforge.xquartz.X11"];
    [xquartzPreferences setObject:[NSNumber numberWithBool:onOrOff] forKey:@"no_quit_alert"];
}

- (IBAction)toggleXQuartzVisibilityAction:(id)sender
{
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"ToogleXQuartzVisibility" ofType:@"sh"];
    
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:INFO_PLIST_DST];
    if (!plist)
    {
        NSLog(@"Unable to load Info.plist");
        [sender setState:![sender state]];
        return;
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:INFO_PLIST_TMP error:&error]; if (error) MCError(&error);
    [[NSFileManager defaultManager] removeItemAtPath:INFO_PLBAK_TMP error:&error]; if (error) MCError(&error);

    /* backup Info.plist */
    [[NSFileManager defaultManager] copyItemAtPath:INFO_PLIST_DST toPath:INFO_PLBAK_TMP error:&error];
    if (error)
    {
        [sender setState:![sender state]];
        MCError(&error);
        return;
    }
    
    /* set LSBackgroundOnly */
    [plist setObject:[NSNumber numberWithBool:![sender state]] forKey:@"LSBackgroundOnly"];
    
    /* apply changes */
    BOOL res = [plist writeToFile:INFO_PLIST_TMP atomically:YES];
    if (!res)
    {
        [sender setState:![sender state]];
        MCError(&error);
        return;
    }

    /* Run the script */
    NSAuthenticatedTask *script = [[NSAuthenticatedTask alloc] init];
    script.launchPath = scriptPath;
    [script launchAuthenticated];
    [script waitUntilExit];
    
    if (script.terminationStatus != 0)
    {
        [sender setState:![sender state]];
        return;
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
    if ([panel runModal] == NSModalResponseOK)
    {
        [self->_conkyConfigLocationTextfield setStringValue:panel.URL.path];
        [self enableMustAddSearchPathsMode];
    }
}

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
    if ([panel runModal] == NSModalResponseOK)
    {
        NSURL *theDocument = [[panel URLs] objectAtIndex:0];
        NSString *theDocumentInString = [theDocument path];
        
        /* add to table contents array if it doesn't already exist! */
        if (![self->_searchLocationsTableContents containsObject:theDocumentInString])
        {
            [self->_searchLocationsTableContents addObject:theDocumentInString];
            [self->_searchLocationsTable reloadData];
            
            [self enableMustAddSearchPathsMode];
        }
    }
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

/*
 * catch changes to _startupDelayField & _conkyConfigsLocationField
 */
- (void)controlTextDidChange:(NSNotification *)obj
{
#define STARTUP_DELAY_FIELD_ID @"startupDelayField"
#define CONFIGS_LOCAT_FIELD_ID @"conkyConfigsLocationField"
    
    NSString *senderID = [[obj object] identifier];
    
    if ([senderID isEqualToString:STARTUP_DELAY_FIELD_ID])
    {
        [self enableMustInstallAgentMode];
    }
    else if ([senderID isEqualToString:CONFIGS_LOCAT_FIELD_ID])
    {
        [self enableMustAddSearchPathsMode];
    }
}

- (IBAction)modifyStartupDelay:(id)sender
{
    _startupDelayField.integerValue = [sender integerValue];
    [self enableMustInstallAgentMode];
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

        [[MCSettings sharedSettings] uninstallCompletelyManageConkyFilesystem];
        
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
        [[MCSettings sharedSettings] installManageConkyFilesystem];
        
        [self close];
        [[MCSettings sharedSettings] popWindow];    // XXX should be handled by [self close]
        [self loadOnWindow:self.targetWindow];
        [self initStuff];
        [self toggleControls:NSOnState];
    }
}

- (IBAction)applyChanges:(id)sender
{
    MCSettings *MCSettingsHolder = [MCSettings sharedSettings];
    
    BOOL changesApplied = YES;
    
    NSString *userLaunchAgentPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents"];
    NSString *conkyAgentPlistPath = [userLaunchAgentPath stringByAppendingPathComponent:kConkyAgentPlistName];
    
    if (mustDisableConkyForStartup)
    {
        mustDisableConkyForStartup = NO;    /* revert */
        
        unlink([conkyAgentPlistPath UTF8String]);
        
        [MCSettingsHolder setConkyRunsAtStartup:NO];
    }
    else if (mustEnableConkyForStartup)
    {
        mustEnableConkyForStartup = NO; /* revert */
        
        NSWindow *sheet = self.window;
        NSInteger startupDelay_ = [_startupDelayField integerValue];
        static BOOL shownX11TakesAlotTimeWarning = NO;
        
        _oldStartupDelay = startupDelay_;   // commit update to backup
        
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
        
        [[MCSettings sharedSettings] setConkyRunsAtStartup:YES];
        [[MCSettings sharedSettings] setKeepAliveConky:keepAlive];
        [[MCSettings sharedSettings] setConkyStartupDelay:startupDelay_];
        
        [[NSApp mainWindow] setDocumentEdited:NO];
    }
    
    /*
     * We should be able to add/remove search paths to our list
     *  whether mustInstallAgent or mustRemoveAgent modes are enabled.
     */
    if (mustAddSearchPaths)
    {
        mustAddSearchPaths = NO;    /* revert */
        
        /*
         * Write Standard Configs Location
         */
        [[MCSettings sharedSettings] setConfigsLocation:_conkyConfigLocationTextfield.stringValue];
        _oldConfigsLocation = _conkyConfigLocationTextfield.stringValue;    /* update backup */
        
        /*
         * Write the Additional Search Locations
         */
        [[MCSettings sharedSettings] setAdditionalSearchPaths:_searchLocationsTableContents];
        
        /*
         * update backup keeper
         */
        _oldSearchLocationsTableContents = [NSMutableArray arrayWithArray:_searchLocationsTableContents];
        
        /*
         * refresh List of Widgets/Themes
         */
        [[[MCSettings sharedSettings] mainViewController] updateWidgetsThemesArray];
    }
    
    [_changesSavedLabel setStringValue:changesApplied ? @"Changes applied successfully" : @"Failed to apply changes!"];
    [_changesSavedLabel setHidden:NO];
    [_doneButton setTitle:@"OK"];
    [_applyChangesButton setHidden:YES];
}

- (IBAction)okButtonPressed:(id)sender
{
    BOOL worksAsCancelButton = (mustEnableConkyForStartup || mustDisableConkyForStartup || mustAddSearchPaths);
    
    if (worksAsCancelButton)
    {
        if (mustAddSearchPaths)
        {
            _searchLocationsTableContents = [NSMutableArray arrayWithArray:_oldSearchLocationsTableContents];
            [_searchLocationsTable reloadData];
        }
        
        _conkyConfigLocationTextfield.stringValue = _oldConfigsLocation;    // revert
        _startupDelayStepper.integerValue = _oldStartupDelay;   // revert
        _startupDelayField.integerValue = _oldStartupDelay;     // revert
        
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
        [[MCSettings sharedSettings] popWindow];    // XXX should be handled automatically by [self close]...
    }
}

//
//
// SEARCH LOCATIONS TABLE
//
//

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
