//
//  Shared.m
//  Manage Conky
//
//  Created by npyl on 31/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Shared.h"
#import <AHLaunchCtl/AHLaunchCtl.h>

void showErrorAlertWithMessageForWindow(NSString* msg, NSWindow* window)
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       NSExtendedAlert *failed = [[NSExtendedAlert alloc] init];
                       [failed setMessageText:@"Error!"];
                       [failed setInformativeText:msg];
                       [failed setAlertStyle:NSAlertStyleCritical];
                       [failed runModalSheetForWindow:window];
                   });
}

/**
 * MCDirectory()
 *
 * Easily retrieve path to ManageConky directory in ~/Library
 */
NSString *MCDirectory(void)
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/ManageConky"];
}

/**
 * createMCDirectory()
 *
 * Helper function to create ~/Library/ManageConky directory
 */
BOOL createMCDirectory(void)
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/ManageConky"];
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    if (error)
    {
        NSLog(@"Failed to create ManageConky directory with error: \n\n%@", error);
    }
    
    // XXX error handling
    
    return YES;
}

void createUserLaunchAgentsDirectory(void)
{
    /* create LaunchAgents directory at User's Home */
    NSString *userLaunchAgentPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:userLaunchAgentPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
}

BOOL createLaunchAgent(NSString *program,
                       NSString *label,
                       NSArray *args,
                       BOOL runAtLoad,
                       NSUInteger throttle)
{
    NSError *error = nil;
    
    AHLaunchJob* job = [AHLaunchJob new];
    job.Program = program;
    job.Label = label;
    job.ProgramArguments = args;
    job.ThrottleInterval = throttle;
    job.RunAtLoad = runAtLoad;
    
    // All sharedController methods return BOOL values.
    // `YES` for success, `NO` on failure (which will also populate an NSError).
    BOOL res = [[AHLaunchCtl sharedController] add:job
                                          toDomain:kAHUserLaunchAgent
                                             error:&error];
    
    if (error)
        NSLog(@"Error adding LaunchAgent. \n\n%@", error);
    
    return res;
}
