//
//  PreferencesController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "PreferencesController.h"

#import "MCObjects/MCObjects.h"

@implementation PreferencesController

- (void)awakeFromNib
{
    /*
     * Logging
     */
    NSString *logfileLocation = [[MCSettings sharedSettings] logfile];
    
    if (!logfileLocation || [logfileLocation isEqualToString:@""])
    {
        _logfileLocationField.placeholderString = [_logfileLocationField.placeholderString stringByAppendingString:@" Default"];
    }
    else
    {
        _logfileLocationField.placeholderString = [_logfileLocationField.placeholderString stringByAppendingString:logfileLocation];
    }
    
    BOOL shouldLogToFile = [[MCSettings sharedSettings] shouldLogToFile];
    [_loggingToggle setState:shouldLogToFile];
    [_logfileLocationField setHidden:!shouldLogToFile];
    
    /*
     * Resizeable Window
     */
    [_resizeableWindow setState:[MCSettings sharedSettings].canResizeWindow];
    [_usesAbsolutePaths setState:[MCSettings sharedSettings].usesAbsolutePaths];
}

- (IBAction)toggleLogging:(id)sender
{
    [[MCSettings sharedSettings] setShouldLogToFile:[sender state]];
    [_logfileLocationField setHidden:![sender state]];
}

- (IBAction)toggleResize:(id)sender
{
    [[MCSettings sharedSettings] setCanResizeWindow:[sender state]];
}

- (IBAction)toggleUseAbsolutePaths:(id)sender
{
    [[MCSettings sharedSettings] setUsesAbsolutePaths:[sender state]];
}

- (IBAction)close:(id)sender
{
    /* check if user did bother about logging; otherwise keep the old setting */
    if ([[_logfileLocationField stringValue] length] != 0)
        [[MCSettings sharedSettings] setLogfile:_logfileLocationField.stringValue];
    
    [super close:sender];
}

@end
