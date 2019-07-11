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
                       NSAlert *failed = [[NSAlert alloc] init];
                       [failed setMessageText:@"Error!"];
                       [failed setInformativeText:msg];
                       [failed setAlertStyle:NSAlertStyleCritical];
                       [failed runModalSheetForWindow:window];
                   });
}

/*
 * Check if user has installed a version of conky through Homebrew
 */
bool usesHomebrewConky(void)
{
    __block bool usesHomebrewConky = NO;
    
    NSLog(@"Quering Homebrew to know if conky is installed.");
    
    @try
    {
        NSTask *brew = [[NSTask alloc] init];
        brew.launchPath = @"/bin/sh";
        brew.arguments = @[@"-l",
                           @"/usr/local/bin/brew",
                           @"list"];
        
        brew.environment = [NSProcessInfo processInfo].environment;
        brew.standardOutput = [NSPipe pipe];
        
        [[brew.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle * _Nonnull fh) {
            /*
             * Homebrew spurs unneeded data, causes this block to be called many times with no reason...
             * Use MC_RUN_ONLY_ONCE to prevent this.
             */
            
            NSData *data = [fh readDataToEndOfFile];
            if (!data)
                return;
            
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!str)
                return;

            /* check if we got an empty str... */
            if (str.length == 0)
                return;
            
            NSLog(@"Homebrew returned: \n%@", str);
            
            /* check if conky or conky-all is in the list */
            if ([str containsString:@"conky"])
                usesHomebrewConky = YES;
        }];
        
        [brew launch];
        [brew waitUntilExit];
    }
    @catch (NSException *ex)
    {
        NSLog(@"%@", ex);
    }
    
    return usesHomebrewConky;
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
    
    /* Create LaunchAgents in case it doesn't exist */
    createUserLaunchAgentsDirectory();
    
    /*
     * Remove $DISPLAY environment variable because
     * it changes upon each login; we don't want to
     * force conky to load on a false socket.
     */
    NSMutableDictionary *environment = [NSProcessInfo processInfo].environment.mutableCopy;
    [environment removeObjectForKey:@"DISPLAY"];
    
    AHLaunchJob* job = [AHLaunchJob new];
    job.Label = label;
    job.Program = @"/bin/bash";
    job.ProgramArguments = @[@"/bin/bash",
                             @"-l",
                             @"-c", cmd];
    job.ThrottleInterval = throttle;
    job.KeepAlive = [NSNumber numberWithBool:keepAlive];
    job.RunAtLoad = YES;
    job.WorkingDirectory = workingDirectory;
    job.EnvironmentVariables = environment;
    
    // All sharedController methods return BOOL values.
    // `YES` for success, `NO` on failure (which will also populate an NSError).
    [[AHLaunchCtl sharedController] add:job
                               toDomain:kAHUserLaunchAgent
                                  error:nil];

    [[AHLaunchCtl sharedController] start:label
                                 inDomain:kAHUserLaunchAgent
                                    error:&error];
}
