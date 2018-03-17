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

- (void)showAlertWithMessageText:(NSString*)msg informativeText:(NSString*)info andAlertStyle:(NSAlertStyle)style
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:msg];
    [alert setInformativeText:info];
    [alert setAlertStyle:style];
    [alert beginSheetModalForWindow:[super sheet] completionHandler:^(NSModalResponse returnCode) {}];
}

- (void)show_error_alert:(NSString*)withErrorMsg
{
    [self showAlertWithMessageText:@"Error" informativeText:withErrorMsg andAlertStyle:NSAlertStyleCritical];
}

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
    
    // mustInstallAgent
    mustInstallAgent = NO;   /* default value */
    
    if (conkyXInstalled)
    {
        /* Is conky agent present? */
        NSString* conkyAgentPlistPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@", NSHomeDirectory(), kConkyAgentPlistName];
        
        conkyAgentPresent = (access([conkyAgentPlistPath UTF8String], R_OK) == 0);
        
        if (conkyAgentPresent)  [_runConkyAtStartupCheckbox setState:1];
        else                    NSLog(@"Agent plist doesnt exist or not accessible!");
        
        /* Conky configuration file location? */
        NSString * conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
        if (!conkyConfigsPath)
        {
            NSString *kConkyConfigsDefaultPath = [NSString stringWithFormat:@"%@/.conky", NSHomeDirectory()];
            
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
}

- (IBAction)runConkyAtStartupCheckboxAction:(id)sender
{
    NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];
    
    if ([sender state] == NSOffState)
    {
        NSLog(@"Request to remove the Agent!");
        
        /* SMJobRemove() deprecated but suggested by Apple, see https://lists.macosforge.org/pipermail/launchd-dev/2016-October/001229.html */
        SMJobRemove(kSMDomainUserLaunchd, CFSTR(CONKY_BUNDLE_IDENTIFIER), nil, YES, nil);
        
        unlink([conkyAgentPlistPath UTF8String]);
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
        
        mustInstallAgent = YES;  /* set to install Agent later */
        [_doneButton setTitle:@"Save changes"];
        [[NSApp mainWindow] setDocumentEdited:YES];
    }
}

- (IBAction)modifyStartupDelay:(id)sender
{
    _startupDelayField.integerValue = [sender integerValue];
}

- (IBAction)startupDelayFieldEnterPressed:(id)sender
{
    static BOOL shownX11TakesAlotTimeWarning = NO;
    
    if (!shownX11TakesAlotTimeWarning)
    {
        NSWindow *win = [super sheet];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Warning"];
        [alert setInformativeText:@"Keep in mind that X11 takes aloooot time to open. You may want to recalculate your startup delay."];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:win completionHandler:^(NSModalResponse returnCode) {}];
        
        shownX11TakesAlotTimeWarning = YES;
    }
}

- (IBAction)conkyConfigLocationFieldEnterPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:@"configsLocation"];
}

- (IBAction)un_in_stallConky:(id)sender
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    /* disable the Install/Uninstall button */
    [_un_in_stallConkyButton setEnabled:NO];
    
    if (conkyXInstalled)
    {
        /*
         * Uninstall conky
         */
        
        [self disableControls];
        
        [fm removeItemAtPath:CONKYX error:&error];
        if (error)
        {
            [self show_error_alert:@"Failed to remove ConkyX."];
            NSLog(@"Error removing ConkyX: \n\n%@", error);
            return;
        }
        
        [fm removeItemAtPath:MANAGE_CONKY error:&error];
        if (error)
        {
            [self show_error_alert:@"Failed to remove Manage Conky."];
            NSLog(@"Error removing Manage Conky: \n\n%@", error);
            return;
        }
        
        [fm removeItemAtPath:CONKY_SYMLINK error:&error];
        if (error)
        {
            NSLog(@"Error removing symlink: \n\n%@", error);
        }
        
        NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];
        [fm removeItemAtPath:conkyAgentPlistPath error:&error];
        if (error)
        {
            [self show_error_alert:@"Failed to remove conky startup item."];
            NSLog(@"Error removing agent plist: \n\n%@", error);
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
        
        /*
         * Copy ConkyX.app to /Applications
         * using code from LetsMove to handle many cases
         * such as dmg, authentication etc.
         */
        CXForciblyMoveToApplicationsFolderConkyX();
        
        /* create ConkyInstaller sheet */
        ctl = [[ConkyInstallerSheetController alloc] init];
        [[NSBundle mainBundle] loadNibNamed:@"ConkyInstaller" owner:ctl topLevelObjects:nil];
        [ctl beginInstalling];
    }
}

- (IBAction)okButtonPressed:(id)sender
{
    /*
     * Here we save things to disk before we close the sheet
     */
    
    if (mustInstallAgent)
    {
        NSInteger startupDelay_ = [_startupDelayField integerValue];    /* deprecate the use/manipulation of startupDelay variable */
        
        /*
         * We must create and save the Conky Agent Property List File
         */
        NSString *conkyAgentPlistPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@", NSHomeDirectory(), kConkyAgentPlistName];
        
        id objects[] = {kConkyLaunchAgentLabel, @[ kConkyExecutablePath, @"-b" ], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:keepAlive], [NSNumber numberWithInteger:startupDelay_]};
        id keys[] = {@"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive", @"ThrottleInterval"};
        NSUInteger count = sizeof(objects) / sizeof(id);
        
        /* write the Agent plist */
        NSDictionary *conkyAgentPlist = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
        [conkyAgentPlist writeToFile:conkyAgentPlistPath atomically:YES];
        
        mustInstallAgent = NO;
        [[NSApp mainWindow] setDocumentEdited:NO];
        
        /* debug */
        NSLog(@"\n\n%@", conkyAgentPlist);
    }

    /*
     * Close the sheet
     */
    [super closeSheet:[super sheet]];
}

@end
