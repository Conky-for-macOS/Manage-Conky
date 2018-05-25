//
//  MCObjects.m
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects.h"
#import "Shared.h"  // createUserLaunchAgentsDirectory(), MCDirectory()

@implementation MCSettings
+ (instancetype)sharedInstance
{
    static id res = nil;
    if (!res)
        res = [[self alloc] init];
    return res;
}
- (void)setConkyRunsAtStartup:(BOOL)a
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:a]
                                              forKey:@"runConkyAtStartup"];
}
- (BOOL)conkyRunsAtStartup
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"runConkyAtStartup"] boolValue];
}

@end

@implementation MCWidgetOrTheme
- (void)enable {}
- (void)reenable {}
- (void)kill {}
- (void)disable {}
- (BOOL)isEnabled { return YES; }
- (void)configureMCSettingsHolder { MCSettingsHolder = [MCSettings sharedInstance]; }
@end

@implementation MCWidget
+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path
{
    id res = [[self alloc] init];
    [res setPid:pid];
    [res setItemPath:path];
    [res configureMCSettingsHolder];
    return res;
}

- (void)kill
{
    int stat_loc = 0;
    kill(_pid, SIGINT);
    waitpid(_pid, &stat_loc, WNOHANG);
    [self setPid:MC_PID_NOT_SET];
}

- (void)enable
{
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        /*
         * IF conky is set to run at startup we must do LaunchAgent housekeeping...
         */
        
        NSError *error;
        NSInteger startupDelay = 0;
        BOOL keepAlive = NO;
        NSString *MCConfigsRunnerScript = [MCDirectory() stringByAppendingPathComponent:@"startup.sh"];
        NSString *MCConfigsRunnerScriptContents = [NSString stringWithContentsOfFile:MCConfigsRunnerScript encoding:NSUTF8StringEncoding error:&error];
        
        if (!MCConfigsRunnerScriptContents)
            MCConfigsRunnerScriptContents = @"";
        
        startupDelay = [[[NSUserDefaults standardUserDefaults] objectForKey:@"startupDelay"] integerValue];
        keepAlive = [[[NSUserDefaults standardUserDefaults] objectForKey:@"keepAlive"] boolValue];
        
        /*
         * command to execute for starting this specific widget (consider the startupDelay)
         */
        NSString *cmd = [NSString stringWithFormat:@"%@conky -c %@ &\n",
                         MCConfigsRunnerScriptContents,
                         _itemPath];
        
        [cmd writeToFile:MCConfigsRunnerScript
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:&error];
        
        /*
         * setup the LaunchAgent
         */
        createLaunchAgent(@"/bin/sh",
                          @"org.npyl.conkyEnabledWidgets",
                          @[@"-c", MCConfigsRunnerScript],
                          keepAlive,
                          startupDelay);
        
        // xxx error checking
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/local/bin/conky"];
    [task setArguments:@[@"-c", _itemPath]];
    [task setCurrentDirectoryPath:[_itemPath stringByDeletingLastPathComponent]];
    [task launch];
    
    pid_t pid = [task processIdentifier];
    [self setPid:pid];
}

/**
 * re-enable
 *
 * Enable Widget BUT first check if already enabled and kill it
 * to achieve restart!
 */
- (void)reenable
{
    if ([self isEnabled])
        [self kill];
    [self enable];
}

- (void)disable
{
    [self kill];
    
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        /*
         * IF conky is set to run at startup we must do LaunchAgent housekeeping...
         */
        
        NSError *error;
        NSString *MCConfigsRunnerScript = [MCDirectory() stringByAppendingPathComponent:@"startup.sh"];
        NSString *MCConfigsRunnerScriptContents = [NSString stringWithContentsOfFile:MCConfigsRunnerScript encoding:NSUTF8StringEncoding error:&error];
        
        NSMutableArray *lines = [[MCConfigsRunnerScriptContents componentsSeparatedByString:@"\n"] mutableCopy];
        
        for (int i = 0; i < [lines count]; i++)
            if ([[lines objectAtIndex:i] containsString:_itemPath])
            {
                [lines removeObjectAtIndex:i];
                break;
            }
        
        [lines writeToFile:MCConfigsRunnerScript
                atomically:YES];
    }
}

- (BOOL)isEnabled
{
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        /*
         * IF conky is set to run at startup we must do LaunchAgent housekeeping...
         */
        
        NSError *error;
        NSString *MCConfigsRunnerScript = [MCDirectory() stringByAppendingPathComponent:@"startup.sh"];
        NSString *MCConfigsRunnerScriptContents = [NSString stringWithContentsOfFile:MCConfigsRunnerScript encoding:NSUTF8StringEncoding error:&error];
        
        return [MCConfigsRunnerScriptContents containsString:_itemPath] ? YES : NO;
    }
    else
    {
        return (_pid != MC_PID_NOT_SET) ? YES : NO;
    }
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
    
    /*
     * General properties
     */
    [res setThemeRC:themeRC];
    [res setConkyConfigs:configs];
    [res setArguments:args];
    [res setStartupDelay:startupDelay];
    [res setWallpaper:wallpaper];
    [res setCreator:creator];
    [res setSource:source];
    
    [res configureMCSettingsHolder];
    
    /*
     * themeName
     */
    [res setThemeName:[[themeRC stringByDeletingLastPathComponent] lastPathComponent]];
    
    /*
     * isEnabled?
     * Set isEnabled property by attempting to access the Theme's equivalent LaunchAgent plist
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
        NSMutableArray *lines = [NSMutableArray array];
        
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


/**
 * enable
 *
 * Applies this Theme to computer by:
 *  - applying conky config
 *  - applying wallpaper
 * supports two types of Themes:
 *  - original conky-manager Themes (plain files with minimal info) (backwards compatibility)
 *  - plist-based (support many parameters/features in a native macOS way)
 */
- (void)enable
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
    createUserLaunchAgentsDirectory();
    MCDirectory();
    
    /*
     * Create the script
     */
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
                          error:&err];
    if (err)
    {
        NSLog(@"applyTheme: Error: \n\n%@", err);
        return;
    }
    
    NSLog(@"%@", scriptContents);
    
    /*
     * Create LaunchAgent for the script
     */
    createLaunchAgent(@"/bin/sh",
                      _themeName,
                      @[@"-c", scriptLocation],
                      YES,
                      _startupDelay);
    // xxx error checking
}

/**
 * re-enable
 *
 * Enable Theme BUT first check if already enabled and kill it
 * to achieve restart!
 */
- (void)reenable
{
    if ([self isEnabled])
        [self kill];
    [self enable];
}

- (void)kill
{
}

- (void)disable
{
    NSLog(@"Off to disable Theme(%@)", self);
}
@end
