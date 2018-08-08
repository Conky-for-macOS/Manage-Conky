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

void createUserLaunchAgentsDirectory(void)
{
    /* create LaunchAgents directory at User's Home */
    NSString *userLaunchAgentPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents"];
    [[NSFileManager defaultManager] createDirectoryAtPath:userLaunchAgentPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
}

BOOL removeLaunchAgent(NSString* label)
{
    [[AHLaunchCtl sharedController] remove:label fromDomain:kAHUserLaunchAgent error:nil];
    return YES;
}

BOOL isLaunchAgentEnabled(NSString *label)
{
    NSString *path = [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@.plist", NSHomeDirectory(), label];
    return (access([path UTF8String], F_OK) == 0);
}

void createLaunchAgent(NSString *label,
                       NSArray *args,
                       BOOL keepAlive,
                       NSUInteger throttle,
                       NSString *workingDirectory,
                       NSError *error)
{
    NSString *cmd = [args componentsJoinedByString:@" "];
    
    AHLaunchJob* job = [AHLaunchJob new];
    job.Label = label;
    job.ProgramArguments = @[@"/bin/bash",
                             @"-l",
                             @"-c", cmd];
    job.ThrottleInterval = throttle;
    job.KeepAlive = [NSNumber numberWithBool:keepAlive];
    job.RunAtLoad = YES;
    job.WorkingDirectory = workingDirectory;
    job.EnvironmentVariables = [NSProcessInfo processInfo].environment;
    
    // All sharedController methods return BOOL values.
    // `YES` for success, `NO` on failure (which will also populate an NSError).
    [[AHLaunchCtl sharedController] add:job
                               toDomain:kAHUserLaunchAgent
                                  error:nil];
    
    [[AHLaunchCtl sharedController] start:label
                                 inDomain:kAHUserLaunchAgent
                                    error:&error];
}
