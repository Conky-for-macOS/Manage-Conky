//
//  PreferencesController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

- (void)awakeFromNib
{
    NSString *logfileLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"LogfileLocation"];
    
    if (!logfileLocation || [logfileLocation isEqualToString:@""])
    {
        _logfileLocationField.placeholderString = [_logfileLocationField.placeholderString stringByAppendingString:@" Default"];
    }
    else
    {
        _logfileLocationField.placeholderString = [_logfileLocationField.placeholderString stringByAppendingString:logfileLocation];
    }
    
    NSNumber *logging = [[NSUserDefaults standardUserDefaults] objectForKey:@"Logging"];
    [_loggingToggle setState:logging.boolValue];
    [_logfileLocationField setHidden:!logging.boolValue];
}

- (IBAction)toggleLogging:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]] forKey:@"Logging"];
    [_logfileLocationField setHidden:![sender state]];
}

- (IBAction)close:(id)sender;
{
    /* check if user did bother about logging; otherwise keep the old setting */
    if ([[_logfileLocationField stringValue] length] != 0)
        [[NSUserDefaults standardUserDefaults] setObject:_logfileLocationField.stringValue forKey:@"LogfileLocation"];
    
    [super close:sender];
}

@end
