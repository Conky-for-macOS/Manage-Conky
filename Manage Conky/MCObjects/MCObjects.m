//
//  MCObjects.m
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects.h"


@implementation MCWidget
+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path
{
    id res = [[self alloc] init];
    [res setPid:pid];
    [res setItemPath:path];
    return res;
}
@end

@implementation MCTheme
+ (instancetype)themeWithResourceFile:(NSString *)themeRC
                         conkyConfigs:(NSArray *)configs
                            arguments:(NSArray *)args
                         startupDelay:(NSInteger)startupDelay
                            wallpaper:(NSString *)wallpaper
                              creator:(NSString *)creator
                            andSource:(NSString *)source;
{
    id res = [[self alloc] init];
    [res setThemeRC:themeRC];
    [res setConkyConfigs:configs];
    [res setArguments:args];
    [res setStartupDelay:startupDelay];
    [res setWallpaper:wallpaper];
    [res setCreator:creator];
    [res setSource:source];
    
    /* themeName */
    [res setThemeName:[[themeRC stringByDeletingLastPathComponent] lastPathComponent]];
    
    /*
     * Check if isEnabled by attempting to access a LaunchAgent
     */
    NSString *plistPath = [NSHomeDirectory() stringByAppendingFormat:@"/Library/LaunchAgents/%@.plist", [res themeName]];
    [res setIsEnabled: (access([plistPath UTF8String], R_OK) == 0)];
    
    return res;
}

+ (instancetype)themeRepresentationForThemeRC:(NSString *)themeRC
{
    /*
     * Information to be extracted from theme rc file
     */
    NSInteger startupDelay = 0;
    NSArray *conkyConfigs = [NSArray array];
    NSArray *arguments = [NSArray array];
    NSString *wallpaper = nil;
    __block NSString *scaling = nil;
    NSString *creator = @"unknown";
    NSString *source = @"unknown";
    
    /*
     * Is it modern or legacy theme?
     */
    BOOL useMCThemeRCFile = [[themeRC pathExtension] isEqualToString:@"plist"] ? YES : NO;
    
    if (useMCThemeRCFile)
    {
        /*
         * Doing it the ManageConky way...
         */        
        NSDictionary *rc = [NSDictionary dictionaryWithContentsOfFile:themeRC];
        
        startupDelay = [[rc objectForKey:@"startupDelay"] integerValue];
        conkyConfigs = [rc valueForKey:@"configs"];    // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        arguments = [rc valueForKey:@"args"];  // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        wallpaper = [[rc objectForKey:@"wallpaper"] stringByExpandingTildeInPath];
        source = [rc objectForKey:@"source"];
        creator = [rc objectForKey:@"creator"];
    }
    else
    {
        /*
         * Doing it the conky-manager way...
         */
        
        NSString *themeRoot = [themeRC stringByDeletingLastPathComponent];
        
        NSError *error = nil;
        NSMutableArray *lines = [[NSMutableArray alloc] init];
        
        [[NSString stringWithContentsOfFile:themeRC
                                   encoding:NSUTF8StringEncoding
                                      error:&error] enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            /* We need to avoid empty lines */
            if (![line isEqualToString:@""])
                [lines addObject:line];
        }];
        
        if ([lines count] == 0)
            return nil;
        
        /* pretty index */
        NSInteger i = [lines count] - 1;
        
        /*
         * Take scaling (last line)
         */
        scaling = [[lines objectAtIndex:i] substringFromIndex:18];
        
        /*
         * Take wallpaper which is always the line before-last;
         */
        i -= 1;
        wallpaper = [[lines objectAtIndex:i] stringByExpandingTildeInPath];
        
        /*
         * Remove scaling & wallpaper;
         * Leave only configs inside
         */
        [lines removeLastObject];
        [lines removeLastObject];
        
        /*
         * Take configs
         */
        /* first expand tilde */
        for (int i = 0; i < [lines count]; i++)
        {
            [lines setObject:[[lines objectAtIndex:i] stringByExpandingTildeInPath] atIndexedSubscript:i];
        }
        conkyConfigs = lines;
        
        source = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/source.txt"] encoding:NSUTF8StringEncoding error:nil];
        if (!source)
            source = @"unknown";
        creator = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/creator.txt"] encoding:NSUTF8StringEncoding error:nil];
        if (!creator)
            creator = @"unknown";
    }
    
    /*
     * create theme representation
     */
    return [self themeWithResourceFile:themeRC
                          conkyConfigs:conkyConfigs
                             arguments:arguments
                          startupDelay:startupDelay
                             wallpaper:wallpaper
                               creator:creator
                             andSource:source];
}

- (BOOL)apply_wallpaper:(NSString *)wallpaper error:(NSError **)error
{
    /*
     * based on https://github.com/sindresorhus/macos-wallpaper
     */
    
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSScreen *screen = [NSScreen mainScreen];
    NSMutableDictionary *so = [[sw desktopImageOptionsForScreen:screen] mutableCopy];
    
    return [sw setDesktopImageURL:[NSURL fileURLWithPath:wallpaper]
                        forScreen:screen
                          options:so
                            error:error];
}

- (void)applyTheme
{
    /**
     * We need to create a LaunchAgent item for this specific Theme
     *  which will be able to load each conky-config with its corresponding
     *  arguments for conky.  This can be 'easily' done by telling Launchd to
     *  execute a script which on its turn will do our job.
     */
#define MANAGE_CONKY_STAMP @"#;ManageConky;\n"
    
    /*
     * Apply wallpaper
     */
    NSError *err = nil;
    [self apply_wallpaper:_wallpaper error:&err];
    if (err)
    {
        NSLog(@"applyTheme: Failed to apply wallpaper with error: \n\n%@", err);
        return;
    }
    
    /*
     * create required directories
     */
    
    /*
     * Create the script
     */
    NSError *error = nil;
    NSString *scriptLocation = [NSHomeDirectory() stringByAppendingFormat:@"/Library/ManageConky/%@.sh", _themeName];
    NSString *scriptContents = MANAGE_CONKY_STAMP;
    /*
     * foreach config create a conky instance like so:
     * conky [args] -c  [config-path]
     */
    for (int i = 0; i < [_conkyConfigs count]; i++)
    {
        NSArray *args = [_arguments objectAtIndex:i];
        NSString *conf = [[_conkyConfigs objectAtIndex:i] stringByExpandingTildeInPath];
        
        scriptContents = [scriptContents stringByAppendingFormat:@"/usr/local/bin/conky %@ -c \"%@\"\n",
                          (args == nil ? @"" : args),
                          conf];
    }
    /* write file */
    [scriptContents writeToFile:scriptLocation
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];
    if (error)
    {
        NSLog(@"applyTheme: Error: \n\n%@", error);
        return;
    }
    
    NSLog(@"%@", scriptContents);
    
    /*
     * Create LaunchAgent for the script
     */
    NSString *plistPath = [NSHomeDirectory() stringByAppendingFormat:@"/Library/LaunchAgents/%@.plist", _themeName];
    id objects[] = {_themeName, @[@"/bin/sh", @"-c", scriptLocation], [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO], [NSNumber numberWithInteger:_startupDelay]};
    id keys[] = {@"Label", @"ProgramArguments", @"RunAtLoad", @"KeepAlive", @"ThrottleInterval"};
    NSUInteger count = sizeof(objects) / sizeof(id);
    
    NSDictionary *plist = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
    BOOL res = [plist writeToFile:plistPath atomically:YES];
    if (!res)
            NSLog(@"applyTheme: Error when saving launchAgent");
}
@end
