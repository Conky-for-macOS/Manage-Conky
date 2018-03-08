//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#import <ServiceManagement/ServiceManagement.h>
#import "PFMoveApplication.h"
#import <unistd.h>

/* defines */
#define kConkyAgentPlistName @"org.npyl.conky.plist"

#define CONKY_BUNDLE_IDENTIFIER "org.npyl.conky"

#define kConkyLaunchAgentLabel  @"org.npyl.conky"
#define kConkyExecutablePath    @"/Applications/ConkyX.app/Contents/Resources/conky"

#define CONKYX          @"/Applications/ConkyX.app"
#define MANAGE_CONKY    @"/Applications/Manage Conky.app"
#define CONKY_SYMLINK   @"/usr/local/bin/conky"


@implementation ConkyPreferencesSheetController

@synthesize runConkyAtStartupCheckbox = _runConkyAtStartupCheckbox;
@synthesize un_in_stallConkyButton = _un_in_stallConkyButton;
@synthesize conkyConfigFilesLocationLabel = _conkyConfigFilesLocationLabel;
@synthesize conkyConfigLocationTextfield = _conkyConfigLocationTextfield;

- (IBAction)activatePreferencesSheet:(id)sender
{
    [super activateSheet:@"ConkyPreferences"];
    
    /* Is ConkyX already installed? */
    conkyXInstalled = (access("/Applications/ConkyX.app", F_OK) == 0);
    
    [_un_in_stallConkyButton setTitle:conkyXInstalled ? @"Uninstall Conky" : @"Install Conky"];
    [_un_in_stallConkyButton setEnabled:YES];
    
    if (conkyXInstalled)
    {
        /* Is conky agent present? */
        NSString* conkyAgentPlistPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@", NSHomeDirectory(), kConkyAgentPlistName];
        
        conkyAgentPresent = (access([conkyAgentPlistPath UTF8String], R_OK) == 0);
        
        if (conkyAgentPresent)
            [_runConkyAtStartupCheckbox setState:1];
        else
            NSLog(@"Agent plist doesnt exist or not accessible!");
        
        /* Conky configuration file location? */
        NSString * conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
        
        if (!conkyConfigsPath)
        {
            NSString * kConkyConfigsDefaultPath = [NSString stringWithFormat:@"%@/.conky", NSHomeDirectory()];
            
            [[NSUserDefaults standardUserDefaults] setObject:kConkyConfigsDefaultPath forKey:@"configsLocation"];
            conkyConfigsPath = kConkyConfigsDefaultPath;
        }
        
        [_conkyConfigLocationTextfield setStringValue:conkyConfigsPath];
        [_conkyConfigLocationTextfield setDelegate:self];       /* Catch Enter-Key notification */
    }
    else
    {
        [_conkyConfigLocationTextfield setEnabled:NO];
        [_runConkyAtStartupCheckbox setEnabled:NO];
        [_conkyConfigFilesLocationLabel setTextColor:[NSColor grayColor]];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    /*
     * See if it was due to key ENTER
     */
    
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement )
    {
        [[NSUserDefaults standardUserDefaults] setObject:[_conkyConfigLocationTextfield stringValue] forKey:@"configsLocation"];
    }
}

- (IBAction)runConkyAtStartupCheckboxAction:(id)sender
{
    NSString * conkyAgentPlistPath = [NSString stringWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];
    
    if ([sender state] == NSOffState)
    {
        NSLog(@"Request to remove the Agent!");
        
        /* SMJobRemove() deprecated but suggested by Apple, see https://lists.macosforge.org/pipermail/launchd-dev/2016-October/001229.html */
        SMJobRemove(kSMDomainUserLaunchd, CFSTR(CONKY_BUNDLE_IDENTIFIER), nil, YES, nil);
        
        unlink( [conkyAgentPlistPath UTF8String] );
    }
    else
    {
        NSLog(@"Request to add the Agent!");
        
        id objects[] = { kConkyLaunchAgentLabel, @[ kConkyExecutablePath ], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES] };
        id keys[] = { @"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive" };
        NSUInteger count = sizeof(objects) / sizeof(id);
        
        NSDictionary * conkyAgentPlist = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
        
        NSAlert *keepAlivePrompt = [[NSAlert alloc] init];
        [keepAlivePrompt setMessageText:@"Select your preference"];
        [keepAlivePrompt setInformativeText:@"Always restart conky when for some reason it quits?"];
        [keepAlivePrompt setAlertStyle:NSAlertStyleInformational];
        [keepAlivePrompt addButtonWithTitle:@"Yes"];
        [keepAlivePrompt addButtonWithTitle:@"No"];
        
        NSModalResponse response = [keepAlivePrompt runModal];
        switch (response)
        {
            case NSAlertSecondButtonReturn:
                objects[3] = [NSNumber numberWithBool:NO];
                break;
        }
        
        [conkyAgentPlist writeToFile:conkyAgentPlistPath atomically:YES];
    }
}

- (IBAction)un_in_stallConky:(id)sender
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (conkyXInstalled)
    {
        /*
         * Uninstall conky
         */
        
        [fm removeItemAtPath:CONKYX error:&error];
        if (error)
        {
            NSLog(@"Error removing ConkyX: \n\n%@", error);
            return;
        }
        
        [fm removeItemAtPath:MANAGE_CONKY error:&error];
        if (error)
        {
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
        
        /*
         * Copy ConkyX.app to /Applications
         * using code from LetsMove to handle many cases
         * such as dmg, authentication etc.
         */
        CXForciblyMoveToApplicationsFolderConkyX();
        
        /* disable the Install/Uninstall button */
        [_un_in_stallConkyButton setEnabled:NO];
        
        /* create ConkyInstaller sheet */
        ctl = [[ConkyInstallerSheetController alloc] init];
        [[NSBundle mainBundle] loadNibNamed:@"ConkyInstaller" owner:ctl topLevelObjects:nil];
        [ctl beginInstalling];
    }
}

@end
