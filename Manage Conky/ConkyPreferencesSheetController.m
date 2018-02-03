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
     *  Conky agent present?
     */
    int res = access( [conkyAgentPlistPath UTF8String], R_OK);
    if (res < 0) {
        NSLog( @"Agent plist doesnt exist or not accessible!" );
        
        // NOTE: by default the checkbox is unchecked
    } else {
        [_runConkyAtStartupCheckbox setState:1];
    }
    
    
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
    [_conkyConfigLocationTextfield setDelegate:self];   /* Do that to allow, getting the Enter-Key notification */
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
    NSString * conkyAgentPlistPath = [[NSString alloc] initWithFormat:@"%@%@%@%@", @"/Users/", NSUserName(), @"/Library/LaunchAgents/", kConkyAgentPlistName ];
    
    NSString * kConkyLaunchAgentLabel = @"org.npyl.conky";
    NSString * kConkyExecutablePath = @"/Applications/ConkyX.app/Contents/Resources/conky";
    
    // TODO: add support for theme
    
    id objects[] = { kConkyLaunchAgentLabel, @[ kConkyExecutablePath ], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO] };
    id keys[] = { @"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive"  };
    NSUInteger count = sizeof(objects) / sizeof(id);
    
    NSDictionary * conkyAgentPlist = [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:count];
    
    
    switch ([sender state]) {
        case 0:
            NSLog( @"Request to remove the Agent!" );
            
            // SMJobRemove() deprecated but suggested by Apple, see https://lists.macosforge.org/pipermail/launchd-dev/2016-October/001229.html
            SMJobRemove( kSMDomainUserLaunchd, CFSTR("org.npyl.conky"), nil, YES, nil);
            
            unlink( [conkyAgentPlistPath UTF8String] );
            
            break;
        case 1:
            NSLog( @"Request to add the Agent!" );
 
            [conkyAgentPlist writeToFile:conkyAgentPlistPath atomically:YES];
            
            break;
        default:
            ;
    }
}

@end
