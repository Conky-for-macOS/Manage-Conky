//
//  ConkyPreferencesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyPreferencesSheetController.h"

#include <unistd.h>


@implementation ConkyPreferencesSheetController

@synthesize runConkyAtStartupCheckbox = _runConkyAtStartupCheckbox;
@synthesize conkyConfigLocationTextfield = _conkyConfigLocationTextfield;

NSString * kConkyConfigLocation = @"/Users/develnpyl/.conky";
NSString * kManageConkyPrefsPath = @"/Users/develnpyl/prefs.plist";

- (IBAction)activatePreferencesSheet:(id)sender
{
    NSDictionary * manageConkyPreferences = nil;
    NSString * conkyConfigLocation = @"";
    
 
    [super activateSheet:@"ConkyPreferences"];
    
    /*
     *  Conky agent present?
     */
    int res = access("/Library/LaunchAgents/org.npyl.conky.plist", R_OK);
    if (res < 0) {
        NSLog( @"Agent plist doesnt exist or not accessible!" );
    } else {
        [_runConkyAtStartupCheckbox setState:1];
    }
    
    /*
     *  Conky configuration file location?
     */
    res = access( [kManageConkyPrefsPath UTF8String], R_OK);
    if (res < 0) {
        id objects[] = { kConkyConfigLocation };
        id keys[] = { @"configLocation" };
        NSUInteger count = sizeof(objects) / sizeof(id);
        
        manageConkyPreferences = [[NSDictionary alloc] initWithObjects:objects forKeys:keys count:count];
        [manageConkyPreferences writeToFile:kManageConkyPrefsPath atomically:YES];
    }
    
    manageConkyPreferences = [[NSDictionary alloc] initWithContentsOfFile:kManageConkyPrefsPath];
    
    if (!manageConkyPreferences)
        return;
    
    conkyConfigLocation = [manageConkyPreferences objectForKey:@"configLocation"];
    [_conkyConfigLocationTextfield setStringValue:conkyConfigLocation];
}

@end
