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

/*
 * Logging
 * =======
 */
BOOL shouldLogToFile = NO;
NSString *logfile = nil;
void NPLog(NSString *format, ...)
{
    va_list vargs;
    va_start(vargs, format);
    NSString* formattedMessage = [[NSString alloc] initWithFormat:format arguments:vargs];
    va_end(vargs);

    if (shouldLogToFile)
    {
        NSError *error = nil;

        /* create logfile if it doesn't exist */
        if (access(logfile.UTF8String, R_OK) != 0)
            [[NSFileManager defaultManager] createFileAtPath:logfile contents:nil attributes:nil];
        
        /* read contents */
        NSString *contents = [NSString stringWithContentsOfFile:logfile encoding:NSUTF8StringEncoding error:&error];

        if (error)
        {
            printf("Error opening logfile(%s): %s\n", logfile.UTF8String, error.localizedDescription.UTF8String);
        }
        
        error = nil;    // re-use

        /* write to file */
        contents = [contents stringByAppendingFormat:@"%@\n", formattedMessage];
        [contents writeToFile:logfile atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error)
        {
            printf("Error writing to logfile(%s): %s\n", logfile.UTF8String, error.localizedDescription.UTF8String);
        }
    }
    else
    {
        printf("%s\n", formattedMessage.UTF8String);
    }
}
