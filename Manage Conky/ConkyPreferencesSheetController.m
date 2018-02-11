//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#include <unistd.h>
#include <ServiceManagement/ServiceManagement.h>

@implementation ConkyPreferencesSheetController

@synthesize runConkyAtStartupCheckbox = _runConkyAtStartupCheckbox;
@synthesize conkyConfigLocationTextfield = _conkyConfigLocationTextfield;


NSString * kConkyAgentPlistName = @"org.npyl.conky.plist";


- (IBAction)activatePreferencesSheet:(id)sender
{
    NSString * conkyAgentPlistPath = [[NSString alloc] initWithFormat:@"%@%@%@%@", @"/Users/", NSUserName(), @"/Library/LaunchAgents/", kConkyAgentPlistName ];
    
    [super activateSheet:@"ConkyPreferences"];
    
    /*
     *  Is conky agent present?
     */
    int res = access( [conkyAgentPlistPath UTF8String], R_OK);
    if (res < 0)
        NSLog( @"Agent plist doesnt exist or not accessible!" );
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
    // See if it was due to a return
    
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement )
    {
        [[NSUserDefaults standardUserDefaults] setObject:[_conkyConfigLocationTextfield stringValue] forKey:@"configsLocation"];
    }
}

- (IBAction)runConkyAtStartupCheckboxAction:(id)sender
{
    // XXX add support for themes
    
    NSString * conkyAgentPlistPath = [[NSString alloc] initWithFormat:@"%@%@%@%@", @"/Users/", NSUserName(), @"/Library/LaunchAgents/", kConkyAgentPlistName ];
    
    if ([sender state] == 0)
    {
        NSLog( @"Request to remove the Agent!" );
        
        // SMJobRemove() deprecated but suggested by Apple, see https://lists.macosforge.org/pipermail/launchd-dev/2016-October/001229.html
        SMJobRemove(kSMDomainUserLaunchd, CFSTR("org.npyl.conky"), nil, YES, nil);
        
        unlink( [conkyAgentPlistPath UTF8String] );
    }
    else if ([sender state] == 1)
    {
        NSLog( @"Request to add the Agent!" );
        
        NSString * kConkyLaunchAgentLabel = @"org.npyl.conky";
        NSString * kConkyExecutablePath = @"/Applications/ConkyX.app/Contents/Resources/conky";
        
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

@end
