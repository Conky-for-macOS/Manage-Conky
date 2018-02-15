//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#include <ServiceManagement/ServiceManagement.h>
#include <unistd.h>

/* defines */
#define kConkyAgentPlistName @"org.npyl.conky.plist"


@implementation ConkyPreferencesSheetController

@synthesize runConkyAtStartupCheckbox = _runConkyAtStartupCheckbox;
@synthesize conkyConfigLocationTextfield = _conkyConfigLocationTextfield;

- (IBAction)activatePreferencesSheet:(id)sender
{
    NSString * conkyAgentPlistPath = [[NSString alloc] initWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];
    
    [super activateSheet:@"ConkyPreferences"];
    
    /*
     *  Is conky agent present?
     */
    int res = access([conkyAgentPlistPath UTF8String], R_OK);
    if (res < 0)
        NSLog(@"Agent plist doesnt exist or not accessible!");
    else
        [_runConkyAtStartupCheckbox setState:1];
    
    /*
     *  Conky configuration file location?
     */
    NSString * conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    if (!conkyConfigsPath)
    {
        NSString * kConkyConfigsDefaultPath = [NSString stringWithFormat:@"/Users/%@/.conky", NSUserName()];
        
        if (!kConkyConfigsDefaultPath)
            return;
        
        [[NSUserDefaults standardUserDefaults] setObject:kConkyConfigsDefaultPath forKey:@"configsLocation"];
        conkyConfigsPath = kConkyConfigsDefaultPath;
    }
    
    [_conkyConfigLocationTextfield setStringValue:conkyConfigsPath];
    /* Do that to allow, getting the Enter-Key notification */
    [_conkyConfigLocationTextfield setDelegate:self];
}

-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    /*
     * See if it was due to key ENTER
     */
    
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement )
    {
        [[NSUserDefaults standardUserDefaults] setObject:[_conkyConfigLocationTextfield stringValue] forKey:@"configsLocation"];
    }
}

// XXX add support for themes
- (IBAction)runConkyAtStartupCheckboxAction:(id)sender
{
#define CONKY_BUNDLE_IDENTIFIER "org.npyl.conky"
    
    NSString * conkyAgentPlistPath = [[NSString alloc] initWithFormat:@"/Users/%@/Library/LaunchAgents/%@", NSUserName(), kConkyAgentPlistName];

    if ([sender state] == 0)
    {
        NSLog( @"Request to remove the Agent!" );
        
        /* SMJobRemove() deprecated but suggested by Apple, see https://lists.macosforge.org/pipermail/launchd-dev/2016-October/001229.html */
        SMJobRemove(kSMDomainUserLaunchd, CFSTR(CONKY_BUNDLE_IDENTIFIER), nil, YES, nil);
        
        unlink( [conkyAgentPlistPath UTF8String] );
    }
    else if ([sender state] == 1)
    {
#define kConkyLaunchAgentLabel  @"org.npyl.conky"
#define kConkyExecutablePath    @"/Applications/ConkyX.app/Contents/Resources/conky"
        
        NSLog( @"Request to add the Agent!" );
        
        id objects[] = { kConkyLaunchAgentLabel, @[ kConkyExecutablePath ], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES] };
        id keys[] = { @"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive" };
        NSUInteger count = sizeof(objects) / sizeof(id);
        
        NSDictionary * conkyAgentPlist = [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:count];
        
        NSAlert *keepAlivePrompt = [[NSAlert alloc] init];
        [keepAlivePrompt setMessageText:@"Select your preference"];
        [keepAlivePrompt setInformativeText:@"Always restart conky when for some reason it quits?"];
        [keepAlivePrompt setAlertStyle:NSAlertStyleInformational];
        [keepAlivePrompt addButtonWithTitle:@"YES"];
        [keepAlivePrompt addButtonWithTitle:@"NO"];
        
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
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    if (access("/Applications/ConkyX.app", F_OK) == 0)
    {
        /*
         * Uninstall conky
         */
        
        [fm removeItemAtPath:@"/Applications/ConkyX.app" error:&error];
        if (error)
        {
            NSLog(@"Error uninstalling conky from computer: %@", error);
            return;
        }
        
        [fm removeItemAtPath:@"/Applications/Manage Conky.app" error:&error];
        if (error)
        {
            NSLog(@"Error unistalling Manage Conky.app from your computer: %@", error);
            return;
        }
        
        NSAlert *successfullyUninstalled = [[NSAlert alloc] init];
        [successfullyUninstalled setMessageText:@"Successfully uninstalled!"];
        [successfullyUninstalled setInformativeText:@"conky (ConkyX and ManageConky) was successfully uninstalled from your computer. Manage Conky will now quit"];
        [successfullyUninstalled runModal];
        
        exit(0);
    }
    else
    {
        /*
         * Install Conky
         */
        
        [fm copyItemAtPath:@"ConkyX.app" toPath:@"/Applications" error:&error];
        if (error)
        {
            NSLog(@"error: %@", error);
            return;
        }
    }
}

@end
