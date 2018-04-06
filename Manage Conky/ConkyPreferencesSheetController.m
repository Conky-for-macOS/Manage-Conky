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
#import <unistd.h>
#import "Shared.h"

/* defines */
#define kConkyAgentPlistName @"org.npyl.conky.plist"

#define CONKY_BUNDLE_IDENTIFIER "org.npyl.conky"
#define CONKYX_PATH             "/Applications/ConkyX.app"

#define kConkyLaunchAgentLabel  @"org.npyl.conky"
#define kConkyExecutablePath    @"/Applications/ConkyX.app/Contents/Resources/conky"

#define CONKYX          @"/Applications/ConkyX.app"
#define MANAGE_CONKY    @"/Applications/Manage Conky.app"
#define CONKY_SYMLINK   @"/usr/local/bin/conky"

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

- (IBAction)activatePreferencesSheet:(id)sender
{
    [super activateSheet:@"ConkyPreferences"];
    
    /* Is ConkyX already installed? */
    conkyXInstalled = (access(CONKYX_PATH, F_OK) == 0);
    
    // Install / Uninstall Button
    [_un_in_stallConkyButton setTitle:conkyXInstalled ? @"Uninstall Conky" : @"Install Conky"];
    [_un_in_stallConkyButton setEnabled:YES];
    
    // Startup Delay
    _startupDelayField.intValue = 20;   /* default value */
    
    // keepAlive
    keepAlive = YES;    /* default value */
    
    // mustInstall/RemoveAgent
    mustInstallAgent = NO;   /* default value */
    mustRemoveAgent = NO;   /* default value */
    mustAddSearchPaths = NO;    /* default value */
    
    if (conkyXInstalled)
    {
        /* first try to read already written information */
        
        _searchLocationsTableContents = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AdditionalSearchPaths"] mutableCopy];
        
        if (!_searchLocationsTableContents)
            _searchLocationsTableContents = [[NSMutableArray alloc] init];
        
        [_searchLocationsTable setDelegate:self];
        [_searchLocationsTable setDataSource:self];
        
        /* Is conky agent present? */
        NSString* conkyAgentPlistPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@", NSHomeDirectory(), kConkyAgentPlistName];
        
        conkyAgentPresent = (access([conkyAgentPlistPath UTF8String], R_OK) == 0);
        if (!conkyAgentPresent)
            NSLog(@"Agent plist doesnt exist or not accessible!");
        
        /* set checkbox state accordingly */
        [_runConkyAtStartupCheckbox setState:conkyAgentPresent];
        
        /* Conky configuration file location? */
        NSString * conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
        if (!conkyConfigsPath)
        {
            NSString *kConkyConfigsDefaultPath = [NSHomeDirectory() stringByAppendingString:@"/.conky"];    /* default value */
            
            [[NSUserDefaults standardUserDefaults] setObject:kConkyConfigsDefaultPath forKey:@"configsLocation"];
            conkyConfigsPath = kConkyConfigsDefaultPath;
        }
        
        [_conkyConfigLocationTextfield setStringValue:conkyConfigsPath];
    }
    else
    {
        [self disableControls];
    }
}

- (void)disableControls
{
    [_conkyConfigLocationTextfield setEnabled:NO];
    [_runConkyAtStartupCheckbox setEnabled:NO];
    [_conkyConfigFilesLocationLabel setTextColor:[NSColor grayColor]];
    [_startupDelayStepper setEnabled:NO];
    [_startupDelayField setEnabled:NO];
    [_startupDelayLabel setTextColor:[NSColor grayColor]];
    [_addSearchLocationButton setEnabled:NO];
    [_removeSearchLocationButton setEnabled:NO];
}

- (void)enableMustInstallAgentMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustInstallAgent = YES;
    mustRemoveAgent = NO;   /* disable if enabled */
}
- (void)enableMustRemoveAgentMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustRemoveAgent = YES;
    mustInstallAgent = NO;  /* disable if enabled */
}
- (void)enableMustAddSearchPathsMode
{
    [_changesSavedLabel setHidden:YES];
    [_applyChangesButton setHidden:NO];
    [_doneButton setTitle:@"Cancel"];
    mustRemoveAgent = NO;   /* disable if enabled */
    mustInstallAgent = NO;  /* disable if enabled */
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
        
        NSExtendedAlert *keepAlivePrompt = [[NSExtendedAlert alloc] init];
        [keepAlivePrompt setMessageText:@"Select your preference"];
        [keepAlivePrompt setInformativeText:@"Always restart conky when for some reason it quits?"];
        [keepAlivePrompt setAlertStyle:NSAlertStyleInformational];
        [keepAlivePrompt addButtonWithTitle:@"Yes"];
        [keepAlivePrompt addButtonWithTitle:@"No"];
        
        NSModalResponse response = [keepAlivePrompt runModalSheetForWindow:[super sheet]];
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
}

- (void)installConkyX
{
    /* create ConkyInstaller sheet */
    ctl = [[ConkyInstallerSheetController alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"ConkyInstaller" owner:ctl topLevelObjects:nil];
    [ctl beginInstalling];
}

- (IBAction)un_in_stallConky:(id)sender
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSWindow *_window = [super sheet];
    
    /* disable the Install/Uninstall button */
    [_un_in_stallConkyButton setEnabled:NO];
    
    if (conkyXInstalled)
    {
        /*
         * Uninstall conky
         */
        
        [self disableControls];
        
        /* unload agent */
        SMJobRemove(kSMDomainUserLaunchd, CFSTR(CONKY_BUNDLE_IDENTIFIER), nil, YES, nil);
        
        /* remove agent plist */
        NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];
        [fm removeItemAtPath:conkyAgentPlistPath error:&error];
        if (error)
        {
            NSLog(@"Error removing agent plist: \n\n%@", error);
            error = nil;
        }
        
        [fm removeItemAtPath:CONKYX error:&error];
        if (error)
        {
            showErrorAlertWithMessageForWindow(@"Failed to remove ConkyX.", _window);
            NSLog(@"Error removing ConkyX: \n\n%@", error);
            return;
        }
        
        [fm removeItemAtPath:MANAGE_CONKY error:&error];
        if (error)
        {
            showErrorAlertWithMessageForWindow(@"Failed to remove Manage Conky.", _window);
            NSLog(@"Error removing Manage Conky: \n\n%@", error);
            return;
        }
        
        [fm removeItemAtPath:CONKY_SYMLINK error:&error];
        if (error)
        {
            NSLog(@"Error removing symlink: \n\n%@", error);
        }
        
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
        
        [self installConkyX];
    }
}

- (IBAction)applyChanges:(id)sender
{
    BOOL changesApplied = NO;
    
    if (mustRemoveAgent)
    {
        /* revert */
        mustRemoveAgent = NO;
        
        NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@", NSHomeDirectory(), kConkyAgentPlistName];
        
        bool res1 = SMJobRemove(kSMDomainUserLaunchd, CFSTR(CONKY_BUNDLE_IDENTIFIER), nil, YES, nil);
        bool res2 = (unlink([conkyAgentPlistPath UTF8String]) == 0);
        
        changesApplied =  (res1 && res2);
    }
    else if (mustInstallAgent)
    {
        /* revert */
        mustInstallAgent = NO;
        
        NSWindow *sheet = [super sheet];
        NSInteger startupDelay_ = [_startupDelayField integerValue];
        static
        BOOL shownX11TakesAlotTimeWarning = NO;
        
        /*
         * show X11 warning
         */
        if (!shownX11TakesAlotTimeWarning && (startupDelay_ != 0))
        {
            NSExtendedAlert *alert = [[NSExtendedAlert alloc] init];
            [alert setMessageText:@"Warning"];
            [alert setInformativeText:@"Keep in mind that X11 takes aloooot time to open. You may want to recalculate your startup delay."];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModalSheetForWindow:sheet];
            
            shownX11TakesAlotTimeWarning = YES;
        }
        
        /*
         * We must create and save the Conky Agent Property List File
         */
        NSString *userLaunchAgentPath = [NSHomeDirectory() stringByAppendingString:@"/Library/LaunchAgents"];
        NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"%@/%@", userLaunchAgentPath, kConkyAgentPlistName];
        
        id objects[] = {kConkyLaunchAgentLabel, @[ kConkyExecutablePath, @"-b" ], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:keepAlive], [NSNumber numberWithInteger:startupDelay_]};
        id keys[] = {@"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive", @"ThrottleInterval"};
        NSUInteger count = sizeof(objects) / sizeof(id);
        
        /* create LaunchAgents directory at User's Home */
        NSError *error;
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:userLaunchAgentPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error)
        {
            NSLog(@"Failed to create LaunchAgents directory @Home with error: \n\n%@", error);
        }
        
        /* write the Agent plist */
        NSDictionary *conkyAgentPlist = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
        changesApplied = [conkyAgentPlist writeToFile:conkyAgentPlistPath atomically:YES];
        
        [[NSApp mainWindow] setDocumentEdited:NO];
        
        /* debug */
        NSLog(@"\n\n%@", conkyAgentPlist);
    }
    else if (mustAddSearchPaths)
    {
        /* revert */
        mustAddSearchPaths = NO;
        
        /*
         * Write the Additional Search Locations
         */
        [[NSUserDefaults standardUserDefaults] setObject:_searchLocationsTableContents forKey:@"AdditionalSearchPaths"];
        changesApplied = YES;
    }
    
    [_changesSavedLabel setStringValue:changesApplied ? @"Changes applied successfully" : @"Failed to apply changes!"];
    [_changesSavedLabel setHidden:NO];
    [_doneButton setTitle:@"OK"];
    [_applyChangesButton setHidden:YES];
}

- (IBAction)okButtonPressed:(id)sender
{
    NSWindow *sheet = [super sheet];
    BOOL worksAsCancelButton = mustInstallAgent || mustRemoveAgent || mustAddSearchPaths;
    
    if (worksAsCancelButton)
    {
        if (mustAddSearchPaths)
        {
            [_searchLocationsTableContents removeAllObjects];
            [_searchLocationsTable reloadData];
        }
        
        mustInstallAgent = NO;
        mustRemoveAgent = NO;
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
        [super closeSheet:sheet];
    }
}

/*
 * Called if the application has been relaunched from an update
 */
- (void)updaterDidRelaunchApplication:(SUUpdater *)updater
{
    /*
     * Install the newest version of ConkyX/conky
     *  brought by the updated ManageConky
     */
    NSLog(@"Must install ConkyX after update...");
    [self installConkyX];
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
    panel.allowsMultipleSelection = NO;
    panel.canSelectHiddenExtension = NO;
    
    /*
     * display the panel
     */
    [panel beginSheetModalForWindow:[super sheet] completionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *theDocument = [[panel URLs] objectAtIndex:0];
            NSString *theDocumentInString = [theDocument path];
            
            /* add to table contents array */
            [_searchLocationsTableContents addObject:theDocumentInString];
            [_searchLocationsTable reloadData];
            
            [self enableMustAddSearchPathsMode];
        }
    }];
}

- (IBAction)removeSearchLocation:(id)sender
{
    NSInteger selectedRow = [_searchLocationsTable selectedRow];
    
    if (selectedRow == -1)
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
